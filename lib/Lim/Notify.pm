package Lim::Notify;

use common::sense;

use Scalar::Util qw(weaken blessed);

use Lim ();

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub AddNotify {
    my ($self, $notify, @what) = @_;

    if (blessed($notify) and $notify->isa('Lim::Notification')) {
        foreach (@what) {
            if (Lim::DEBUG and exists $self->{logger}) {
                $self->{logger}->debug('Adding notification for ', $_, ' in ', $self, ' to ', $notify);
            }
            $self->{__notify_what}->{$_}->{$notify} = $notify;
            weaken($self->{__notify_what}->{$_}->{$notify});
        }
    }
    
    $self;
}

=head2 function1

=cut

sub RemoveNotify {
    my ($self, $notify, @what) = @_;
    
    foreach (@what) {
        if (exists $self->{__notify_what}->{$_}) {
            if (Lim::DEBUG and exists $self->{logger}) {
                $self->{logger}->debug('Removing notification for ', $_, ' in ', $self, ' to ', $notify);
            }
            delete $self->{__notify_what}->{$_}->{$notify};
        }
    }
    
    $self;
}

=head2 function1

=cut

sub Notify {
    my ($self, $what, @parameters) = @_;

    if (exists $self->{__notify_what}->{$what}) {
        foreach (values %{$self->{__notify_what}->{$what}}) {
            if (defined $_) {
                if (Lim::DEBUG and exists $self->{logger}) {
                    $self->{logger}->debug('Notifying ', $_, ' about ', $what, '(', $self, ', ...)');
                }
                $_->Notification($self, $what, @parameters);
            }
        }
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

1; # End of Lim::Notify
