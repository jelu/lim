package Lim::RPC::Call;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(blessed weaken);

use Lim ();
use Lim::Util ();
use Lim::RPC::Client ();

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;

sub OK (){ 1 }
sub ERROR (){ -1 }

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {
        logger => Log::Log4perl->get_logger,
        status => 0,
        error => ''
    };
    bless $self, $class;
    my $real_self = $self;
    weaken($self);

    $self->{module} = shift;
    $self->{call} = shift;
    $self->{component} = shift;
    my ($data, $cb, $args, $method, $uri);
    
    $args = {};
    if (scalar @_ == 1) {
        unless (ref($_[0]) eq 'CODE') {
            confess __PACKAGE__, ': Given one argument but its not a CODE callback';
        }
        
        $cb = $_[0];
    }
    elsif (scalar @_ == 2) {
        if (ref($_[0]) eq 'CODE') {
            $cb = $_[0];
            $args = $_[1];
        }
        elsif (ref($_[1]) eq 'CODE') {
            $data = $_[0];
            $cb = $_[1];
        }
        else {
            confess __PACKAGE__, ': Given two arguments but non are CODE callback';
        }
    }
    elsif (scalar @_ == 3) {
        unless (ref($_[1]) eq 'CODE') {
            confess __PACKAGE__, ': Given three argument but second its not a CODE callback';
        }
        
        $data = $_[0];
        $cb = $_[1];
        $args = $_[2];
    }
    else {
        confess __PACKAGE__, ': Too many arguments';
    }
    
    unless (ref($args) eq 'HASH') {
        confess __PACKAGE__, ': Given an arguments argument but its not an hash';
    }

    unless (defined $self->{call}) {
        confess __PACKAGE__, ': No call specified';
    }
    unless (blessed $self->{component} and $self->{component}->isa('Lim::Component::Client')) {
        confess __PACKAGE__, ': No component specified or not a Lim::Component::Client';
    }
    unless (defined $cb) {
        confess __PACKAGE__, ': No cb specified';
    }

    if (defined $args->{host}) {
        $self->{host} = $args->{host};
    }
    else {
        $self->{host} = Lim::Config->{host};
    }
    if (defined $args->{port}) {
        $self->{port} = $args->{port};
    }
    else {
        $self->{port} = Lim::Config->{port};
    }
    $self->{cb} = $cb;
    
    unless (defined $self->{host}) {
        confess __PACKAGE__, ': No host specified';
    }
    unless (defined $self->{port}) {
        confess __PACKAGE__, ': No port specified';
    }
    
    ($method, $uri) = Lim::Util::URIize($self->{call});
    
    $uri = '/'.lc($self->{module}).$uri;

    $self->{component}->_addCall($real_self);
    $self->{client} = Lim::RPC::Client->new(
        host => $self->{host},
        port => $self->{port},
        method => $method,
        uri => $uri,
        data => $data,
        cb => sub {
            my (undef, $data) = @_;

            if ($self->{client}->status == Lim::RPC::Client::OK) {
                $self->{status} = OK;
            }
            else {
                $self->{status} = ERROR;
                $self->{error} = $self->{client}->error;
            }
            
            delete $self->{client};
            $self->{cb}->($self, $data);
            $self->{component}->_deleteCall($self);
        }
    );
    
    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $real_self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
}

=head2 function1

=cut

sub Successful {
    $_[0]->{status} == OK;
}

=head2 function1

=cut

sub Error {
    $_[0]->{error};
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

1; # End of Lim::RPC::Call
