package Lim::RPC::Callback::XMLRPC;

use common::sense;

use base qw(Lim::RPC::Callback);

=head1 NAME

Lim::RPC::Callback::XMLRPC - Callback for XMLRPC RPC request.

=head1 VERSION

See L<Lim> for version.

=cut

=head1 SYNOPSIS

=over 4

use Lim::RPC::Callback::XMLRPC;

$json_callback = Lim::RPC::Callback::XMLRPC(key => value...)

=back

=head1 METHODS

This module uses L<Lim::RPC::Callback> as base, see that modules documentation
for methods.

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::RPC::Callback::XMLRPC

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

1; # End of Lim::RPC::Callback::XMLRPC
