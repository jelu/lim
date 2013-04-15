package Lim::RPC::Protocol::REST;

use common::sense;

use Scalar::Util qw(blessed weaken);

use HTTP::Status qw(:constants);
use HTTP::Request ();
use HTTP::Response ();
use URI ();
use URI::QueryParam ();
use JSON::XS ();

use Lim ();
use Lim::Util ();
use Lim::RPC::Callback ();

use base qw(Lim::RPC::Protocol);

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;
our $JSON = JSON::XS->new->ascii->convert_blessed;
our %REST_CRUD = (
    GET => 'READ',
    POST => 'UPDATE',
    PUT => 'CREATE',
    DELETE => 'DELETE'
);

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub Init {
}

=head2 function1

=cut

sub Destroy {
}

=head2 function1

=cut

sub name {
    'rest';
}

=head2 function1

=cut

sub serve {
}

=head2 function1

=cut

sub handle {
    my ($self, $cb, $request) = @_;
    
    unless (blessed($request) and $request->isa('HTTP::Request')) {
        return;
    }

    if ($request->uri =~ /^\/([a-zA-Z]+)\/([a-zA-Z_]+)(?:\/([^\?]*)){0,1}/o) {
        my ($module, $function, $parameters) = ($1, $2, $3);
        my $response = HTTP::Response->new;
        $response->request($request);
        $response->protocol($request->protocol);
        
        $module = lc($module);
        my $server = $self->server;
        if (defined $server and $server->have_module($module)) {
            my ($method, $call);
            
            if (exists $REST_CRUD{$request->method}) {
                $method = lc($REST_CRUD{$request->method});
            }
            else {
                $method = lc($request->method);
            }
            $function = lc($function);
            $call = ucfirst($method).Lim::Util::Camelize($function);

            my $obj;
            if ($server->have_module_call($module, $call)) {
                $obj = $server->module_obj_by_protocol($module, $self->name);
            }
            
            my ($query);
            if (defined $obj) {
                Lim::DEBUG and $self->{logger}->debug('API call ', $module, '->', $call, '()');
                
                if ($request->header('Content-Type') =~ /application\/x-www-form-urlencoded/o) {
                    my $query_str = $request->content;
                    $query_str =~ s/[\015\012]+$//o;

                    my $uri = URI->new;
                    $uri->query($query_str);

                    $query = $uri->query_form_hash;
                }
                elsif ($request->header('Content-Type') =~ /application\/json/o) {
                    eval {
                        $query = $JSON->decode($request->content);
                    };
                    if ($@) {
                        $response->code(HTTP_INTERNAL_SERVER_ERROR);
                        undef($query);
                        undef($obj);
                    }
                }
                else {
                    $query = $request->uri->query_form_hash;
                }
                
                if (ref($query) eq 'ARRAY' or ref($query) eq 'HASH') {
                    my @process = ($query);
                    
                    foreach my $process (shift(@process)) {
                        if (ref($process) eq 'ARRAY') {
                            push(@process, @$process);
                        }
                        elsif (ref($process) eq 'HASH') {
                            foreach my $key (keys %$process) {
                                if ($key =~ /^([a-zA-Z0-9_]+)\[([a-zA-Z0-9_]+)\]$/o) {
                                    my ($hname, $hkey) = ($1, $2);
                                    
                                    $process->{$hname}->{$hkey} = $process->{$key};
                                    delete $process->{$key};
                                    push(@process, $process->{$hname}->{$hkey});
                                }
                                elsif ($key =~ /^([a-zA-Z0-9_]+)\[\]$/o) {
                                    my $aname = $1;
                                    
                                    if (ref($process->{$key}) eq 'ARRAY') {
                                        push(@{$process->{$aname}}, @{$process->{$key}});
                                        push(@process, @{$process->{$key}});
                                    }
                                    else {
                                        push(@{$process->{$aname}}, $process->{$key});
                                        push(@process, $process->{$key});
                                    }
                                    delete $process->{$key};
                                }
                            }
                        }
                    }
                }
                
                if (defined $parameters) {
                    my $redirect_call = $server->process_module_call_uri_map($module, $call, $parameters, $query);
                    
                    if (defined $redirect_call and $redirect_call) {
                        Lim::DEBUG and $self->{logger}->debug('API call redirected ', $call, ' => ', $redirect_call);
                        $call = $redirect_call;
                    }
                }
            }
                
            if (defined $obj) {
                my $real_self = $self;
                weaken($self);
                $obj->$call(Lim::RPC::Callback->new(
                    cb => sub {
                        my ($result) = @_;
                        
                        unless (defined $self) {
                            return;
                        }
                        
                        if (blessed $result and $result->isa('Lim::Error')) {
                            $response->code($result->code);
                            eval {
                                $response->content($JSON->encode($result));
                            };
                            if ($@) {
                                $response->code(HTTP_INTERNAL_SERVER_ERROR);
                                $self->{logger}->warn('JSON encode error: ', $@);
                            }
                            else {
                                $response->header(
                                    'Content-Type' => 'application/json; charset=utf-8',
                                    'Cache-Control' => 'no-cache',
                                    'Pragma' => 'no-cache'
                                    );
                            }
                        }
                        elsif (ref($result) eq 'HASH') {
                            eval {
                                $response->content($JSON->encode($result));
                            };
                            if ($@) {
                                $response->code(HTTP_INTERNAL_SERVER_ERROR);
                                $self->{logger}->warn('JSON encode error: ', $@);
                            }
                            else {
                                $response->header(
                                    'Content-Type' => 'application/json; charset=utf-8',
                                    'Cache-Control' => 'no-cache',
                                    'Pragma' => 'no-cache'
                                    );
                                $response->code(HTTP_OK);
                            }
                        }
                        else {
                            $response->code(HTTP_INTERNAL_SERVER_ERROR);
                        }
                        
                        $cb->cb->($response);
                        return;
                    },
                    reset_timeout => sub {
                        $cb->reset_timeout;
                    }), $query);
                return 1;
            }
            else {
                $response->code(HTTP_NOT_FOUND);
            }
        }

        $cb->cb->($response);
        return 1;
    }
    return;
}

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Lim

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::RPC::Protocol::REST
