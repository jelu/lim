package Lim::RPC::Call;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(blessed weaken);

use Lim ();
use Lim::RPC::Client ();

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;

sub OK (){ 1 }
sub ERROR (){ -1 }

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
        status => 0,
        error => ''
    };
    bless $self, $class;
    my $real_self = $self;
    weaken($self);
    
    unless (defined $args{cli}) {
        unless (defined $args{host}) {
            confess __PACKAGE__, ': No host specified';
        }
        unless (defined $args{port}) {
            confess __PACKAGE__, ': No port specified';
        }
    }
    unless (defined $args{rpc}) {
        confess __PACKAGE__, ': No rpc specified';
    }
    unless (defined $args{call}) {
        confess __PACKAGE__, ': No call specified';
    }
    unless (defined $args{cb}) {
        confess __PACKAGE__, ': No cb specified';
    }
    
    if (defined $args{cli}) {
        unless (blessed($args{cli}) and $args{cli}->isa('Lim::CLI')) {
            confess __PACKAGE__, ': cli parameter is not a Lim::CLI';
        }
    }
    unless (blessed($args{rpc}) and $args{rpc}->isa('Lim::RPC::Base')) {
        confess __PACKAGE__, ': rpc parameter is not a Lim::RPC::Base';
    }

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $real_self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
}

=head2 function1

=cut

sub status {
    $_[0]->{status};
}

=head2 function1

=cut

sub error {
    $_[0]->{error};
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

1; # End of Lim::RPC::Call
