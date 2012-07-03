package Lim::Error;

use common::sense;
use Carp;

use Scalar::Util qw(blessed);

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

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %args = ( @_ );
    my $self = {
        code => 500,
        message => 'Generic Error',
        module => 'UNKNOWN'
    };
    bless $self, $class;
    
    unless (defined $args{message}) {
        confess __PACKAGE__, ': Missing message';
    }
    
    if (defined $args{code}) {
        $self->{code} = $args{code};
    }
    $self->{message} = $args{message};
    if (defined $args{module}) {
        if (blessed($args{module})) {
            $self->{module} = ref($args{module});
        }
        else {
            $self->{module} = $args{module};
        }
    }

    $self;
}

sub DESTROY {
}

=head2 function1

=cut

sub code {
    $_[0]->{code};
}

=head2 function1

=cut

sub set_code {
    $_[0]->{code} = $_[1];
}

=head2 function1

=cut

sub message {
    $_[0]->{message};
}

=head2 function1

=cut

sub set_message {
    $_[0]->{message} = $_[1];
}

=head2 function1

=cut

sub module {
    $_[0]->{module};
}

=head2 function1

=cut

sub set_module {
    $_[0]->{module} = $_[1];
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

1; # End of Lim::Error
