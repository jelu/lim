package Lim::RPC;

use common::sense;
use Carp;

use Scalar::Util qw(blessed);

use SOAP::Lite ();

use Lim ();
use Lim::DB ();
use Lim::Error ();

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

sub C {
    my $object = shift;

    my $som = $_[scalar @_ - 2];
    if (blessed($som) and $som->isa('SOAP::SOM')) {
        unless (exists $som->{__lim_rpc_cb} and blessed($som->{__lim_rpc_cb}) and $som->{__lim_rpc_cb}->isa('Lim::RPC::Callback::SOAP')) {
            confess __PACKAGE__, ': SOAP::SOM does not contain lim rpc callback or invalid';
        }
        my $cb = $som->{__lim_rpc_cb};
        delete $som->{__lim_rpc_cb};
        my $valueof = pop;
        my $som = pop;
        if (defined $valueof) {
            $som->valueof($valueof);
        }
        return ($object, $cb, @_);
    }
    else {
        pop;
    }

    return ($object, @_);
}

=head2 function1

=cut

sub __soap_result {
    my @a;
    
    foreach my $k (keys %{$_[1]}) {
        if (ref($_[1]->{$k}) eq 'ARRAY') {
            foreach my $v (@{$_[1]->{$k}}) {
                if (ref($v) eq 'HASH') {
                    push(@a,
                        SOAP::Data->new->name(lc($k))
                        ->value(Lim::RPC::__soap_result($_[0].'.'.$k, $v))
                        ->prefix('lim1')
                        );
                }
                else {
                    push(@a,
                        SOAP::Data->new->name(lc($k))
                        ->value($v)
                        ->prefix('lim1')
                        );
                }
            }
        }
        elsif (ref($_[1]->{$k}) eq 'HASH') {
            push(@a,
                SOAP::Data->new->name(lc($k))
                ->value(Lim::RPC::__soap_result($_[0].'.'.$k, $_[1]->{$k}))
                ->prefix('lim1')
                );
        }
        else {
            push(@a,
                SOAP::Data->new->name(lc($k))
                ->value($_[1]->{$k})
                ->prefix('lim1')
                );
        }
    }

    if ($_[0] eq 'base') {
        return @a;
    }
    else {
        return \@a;
    }
}

sub R {
    my ($cb, $data) = @_;
    
    unless (blessed($cb)) {
        confess __PACKAGE__, ': cb not blessed';
    }
    
    if (blessed($data)) {
        if ($data->isa('DBIx::Class::ResultSet')) {
            my @r;
            my $c = lc($data->result_source->source_name);
            foreach ($data->all) {
                my %r = $_->get_columns;
                push(@r, \%r);
            }
            $data = { $c => \@r };
        }
        elsif ($data->isa('Lim::Error')) {
            if ($cb->isa('Lim::RPC::Callback::SOAP')) {
                # TODO generate SOAP Error
            }
            else {
                return $cb->cb->($data);
            }
        }
    }
    elsif (ref($data) ne 'HASH') {
        confess __PACKAGE__, ': data not a hash';
    }
    
    if ($cb->isa('Lim::RPC::Callback::SOAP')) {
        return $cb->cb->(SOAP::Data->value(Lim::RPC::__soap_result('base', $data)));
    }

    return $cb->cb->($data);
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
