package Lim::RPC::Server;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(weaken);

use AnyEvent ();
use AnyEvent::Socket ();
use AnyEvent::TLS ();

use Lim ();
use Lim::RPC::Server::Client ();

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
        client => {},
        module => {}
    };
    bless $self, $class;
    my $real_self = $self;
    weaken($self);
    
    unless (defined $args{key} and -f $args{key}) {
        confess __PACKAGE__, ': No key file specified or not found';
    }
    unless (defined $args{host}) {
        confess __PACKAGE__, ': No host specified';
    }
    unless (defined $args{port}) {
        confess __PACKAGE__, ': No port specified';
    }
    
    $self->{tls_ctx} = AnyEvent::TLS->new(method => 'any', cert_file => $args{key});

    $self->{host} = $args{host};
    $self->{port} = $args{port};
    if (defined $args{html}) {
        $self->{html} = $args{html};
        
        unless (-d $self->{html} and -r $self->{html} and -x $self->{html}) {
            confess __PACKAGE__, ': Path to html "', $self->{html}, '" is invalid';
        }
    }

    $self->{socket} = AnyEvent::Socket::tcp_server $self->{host}, $self->{port}, sub {
        my ($fh, $host, $port) = @_;
        
        my $handle;
        $handle = Lim::RPC::Server::Client->new(
            server => $self,
            fh => $fh,
            tls_ctx => $self->{tls_ctx},
            on_error => sub {
                my ($handle, $fatal, $message) = @_;
                
                $self->{logger}->warn($handle, ' Error: ', $message);
                
                delete $self->{client}->{$handle};
            },
            on_eof => sub {
                my ($handle) = @_;
                
                $self->{logger}->debug($handle, ' EOF');
                
                delete $self->{client}->{$handle};
            });
        
        if (exists $self->{html}) {
            $handle->set_html($self->{html});
        }
        
        $self->{client}->{$handle} = $handle;
    }, sub {
        my (undef, $host, $port) = @_;
        
        Lim::DEBUG and $self->{logger}->debug(__PACKAGE__, ' ', $self, ' ready at ', $host, ':', $port);
        
        Lim::SRV_LISTEN;
    };

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $real_self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
    
    delete $self->{client};
    delete $self->{socket};
    delete $self->{module};
}

=head2 function2

=cut

sub serve {
    my ($self) = shift;
    
    foreach my $module (@_) {
        if ($module->isa('Lim::RPC')) {
            my $name = lc($module->Module);
            
            if (exists $self->{module}->{$name}) {
                $self->{logger}->warn('Can not serve ', $name, ': module already served');
                next;
            }
            
            unless ($module->VERSION) {
                $self->{logger}->warn('Can not serve ', $name, ': no VERSION specified in module');
                next;
            }
            
            my $calls = $module->Calls;
            unless ($calls) {
                $self->{logger}->info('Not serving ', $name, ', nothing to serve');
                next;
            }
            unless (ref($calls) eq 'HASH') {
                $self->{logger}->warn('Can not serve ', $name, ': Calls() return was invalid');
                next;
            }
            unless (%$calls) {
                $self->{logger}->info('Not serving ', $name, ', nothing to serve');
                next;
            }
            foreach my $call (keys %$calls) {
                unless ($module->can($call)) {
                    $self->{logger}->warn('Can not serve ', $name, ': Missing specified call ', $call, ' function');
                    undef($calls);
                    last;
                }
                unless ($module->can('__lim_rpc_'.$call)) {
                    my ($orig_call, $rpc_call, $valueof);
                    
                    if (exists $calls->{in}) {
                        unless (ref($calls->{in}) eq 'HASH') {
                            $self->{logger}->warn('Can not serve ', $name, ': call ', $call, ' has invalid in parameter definition');
                            undef($calls);
                            last;
                        }
                        
                        my @keys = keys %{$calls->{in}};
                        
                        if (scalar @keys != 1) {
                            $self->{logger}->warn('Can not serve ', $name, ': call ', $call, ' has invalid in parameter definition');
                            undef($calls);
                            last;
                        }
                        
                        $valueof = '//'.shift(@keys).'/';
                    }
                    
                    $orig_call = ref($module).'::'.$call;
                    $call = '__lim_rpc_'.$call;;
                    $rpc_call = ref($module).'::'.$call;
                    
                    no strict 'refs';
                    *$rpc_call = \&$orig_call;
                    *$orig_call = sub {
                        my ($self, $cb, @args) = Lim::RPC::C(@_, $valueof);
                        
                        Lim::RPC::R($cb, $self->$call(@args));
                    };
                }
            }
            unless ($calls) {
                next;
            }
            
            # TODO: Generate wsdl defs
            
            Lim::DEBUG and $self->{logger}->debug('serving ', $name);
            
            $self->{module}->{$name} = {
                name => $name,
                module => $module
            };
        }
    }
    
    $self;
}

=head2 function2

=cut

sub key {
    $_[0]->{key};
}

=head2 function2

=cut

sub port {
    $_[0]->{port};
}

=head2 function2

=cut

sub host {
    $_[0]->{host};
}

=head2 function2

=cut

sub html {
    $_[0]->{html};
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

1; # End of Lim::RPC::Server
