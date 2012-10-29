package Lim::RPC::Request;

use common::sense;
use Carp;

use Scalar::Util qw(blessed);
use Log::Log4perl ();

use Lim ();

=encoding utf8

=head1 NAME

Lim::RPC::Request - 

=head1 VERSION

See L<Lim> for version.

=cut

=head1 SYNOPSIS

...

=head1 METHODS

=over 4

...

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %args = ( @_ );
    my $self = {
        logger => Log::Log4perl->get_logger,
        request => undef,
        response => undef,
        server => undef,
        transport => undef,
        protocol => undef
    };
    bless $self, $class;

    if (exists $args{request}) {
        $self->{request} = $args{request};
    }
    if (exists $args{response}) {
        $self->{response} = $args{response};
    }
    if (exists $args{server}) {
        $self->set_server($args{server});
    }
    if (exists $args{transport}) {
        $self->set_transport($args{transport});
    }
    if (exists $args{protocol}) {
        $self->set_protocol($args{protocol});
    }

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);

    delete $self->{callbacks};
}

=item 

=cut

sub request {
    $_[0]->{request};
}

=item 

=cut

sub set_request {
    $_[0]->{request} = $_[1];
    
    $_[0];
}

=item 

=cut

sub response {
    $_[0]->{response};
}

=item 

=cut

sub set_response {
    $_[0]->{response} = $_[1];
    
    $_[0];
}

=item 

=cut

sub server {
    $_[0]->{server};
}

=item 

=cut

sub set_server {
    unless (blessed($_[1]) and $_[1]->isa('Lim::RPC::Server')) {
        confess 'Argument is not a Lim::RPC::Server object';
    }
    
    $_[0]->{server} = $_[1];

    $_[0];
}

=item 

=cut

sub transport {
    $_[0]->{transport};
}

=item 

=cut

sub set_transport {
    unless (blessed($_[1]) and $_[1]->isa('Lim::RPC::Transport')) {
        confess 'Argument is not a Lim::RPC::Transport object';
    }
    
    $_[0]->{server} = $_[1];

    $_[0];
}

=item 

=cut

sub protocol {
    $_[0]->{protocol};
}

=item 

=cut

sub set_protocol {
    unless (blessed($_[1]) and $_[1]->isa('Lim::RPC::Protocol')) {
        confess 'Argument is not a Lim::RPC::Protocol object';
    }
    
    $_[0]->{protocol} = $_[1];

    $_[0];
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

...

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

1; # End of Lim::RPC::Request
