package Lim::RPC::Callback::JSON;

use common::sense;
use Carp;

use Log::Log4perl ();

use Lim ();

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my ($cb) = @_;
    my $self = {
        logger => Log::Log4perl->get_logger
    };
    bless $self, $class;

    unless (defined $cb and ref($cb) eq 'CODE') {
        confess __PACKAGE__, ': Callback not given or invalid';
    }
    
    $self->{cb} = $cb;

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
}

=head2 function1

=cut

sub cb {
    $_[0]->{cb}
}

=head2 function1

=cut

sub call_def {
    $_[0]->{call_def};
}

=head2 function1

=cut

sub set_call_def {
    if (ref($_[1]) eq 'HASH') {
        $_[0]->{call_def} = $_[1];
    }
    
    $_[0];
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

1; # End of Lim::RPC::Callback::JSON
