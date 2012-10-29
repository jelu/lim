package Lim::RPC::Transport::HTTP::Client;

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
use Lim::RPC::Transport::HTTP ();
use Lim::RPC::Request ();


use Lim::Error ();
use Lim::RPC::Callback::JSON ();
use Lim::RPC::Callback::SOAP ();
use Lim::RPC::Callback::XMLRPC ();
use Lim::RPC::Callback::JSONRPC ();

use base qw(Lim::RPC::Transport);

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::RPC::Transport::HTTP::VERSION;
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

sub Init {
    my $self = shift;
    my %args = ( @_ );
    my $real_self = $self;
    weaken($self);

    $self->{headers} = '';
    $self->{close} = 0;

    unless (defined $args{fh}) {
        confess __PACKAGE__, ': Missing fh (file handle)';
    }
    if ($self->isa('Lim::RPC::Transport::HTTPS::Client')) {
        unless (defined $args{tls_ctx}) {
            confess __PACKAGE__, ': Missing tls_ctx (TLS context)';
        }
    }
    unless (defined $args{transport} and $args{transport}->isa('Lim::RPC::Transport::HTTP')) {
        confess __PACKAGE__, ': Missing transport object';
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

    $self->{transport} = $args{transport};
    #weaken($self->{transport});
    
    $self->{handle} = AnyEvent::Handle->new(
        fh => $args{fh},
        ($self->isa('Lim::RPC::Transport::HTTPS::Client') ? (tls => 'accept', tls_ctx => $args{tls_ctx}) : ()),
        timeout => Lim::Config->{rpc}->{timeout},
        on_error => sub {
            my ($handle, $fatal, $message) = @_;
            
            $self->{logger}->warn($handle, ' Error: ', $message);

            if (exists $self->{on_error}) {
                $self->{on_error}->($self, $fatal, $message);
            }
            $handle->destroy;
        },
#        on_timeout => sub {
#            my ($handle) = @_;
#            
#            $self->{logger}->warn($handle, ' TIMEOUT');
#            
#            if (exists $self->{processing}) {
#                $self->timeout;
#            }
#            
#            if (exists $self->{on_eof}) {
#                $self->{on_eof}->($self);
#            }
#            $handle->destroy;
#        },
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
#                $self->{handle}->timeout(Lim::Config->{rpc}->{call_timeout});
                $self->{process_watcher} = AnyEvent->timer(
                    after => 0,
                    cb => sub {
                        if (defined $self) {
                            $self->process;
                        }
                    });
            }
        });
}

=head2 function1

=cut

sub Destroy {
    my ($self) = @_;
    
    if (defined $self->{handle}) {
        $self->{handle}->push_shutdown;
    }
    delete $self->{handle};
}

=head2 function1

=cut

sub name {
    'http';
}

=head2 function1

=cut

sub result {
}

=head2 function2

=cut

sub process {
    my ($self) = @_;
    my $request = Lim::RPC::Request->new(
        request => $self->{request},
        server => undef,
        transport => $self
    );

    foreach my $protocol ($self->{transport}->protocols) {
        Lim::RPC_DEBUG and $self->{logger}->debug('Trying protocol ', $protocol->name);
        if ($protocol->handle($request)) {
            Lim::RPC_DEBUG and $self->{logger}->debug('Request handled by protocol ', $protocol->name);
            return;
        }
    }
    Lim::RPC_DEBUG and $self->{logger}->debug('Did not find any protocol handler for request');

    return;
}

=head2 function2

=cut

sub _result {
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

sub _timeout {
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

1; # End of Lim::RPC::Transport::HTTP::Client
