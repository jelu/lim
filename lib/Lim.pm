package Lim;

use common::sense;
use Carp;

=head1 NAME

Lim - The great new Lim!

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';
our $CONFIG;

sub OBJ_DEBUG (){ 1 }
sub RPC_DEBUG (){ 1 }
sub DEBUG (){ 1 }
sub INFO (){ 1 }
sub WARN (){ 1 }
sub ERR (){ 1 }

sub SRV_LISTEN (){ 10 }

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub Config {
    $CONFIG ||= {
        prefix => ['', '/usr', '/usr/local'],
        rpc => {
            timeout => 30,
            call_timeout => 300
        }
    };
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

1; # End of Lim
