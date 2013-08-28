package Lim::Util::DBI;

use common::sense;
use Carp;
use Scalar::Util qw(weaken);

use Log::Log4perl ();
use DBI ();
use JSON::XS ();

use AnyEvent ();
use AnyEvent::Util ();

use Lim ();

=encoding utf8

=head1 NAME

Lim::Util::DBI - Create a DBH that is executed in a forked process

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;

=head1 SYNOPSIS

=over 4

use Lim::Util::DBI;

=back

=head1 METHODS

=over 4

=item new

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %args = ( @_ );
    my $self = {
        logger => Log::Log4perl->get_logger,
        json => JSON::XS->new->ascii->convert_blessed
    };
    bless $self, $class;
    my $real_self = $self;
    weaken($self);
    
    unless (defined $args{on_connect} and ref($args{on_connect}) eq 'CODE') {
        confess __PACKAGE__, ': Missing on_connect or it is not CODE';
    }
    
    $self->{on_connect} = delete $args{on_connect};

    if (defined $args{on_error}) {
        unless (ref($args{on_error}) eq 'CODE') {
            confess __PACKAGE__, ': on_error is not CODE';
        }
        $self->{on_error} = delete $args{on_error};
    }

    my ($child, $parent) = AnyEvent::Util::portable_socketpair;
    unless (defined $child and defined $parent) {
        confess __PACKAGE__, ': Unable to create client/server socket pairs: ', $!;
    }

    AnyEvent::Util::fh_nonblocking $child, 1;
    $self->{child} = $child;

    my $pid = fork;
    
    if ($pid) {
        #
        # Parent process
        #
        
        close $parent;

        $self->{child_watcher} = AnyEvent->io(
            fh => $child,
            poll => 'r',
            cb => sub {
                unless (defined $self and exists $self->{child}) {
                    return;
                }
                
                my $response;
                my $len = sysread $self->{child}, my $buf, 64*1024;
                if ($len > 0) {
                    undef $@;
                    
                    eval {
                        $reponse = $self->{json}->incr_parse($buf);
                    };
                    if ($@) {
                        $response = [];
                    }
                    unless (defined $response and ref($response) eq 'ARRAY') {
                        $@ = 'Invalid response';
                        $response = [];
                    }
                }
                elsif (defined $len) {
                    $@ = 'Unexpected EOF';
                    
                    shutdown($self->{child}, 2);
                    close(delete $self->{child});
                    $response = [];
                }
                else {
                    $@ = 'Unable to read from child: '.$!;

                    shutdown($self->{child}, 2);
                    close(delete $self->{child});
                    $response = [];
                }
                
                if (defined $response and exists $self->{cb}) {
                    $self->{cb}->(@$response);
                    delete $self->{cb};
                }
            });
    }
    elsif (defined $pid) {
        #
        # Child process
        #

        $SIG{HUP} => 'IGNORE';
        $SIG{INT} => 'IGNORE';
        $SIG{TERM} => 'IGNORE';
        $SIG{PIPE} => 'IGNORE';
        $SIG{QUIT} => 'IGNORE';

                
    }
    else {
        confess __PACKAGE__, ': Unable to fork: ', $!;
    }

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
    
    if (exists $self->{child}) {
        shutdown($self->{child}, 2);
        close(delete $self->{child});
    }
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Util::DBI

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

1; # End of Lim::Util::DBI
