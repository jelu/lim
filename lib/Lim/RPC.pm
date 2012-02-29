package Lim::RPC;

use common::sense;
use Carp;

use SOAP::Lite ();

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

sub Module
{
    croak 'Module not overloaded';
}

=head2 function1

=cut

sub GetIndex
{
    croak 'GetIndex not overloaded';
}

=head2 function1

=cut

sub isSoap
{
    $_[0]->{__rpc_isSoap} = $_[1] if (defined $_[1]);
    
    $_[0]->{__rpc_isSoap};
}

=head2 function1

=cut

sub __result
{
    my @a;
    
    if (defined $_[2] and exists $_[2]->{$_[0]}) {
        foreach my $k (@{$_[2]->{$_[0]}}) {
            if (exists $_[1]->{$k}) {
                if (ref($_[1]->{$k}) eq 'ARRAY') {
                    foreach my $v (@{$_[1]->{$k}}) {
                        if (ref($v) eq 'HASH') {
                            push(@a,
                                SOAP::Data->new->name($k)
                                ->value(Lim::RPC::__result($_[0].'.'.$k, $v, $_[2]))
                                ->prefix('lim1')
                                );
                        }
                        else {
                            push(@a,
                                SOAP::Data->new->name($k)
                                ->value($v)
                                );
                        }
                    }
                }
                elsif (ref($_[1]->{$k}) eq 'HASH') {
                    push(@a,
                        SOAP::Data->new->name($k)
                        ->value(Lim::RPC::__result($_[0].'.'.$k, $_[1]->{$k}, $_[2]))
                        ->prefix('lim1')
                        );
                }
                else {
                    push(@a,
                        SOAP::Data->new->name($k)
                        ->value($_[1]->{$k})
                        );
                }
            }
        }
    }
    else {
        foreach my $k (keys %{$_[1]}) {
            if (ref($_[1]->{$k}) eq 'ARRAY') {
                foreach my $v (@{$_[1]->{$k}}) {
                    if (ref($v) eq 'HASH') {
                        push(@a,
                            SOAP::Data->new->name($k)
                            ->value(Lim::RPC::__result($_[0].'.'.$k, $v, $_[2]))
                            ->prefix('lim1')
                            );
                    }
                    else {
                        push(@a,
                            SOAP::Data->new->name($k)
                            ->value($v)
                            );
                    }
                }
            }
            elsif (ref($_[1]->{$k}) eq 'HASH') {
                push(@a,
                    SOAP::Data->new->name($k)
                    ->value(Lim::RPC::__result($_[0].'.'.$k, $_[1]->{$k}, $_[2]))
                    ->prefix('lim1')
                    );
            }
            else {
                push(@a,
                    SOAP::Data->new->name($k)
                    ->value($_[1]->{$k})
                    );
            }
        }
    }

    if ($_[0] eq 'base') {
        return @a;
    }
    else {
        return \@a;
    }
}

sub R
{
    if ($_[0]->{__rpc_isSoap}) {
        if (ref($_[1]) eq 'HASH') {
            return SOAP::Data->value(Lim::RPC::__result('base', $_[1], $_[2]));
        }
        else {
            return SOAP::Data->value($_[1]);
        }
    }
    
    $_[1];
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

1; # End of Lim::RPC
