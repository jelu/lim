package Lim::CLI;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(blessed weaken);
use Module::Find qw(findsubmod);

use Lim ();
use Lim::Error ();
use Lim::Agent ();
use Lim::Plugins ();

use IO::Handle ();
use AnyEvent::Handle ();

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
        cli => {},
        busy => 0
    };
    bless $self, $class;
    my $real_self = $self;
    weaken($self);

    unless (defined $args{on_quit}) {
        confess __PACKAGE__, ': Missing on_quit';
    }
    unless (ref($args{on_quit}) eq 'CODE') {
        confess __PACKAGE__, ': on_quit is not CODE';
    }
    $self->{on_quit} = $args{on_quit};

    foreach my $module (qw(Lim::Agent)) {
        my $obj = $module->CLI(cli => $self);
        my $name = lc($module->Module);
        
        if (exists $self->{cli}->{$name}) {
            $self->{logger}->warn('Can not load internal CLI module ', $module, ': name ', $name, ' already in use');
            next;
        }
        
        $self->{cli}->{$name} = {
            name => $name,
            module => $module,
            obj => $obj
        };
    }
    
    foreach my $module (Lim::Plugins->instance->Loaded) {
        my $obj = $module->CLI(cli => $self);
        my $name = lc($module->Module);
        
        if (exists $self->{cli}->{$name}) {
            $self->{logger}->warn('Can not use CLI module ', $module, ': name ', $name, ' already in use');
            next;
        }
        
        $self->{cli}->{$name} = {
            name => $name,
            module => $module,
            obj => $obj
        };
    }
    
    $self->{stdin_watcher} = AnyEvent::Handle->new(
         fh => \*STDIN,
         on_error => sub {
            my ($handle, $fatal, $msg) = @_;
            $handle->destroy;
            $self->{on_quit}($self);
         },
         on_eof => sub {
             my ($handle) = @_;
             $handle->destroy;
             $self->{on_quit}($self);
         },
         on_read => sub {
             my ($handle) = @_;
             
             $handle->push_read(line => sub {
                 if ($self->{busy}) {
                     return;
                 }
                 
                 my ($handle, $line) = @_;
                 my ($cmd, $args) = split(/\s+/o, $line, 2);
                 $cmd = lc($cmd);
                 
                 if ($cmd eq 'quit' or $cmd eq 'exit') {
                     if (exists $self->{current}) {
                         delete $self->{current};
                         $self->Prompt;
                     }
                     else {
                         $handle->destroy;
                         $self->{on_quit}($self);
                         return;
                     }
                 }
                 else {
                     if ($cmd) {
                         if (exists $self->{current}) {
                             if ($self->{current}->{module}->Commands->{$cmd} and
                                 $self->{current}->{obj}->can($cmd))
                             {
                                 $self->{busy} = 1;
                                 $self->{current}->{obj}->$cmd($args);
                             }
                             else {
                                 $self->unknown_command($cmd);
                                 $self->Prompt;
                             }
                         }
                         elsif (exists $self->{cli}->{$cmd}) {
                             $self->{current} = $self->{cli}->{$cmd};
                             $self->Prompt;
                         }
                         else {
                             $self->unknown_command($cmd);
                             $self->Prompt;
                         }
                     }
                     else {
                         $self->Prompt;
                     }
                 }

             });
         });

    IO::Handle::autoflush STDOUT 1;
    print 'Welcome to LIM ', $Lim::VERSION, ' command line interface', "\n";
    print 'lim> ';
    
    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $real_self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
    delete $self->{current};
    delete $self->{stdin_watcher};
    delete $self->{cli};
}

=head2 function1

=cut

sub Prompt {
    print 'lim',(exists $_[0]->{current} ? $_[0]->{current}->{obj}->Prompt : '' ),'> ';
}

=head2 function1

=cut

sub unknown_command {
    my ($self, $cmd) = @_;
    
    $self->println('unknown command: ', $cmd);
}

=head2 function1

=cut

sub print {
    my $self = shift;
    
    print @_;
}

=head2 function1

=cut

sub printf {
    my $self = shift;
    
    printf @_;
}

=head2 function1

=cut

sub println {
    my $self = shift;
    
    print @_, "\n";
}

=head2 function1

=cut

sub Successful {
    $_[0]->{busy} = 0;
    $_[0]->Prompt;
}

=head2 function1

=cut

sub Error {
    my $self = shift;
    
    $self->print('Command Error: ', ( scalar @_ > 0 ? @_ : 'unknown' ));
    foreach (@_) {
        if (blessed $_ and $_->isa('Lim::Error')) {
            $self->print('Module: ', $_[0]->module, ' Code: ', $_[0]->code, ' Message: ', $_[0]->message);
        }
        else {
            $self->print($_);
        }
    }
    $self->println;
    
    $self->{busy} = 0;
    $self->Prompt;
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

1; # End of Lim::CLI
