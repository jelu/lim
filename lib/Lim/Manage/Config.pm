package Lim::Manage::Config;

use common::sense;
use Carp;

use base qw(Lim::Manage);

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

sub VIEW (){ 'view' }
sub EDIT (){ 'edit' }

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub Init {
    my $self = shift;
    my %args = ( @_ );
    
    unless (defined $args{file}) {
        confess __PACKAGE__, ': Missing file';
    }
    
    $self->{type} = 'config';
    $self->add_action(VIEW, 'View', 'view');
    $self->add_action(EDIT, 'Edit', 'edit');

    $self->{file} = $args{file};
}

=head2 function1

=cut

sub Destroy {
}

=head2 function1

=cut

sub file {
    $_[0]->{file};
}

=head2 function1

=cut

sub Action {
    my ($self, $action, $data) = @_;
    
    if ($action eq VIEW) {
        if (open(FILE, $self->{file})) {
            my ($read, $buffer, $content);

            while (($read = read(FILE, $buffer, 64*1024))) {
                $content .= $buffer;
            }
            close(FILE);
            
            if (defined $read) {
                return ('view', $content);
            }
        }
    }
    elsif ($action eq EDIT) {
        
    }
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

1; # End of Lim::Manage::Config
