package Lim::Manage;

use common::sense;
use Carp;

use Log::Log4perl ();

use Lim ();

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
        logger => Log::Log4perl->get_logger
    };
    bless $self, $class;
    
    unless (defined $args{name}) {
        confess __PACKAGE__, ': Missing name';
    }
    unless (defined $args{plugin}) {
        confess __PACKAGE__, ': Missing plugin';
    }
    unless (defined $args{action}) {
        confess __PACKAGE__, ': Missing action';
    }
    
    $self->{name} = $args{name};
    $self->{plugin} = $args{plugin};
    $self->{action} = $args{action};

    $self->Init(%args);
    
    unless (exists $self->{type}) {
        confess __PACKAGE__, ': Init() did not set type';
    }

    my $actions = 0;
    foreach (values %{$self->{__action_bitmap}}) {
        $actions &= $_;
    }
    unless (($args{action} & $actions) == $args{action}) {
        confess __PACKAGE__, ': Invalid action(s)';
    }
    
    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
    
    $self->Destroy;
}

=head2 function1

=cut

sub Init {
}

=head2 function1

=cut

sub Destroy {
}

=head2 function1

=cut

sub type {
    $_[0]->{type};
}

=head2 function1

=cut

sub name {
    $_[0]->{name};
}

=head2 function1

=cut

sub plugin {
    $_[0]->{plugin};
}

=head2 function1

=cut

sub action {
    $_[0]->{action};
}

=head2 function1

=cut

sub actions {
    if (exists $_[0]->{__action_bitmap}) {
        return keys %{$_[0]->{__action_bitmap}};
    }
}

=head2 function1

=cut

sub __add_action {
    my ($self, $action, $string) = @_;

    if (defined $action and defined $string) {
        $string = lc($string);
        
        if (exists $self->{__action_string}->{$action} and
            exists $self->{__action_bitmap}->{$string})
        {
            confess __PACKAGE__, ': __add_action failed, ', $string, ' action already added';
        }
        
        $self->{__action_string}->{$action} = $string;
        $self->{__action_bitmap}->{$string} = $action;
    }
    
    $self;
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

1; # End of Lim::Manage
