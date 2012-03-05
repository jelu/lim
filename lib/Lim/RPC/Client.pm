package Lim::RPC::Client;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(weaken);

use AnyEvent ();
use AnyEvent::Socket ();
use AnyEvent::Handle ();
use AnyEvent::TLS ();

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

sub OK (){ 1 }
sub ERROR (){ -1 }

sub MAX_RESPONSE_LEN (){ 256 * 1024 }

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
    unless (defined $args{uri}) {
        confess __PACKAGE__, ': No uri specified';
    }
    
    $self->{host} = $args{host};
    $self->{port} = $args{port};
    $self->{uri} = $args{uri};
    if (defined $args{cb} and ref($args{cb}) eq 'CODE') {
        $self->{cb} = $args{cb};
    }
    if (defined $args{data}) {
        # TODO:
    }
    $self->{request} = HTTP::Request->new('GET', $self->{uri});
    $self->{request}->protocol('HTTP/1.1');
    $self->{request}->header('Content-Length' => 0);

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
            on_error => sub {
                my ($handle, $fatal, $message) = @_;
                
                $self->{logger}->warn($handle, ' Error: ', $message);
                $self->{status} = ERROR;
                $self->{error} = $message;
                
                if (exists $self->{cb}) {
                    $self->{cb}->($self);
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
                    
                    if ($self->{headers} =~ /\r\n\r\n/o) {
                        my ($headers, $content) = split(/\r\n\r\n/o, $self->{headers}, 2);
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
                    
                    # TODO: handle JSON error
                    my $data;
                    eval {
                        $data = $JSON->decode($response->decoded_content);
                    };
                    $self->{status} = OK;
                    
                    if (exists $self->{cb}) {
                        $self->{cb}->($self, $data);
                        delete $self->{cb};
                    }
                    $handle->push_shutdown;
                    $handle->destroy;
                }
            });
        
        $self->{handle} = $handle;
        $handle->push_write($self->{request}->as_string("\r\n"));
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

sub status
{
    $_[0]->{status};
}

=head2 function1

=cut

sub error
{
    $_[0]->{error};
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

1; # End of Lim::RPC::Client
