package Lim::Component;

use common::sense;
use Carp;

use Log::Log4perl ();

use Lim ();
use Lim::Plugins ();

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

sub CLI {
    my $self = shift;
    
    if (ref($self)) {
        confess __PACKAGE__, ': Should not be called with refered/blessed argument';
    }
    $self .= '::CLI';
    
    eval 'use '.$self.' ();';
    die $self.' : '.$@ if $@;
    $self->new(@_);
}

=head2 function1

=cut

sub Client {
    my $self = shift;
    
    if (ref($self)) {
        confess __PACKAGE__, ': Should not be called with refered/blessed argument';
    }
    my $calls = $self->Calls;
    $self .= '::Client';
    
    eval 'use '.$self.' ();';
    die $self.' : '.$@ if $@;

    no strict 'refs';    
    foreach my $call (keys %$calls) {
        unless ($self->can($call)) {
            my $sub = $self.'::'.$call;
            
            *$sub = sub {
                Lim::RPC::Call->new($call, @_);
            };
        }
    }
    
    $self->new(@_);
}

=head2 function1

=cut

sub Server {
    my $self = shift;
    
    if (ref($self)) {
        confess __PACKAGE__, ': Should not be called with refered/blessed argument';
    }
    $self .= '::Server';
    
    eval 'use '.$self.' ();';
    die $self.' : '.$@ if $@;
    $self->new(@_);
}

=head2 function1

=cut

sub Module {
    confess 'Module not overloaded';
}

=head2 function1

=cut

sub Calls {
    confess 'Calls not overloaded';
}

=head2 function1

=cut

sub Commands {
    confess 'Commands not overloaded';
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

1; # End of Lim::Component
