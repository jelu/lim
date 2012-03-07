package Lim::Manager;

use common::sense;
use Carp;

use Scalar::Util qw(blessed);
use Log::Log4perl ();

use Lim ();
use base qw(Lim::RPC);

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

sub _new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {
        logger => Log::Log4perl->get_logger,
        manage => {},
        manages => []
    };
    bless $self, $class;
    
    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);

    delete $self->{manage};
    delete $self->{manages};
}

=head2 function1

=cut

sub instance {
    $INSTANCE ||= Lim::Manager->_new;
}

=head2 function1

=cut

sub deinstance {
    undef($INSTANCE);
}

=head2 function1

=cut

sub Module {
    'Manager';
}

=head2 function1

=cut

sub Manage {
    my ($self, $manage) = @_;
    
    if (blessed $manage and $manage->isa('Lim::Manage')) {
        if (exists $self->{manage}->{$manage->type}->{$manage->name}->{$manage->plugin}) {
            confess __PACKAGE__, ': Object [type: ', $manage->type, ' name: ', $manage->name, '] already managed by ', $manage->plugin;
        }
        
        $self->{manage}->{$manage->type}->{$manage->name}->{$manage->plugin} = $manage;
        push(@{$self->{manages}}, $manage);
    }
}

=head2 function1

=cut

sub ReadIndex {
    my ($self, $cb) = Lim::RPC::C(@_, undef);

    my @manages;
    foreach (@{$self->{manages}}) {
        push(@manages, {
            type => $_->type,
            name => $_->name,
            plugin => $_->plugin,
            actions => [ $_->actions ]
        });
    }

    Lim::RPC::R($cb, {
        manage => \@manages
    }, {
       'base.manage' => [ 'type', 'name', 'plugin', 'actions' ]
    });
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

1; # End of Lim::Manager
