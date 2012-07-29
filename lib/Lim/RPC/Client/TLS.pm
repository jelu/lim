package Lim::RPC::Client::TLS;

use common::sense;
use Carp;

use Log::Log4perl ();

use AnyEvent::TLS ();

use Lim ();

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;
our $INSTANCE;

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
    };
    bless $self, $class;
    
    unless (defined $args{key} and -f $args{key}) {
        confess __PACKAGE__, ': No key file specified or not found';
    }

    $self->{tls_ctx} = AnyEvent::TLS->new(
        method => 'any',
        ca_file => $args{key},
        cert_file => $args{key},
        key_file => $args{key},
        verify => 1,
        verify_require_client_cert => 1
        );

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
}

END {
    undef($INSTANCE);
}

=head2 function1

=cut

sub instance {
    $INSTANCE ||= Lim::RPC::Client::TLS->new;
}

=head2 function1

=cut

sub set_instance {
    shift;
    $INSTANCE = shift;
}

=head2 function1

=cut

sub tls_ctx {
    $_[0]->{tls_ctx};
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

1; # End of Lim::RPC::Client::TLS
