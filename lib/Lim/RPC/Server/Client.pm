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

use SOAP::Transport::HTTP ();
use XMLRPC::Transport::HTTP::Server ();

use JSON::XS ();

use Lim ();
use Lim::Error ();
use Lim::RPC::Callback::JSON ();
use Lim::RPC::Callback::SOAP ();
use Lim::RPC::Callback::XMLRPC ();
use Lim::RPC::Callback::JSONRPC ();

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

sub MAX_REQUEST_LEN (){ 8 * 1024 * 1024 }

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
        headers => '',
        close => 0
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
    $self->{server} = $args{server};
    weaken($self->{server});
    
    $self->{handle} = AnyEvent::Handle->new(
        fh => $args{fh},
        tls => 'accept',
        tls_ctx => $args{tls_ctx},
        timeout => Lim::Config->{rpc}->{timeout},
        on_error => sub {
            my ($handle, $fatal, $message) = @_;
            
            $self->{logger}->warn($handle, ' Error: ', $message);

            if (exists $self->{on_error}) {
                $self->{on_error}->($self, $fatal, $message);
            }
            $handle->destroy;
        },
        on_timeout => sub {
            my ($handle) = @_;
            
            $self->{logger}->warn($handle, ' TIMEOUT');
            
            if (exists $self->{processing}) {
                $self->timeout;
            }
            
            if (exists $self->{on_eof}) {
                $self->{on_eof}->($self);
            }
            $handle->destroy;
        },
        on_eof => sub {
            my ($handle) = @_;
            
            $self->{logger}->debug($handle, ' EOF');
            
            if (exists $self->{on_eof}) {
                $self->{on_eof}->($self);
            }
            $handle->destroy;
        },
        on_drain => sub {
            if ($self->{close}) {
                shutdown $_[0]{fh}, 2;
            }
        },
        on_read => sub {
            my ($handle) = @_;
            
            if (exists $self->{process_watcher}) {
                if (exists $self->{on_error}) {
                    $self->{on_error}->($self, 1, 'Request received while processing other request');
                }
                $handle->push_shutdown;
                $handle->destroy;
                return;
            }
            
            if ((length($self->{headers}) + (exists $self->{content} ? length($self->{content}) : 0) + length($handle->{rbuf})) > MAX_REQUEST_LEN) {
                if (exists $self->{on_error}) {
                    $self->{on_error}->($self, 1, 'Request too long');
                }
                $handle->push_shutdown;
                $handle->destroy;
                return;
            }
            
            unless (exists $self->{content}) {
                $self->{headers} .= $handle->{rbuf};
                
                if ($self->{headers} =~ /\015?\012\015?\012/o) {
                    my ($headers, $content) = split(/\015?\012\015?\012/o, $self->{headers}, 2);
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
                $self->{request}->content($self->{content});
                delete $self->{content};
                $self->{headers} = '';
                
                Lim::RPC_DEBUG and $self->{logger}->debug('HTTP Request: ', $self->{request}->as_string);
                
                $self->{processing} = 1;
                $self->{handle}->timeout(Lim::Config->{rpc}->{call_timeout});
                $self->{process_watcher} = AnyEvent->timer(
                    after => 0,
                    cb => sub {
                        $self->process;
                    });
            }
        });
    
    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);

    $real_self;
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

=head2 function2

=cut

