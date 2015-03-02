package Lim::RPC::Transport::RabbitMQ;

use common::sense;
use Carp;

use Scalar::Util qw(blessed weaken);

use AnyEvent ();
use AnyEvent::RabbitMQ ();

use HTTP::Status qw(:constants);
use HTTP::Request ();
use HTTP::Response ();
use URI ();
use Socket;

use Lim ();
use Lim::RPC::Callback ();

use base qw(Lim::RPC::Transport);

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=over 4

=item

=back

=cut

our $VERSION = $Lim::VERSION;

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 Init

=cut

sub Init {
    my $self = shift;
    my %args = ( @_ );
    my $real_self = $self;
    weaken($self);

    $self->{channel} = {};
    $self->{host} = 'localhost';
    $self->{port} = 5672;
    $self->{user} = 'guest';
    $self->{pass} = 'guest';
    $self->{vhost} = '/';
    $self->{timeout} = 1;
    $self->{queue_prefix} = 'lim_';

    foreach (qw(host port user pass vhost timeout)) {
        if (defined Lim::Config->{rpc}->{transport}->{rabbitmq}->{$_}) {
            $self->{$_} = Lim::Config->{rpc}->{transport}->{rabbitmq}->{$_};
        }
    }

    if (exists $args{uri}) {
        unless (blessed($args{uri}) and $args{uri}->isa('URI')) {
            confess 'uri argument is not a URI class';
        }

        $self->{host} = $args{uri}->host;
        $self->{port} = $args{uri}->port;
    }

    $self->{connected} = 0;

    eval {
        $self->{rabbitmq} = AnyEvent::RabbitMQ->new(verbose => 9)->load_xml_spec;
    };
    if ($@) {
        Lim::ERR and $self->{logger}->error('Failed to initiate AnyEvent::RabbitMQ: '.$@);
        return;
    }

    Lim::Util::resolve_host $self->{host}, $self->{port}, sub {
        my ($host, $port) = @_;

        unless (defined $self) {
            return;
        }

        unless (defined $host and defined $port) {
            Lim::WARN and $self->{logger}->warn('Unable to resolve host ', $self->{host});
            return;
        }

        $self->{host} = $host;
        $self->{port} = $port;
        $self->_connect;
    };
}

=head2 _connect

=cut

sub _connect {
    my ($self) = @_;
    my $real_self = $self;
    weaken($self);

    $self->{rabbitmq}->connect(
        (map { $_ => $self->{$_} } qw(host port user pass vhost timeout)),
        on_success => sub {
            unless (defined $self) {
                return;
            }

            Lim::DEBUG and $self->{logger}->debug('Server connected successfully');
            $self->{connected} = 1;

            foreach my $module_shortname (keys %{$self->{channel}}) {
                unless ($self->{channel}->{$module_shortname}->{open} == -1) {
                    next;
                }
                $self->_open($self->{channel}->{$module_shortname});
            }
        },
        on_failure => sub {
            my (undef, $fatal, $message) = @_;

            unless (defined $self) {
                return;
            }

            if ($fatal) {
                Lim::ERR and $self->{logger}->error('Server connection failure: '.$message);
            }
            else {
                Lim::WARN and $self->{logger}->warn('Server connection failure: '.$message);
            }
            $self->{connected} = 0;
        },
        on_close => sub {
            unless (defined $self) {
                return;
            }

            Lim::INFO and $self->{logger}->info('Server connection closed');
            $self->{connected} = 0;
        },
        on_read_failure => sub {
            unless (defined $self) {
                return;
            }

            my ($message) = @_;
            Lim::WARN and $self->{logger}->warn('Server read failure: '.$message);
        }
    );
}

=head2 Destroy

=cut

sub Destroy {
}

=head2 name

=cut

sub name {
    'rabbitmq';
}

=head2 uri

=cut

sub uri {
}

=head2 host

=cut

sub host {
}

=head2 port

=cut

sub port {
}

=head2 serve

=cut

