package Lim::Agent;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(weaken);

use Lim ();
use Lim::DB::Master ();
use Lim::RPC::Client ();

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

sub UNKNOWN (){ 0 }
sub CONNECTING (){ 1 }
sub ONLINE (){ 2 }
sub OFFLINE (){ 3 }
sub WRONG_TYPE (){ 4 }
sub INVALID (){ 5 }

sub EXECUTOR_STATUS_INTERVAL (){ 10 }

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
        executor => {},
        watchers => []
    };
    bless $self, $class;
    my $real_self = $self;
    weaken($self);
    
    unless (defined $args{server}) {
        confess __PACKAGE__, ': Missing server';
    }
    unless (defined $args{exec_host}) {
        confess __PACKAGE__, ': Missing exec_host';
    }
    unless (defined $args{exec_port}) {
        confess __PACKAGE__, ': Missing exec_port';
    }
    
    $self->{db_master} = Lim::DB::Master->new
        ->AddNotify($self, 'CreateMaster', 'UpdateMaster', 'DeleteMaster');
    
    $self->{executor} = {
        host => $args{exec_host},
        port => $args{exec_port},
        status => UNKNOWN,
        status_message => 'Not checked'
    };

    $self->{watcher_executor_status} = AnyEvent->timer(
        after => EXECUTOR_STATUS_INTERVAL,
        interval => EXECUTOR_STATUS_INTERVAL,
        cb => sub {
            unless (exists $self->{run_executor_status}) {
                $self->{run_executor_status} = 1;
                $self->ExecutorGetStatus;
                delete $self->{run_executor_status};
            }
        });
    
    $args{server}->serve(
        $self->{db_master}
    );
    
    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $real_self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
}

=head2 function2

=cut

sub Module {
    'Agent';
}

=head2 function2

=cut

sub ReadManages {
    my ($self, $cb) = Lim::RPC::C(@_, undef);

    if (exists $self->{executor}) {
        if ($self->{executor}->{status} == ONLINE) {
            my $cli; $cli = Lim::RPC::Client->new(
                host => $self->{executor}->{host},
                port => $self->{executor}->{port},
                uri => '/manager',
                cb => sub {
                    my (undef, $data) = @_;
                    
                    if ($cli->status == Lim::RPC::Client::OK
                        and defined $data and ref($data) eq 'HASH'
                        and exists $data->{manage}
                        and ref($data->{manage}) eq 'ARRAY')
                    {
                        Lim::RPC::R($cb, $data, {
                           'base.manage' => [ 'type', 'name', 'plugin', 'action' ],
                           'base.manage.action' => [ 'name', 'displayName', 'helper' ]
                        });
                    }
                    else {
                        # TODO: cli not ok
                        Lim::RPC::R($cb);
                    }
                    undef($cli);
                });
            return;
        }
        else {
            # TODO: executor not online
        }
    }
    else {
        # TODO: no executor
    }
    Lim::RPC::R($cb);
}

=head2 function2

=cut

sub ReadManage {
    my ($self, $cb, undef, $type, $name, $plugin, $action) = Lim::RPC::C(@_, undef);
    
    unless (defined $type and defined $name and defined $plugin and defined $action) {
        Lim::RPC::R($cb);
        return;
    }
    
    if (exists $self->{executor}) {
        if ($self->{executor}->{status} == ONLINE) {
            my $cli; $cli = Lim::RPC::Client->new(
                host => $self->{executor}->{host},
                port => $self->{executor}->{port},
                uri => '/manager/manage/'.join('/', $type, $name, $plugin, $action),
                cb => sub {
                    my (undef, $data) = @_;
                    
                    if ($cli->status == Lim::RPC::Client::OK
                        and defined $data and ref($data) eq 'HASH'
                        and exists $data->{helper}
                        and ref($data->{helper}) eq 'HASH')
                    {
                        Lim::RPC::R($cb, {
                            helper => $data->{helper}
                        }, {
                            'base.helper' => [ 'name', 'data' ]
                        });
                    }
                    else {
                        # TODO: cli not ok
                        Lim::RPC::R($cb);
                    }
                    undef($cli);
                });
            return;
        }
        else {
            # TODO: executor not online
        }
    }
    else {
        # TODO: no executor
    }
    Lim::RPC::R($cb);
}

=head2 function2

=cut

sub Notification {
    my ($self, $notifier, $what, @parameters) = @_;
}

=head2 function2

=cut

sub ExecutorGetStatus {
    my ($self) = @_;
    my $real_self = $self;
    weaken($self);
    
    if (exists $self->{executor} and !exists $self->{executor}->{watcher_status}) {
        my $executor = $self->{executor};
        weaken($executor);
        
        $executor->{watcher_status} = Lim::RPC::Client->new(
            host => $executor->{host},
            port => $executor->{port},
            uri => '/lim',
            cb => sub {
                my ($cli, $data) = @_;
                
                if ($cli->status == Lim::RPC::Client::OK) {
                    if (defined $data and ref($data) eq 'HASH'
                        and exists $data->{lim}
                        and ref($data->{lim}) eq 'HASH'
                        and exists $data->{lim}->{type}
                        and exists $data->{lim}->{version})
                    {
                        if ($data->{lim}->{type} eq 'executor') {
                            $self->{executor}->{status} = ONLINE;
                            $self->{executor}->{status_message} = 'Online';
                            $self->{executor}->{version} = $data->{lim}->{version};
                        }
                        else {
                            $self->{executor}->{status} = WRONG_TYPE;
                            $self->{executor}->{status_message} = 'Expected executor but got '.$data->{lim}->{type};
                        }
                    }
                    else {
                        $self->{executor}->{status} = INVALID;
                        $self->{executor}->{status_message} = 'Invalid data returned';
                    }
                }
                elsif ($cli->status == Lim::RPC::Client::ERROR) {
                    $self->{executor}->{status} = OFFLINE;
                    $self->{executor}->{status_message} = 'Error: '.$cli->error;
                }
                else {
                    $self->{executor}->{status} = OFFLINE;
                    $self->{executor}->{status_message} = 'Unknown';
                }
                
                delete $executor->{watcher_status};
            });
        $self->{executor}->{status} = CONNECTING;
        $self->{executor}->{status_message} = 'Connecting';
    }
    
    $real_self;
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

1; # End of Lim::Agent
