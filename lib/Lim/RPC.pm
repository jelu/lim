package Lim::RPC;

use common::sense;
use Carp;

use Scalar::Util qw(blessed);

use SOAP::Lite ();

use Lim::DB ();

use base qw(SOAP::Server::Parameters);

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

sub OPTIONAL (){ 0 }
sub REQUIRED (){ 1 }

sub STRING (){ 1 << 4 }
sub INTEGER (){ 2 << 4 }

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub Module {
    confess 'Module not overloaded';
}

=head2 function1

=cut

sub Calls {
    confess 'Calls not overloaded';
}

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

sub __result {
    my @a;
    
    if (defined $_[2] and exists $_[2]->{$_[0]}) {
        foreach my $k (@{$_[2]->{$_[0]}}) {
            if (exists $_[1]->{$k}) {
                if (ref($_[1]->{$k}) eq 'ARRAY') {
                    foreach my $v (@{$_[1]->{$k}}) {
                        if (ref($v) eq 'HASH') {
                            push(@a,
                                SOAP::Data->new->name(lc($k))
                                ->value(Lim::RPC::__result($_[0].'.'.$k, $v, $_[2]))
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
                        ->value(Lim::RPC::__result($_[0].'.'.$k, $_[1]->{$k}, $_[2]))
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
        }
    }
    else {
        foreach my $k (keys %{$_[1]}) {
            if (ref($_[1]->{$k}) eq 'ARRAY') {
                foreach my $v (@{$_[1]->{$k}}) {
                    if (ref($v) eq 'HASH') {
                        push(@a,
                            SOAP::Data->new->name(lc($k))
                            ->value(Lim::RPC::__result($_[0].'.'.$k, $v, $_[2]))
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
                    ->value(Lim::RPC::__result($_[0].'.'.$k, $_[1]->{$k}, $_[2]))
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
    }

    if ($_[0] eq 'base') {
        return @a;
    }
    else {
        return \@a;
    }
}

sub R {
    my ($cb, $data, $map) = @_;
    
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
    }
    
    if ($cb->isa('Lim::RPC::Callback::SOAP')) {
        if (ref($data) eq 'HASH') {
            return $cb->cb->(SOAP::Data->value(Lim::RPC::__result('base', $data, $map)));
        }
        else {
            return $cb->cb->(SOAP::Data->value($data));
        }
    }

    if (ref($data) eq 'ARRAY' or ref($data) eq 'HASH') {
        return $cb->cb->($data);
    }
    $cb->cb->([ $data ]);
}

=head2 function1

=cut

sub E {
    my ($cb, $e) = @_;
    
    unless (blessed($cb)) {
        confess __PACKAGE__, ': cb not blessed';
    }
    if (blessed($e)) {
        if ($e->isa('Lim::Error')) {
            $e = {
                code => $e->code,
                module => $e->module,
                message => $e->message
            };
        }
        else {
            confess __PACKAGE__, ': blessed object given as error but was not Lim::Error';
        }
    }
    if (ref($e) eq 'SCALAR' or scalar @_ > 2) {
        shift;
        my $module = shift;
        $e = {
            code => 500,
            module => $module,
            message => join(' ', @_)
        };
    }
    unless (ref($e) eq 'HASH') {
        confess __PACKAGE__, ': error is not a hash';
    }
    unless (exists($e->{message})) {
        confess __PACKAGE__, ': required parameter message does not exists in error';
    }
    unless (exists($e->{module})) {
        confess __PACKAGE__, ': required parameter module does not exists in error';
    }
    unless (exists($e->{code})) {
        $e->{code} = 500;
    }
    
    $e = { error => $e };
    
    if ($cb->isa('Lim::RPC::Callback::SOAP')) {
        return $cb->cb->(SOAP::Data->value(Lim::RPC::__result('base', $e, {
            'base.error' => [ 'code', 'module', 'message' ]
        })));
    }

    return $cb->cb->($e);
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
