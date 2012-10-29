package Lim::RPC::Protocol::REST;

use common::sense;

use HTTP::Status qw(:constants);
use JSON::XS ();

use Lim ();
use Lim::Util ();

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
    my ($self, $request) = @_;
    
    unless (blessed($request) and $request->isa('Lim::RPC::Request')) {
        return;
    }

    unless (blessed($request->request) and $request->request->isa('HTTP::Request')) {
        return;
    }
    my $httpreq = $request->request;
    my $response = HTTP::Response->new;
    $response->request($httpreq);
    $response->protocol($httpreq->protocol);

    if ($httpreq->uri =~ /^\/([a-zA-Z]+)\/([a-zA-Z_]+)(?:\/([^\?]*)){0,1}/o) {
        my ($module, $function, $parameters) = ($1, $2, $3);
        
        $module = lc($module);
        my $server = $request->server;
        if (defined $server and $server->have_module($module)) {
            my ($method, $call);
            
            if (exists $REST_CRUD{$httpreq->method}) {
                $method = lc($REST_CRUD{$httpreq->method});
            }
            else {
                $method = lc($httpreq->method);
            }
            $function = lc($function);
            $call = ucfirst($method).Lim::Util::Camelize($function);

            my $obj;
            if ($server->have_module_call($module, $call)) {
                $obj = $server->module_obj($module);
            }
            
            my ($query, @parameters);
            if (blessed($obj)) {
                Lim::DEBUG and $self->{logger}->debug('API call ', $module, '->', $call, '()');
                
                if (defined $parameters) {
                    foreach my $parameter (split(/\//o, $parameters)) {
                        $parameter =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
                        push(@parameters, $parameter);
                    }
                }
            
                if ($httpreq->header('Content-Type') =~ /application\/x-www-form-urlencoded/o) {
                    my $query_str = $httpreq->content;
                    $query_str =~ s/[\015\012]+$//o;

                    my $uri = URI->new;
                    $uri->query($query_str);

                    $query = $uri->query_form_hash;
                }
                elsif ($httpreq->header('Content-Type') =~ /application\/json/o) {
                    eval {
                        $query = $JSON->decode($httpreq->content);
                    };
                    if ($@) {
                        $response->code(HTTP_INTERNAL_SERVER_ERROR);
                        undef($query);
                        undef($obj);
                    }
                }
                else {
                    $query = $httpreq->uri->query_form_hash;
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
            }
                
            if (blessed($obj)) {
#                my $real_self = $self;
#                weaken($self);
#                return $obj->$call(Lim::RPC::Callback::JSON->new(
#                    client => $self,
#                    cb => sub {
#                }), $query, @parameters);
                return 1;
            }
            else {
                $response->code(HTTP_NOT_FOUND);
            }
        }
        
        $request->set_response($response);
        $request->transport->result($request);
        return 1;
    }
    return;
}

=head2 function1

=cut

sub result {
                    my ($result) = @_;
                    
                    unless (defined $self) {
                        return;
                    }
                    
                    my $response = $self->{response};
                    
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
                    
                    $self->result;
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

Copyright 2012 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::RPC::Protocol::REST