sub process {
    my ($self) = @_;
    
    my $request = $self->{request};
    my $response = HTTP::Response->new;
    $response->request($request);
    $response->protocol($request->protocol);
    
    $self->{response} = $response;

    my $uri = $request->uri;

    Lim::DEBUG and $self->{logger}->debug('Request recieved for ', $uri);
    
    if ($uri =~ /^\/([a-zA-Z]+)\s*$/o) {
        my $module = lc($1);
        my $server = $self->{server}; # make a copy of server ref to make it strong
        if (defined $server) {
            if (exists $server->{module}->{$module}) {
                
                #
                # Handle SOAP
                #

                if ($request->header('SOAPAction')) {
                    Lim::RPC_DEBUG and $self->{logger}->debug('SOAP dispatch to module ', $server->{module}->{$module}->{module}, ' obj ', $server->{module}->{$module}->{obj});
    
                    unless (exists $self->{soap}) {
                        $self->{soap} = SOAP::Transport::HTTP::Server->new;
                        $self->{soap}->serializer->ns('urn:'.$server->{module}->{$module}->{module}.'::Server', 'lim1');
                        $self->{soap}->serializer->autotype(0);
                    }
                    
                    {
                        my ($action, $method_uri, $method_name);
                        my $self2 = $self;
                        weaken($self2);
                        $self->{soap}->on_dispatch(sub {
                            my ($request) = @_;
                            
                            unless (defined $self2) {
                                return;
                            }
                            
                            $request->{__lim_rpc_cb} = Lim::RPC::Callback::SOAP->new(
                                client => $self2,
                                cb => sub {
                                my ($data) = @_;
                                
                                unless (defined $self2) {
                                    return;
                                }
                                
                                if (blessed $data and $data->isa('Lim::Error')) {
                                    $self2->{soap}->make_fault($data->code, $data->message);
                                }
                                else {
                                    my $result;
                                    
                                    if (defined $data) {
                                        $result = $self2->{soap}->serializer
                                            ->prefix('s')
                                            ->uri($method_uri)
                                            ->envelope(response => $method_name . 'Response', $data);
                                    }
                                    else {
                                        $result = $self2->{soap}->serializer
                                            ->prefix('s')
                                            ->uri($method_uri)
                                            ->envelope(response => $method_name . 'Response');
                                        $result =~ s/ xsi:nil="true"//go;
                                    }
                                    
                                    $self2->{soap}->make_response($SOAP::Constants::HTTP_ON_SUCCESS_CODE, $result);
                                }
                                
                                $self2->{response} = $self2->{soap}->response;
                                $self2->{response}->header(
                                    'Cache-Control' => 'no-cache',
                                    'Pragma' => 'no-cache'
                                    );
            
                                $self2->result;
                            });
                            
                            return;
                        });
                        
                        $self->{soap}->on_action(sub {
                            ($action, $method_uri, $method_name) = @_;
                        });
                    }

                    $self->{call_type} = 'soap';
                    $self->{soap}->dispatch_to($server->{module}->{$module}->{obj});
                    
                    eval {
                        $self->{soap}->request($request);
                        $self->{soap}->handle;
                    };
                    if ($@) {
                        $self->{logger}->warn('SOAP action failed: ', $@);
                    }
                    return;
                }
                
                #
                # Handle XML-RPC
                #
                
                elsif ($request->header('Content-Type') =~ /(?:^|\s)text\/xml(?:$|\s)/o) {
                    Lim::RPC_DEBUG and $self->{logger}->debug('XMLRPC dispatch to module ', $server->{module}->{$module}->{module}, ' obj ', $server->{module}->{$module}->{obj});
    
                    unless (exists $self->{xmlrpc}) {
                        $self->{xmlrpc} = XMLRPC::Transport::HTTP::Server->new;
                    }
                    
                    {
                        my ($method_uri, $method_name);
                        my $self2 = $self;
                        weaken($self2);
                        
                        $method_uri = 'urn:'.$server->{module}->{$module}->{module}.'::Server';
                        
                        $self->{xmlrpc}->on_dispatch(sub {
                            my ($request) = @_;
                            
                            unless (defined $self2) {
                                return;
                            }
                            
                            $request->{__lim_rpc_cb} = Lim::RPC::Callback::XMLRPC->new(
                                client => $self2,
                                cb => sub {
                                my (@data) = @_;
                                
                                unless (defined $self2) {
                                    return;
                                }
                                
                                if (blessed $data[0] and $data[0]->isa('Lim::Error')) {
                                    $self2->{xmlrpc}->make_fault($data[0]->code, $data[0]->message);
                                }
                                else {
                                    my $result = $self2->{xmlrpc}->serializer
                                        ->prefix('s')
                                        ->uri($method_uri)
                                        ->envelope(response => $method_name . 'Response', @data);
                                    
                                    $self2->{xmlrpc}->make_response($SOAP::Constants::HTTP_ON_SUCCESS_CODE, $result);
                                }
                                
                                $self2->{response} = $self2->{xmlrpc}->response;
                                $self2->{response}->header(
                                    'Cache-Control' => 'no-cache',
                                    'Pragma' => 'no-cache'
                                    );
            
                                $self2->result;
                            });
                            
                            unless ($request->method =~ /^\w+$/o) {
                                $request->{__lim_rpc_cb}->(Lim::Error->new(500, 'Invalid characters in method name'));
                                return;
                            }
                            
                            return ($method_uri, ($method_name = $request->method));
                        });
                    }
    
                    $self->{call_type} = 'xmlrpc';
                    $self->{xmlrpc}->dispatch_to($server->{module}->{$module}->{obj});
                    
                    eval {
                        $self->{xmlrpc}->request($request);
                        $self->{xmlrpc}->handle;
                    };
                    if ($@) {
                        $self->{logger}->warn('XML-RPC action failed: ', $@);
                    }
                    return;
                    
                }
                
                #
                # Handle JSON-RPC v2
                #
                
                elsif ($request->header('Content-Type') =~ /(?:^|\s)application\/json(?:$|\s)/o) {
                    my ($jsonreq, $jsonresp);
                    
                    eval {
                        $jsonreq = $JSON->decode($request->content);
                    };
                    unless ($@) {
                        if (ref($jsonreq) eq 'HASH') {
                            if (exists $jsonreq->{jsonrpc} and exists $jsonreq->{id} and exists $jsonreq->{method}) {
                                if ($server->{module}->{$module}->{module}->Calls->{$jsonreq->{method}}) {
                                    my $id = $jsonreq->{id};
                                    my $obj = $server->{module}->{$module}->{obj};
                                    my $call = $jsonreq->{method};
                                    
                                    $self->{call_type} = 'jsonrpc';
                                    weaken($self);
                                    unless (defined $self) {
                                        return;
                                    }
                                    return $obj->$call(Lim::RPC::Callback::JSONRPC->new(
                                        client => $self,
                                        cb => sub {
                                        my ($result) = @_;
                                        
                                        unless (defined $self) {
                                            return;
                                        }
                                        
                                        my $response = $self->{response};
                                        
                                        if (blessed $result and $result->isa('Lim::Error')) {
                                            $response->code($result->code);
                                            eval {
                                                $response->content($JSON->encode({
                                                    jsonrpc => '2.0',
                                                    error => {
                                                        code => $result->code,
                                                        message => $result->message
                                                    },
                                                    id => $id
                                                }));
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
                                                $response->content($JSON->encode({
                                                    jsonrpc => '2.0',
                                                    result => $result,
                                                    id => $id
                                                }));
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
                                    }), $jsonreq->{params});
                                }
                                else {
                                    $jsonresp = {
                                        jsonrpc => '2.0',
                                        error => {
                                            code => -32601,
                                            message => 'Method not found'
                                        },
                                        id => $jsonreq->{id}
                                    };
                                }
                            }
                            else {
                                $jsonresp = {
                                    jsonrpc => '2.0',
                                    error => {
                                        code => -32600,
                                        message => 'Invalid Request'
                                    },
                                    id => $jsonreq->{id}
                                };
                            }
                        }
                        else {
                            $response->code(HTTP_INTERNAL_SERVER_ERROR);
                        }
                    }
                    if ($@ and !defined $jsonresp) {
                        $jsonresp = {
                            jsonrpc => '2.0',
                            error => {
                                code => -32700,
                                message => 'Parse error'
                            },
                            id => undef
                        };
                    }
                    if (defined $jsonresp) {
                        eval {
                            $response->content($JSON->encode($jsonresp));
                        };
                        if ($@) {
                            $response->code(HTTP_INTERNAL_SERVER_ERROR);
                        }
                    }
                    elsif (!$response->code) {
                        $response->code(HTTP_INTERNAL_SERVER_ERROR);
                    }
                }
                
                #
                # No RPC found
                #
                
                else {
                    $response->code(HTTP_NOT_FOUND);
                }
            }
            else {
                $response->code(HTTP_INTERNAL_SERVER_ERROR);
            }
            undef($server);
        }
        else {
            $response->code(HTTP_INTERNAL_SERVER_ERROR);
        }
    }
    elsif ($uri =~ /^\/([a-zA-Z]+)\.wsdl/o) {
        my $module = lc($1);
        my $server = $self->{server}; # make a copy of server ref to make it strong
        if (defined $server) {
            if (exists $server->{module}->{$module}) {
                unless (defined $server->{module}->{$module}->{wsdl}) {
                    $response->code(HTTP_INTERNAL_SERVER_ERROR);
                }
                else {
                    $response->content($server->{module}->{$module}->{wsdl}->[0].
                        $self->{uri}.'/'.$server->{module}->{$module}->{name}.
                        $server->{module}->{$module}->{wsdl}->[1]);
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
    elsif ($uri =~ /^\/([a-zA-Z]+)\/([a-zA-Z_]+)(?:\/([^\?]*)){0,1}/o) {
        my ($module, $function, $parameters) = ($1, $2, $3);
        
        $module = lc($module);
        my $server = $self->{server}; # make a copy of server ref to make it strong
        if (defined $server and exists $server->{module}->{$module}) {
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
            if ($server->{module}->{$module}->{module}->Calls->{$call}) {
                $obj = $server->{module}->{$module}->{obj};
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
            }
                
            if (blessed($obj)) {
                $self->{call_type} = 'json';
                weaken($self);
                unless (defined $self) {
                    return;
                }
                return $obj->$call(Lim::RPC::Callback::JSON->new(
                    client => $self,
                    cb => sub {
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
                }), $query, @parameters);
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
    
    $self->result;
}

=head2 function2

=cut

sub result {
    my ($self) = @_;
    my $response = $self->{response};
    my $handle = $self->{handle};

    unless (exists $self->{processing}) {
        return;
    }
    
    unless ($response->code) {
        $response->code(HTTP_NOT_FOUND);
    }
    
    if ($response->code != HTTP_OK and !length($response->content)) {
        $response->header('Content-Type' => 'text/plain; charset=utf-8');
        $response->content($response->code.' '.HTTP::Status::status_message($response->code)."\015\012");
    }
    
    $response->header('Content-Length' => length($response->content));
    unless (defined $response->header('Content-Type')) {
        $response->header('Content-Type' => 'text/html; charset=utf-8');
    }
    
    unless ($response->protocol) {
        $response->protocol('HTTP/1.1');
    }
    
    Lim::RPC_DEBUG and $self->{logger}->debug('HTTP Response: ', $response->as_string);

    if ($self->{request}->header('Connection') eq 'close') {
        Lim::RPC_DEBUG and $self->{logger}->debug('Connection requested to be closed');
        $self->{handle}->timeout(0);
        $self->{close} = 1;
    }
    else {
        $self->{handle}->timeout(Lim::Config->{rpc}->{timeout});
    }
    $handle->push_write($response->as_string("\015\012"));

    delete $self->{call_type};
    delete $self->{processing};
    delete $self->{request};
    delete $self->{response};
    delete $self->{process_watcher};
}

=head2 function2

=cut

sub timeout {
    my ($self) = @_;
    my $response = $self->{response};
    
    if (exists $self->{call_type}) {
        if ($self->{call_type} eq 'soap' and defined $self->{soap}) {
            $self->{soap}->make_fault(408, 'Call Timeout');
            $self->{response} = $self->{soap}->response;
            $self->{response}->header(
                'Cache-Control' => 'no-cache',
                'Pragma' => 'no-cache'
                );
        }
        elsif ($self->{call_type} eq 'xmlrpc') {
            $self->{xmlrpc}->make_fault(408, 'Call Timeout');
            $self->{response} = $self->{xmlrpc}->response;
            $self->{response}->header(
                'Cache-Control' => 'no-cache',
                'Pragma' => 'no-cache'
                );
        }
        elsif ($self->{call_type} eq 'jsonrpc') {
            $response->code(HTTP_REQUEST_TIMEOUT);
            eval {
                $response->content($JSON->encode({
                    jsonrpc => '2.0',
                    error => {
                        code => -32000,
                        message => 'Call Timeout'
                    },
                    id => undef
                }));
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
        elsif ($self->{call_type} eq 'json') {
            $response->code(HTTP_REQUEST_TIMEOUT);
            eval {
                $response->content($JSON->encode(Lim::Error->new(
                    code => 408,
                    message => 'Call Timeout',
                    module => $self
                )));
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
        else {
            $response->code(HTTP_INTERNAL_SERVER_ERROR);
        }
    }
    
    $self->result;
}

=head2 function2

=cut

sub reset_timeout {
    if (defined $_[0]->{handle}) {
        $_[0]->{handle}->timeout_reset;
    }
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

1; # End of Lim::RPC::Server::Client
