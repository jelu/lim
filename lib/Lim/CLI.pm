package Lim::CLI;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(blessed weaken);
use Module::Find qw(findsubmod);
use Fcntl qw(:seek);
use File::Temp ();
use IO::File ();
use Digest::SHA ();

use Lim ();
use Lim::Error ();
use Lim::Agent ();
use Lim::Plugins ();

use IO::Handle ();
use AnyEvent::Handle ();

use AnyEvent::ReadLine::Gnu ();

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
        busy => 0,
        no_completion => 0
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
    
    foreach my $module (Lim::Plugins->instance->LoadedModules) {
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
    
#    print 'Welcome to LIM ', $Lim::VERSION, ' command line interface', "\n";

    $self->{rl} = AnyEvent::ReadLine::Gnu->new(
        prompt => 'lim> ',
        on_line => sub {
            if ($self->{busy}) {
                return;
            }
             
            my ($line) = @_;
            my ($cmd, $args) = split(/\s+/o, $line, 2);
            $cmd = lc($cmd);
             
            if ($cmd eq 'quit' or $cmd eq 'exit') {
                if (exists $self->{current}) {
                    delete $self->{current};
                    $self->{rl}->hide;
                    $AnyEvent::ReadLine::Gnu::prompt = 'lim> ';
                    $self->{rl}->show;
                }
                else {
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
                        }
                    }
                    elsif (exists $self->{cli}->{$cmd}) {
                        $self->{current} = $self->{cli}->{$cmd};
                        $self->{rl}->hide;
                        $AnyEvent::ReadLine::Gnu::prompt = 'lim'.$self->{current}->{obj}->Prompt.'> ';
                        $self->{rl}->show;
                    }
                    else {
                        $self->unknown_command($cmd);
                    }
                }
            }
        });

    $self->{rl}->Attribs->{completion_entry_function} = $self->{rl}->Attribs->{list_completion_function};
    $self->{rl}->Attribs->{attempted_completion_function} = sub {
        my ($text, $line, $start, $end) = @_;
        
        my @parts = split(/\s+/o, substr($line, 0, $start));
        
        if ($self->{current}) {
            unshift(@parts, $self->{current}->{name});
        }
        
        if (scalar @parts) {
            my $part = shift(@parts);

            if (exists $self->{cli}->{$part}) {
                my $cmd = $self->{cli}->{$part}->{module}->Commands;
                
                while (defined ($part = shift(@parts))) {
                    unless (exists $cmd->{part} and ref($cmd->{part}) eq 'HASH') {
                        if ($self->{no_completion}++ == 2) {
                            $self->println('no completion found');
                        }
                        $self->{rl}->Attribs->{completion_word} = [];
                        return ();
                    }
                    
                    $cmd = $cmd->{$part};
                }
                $self->{rl}->Attribs->{completion_word} = [keys %{$cmd}];
            }
        }
        else {
            $self->{rl}->Attribs->{completion_word} = [keys %{$self->{cli}}];
        }
        $self->{no_completion} = 0;
        return ();
    };

    if (defined (my $appender = Log::Log4perl->appender_by_name('LimCLI'))) {
        Log::Log4perl->eradicate_appender('Screen');
        $appender->{cli} = $self;
    }
    
    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $real_self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
    delete $self->{current};
    delete $self->{rl};
    delete $self->{cli};
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
    
    $self->{rl}->print(@_);
}

=head2 function1

=cut

sub println {
    my $self = shift;
    
    $self->{rl}->hide;
    $self->{rl}->print(@_, "\n");
    $self->{rl}->show;
}

=head2 function1

=cut

sub Successful {
    $_[0]->{busy} = 0;
}

=head2 function1

=cut

sub Error {
    my $self = shift;
    
    $self->print('Command Error: ', ( scalar @_ > 0 ? '' : 'unknown' ));
    foreach (@_) {
        if (blessed $_ and $_->isa('Lim::Error')) {
            $self->print($_->toString);
        }
        else {
            $self->print($_);
        }
    }
    $self->println;
    
    $self->{busy} = 0;
}

=head2 function1

=cut

sub Editor {
    my ($self, $content) = @_;
    my $tmp = File::Temp->new;
    my $sha = Digest::SHA::sha1_base64($content);
    
    Lim::DEBUG and $self->{logger}->debug('Editing ', $tmp->filename, ', hash before ', $sha);
    
    print $tmp $content;
    $tmp->flush;

    # TODO check EDITOR
    
    if (system($ENV{EDITOR}, $tmp->filename)) {
        Lim::DEBUG and $self->{logger}->debug('EDITOR returned failure');
        return;
    }

    my $fh = IO::File->new;
    unless ($fh->open($tmp->filename)) {
        Lim::DEBUG and $self->{logger}->debug('Unable to reopen temp file');
        return;
    }
        
    $fh->seek(0, SEEK_END);
    my $tell = $fh->tell;
    $fh->seek(0, SEEK_SET);
    unless ($fh->read($content, $tell) == $tell) {
        Lim::DEBUG and $self->{logger}->debug('Unable to read temp file');
        return;
    }
    
    if ($sha eq Digest::SHA::sha1_base64($content)) {
        Lim::DEBUG and $self->{logger}->debug('No change detected, checksum is the same');
        return;
    }
    
    return $content;
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
