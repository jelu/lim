package Lim::Master;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(weaken);

use AnyEvent ();
use AnyEvent::Socket ();
use AnyEvent::TLS ();

use Lim ();
use Lim::Server ();

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
        logger => Log::Log4perl->get_logger,
        host => '0.0.0.0',
        port => 5353,
        html => '/usr/share/lim/html',
        client => {}
    };
    bless $self, $class;
    my $real_self = $self;
    weaken($self);
    
    unless (defined $args{key} and -f $args{key}) {
        croak __PACKAGE__, ': No key file specified or not found';
    }
    $self->{key} = $args{key};

    if (defined $args{host}) {
        $self->{host} = $args{host};
    }
    if (defined $args{port}) {
        $self->{port} = $args{port};
    }
    if (defined $args{html}) {
        $self->{html} = $args{html};
    }
    
    $self->{server} = Lim::Server->new(
        host => $self->{host},
        port => $self->{port},
        html => $self->{html},
        key => $self->{key}
    );
    
    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $real_self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
    
    delete $self->{server};
}

=head2 function2

=cut

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

1; # End of Lim::Master
