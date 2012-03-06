package Lim::DB::Agent;

use common::sense;
use Carp;

use Log::Log4perl ();

use Lim ();
use Lim::DB ();

use base qw(
    Lim::RPC
    Lim::Notify
    );

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
    };
    bless $self, $class;
    
    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
}

=head2 function2

=cut

sub Module {
    'DB';
}

=head2 function2

=cut

sub WSDL {
    'db_agent';
}

=head2 function1

=cut

sub Agents {
    Lim::DB->schema->resultset('Agent')->all;
}

=head2 function1

=cut

sub Agent {
    shift;
    Lim::DB->schema->resultset('Agent')->find(@_);
}

=head2 function1

=cut

sub ReadAgents {
    Lim::RPC::F(@_, undef);
    
    $_[0]->R(
        Lim::DB->schema->resultset('Agent'),
        {
            'base.agent' => [ 'agent_id', 'agent_name', 'agent_host', 'agent_port' ]
        });
}

=head2 function1

=cut

sub ReadAgent {
    my ($self, $q, $id) = Lim::RPC::F(@_, '//ReadAgent/');
    my $r = {};

    if (defined $id) {
        if (($_ = Lim::DB->schema->resultset('Agent')->find($id))) {
            my %r = $_->get_columns;
            $r->{agent} = [ \%r ];
        }
    }
    elsif (ref($q) eq 'HASH') {
        if (exists $q->{agent}) {
            if (ref($q->{agent}) eq 'HASH') {
                $q->{agent} = [ $q->{agent} ];
            }
            if (ref($q->{agent}) eq 'ARRAY') {
                foreach (@{$q->{agent}}) {
                    if (ref($_) eq 'HASH') {
                        foreach (Lim::DB->schema->resultset('Agent')->search($_)) {
                            my %r = $_->get_columns;
                            push(@{$r->{agent}}, \%r);
                        }
                    }
                }
            }
        }
    }
    
    $self->R($r,
        {
            'base.agent' => [ 'agent_id', 'agent_name', 'agent_host', 'agent_port' ]
        });
}

=head2 function1

=cut

sub CreateAgent {
    my ($self, $q, $id) = Lim::RPC::F(@_, '//CreateAgent/');
    my $r = {};
    
    if (ref($q) eq 'HASH') {
        if (exists $q->{agent}) {
            if (ref($q->{agent}) eq 'HASH') {
                $q->{agent} = [ $q->{agent} ];
            }
            if (ref($q->{agent}) eq 'ARRAY') {
                foreach (@{$q->{agent}}) {
                    if (ref($_) eq 'HASH') {
                        if (($_ = Lim::DB->schema->resultset('Agent')->new($_))) {
                            $_->insert;
                            my %r = $_->get_columns;
                            push(@{$r->{agent}}, \%r);
                            $self->Notify('CreateAgent', $_);
                        }
                    }
                }
            }
        }
    }
    
    $self->R($r,
        {
            'base.agent' => [ 'agent_id', 'agent_name', 'agent_host', 'agent_port' ]
        });
}

=head2 function1

=cut

sub UpdateAgent {
    my ($self, $q, $id) = Lim::RPC::F(@_, '//UpdateAgent/');
    my $r = {};

    if (defined $id) {
        if (($_ = Lim::DB->schema->resultset('Agent')->find($id))) {
            $_->update($q);
            my %r = $_->get_columns;
            $r->{agent} = [ \%r ];
            $self->Notify('UpdateAgent', $_);
        }
    }
    elsif (ref($q) eq 'HASH') {
        if (exists $q->{agent}) {
            if (ref($q->{agent}) eq 'HASH') {
                $q->{agent} = [ $q->{agent} ];
            }
            if (ref($q->{agent}) eq 'ARRAY') {
                foreach (@{$q->{agent}}) {
                    if (ref($_) eq 'HASH') {
                        if (exists $_->{agent_id}) {
                            $id = delete $_->{agent_id};
                            if ((my $o = Lim::DB->schema->resultset('Agent')->find($id))) {
                                $o->update($_);
                                my %r = $o->get_columns;
                                push(@{$r->{agent}}, \%r);
                                $self->Notify('UpdateAgent', $o);
                            }
                        }
                    }
                }
            }
        }
    }

    $self->R($r,
        {
            'base.agent' => [ 'agent_id', 'agent_name', 'agent_host', 'agent_port' ]
        });
}

=head2 function1

=cut

sub DeleteAgent {
    my ($self, $q, $id) = Lim::RPC::F(@_, '//DeleteAgent/');
    my $r = {};

    if (defined $id) {
        if (($_ = Lim::DB->schema->resultset('Agent')->find($id))) {
            $_->delete;
            my %r = $_->get_columns;
            $r->{agent} = [ \%r ];
            $self->Notify('DeleteAgent', $_);
        }
    }
    elsif (ref($q) eq 'HASH') {
        if (exists $q->{agent}) {
            if (ref($q->{agent}) eq 'HASH') {
                $q->{agent} = [ $q->{agent} ];
            }
            if (ref($q->{agent}) eq 'ARRAY') {
                foreach (@{$q->{agent}}) {
                    if (ref($_) eq 'HASH') {
                        if (exists $_->{agent_id}) {
                            $id = delete $_->{agent_id};
                            if ((my $o = Lim::DB->schema->resultset('Agent')->find($id))) {
                                $o->delete;
                                my %r = $o->get_columns;
                                push(@{$r->{agent}}, \%r);
                                $self->Notify('DeleteAgent', $o);
                            }
                        }
                    }
                }
            }
        }
    }

    $self->R($r,
        {
            'base.agent' => [ 'agent_id', 'agent_name', 'agent_host', 'agent_port' ]
        });
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

1; # End of Lim::Master
