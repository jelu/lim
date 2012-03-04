package Lim::RPC::Server::Client;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(weaken blessed);
use Socket;

use AnyEvent ();
use AnyEvent::Handle ();

use HTTP::Status qw(:constants);
use HTTP::Request ();
use HTTP::Response ();
use URI ();
use URI::QueryParam ();

use JSON::XS ();

use Lim ();

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;
our $JSON = JSON::XS->new->ascii;
our %REST_CRUD = (
    GET => 'READ',
    POST => 'UPDATE',
    PUT => 'CREATE',
    DELETE => 'DELETE'
);

sub MAX_REQUEST_LEN (){ 256 * 1024 }

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %args = ( @_ );
    my $self = {
        logger => Log::Log4perl->get_logger,
        headers => ''
    };
    bless $self, $class;
    my $real_self = $self;
    weaken($self);

    unless (defined $args{fh}) {
        confess __PACKAGE__, ': Missing fh (file handle)';
    }
    unless (defined $args{tls_ctx}) {
        confess __PACKAGE__, ': Missing tls_ctx (TLS context)';
    }
    unless (defined $args{wsdl}) {
        confess __PACKAGE__, ': Missing wsdl (Path to WSDL files)';
    }
    unless (defined $args{server}) {
        confess __PACKAGE__, ': Missing server object';
    }

    if (exists $args{on_error} and ref($args{on_error}) eq 'CODE') {
        $self->{on_error} = $args{on_error};
    }
    if (exists $args{on_eof} and ref($args{on_eof}) eq 'CODE') {
        $self->{on_eof} = $args{on_eof};
        $args{on_eof} = sub {
            $self->close;
            $self->{on_eof}->($self);
        };
    }

    my ($port, $host) = sockaddr_in(getsockname($args{fh}));

    $self->{uri} = 'https://'.inet_ntoa($host).':'.$args{server}->{port};
    if (defined $args{html}) {
        $self->{html} = $args{html};
    }
    $self->{wsdl} = $args{wsdl};
    $self->{server} = $args{server};
    weaken($self->{server});
    $self->{handle} = AnyEvent::Handle->new(
        fh => $args{fh},
        tls => 'accept',
        tls_ctx => $args{tls_ctx},
        on_error => sub {
            my ($handle, $fatal, $message) = @_;
            
            $self->{logger}->warn($handle, ' Error: ', $message);

            if (exists $self->{on_error}) {
                $self->{on_error}->($self, $fatal, $message);
            }
            $handle->destroy;
        },
        on_eof => sub {
            my ($handle) = @_;
            
            $self->{logger}->warn($handle, ' EOF');
            
            if (exists $self->{on_eof}) {
                $self->{on_eof}->($self);
            }
            $handle->destroy;
        },
        on_read => sub {
            my ($handle) = @_;
            
            if ((length($self->{rbuf}) + length($handle->{rbuf})) > MAX_REQUEST_LEN) {
                if (exists $self->{on_error}) {
                    $self->{on_error}->($self, 1, 'Request too long');
                }
                $handle->push_shutdown;
                $handle->destroy;
                return;
            }
            
            unless (exists $self->{content}) {
                $self->{headers} .= $handle->{rbuf};
                
                if ($self->{headers} =~ /\r\n\r\n/o) {
                    my ($headers, $content) = split(/\r\n\r\n/o, $self->{headers}, 2);
                    $self->{headers} = $headers;
                    $self->{content} = $content;
                    $self->{request} = HTTP::Request->parse($self->{headers});
                }
            }
            else {
                $self->{content} .= $handle->{rbuf};
            }
            $handle->{rbuf} = '';
            
            if (defined $self->{request} and length($self->{content}) == $self->{request}->header('Content-Length')) {
                my $request = $self->{request};
                $request->content($self->{content});
                delete $self->{request};
                delete $self->{content};
                $self->{headers} = '';
                
                my $response = HTTP::Response->new;
                $response->request($request);
                $response->protocol($request->protocol);
                
                my $uri = $request->uri;

                Lim::DEBUG and $self->{logger}->debug('Request recieved for ', $uri);
                
                if ($uri =~ /^\/soap\/([a-zA-Z]+)/o) {
                    my $module = lc($1);
                    my $server = $self->{server}; # make a copy of server ref to make it strong
                    if (defined $server) {
                        if (exists $server->{module_name}->{$module}) {
                            eval {
                                $server->{soap}->request($request);
                                $server->{soap}->handle;
                                $response = $server->{soap}->response;
                            };
                            
                            if ($@) {
                                use Data::Dumper;
                                print "$@\n", Dumper($request), "\n\n", Dumper($response), "\n";
                            }
                            
                            $response->header(
                                'Cache-Control' => 'no-cache',
                                'Pragma' => 'no-cache'
                                );
                        }
                        else {
                            $response->code(HTTP_NOT_FOUND);
                        }
                    }
                    else {
                        $response->code(HTTP_INTERNAL_SERVER_ERROR);
                    }
                    undef($server);
                }
                elsif ($uri =~ /^\/wsdl\/([a-zA-Z_]+)/o) {
                    my $wsdl = lc($1);
                    my $server = $self->{server}; # make a copy of server ref to make it strong
                    if (defined $server) {
                        my $file = $self->{wsdl}.'/'.$wsdl.'.wsdl';

                        if (exists $server->{wsdl_module}->{$wsdl} and -f $file and open(FILE, $file)) {
                            my ($read, $buffer, $content) = (0, '', '');

                            Lim::DEBUG and $self->{logger}->debug('Sending wsdl ', $file);
                            
                            while (($read = read(FILE, $buffer, 64*1024))) {
                                $content .= $buffer;
                            }
                            close(FILE);
                            
                            unless (defined $read) {
                                $response->code(HTTP_INTERNAL_SERVER_ERROR);
                            }
                            else {
                                $content =~ s/\@SOAP_LOCATION\@/$self->{uri}/go;
                                $response->content($content);
                                $response->header(
                                    'Content-Type' => 'text/xml; charset=utf-8',
                                    'Cache-Control' => 'no-cache',
                                    'Pragma' => 'no-cache'
                                    );
                                $response->code(HTTP_OK);
                            }
                        }
                        else {
                            $response->code(HTTP_NOT_FOUND);
                        }
                    }
                    else {
                        $response->code(HTTP_INTERNAL_SERVER_ERROR);
                    }
                    undef($server);
                }
                elsif ($uri =~ /^\/([a-zA-Z]+)(?:\/([a-zA-Z]+)\/{0,1}([^\?]*)){0,1}/o) {
                    my ($module, $function, $parameters) = ($1, $2, $3);
                    
                    $module = lc($module);
                    my $server = $self->{server}; # make a copy of server ref to make it strong
                    if (defined $server and exists $server->{module_name}->{$module}) {
                        my ($method, $call);
                        
                        if (exists $REST_CRUD{$request->method}) {
                            $method = lc($REST_CRUD{$request->method});
                        }
                        else {
                            $method = lc($request->method);
                        }
                        unless (defined($function)) {
                            $function = 'index';
                        }
                        else {
                            $function = lc($function);
                        }
                        $call = ucfirst($method).ucfirst($function);
                        
                        if (exists $server->{module_name_call}->{$module}->{$call}) {
                            $module = $server->{module_name_call}->{$module}->{$call};
                        }
                        else {
                            foreach (@{$server->{module_name}->{$module}}) {
                                if ($_->can($call)) {
                                    $module =
                                        $server->{module_name_call}->{$module}->{$call} =
                                        $_;
                                    last;
                                }
                            }
                        }
                        
                        if (blessed($module)) {
                            my ($query, @parameters);

                            Lim::DEBUG and $self->{logger}->debug('API call ', $module->Module, '->', $call, '()');
                            
                            if (defined $parameters) {
                                foreach my $parameter (split(/\//o, $parameters)) {
                                    # TODO urldecode $parameter
                                    push(@parameters, $parameter);
                                }
                            }
                        
                            if ($request->header('Content-Type') =~ /application\/x-www-form-urlencoded/o) {
                                my $query_str = $request->content;
                                $query_str =~ s/[\r\n]+$//o;
    
                                my $uri = URI->new;
                                $uri->query($query_str);
    
                                $query = $uri->query_form_hash;
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
                            
                            my $result = $module->$call($query, @parameters);
                            if (ref($result) eq 'HASH' or ref($result) eq 'ARRAY') {
                                # TODO: handle JSON error
                                eval {
                                    $response->content($JSON->encode($result));
                                };
                                $response->header(
                                    'Content-Type' => 'application/json; charset=utf-8',
                                    'Cache-Control' => 'no-cache',
                                    'Pragma' => 'no-cache'
                                    );
                                $response->code(HTTP_OK);
                            }
                            else {
                                $response->code(HTTP_INTERNAL_SERVER_ERROR);
                            }
                        }
                        else {
                            $response->code(HTTP_NOT_FOUND);
                        }
                    }
                    undef($server);
                }
                
                if (!$response->code and exists $self->{html} and $uri =~ /^\//o) {
                    my $file = $self->{html};
                    
                    if ($uri eq '/') {
                        $uri = '/index.html';
                    }

                    $uri =~ s/\///o;
                    foreach my $path (split(/\//o, $uri)) {
                        if ($path eq '.' or $path eq '..') {
                            undef($file);
                            last;
                        }
                        if (-d $file.'/'.$path) {
                            $file .= '/'.$path;
                        }
                        elsif (-f $file.'/'.$path) {
                            $file .= '/'.$path;
                            last;
                        }
                        else {
                            undef($file);
                            last;
                        }
                    }
                    
                    if (defined $file and open(FILE, $file)) {
                        my ($read, $buffer, $content) = (0, '', '');

                        Lim::DEBUG and $self->{logger}->debug('Sending file ', $file);
                        
                        while (($read = read(FILE, $buffer, 64*1024))) {
                            $content .= $buffer;
                        }
                        close(FILE);
                        
                        unless (defined $read) {
                            $response->code(HTTP_INTERNAL_SERVER_ERROR);
                        }
                        else {
                            $response->content($content);
                            
                            if ($file =~ /\.js$/o) {
                                $response->header('Content-Type' => 'text/javascript; charset=utf-8');
                            }
                            elsif ($file =~ /\.css$/o) {
                                $response->header('Content-Type' => 'text/css; charset=utf-8');
                            }
                            $response->header(
                                'Cache-Control' => 'no-cache',
                                'Pragma' => 'no-cache'
                                );
                            $response->code(HTTP_OK);
                        }
                    }
                    else {
                        $response->code(HTTP_NOT_FOUND);
                    }
                }
                
                unless ($response->code) {
                    $response->code(HTTP_NOT_FOUND);
                }
                
                if ($response->code != HTTP_OK and !length($response->content)) {
                    $response->content($response->code.' '.HTTP::Status::status_message($response->code)."\r\n");
                }
                
                #$response->header('Connection' => 'close');
                $response->header('Content-Length' => length($response->content));
                unless (defined $response->header('Content-Type')) {
                    $response->header('Content-Type' => 'text/html; charset=utf-8');
                }
                
                unless ($response->protocol) {
                    $response->protocol('HTTP/1.1');
                }
                
                $handle->push_write($response->protocol.' '.$response->code.' '.HTTP::Status::status_message($response->code)."\r\n");
                $handle->push_write($response->headers_as_string("\r\n"));
                $handle->push_write("\r\n");
                $handle->push_write($response->content);
                #$handle->push_shutdown;
            }
        });
    
    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);

    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
    
    if (defined $self->{handle}) {
        $self->{handle}->push_shutdown;
    }
    delete $self->{handle};
}

=head2 function2

=cut

sub handle {
    $_[0]->{handle};
}

sub set_handle {
    $_[0]->{handle} = $_[1] if (defined $_[1]);
    
    $_[0];
}

=head2 function2

=cut

sub html {
    $_[0]->{html};
}

sub set_html {
    $_[0]->{html} = $_[1] if (defined $_[1]);
    
    $_[0];
}

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lim at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lim>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Lim


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lim>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lim>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lim>

=item * Search CPAN

L<http://search.cpan.org/dist/Lim/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::RPC::Server::Client