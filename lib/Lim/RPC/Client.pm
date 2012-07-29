package Lim::RPC::Client;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(blessed weaken);

use AnyEvent ();
use AnyEvent::Socket ();
use AnyEvent::Handle ();

use HTTP::Request ();
use HTTP::Response ();
use HTTP::Status qw(:constants);
use URI ();
use URI::QueryParam ();

use JSON::XS ();

use Lim ();
use Lim::Error ();
use Lim::RPC::Client::TLS ();

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;
our $JSON = JSON::XS->new->ascii;

sub OK (){ 1 }
sub ERROR (){ -1 }

sub MAX_RESPONSE_LEN (){ 8 * 1024 * 1024 }

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
        rbuf => '',
        status => 0,
        error => ''
    };
    bless $self, $class;
    my $real_self = $self;
    weaken($self);
    
    unless (defined $args{host}) {
        confess __PACKAGE__, ': No host specified';
    }
    unless (defined $args{port}) {
        confess __PACKAGE__, ': No port specified';
    }
    unless (defined $args{method}) {
        confess __PACKAGE__, ': No method specified';
    }
    unless (defined $args{uri}) {
        confess __PACKAGE__, ': No uri specified';
    }
    if (defined $args{data} and ref($args{data}) ne 'HASH') {
        confess __PACKAGE__, ': Data is not a hash';
    }
    
    $self->{host} = $args{host};
    $self->{port} = $args{port};
    $self->{uri} = $args{uri};
    if (defined $args{cb} and ref($args{cb}) eq 'CODE') {
        $self->{cb} = $args{cb};
    }
    $self->{request} = HTTP::Request->new($args{method}, $self->{uri});
    $self->{request}->protocol('HTTP/1.1');
    if (defined $args{data}) {
        my $json;
        eval {
            $json = $JSON->encode($args{data});
        };
        if ($@) {
            $self->{status} = ERROR;
            $self->{error} = $@;
            
            if (exists $self->{cb}) {
                $self->{cb}->($self);
                delete $self->{cb};
            }
            return;
        }
        $self->{request}->content($json);
        $self->{request}->header('Content-Length' => length($json));
        $self->{request}->header('Content-Type' => 'application/json');
    }
    else {
        $self->{request}->header('Content-Length' => 0);
    }

    $self->{socket} = AnyEvent::Socket::tcp_connect $self->{host}, $self->{port}, sub {
        my ($fh, $host, $port) = @_;
        
        unless (defined $fh) {
            $self->{logger}->warn('Error: ', $!);
            $self->{status} = ERROR;
            $self->{error} = $!;
        
            if (exists $self->{cb}) {
                $self->{cb}->($self);
                delete $self->{cb};
            }
            return;
        }
        
        my $handle;
        $handle = AnyEvent::Handle->new(
            fh => $fh,
            tls => 'connect',
            tls_ctx => Lim::RPC::Client::TLS->instance->tls_ctx,
            timeout => Lim::Config->{rpc}->{timeout},
            on_error => sub {
                my ($handle, $fatal, $message) = @_;
                
                $self->{logger}->warn($handle, ' Error: ', $message);
                $self->{status} = ERROR;
                $self->{error} = $message;
                
                if (exists $self->{cb}) {
                    $self->{cb}->($self, Lim::Error->new(
                        message => $self->{error},
                        module => $self
                    ));
                    delete $self->{cb};
                }
                $handle->destroy;
            },
            on_timeout => sub {
                my ($handle) = @_;
                
                $self->{logger}->warn($handle, ' TIMEOUT');
                $self->{status} = ERROR;
                $self->{error} = 'Connection/Request/Response Timeout';
                
                if (exists $self->{cb}) {
                    $self->{cb}->($self, Lim::Error->new(
                        code => HTTP_REQUEST_TIMEOUT,
                        message => $self->{error},
                        module => $self
                    ));
                    delete $self->{cb};
                }
                $handle->destroy;
            },
            on_eof => sub {
                my ($handle) = @_;
                
                $self->{logger}->warn($handle, ' EOF');
                
                if (exists $self->{cb}) {
                    $self->{cb}->($self);
                    delete $self->{cb};
                }
                $handle->destroy;
            },
            on_read => sub {
                my ($handle) = @_;
                
                if ((length($self->{rbuf}) + length($handle->{rbuf})) > MAX_RESPONSE_LEN) {
                    if (exists $self->{on_error}) {
                        $self->{on_error}->($self, 1, 'Response too long');
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
                        $self->{response} = HTTP::Response->parse($self->{headers});
                    }
                }
                else {
                    $self->{content} .= $handle->{rbuf};
                }
                $handle->{rbuf} = '';
                
                if (defined $self->{response} and length($self->{content}) == $self->{response}->header('Content-Length')) {
                    my $response = $self->{response};
                    $response->content($self->{content});
                    delete $self->{response};
                    delete $self->{content};
                    $self->{headers} = '';
                    
                    my $data;
                    
                    if ($response->code == 200) {
                        $self->{status} = OK;
                    }
                    else {
                        $self->{status} = ERROR;
                    }

                    if ($response->header('Content-Length')) {
                        if ($response->header('Content-Type') =~ /application\/json/io) {
                            eval {
                                $data = $JSON->decode($response->decoded_content);
                            };
                            if ($@) {
                                $self->{status} = ERROR;
                                $self->{error} = $@;
                                undef($data);
                            }
                            else {
                                if (ref($data) ne 'HASH') {
                                    $data = Lim::Error->new(
                                        code => 500,
                                        message => 'Invalid data returned, not a hash',
                                        module => $self);
                                    $self->{status} = ERROR;
                                }
                                elsif ($self->{status} == ERROR) {
                                    $data = Lim::Error->new->set($data);
                                }
                            }
                        }
                        else {
                            $self->{status} = ERROR;
                            $self->{error} = 'Unknown content type ['.$response->header('Content-Type').'] returned';
                        }
                    }
                    
                    if ($self->{status} == ERROR) {
                        unless (defined $data) {
                            $data = Lim::Error->new(
                                code => $response->code,
                                message => $self->{error},
                                module => $self);
                        }
                        unless (blessed $data and $data->isa('Lim::Error')) {
                            confess __PACKAGE__, ': status is ERROR but data is not a Lim::Error object';
                        }
                    }

                    if (exists $self->{cb}) {
                        $self->{cb}->($self, $data);
                        delete $self->{cb};
                    }
                    $handle->push_shutdown;
                    $handle->destroy;
                }
            });
        
        $self->{handle} = $handle;
        $handle->push_write($self->{request}->as_string("\015\012"));
        delete $self->{request};
    };

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $real_self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
    
    delete $self->{client};
    delete $self->{socket};
    delete $self->{handle};
}

=head2 function1

=cut

sub status {
    $_[0]->{status};
}

=head2 function1

=cut

sub error {
    $_[0]->{error};
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

1; # End of Lim::RPC::Client
