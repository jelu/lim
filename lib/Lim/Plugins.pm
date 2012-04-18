package Lim::Plugins;

use common::sense;
use Carp;

use Log::Log4perl ();
use Module::Find qw(usesub);

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
        plugin => {},
        plugin_obj => {}
    };
    bless $self, $class;

    foreach my $module (usesub Lim::Plugin) {
        my $name = $module;
        $name =~ s/.*:://o;
        
        $self->{plugin_obj}->{$module} = $module->new;
        $self->{plugin}->{$module} = {
            name => $name,
            module => $module
        };
    }

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
}

=head2 function1

=cut

sub instance {
    $INSTANCE ||= Lim::Plugins->_new;
}

=head2 function1

=cut

sub deinstance {
    undef($INSTANCE);
}

=head2 function1

=cut

sub Module {
    'Plugins';
}

=head2 function1

=cut

sub ReadIndex {
    my ($self, $cb) = Lim::RPC::C(@_, undef);
    
    Lim::RPC::R($cb, {
       plugin => [ values %{$self->{plugin}} ]
    }, {
        'base.plugin' => [ 'name', 'module' ]
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

1; # End of Lim::Plugins
