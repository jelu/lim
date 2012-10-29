package Lim::RPC::Transport::HTTP;

use common::sense;
use Carp;

use Scalar::Util qw(blessed weaken);

use AnyEvent ();
use AnyEvent::Socket ();

use Lim ();
use Lim::RPC::Transport::HTTP::Client ();
use Lim::RPC::TLS ();

use base qw(Lim::RPC::Transport);

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;

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

    $self->{client} = {};
    $self->{host} = Lim::Config->{rpc}->{transport}->{http}->{host};
    $self->{port} = Lim::Config->{rpc}->{transport}->{http}->{port};
    $self->{html} = Lim::Config->{rpc}->{transport}->{http}->{html};

    if (exists $args{uri}) {
        unless (blessed($args{uri}) and $args{uri}->isa('URI')) {
            confess 'uri argument is not a URI class';
        }
        
        $self->{host} = $args{uri}->host;
        $self->{port} = $args{uri}->port;
    }

    $self->{socket} = AnyEvent::Socket::tcp_server $self->{host}, $self->{port}, sub {
        my ($fh, $host, $port) = @_;
        
        my $handle;
        $handle = Lim::RPC::Transport::HTTP::Client->new(
            transport => $self,
            fh => $fh,
            ($self->isa('Lim::RPC::Transport::HTTPS') ? (tls_ctx => Lim::RPC::TLS->tls_ctx) : ()),
            on_error => sub {
                my ($handle, $fatal, $message) = @_;
                
                $self->{logger}->warn($handle, ' Error: ', $message);
                
                delete $self->{client}->{$handle};
            },
            on_eof => sub {
                my ($handle) = @_;
                
                Lim::RPC_DEBUG and $self->{logger}->debug($handle, ' EOF');
                
                delete $self->{client}->{$handle};
            });
        
        if (exists $self->{html}) {
            $handle->set_html($self->{html});
        }
        
        $self->{client}->{$handle} = $handle;
    }, sub {
        my (undef, $host, $port) = @_;
        
        Lim::DEBUG and $self->{logger}->debug(__PACKAGE__, ' ', $self, ' ready at ', $host, ':', $port);
        
        Lim::SRV_LISTEN;
    };
}

=head2 function1

=cut

sub Destroy {
    my ($self) = @_;
    
    delete $self->{client};
    delete $self->{socket};
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

1; # End of Lim::RPC::Transport::HTTP
