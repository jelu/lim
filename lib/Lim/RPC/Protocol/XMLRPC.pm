package Lim::RPC::Protocol::XMLRPC;

use common::sense;
use Carp;

use Scalar::Util qw(blessed weaken);

use HTTP::Status qw(:constants);
use HTTP::Request ();
use HTTP::Response ();
use URI ();
use URI::QueryParam ();

use XMLRPC::Lite ();
use XMLRPC::Transport::HTTP ();

use Lim ();

use base qw(Lim::RPC::Protocol);

=encoding utf8

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

sub Init {
}

=head2 function1

=cut

sub Destroy {
}

=head2 function1

=cut

sub name {
    'xmlrpc';
}

=head2 function1

=cut

sub serve {
}

=head2 function1

=cut

sub handle {
}

=head2 function1

=cut

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

=head2 function1

=cut

sub precall {
    my ($self, $call, $object, $som) = @_;
    
    unless (ref($call) eq '' and blessed($object) and blessed($som) and $som->isa('XMLRPC::SOM')) {
        confess __PACKAGE__, ': Invalid XMLRPC call';
    }

    unless (exists $som->{__lim_rpc_protocol_xmlrpc_cb} and blessed($som->{__lim_rpc_protocol_xmlrpc_cb}) and $som->{__lim_rpc_protocol_xmlrpc_cb}->isa('Lim::RPC::Callback')) {
        confess __PACKAGE__, ': XMLRPC::SOM does not contain lim rpc callback or invalid';
    }
    my $cb = delete $som->{__lim_rpc_protocol_xmlrpc_cb};
    my $valueof = $som->valueof('//'.$call.'/');
    
    if ($valueof) {
        unless (ref($valueof) eq 'HASH') {
            confess __PACKAGE__, ': Invalid data in XMLRPC call';
        }
    }
    else {
        undef($valueof);
    }

    return ($object, $cb, $valueof);
}

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Lim

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

1; # End of Lim::RPC::Protocol::XMLRPC
