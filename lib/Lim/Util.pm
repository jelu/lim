package Lim::Util;

use common::sense;
use Carp;

use Lim ();

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;
our %CALL_METHOD = (
    Create => 'PUT',
    Read => 'GET',
    Update => 'POST',
    Delete => 'DELETE'
);

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub FileExists {
    my ($file) = @_;
    
    if (defined $file) {
        $file =~ s/^\///o;
        foreach (@{Lim::Config->{prefix}}) {
            my $real_file = $_.'/'.$file;
            
            if (-f $real_file) {
                return $real_file;
            }
        }
    }
    return;
}

=head2 function1

=cut

sub FileReadable {
    my ($file) = @_;
    
    if (defined $file) {
        $file =~ s/^\///o;
        foreach (@{Lim::Config->{prefix}}) {
            my $real_file = $_.'/'.$file;
            
            if (-f $real_file and -r $real_file) {
                return $real_file;
            }
        }
    }
    return;
}


=head2 function1

=cut

sub FileWritable {
    my ($file) = @_;
    
    if (defined $file) {
        $file =~ s/^\///o;
        foreach (@{Lim::Config->{prefix}}) {
            my $real_file = $_.'/'.$file;
            
            if (-f $real_file and -w $real_file) {
                return $real_file;
            }
        }
    }
    return;
}

=head2 function1

=cut

sub URIize {
    my @parts = split(/([A-Z][^A-Z]*)/o, $_[0]);
    my ($part, $method, $uri);
    
    while (scalar @parts) {
        $part = shift(@parts);
        if ($part ne '') {
            last;
        }
    }
    
    unless (exists $CALL_METHOD{$part}) {
        confess __PACKAGE__, ': No conversion found for ', $part, ' (', $_[0], ')';
    }
    
    $method = $CALL_METHOD{$part};
    
    @parts = grep !/^$/o, @parts;
    unless (scalar @parts) {
        confess __PACKAGE__, ': Could not build URI (', $_[0], ')';
    }
    $uri = lc(join('_', @parts));
    
    return ($method, '/'.$uri);
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

1; # End of Lim::Util