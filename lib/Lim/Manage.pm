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
        logger => Log::Log4perl->get_logger,
        action => {}
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

    $self->Init(%args);
    
    unless (exists $self->{type}) {
        confess __PACKAGE__, ': Init() did not set type';
    }

    if (exists $args{action}) {
        if (ref($args{action}) eq 'ARRAY') {
            foreach my $action (@{$args{action}}) {
                unless (exists $self->{action}->{$action}) {
                    confess __PACKAGE__, ': Invalid action ', $action, ', does not exist';
                }
                
                $self->{action}->{$action}->{enabled} = 1;
            }
        }
        else {
            unless (exists $self->{action}->{$args{action}}) {
                confess __PACKAGE__, ': Invalid action ', $args{action}, ', does not exist';
            }
            
            $self->{action}->{$args{action}}->{enabled} = 1;
        }
    }
    
    foreach my $action (keys %{$self->{action}}) {
        unless (exists $self->{action}->{$action}->{enabled}) {
            delete $self->{action}->{$action};
        }
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

sub add_action {
    my ($self, $action, $displayName, $helper) = @_;
    
    unless (defined $action) {
        confess __PACKAGE__, ': no action given';
    }
    unless (defined $displayName) {
        confess __PACKAGE__, ': no displayName given';
    }
    unless (defined $helper) {
        $helper = 'none';
    }
    if (exists $self->{action}->{$action})
    {
        confess __PACKAGE__, ': action ', $action, ' already exists';
    }
        
    $self->{action}->{$action} = {
        action => $action,
        displayName => $displayName,
        helper => $helper
    };

    $self;
}

=head2 function1

=cut

sub Action {
    confess __PACKAGE__, ': Action not overloaded';
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
