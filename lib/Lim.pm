package Lim;

use common::sense;
use Carp;

use base qw(Lim::RPC);

=head1 NAME

Lim - The great new Lim!

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';
our $CONFIG;

sub OBJ_DEBUG (){ 1 }
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

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %args = ( @_ );
    my $self = {
        logger => Log::Log4perl->get_logger,
    };
    bless $self, $class;
    
    unless (defined $args{type}) {
        confess __PACKAGE__, ': Missing type';
    }
    
    $self->{type} = $args{type};

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
}

=head2 function1

=cut

sub Config {
    $CONFIG ||= {
        prefix => [qw(/ /usr /usr/local)]
    };
}

=head2 function1

=cut

sub Module {
    'Lim';
}

=head2 function1

=cut

sub Calls {
    {
        ReadIndex => {
            out => {
                lim => {
                    version => Lim::RPC::STRING,
                    type => Lim::RPC::STRING
                }
            }
        },
        ReadVersion => {
            out => {
                version => Lim::RPC::STRING
            }
        },
        ReadType => {
            out => {
                type => Lim::RPC::STRING
            }
        }
    };
}

=head2 function1

=cut

sub ReadIndex {
    my ($self) = @_;
    
    {
        lim => {
            version => $VERSION,
            type => $self->{type}
        }
    };
}

=head2 function1

=cut

sub ReadVersion {
    {
        version => $VERSION
    };
}

=head2 function1

=cut

sub ReadType {
    my ($self) = @_;
    
    {
        type => $self->{type}
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