sub serve {
    my ($self, $module, $module_shortname) = @_;
    my $real_self = $self;
    weaken($self);

    if (exists $self->{channel}->{$module_shortname}) {
        Lim::WARN and $self->{logger}->warn('Already serving '.$module_shortname);
        return;
    }

    $self->{channel}->{$module_shortname} = {
        module => $module_shortname,
        open => -1,
        obj => undef
    };

    if ($self->{connected}) {
        $self->_open($self->{channel}->{$module_shortname});
    }
}

sub _open {
    my ($self, $channel) = @_;
    my $real_self = $self;
    weaken($self);

    $channel->{open} = 0;
    $self->{rabbitmq}->open_channel(
        on_success => sub {
            unless (defined $self) {
                return;
            }

            Lim::DEBUG and $self->{logger}->debug('Channel opened successfully for '.$channel->{module});
            $self->_declare($channel, @_);
        },
        on_failure => sub {
            my ($message) = @_;

            unless (defined $self) {
                return;
            }

            Lim::ERR and $self->{logger}->error('Channel open failure for '.$channel->{module}.': '.$message);
            $channel->{open} = 0;
        },
        on_close => sub {
            unless (defined $self) {
                return;
            }

            Lim::INFO and $self->{logger}->info('Channel closed for '.$channel->{module});
            $channel->{open} = 0;
        }
    );
}

sub _declare {
    my ($self, $channel, $obj) = @_;
    my $real_self = $self;
    weaken($self);

    unless (blessed $obj and $obj->isa('AnyEvent::RabbitMQ::Channel')) {
        Lim::ERR and $self->{logger}->error('Channel open failure for '.$channel->{module}.': object returned is not AnyEvent::RabbitMQ::Channel');
        return;
    }

    $channel->{obj} = $obj;
    $channel->{obj}->declare_queue(
        queue => $self->{queue_prefix}.$channel->{module},
        on_success => sub {
            unless (defined $self) {
                return;
            }

            Lim::DEBUG and $self->{logger}->debug('Channel queue declared successfully for '.$channel->{module});
            $self->_consume($channel);
        },
        on_failure => sub {
            my ($message) = @_;

            unless (defined $self) {
                return;
            }

            Lim::ERR and $self->{logger}->error('Channel queue declare failure for '.$channel->{module}.': '.$message);
            $channel->{open} = 0;
        }
    );
}

sub _consume {
    my ($self, $channel) = @_;
    my $real_self = $self;
    weaken($self);

    $channel->{obj}->consume(
        queue => $self->{queue_prefix}.$channel->{module},
        no_ack => 0,
        on_success => sub {
            unless (defined $self) {
                return;
            }

            Lim::DEBUG and $self->{logger}->debug('Channel consuming successfully for '.$channel->{module});
            $channel->{open} = 1;
        },
        on_consume => sub {
            my ($req) = @_;

            unless (defined $self) {
                return;
            }

            unless (ref($req) eq 'HASH'
                and blessed $req->{deliver} and $req->{deliver}->can('method_frame')
                and blessed $req->{deliver}->method_frame and $req->{deliver}->method_frame->can('delivery_tag'))
            {
                Lim::ERR and $self->{logger}->error('Consume request invalid, may go unacked');
                return;
            }

            unless (blessed $req->{body} and $req->{body}->can('payload')) {
                Lim::ERR and $self->{logger}->error('Consume request invalid, no payload');
                return;
            }

            if (blessed $req->{header} and $req->{header}->can('reply_to')) {
                $channel->{obj}->publish(
                    exchange    => '',
                    routing_key => $req->{header}->reply_to,
                    body        => 'response'
                );
            }

            $channel->{obj}->ack(
                delivery_tag => $req->{deliver}->method_frame->delivery_tag
            );
        },
        on_failure => sub {
            my ($message) = @_;

            unless (defined $self) {
                return;
            }

            Lim::ERR and $self->{logger}->error('Channel consume failure for '.$channel->{module}.': '.$message);
            $channel->{open} = 0;
        }
    );
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

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::RPC::Transport::RabbitMQ
