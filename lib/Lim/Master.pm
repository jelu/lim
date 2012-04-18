package Lim::Master;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(weaken);

use Lim ();
use Lim::DB::Agent ();
use Lim::RPC::Client ();
use Lim::Helpers ();

use base qw(
    Lim::RPC
    Lim::Notification
    );

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;

sub UNKNOWN (){ 'UNKNOWN' }
sub CONNECTING (){ 'CONNECTING' }
sub ONLINE (){ 'ONLINE' }
sub OFFLINE (){ 'OFFLINE' }
sub WRONG_TYPE (){ 'WRONG_TYPE' }
sub INVALID (){ 'INVALID' }

sub AGENT_STATUS_INTERVAL (){ 10 }

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
        agent => {}
    };
    bless $self, $class;
    my $real_self = $self;
    weaken($self);
    
    unless (defined $args{server}) {
        confess __PACKAGE__, ': Missing server';
    }
    
    $self->{db_agent} = Lim::DB::Agent->new
        ->AddNotify($self, 'CreateAgent', 'UpdateAgent', 'DeleteAgent');

    foreach ($self->{db_agent}->Agents) {
        $self->{agent}->{$_->agent_id} = {
            id => $_->agent_id,
            name => $_->agent_name,
            host => $_->agent_host,
            port => $_->agent_port,
            status => UNKNOWN,
            status_message => 'Loaded from database at startup'
        };
    }
    
    $self->{watcher_agent_status} = AnyEvent->timer(
        after => AGENT_STATUS_INTERVAL,
        interval => AGENT_STATUS_INTERVAL,
        cb => sub {
            unless (exists $self->{run_agent_status}) {
                $self->{run_agent_status} = 1;
                foreach (keys %{$self->{agent}}) {
                    $self->AgentGetStatus($_);
                }
                delete $self->{run_agent_status};
            }
        });

    $args{server}->serve(
        $self->{db_agent},
        Lim::Helpers->new(html => $args{server}->html)
    );
    
    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $real_self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
    
    delete $self->{watcher_agent_status};
    delete $self->{agent};
    delete $self->{db_agent};
}

=head2 function2

=cut

sub Module {
    'Master';
}

=head2 function2

=cut

sub ReadAgents {
    my ($self, $cb) = Lim::RPC::C(@_, undef);
    
    Lim::RPC::R($cb, {
        agent => [ values %{$self->{agent}} ]
    }, {
        'base.agent' => [ 'id', 'name', 'host', 'port', 'status', 'status_message', 'manage' ],
        'base.agent.manage' => [ 'type', 'name', 'plugin', 'actions' ]
    });
}

=head2 function2

=cut

sub Notification {
    my ($self, $notifier, $what, @parameters) = @_;
    
    if ($what eq 'CreateAgent') {
        my ($agent) = @parameters;
        
        if (defined $agent) {
            my $id = $agent->agent_id;
            
            $self->{agent}->{$id} = {
                id => $id,
                name => $agent->agent_name,
                host => $agent->agent_host,
                port => $agent->agent_port,
                status => UNKNOWN,
                status_message => 'Just added'
            };
            
            $self->AgentGetStatus($id);
        }
    }
    elsif ($what eq 'UpdateAgent') {
        my ($agent) = @parameters;
        
        if (defined $agent) {
            my $id = $agent->agent_id;
            
            if (exists $self->{agent}->{$id}) {
                my $myAgent = $self->{agent}->{$id};
                my $updateStatus = 0;
                
                if ($myAgent->{host} ne $agent->agent_host or $myAgent->{port} ne $agent->agent_port) {
                    $myAgent->{status} = UNKNOWN;
                    $myAgent->{status_message} = 'Agent updated with new host/port';
                    $updateStatus = 1;
                }
                $myAgent->{name} = $agent->agent_name;
                $myAgent->{host} = $agent->agent_host;
                $myAgent->{port} = $agent->agent_port;
                
                if ($updateStatus) {
                    $self->AgentGetStatus($id);
                }
            }
            else {
                $self->{logger}->warn('UpdateAgent notification on non-existing agent [id: ', $id, ']');
            }
        }
    }
    elsif ($what eq 'DeleteAgent') {
        my ($agent) = @parameters;
        
        if (defined $agent) {
            my $id = $agent->agent_id;
            
            if (exists $self->{agent}->{$id}) {
                delete $self->{agent}->{$id};
            }
            else {
                $self->{logger}->warn('DeleteAgent notification on non-existing agent [id: ', $id, ']');
            }
        }
    }
}

=head2 function2

=cut

sub AgentGetStatus {
    my ($self, $id) = @_;
    
    if (defined $id and exists $self->{agent}->{$id} and !exists $self->{agent}->{$id}->{watcher_status}) {
        my $agent = $self->{agent}->{$id};
        
        weaken($self);
        weaken($agent);

        $agent->{status} = CONNECTING;
        $agent->{status_message} = 'Connecting';
        $agent->{watcher_status} = Lim::RPC::Client->new(
            host => $agent->{host},
            port => $agent->{port},
            uri => '/lim',
            cb => sub {
                my ($cli, $data) = @_;
                
                if ($cli->status == Lim::RPC::Client::OK) {
                    if (defined $data and ref($data) eq 'HASH'
                        and exists $data->{lim}->{type}
                        and exists $data->{lim}->{version})
                    {
                        if ($data->{lim}->{type} eq 'agent') {
                            $agent->{status} = ONLINE;
                            $agent->{status_message} = 'Online';
                            $agent->{version} = $data->{lim}->{version};
                            $self->AgentGetInformation($id);
                        }
                        else {
                            $agent->{status} = WRONG_TYPE;
                            $agent->{status_message} = 'Expected agent but got '.$data->{lim}->{type};
                        }
                    }
                    else {
                        $agent->{status} = INVALID;
                        $agent->{status_message} = 'Invalid data returned';
                    }
                }
                elsif ($cli->status == Lim::RPC::Client::ERROR) {
                    $agent->{status} = OFFLINE;
                    $agent->{status_message} = 'Error: '.$cli->error;
                }
                else {
                    $agent->{status} = OFFLINE;
                    $agent->{status_message} = 'Unknown';
                }
                
                delete $agent->{watcher_status};
            });
    }
}

=head2 function2

=cut

sub AgentGetInformation {
    my ($self, $id) = @_;
    
    if (defined $id and exists $self->{agent}->{$id} and !exists $self->{agent}->{$id}->{watcher_information}) {
        my $agent = $self->{agent}->{$id};

        if ($agent->{status} == ONLINE) {
            weaken($agent);
            $agent->{watcher_information} = Lim::RPC::Client->new(
                host => $agent->{host},
                port => $agent->{port},
                uri => '/agent/manage',
                cb => sub {
                    my ($cli, $data) = @_;
                    
                    if ($cli->status == Lim::RPC::Client::OK
                        and defined $data and ref($data) eq 'HASH'
                        and exists $data->{manage}
                        and ref($data->{manage}) eq 'ARRAY')
                    {
                        $agent->{manage} = $data->{manage};
                    }
                    
                    delete $agent->{watcher_information};
                });
        }
    }
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
