package Lim::RPC;

use common::sense;
use Carp;

use Scalar::Util qw(blessed);

use SOAP::Lite ();
use XMLRPC::Lite ();

use Lim ();
use Lim::Error ();

=head1 NAME

Lim::RPC - Utilities for Lim's RPC

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;

=head1 SYNOPSIS

=over 4

use Lim::RPC;

=back

=head1 NOTE

These functions are mainly used internaly, you should not have any reason to
call them.

=head1 METHODS

=over 4

=item Lim::RPC::V($q, $def)

V is for Verify, it will verify the content of the hash ref C<$q> against the
RPC definition in C<$def>. On an error it will L<confess>.

=cut

sub V {
    my ($q, $def) = @_;
    
    if (defined $q and defined $def) {
        unless (ref($q) eq 'HASH' and ref($def) eq 'HASH') {
            confess __PACKAGE__, ': Can not verify data, invalid parameters given';
        }
        
        my @v = ([$q, $def]);
        while (defined (my $v = shift(@v))) {
            ($q, $def) = @$v;
            my $a;

            if (ref($q) eq 'ARRAY') {
                $a = $q;
            }
            else {
                $a = [$q];
            }
            
            foreach $q (@{$a}) {
                unless (ref($q) eq 'HASH') {
                    confess __PACKAGE__, ': Can not verify data, invalid data given';
                }
                
                # check required
                foreach my $k (keys %$def) {
                    if (blessed($def->{$k}) and $def->{$k}->required and !exists $q->{$k}) {
                        confess __PACKAGE__, ': required data missing, does not match definition';
                    }
                }
                
                # check data
                foreach my $k (keys %$q) {
                    unless (exists $def->{$k}) {
                        confess __PACKAGE__, ': invalid data, no definition exists';
                    }
                    
                    if (blessed($def->{$k}) and !$def->{$k}->comform($q->{$k})) {
                        confess __PACKAGE__, ': invalid data, validation failed';
                    }
                    
                    if (ref($q->{$k}) eq 'HASH' or ref($q->{$k}) eq 'ARRAY') {
                        if (ref($def->{$k}) eq 'HASH') {
                            push(@v, [$q->{$k}, $def->{$k}]);
                        }
                        elsif (blessed $def->{$k} and $def->{$k}->isa('Lim::RPC::Value::Collection')) {
                            push(@v, [$q->{$k}, $def->{$k}->children]);
                        }
                        else {
                            confess __PACKAGE__, ': invalid definition, can not validate data';
                        }
                    }
                }
            }
        }
    }
    return;
}

=item (...) = Lim::RPC::C(...)

C is for Call, used to convert the incoming call arguments from protocol
specific list to a general one.

=cut

sub C {
    my $object = shift;

    my $som = $_[scalar @_ - 2];
    if (blessed($som) and $som->isa('XMLRPC::SOM')) {
        unless (exists $som->{__lim_rpc_cb} and blessed($som->{__lim_rpc_cb}) and $som->{__lim_rpc_cb}->isa('Lim::RPC::Callback::XMLRPC')) {
            confess __PACKAGE__, ': XMLRPC::SOM does not contain lim rpc callback or invalid';
        }
        my $cb = $som->{__lim_rpc_cb};
        delete $som->{__lim_rpc_cb};
        my $valueof = pop;
        my $som = pop;
        if (defined $valueof) {
            return ($object, $cb, $som->valueof($valueof));
        }
        return ($object, $cb, @_);
    }
    elsif (blessed($som) and $som->isa('SOAP::SOM')) {
        unless (exists $som->{__lim_rpc_cb} and blessed($som->{__lim_rpc_cb}) and $som->{__lim_rpc_cb}->isa('Lim::RPC::Callback::SOAP')) {
            confess __PACKAGE__, ': SOAP::SOM does not contain lim rpc callback or invalid';
        }
        my $cb = $som->{__lim_rpc_cb};
        delete $som->{__lim_rpc_cb};
        my $valueof = pop;
        my $som = pop;
        if (defined $valueof) {
            return ($object, $cb, $som->valueof($valueof));
        }
        return ($object, $cb, @_);
    }
    else {
        pop;
    }

    return ($object, @_);
}

=item Lim::RPC::R($cb, $data)

R is for Result, called when a RPC call finish and convert the given C<$data> to 
the corresponding protocol.

=cut

sub __soap_result {
    my @a;
    
    foreach my $k (keys %{$_[1]}) {
        if (ref($_[1]->{$k}) eq 'ARRAY') {
            foreach my $v (@{$_[1]->{$k}}) {
                if (ref($v) eq 'HASH') {
                    push(@a,
                        SOAP::Data->new->name($k)
                        ->value(Lim::RPC::__soap_result($_[0].'.'.$k, $v))
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
                ->value(Lim::RPC::__soap_result($_[0].'.'.$k, $_[1]->{$k}))
                );
        }
        else {
            push(@a,
                SOAP::Data->new->name($k)
                ->value($_[1]->{$k})
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

sub __xmlrpc_result {
    my @a;
    
    foreach my $k (keys %{$_[1]}) {
        if (ref($_[1]->{$k}) eq 'ARRAY') {
            foreach my $v (@{$_[1]->{$k}}) {
                if (ref($v) eq 'HASH') {
                    push(@a,
                        XMLRPC::Data->new->value({ $k => Lim::RPC::__xmlrpc_result($_[0].'.'.$k, $v) })
                        );
                }
                else {
                    push(@a,
                        XMLRPC::Data->new->value({ $k => $v })
                        );
                }
            }
        }
        elsif (ref($_[1]->{$k}) eq 'HASH') {
            push(@a,
                XMLRPC::Data->new->value({ $k => Lim::RPC::__xmlrpc_result($_[0].'.'.$k, $_[1]->{$k}) })
                );
        }
        else {
            push(@a,
                XMLRPC::Data->new->value({ $k => $_[1]->{$k} })
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
        if ($data->isa('Lim::Error')) {
            return $cb->cb->($data);
        }
    }
    elsif (defined $data) {
        unless (ref($data) eq 'HASH') {
            confess __PACKAGE__, ': data not a hash';
        }
        
        if ($cb->call_def and exists $cb->call_def->{out}) {
            Lim::RPC::V($data, $cb->call_def->{out});
        }
        elsif (%$data) {
            confess __PACKAGE__, ': data given without definition';
        }
    }
    else {
        if ($cb->call_def and exists $cb->call_def->{out}) {
            Lim::RPC::V({}, $cb->call_def->{out});
        }
    }
    
    if ($cb->isa('Lim::RPC::Callback::SOAP')) {
        return $cb->cb->(defined $data ? SOAP::Data->value(Lim::RPC::__soap_result('base', $data)) : undef);
    }
    elsif ($cb->isa('Lim::RPC::Callback::XMLRPC')) {
        return $cb->cb->(defined $data ? Lim::RPC::__xmlrpc_result('base', $data) : undef);
    }

    return $cb->cb->(defined $data ? $data : {});
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::RPC

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim/issues>

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
