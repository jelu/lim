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

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;
our @BUILTINS = (qw(quit help));

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
        no_completion => 0,
        prompt => 'lim> '
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
        my $name = lc($module->Module);
        
        if (exists $self->{cli}->{$name}) {
            $self->{logger}->warn('Can not load internal CLI module ', $module, ': name ', $name, ' already in use');
            next;
        }

        if (defined (my $obj = $module->CLI(cli => $self))) {
            $self->{cli}->{$name} = {
                name => $name,
                module => $module,
                obj => $obj
            };
        }
    }
    
    foreach my $module (Lim::Plugins->instance->LoadedModules) {
        my $name = lc($module->Module);
        
        if (exists $self->{cli}->{$name}) {
            $self->{logger}->warn('Can not use CLI module ', $module, ': name ', $name, ' already in use');
            next;
        }
        
        if (defined (my $obj = $module->CLI(cli => $self))) {
            $self->{cli}->{$name} = {
                name => $name,
                module => $module,
                obj => $obj
            };
        }
    }
    
    eval {
        require AnyEvent::ReadLine::Gnu;
    };
    unless ($@) {
        $self->{rl} = AnyEvent::ReadLine::Gnu->new(
            prompt => 'lim> ',
            on_line => sub {
                $self->process(@_);
            });
    
        $self->{rl}->Attribs->{completion_entry_function} = $self->{rl}->Attribs->{list_completion_function};
        $self->{rl}->Attribs->{attempted_completion_function} = sub {
            my ($text, $line, $start, $end) = @_;
            my @parts = split(/\s+/o, substr($line, 0, $start));
            my $builtins = 0;
            
            if ($self->{current}) {
                unshift(@parts, $self->{current}->{name});
                $builtins = 1;
            }
            
            if (scalar @parts) {
                my $part = shift(@parts);
    
                if (exists $self->{cli}->{$part}) {
                    my $cmd = $self->{cli}->{$part}->{module}->Commands;
                    
                    while (defined ($part = shift(@parts))) {
                        unless (exists $cmd->{$part} and ref($cmd->{$part}) eq 'HASH') {
                            if ($self->{no_completion}++ == 2) {
                                $self->println('no completion found');
                            }
                            $self->{rl}->Attribs->{completion_word} = [];
                            return ();
                        }
                        
                        $builtins = 0;
                        $cmd = $cmd->{$part};
                    }
                    if ($builtins) {
                        $self->{rl}->Attribs->{completion_word} = [keys %{$cmd}, @BUILTINS];
                    }
                    else {
                        $self->{rl}->Attribs->{completion_word} = [keys %{$cmd}];
                    }
                }
                else {
                    if ($self->{no_completion}++ == 2) {
                        $self->println('no completion found');
                    }
                    $self->{rl}->Attribs->{completion_word} = [];
                    return;
                }
            }
            else {
                $self->{rl}->Attribs->{completion_word} = [keys %{$self->{cli}}, @BUILTINS];
            }
            $self->{no_completion} = 0;
            return ();
        };

        $self->{rl}->StifleHistory(Lim::Config->{cli}->{history_length});
        if (Lim::Config->{cli}->{history_file} and -r Lim::Config->{cli}->{history_file}) {
            $self->{rl}->ReadHistory(Lim::Config->{cli}->{history_file});
        }
    }
    else {
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
                     shift;
                     $self->process(@_);
                 });
             });
    
        IO::Handle::autoflush STDOUT 1;
    }

    if (defined (my $appender = Log::Log4perl->appender_by_name('LimCLI'))) {
        Log::Log4perl->eradicate_appender('Screen');
        $appender->{cli} = $self;
    }
    
    $self->println('Welcome to LIM ', $Lim::VERSION, ' command line interface');
    $self->prompt;

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $real_self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
    
    if (exists $self->{rl}) {
        if (Lim::Config->{cli}->{history_file}) {
            $self->{rl}->WriteHistory(Lim::Config->{cli}->{history_file});
        }
    }
    
    delete $self->{current};
    delete $self->{rl};
    delete $self->{stdin_watcher};
    delete $self->{cli};
}

=head2 function1

=cut

sub process {
    my ($self, $line) = @_;
    
    if ($self->{busy}) {
        return;
    }

    my ($cmd, $args) = split(/\s+/o, $line, 2);
    $cmd = lc($cmd);
     
    if ($cmd eq 'quit' or $cmd eq 'exit') {
        if (exists $self->{current}) {
            delete $self->{current};
            $self->set_prompt('lim> ');
            $self->prompt;
        }
        else {
            $self->{on_quit}($self);
            return;
        }
    }
    elsif ($cmd eq 'help') {
        $self->prompt;
    }
    else {
        if ($cmd) {
            if (exists $self->{current}) {
                if ($self->{current}->{module}->Commands->{$cmd} and
                    $self->{current}->{obj}->can($cmd))
                {
                    $self->{busy} = 1;
                    $self->set_prompt('');
                    $self->{current}->{obj}->$cmd($args);
                }
                else {
                    $self->unknown_command($cmd);
                }
            }
            elsif (exists $self->{cli}->{$cmd}) {
                if ($args) {
                    my $current = $self->{cli}->{$cmd};
                    ($cmd, $args) = split(/\s+/o, $args, 2);
                    $cmd = lc($cmd);
                    
                    if ($current->{module}->Commands->{$cmd} and
                        $current->{obj}->can($cmd))
                    {
                        $self->{busy} = 1;
                        $self->set_prompt('');
                        $current->{obj}->$cmd($args);
                    }
                    else {
                        $self->unknown_command($cmd);
                    }
                }
                else {
                    $self->{current} = $self->{cli}->{$cmd};
                    $self->set_prompt('lim'.$self->{current}->{obj}->Prompt.'> ');
                    $self->prompt;
                }
            }
            else {
                $self->unknown_command($cmd);
            }
        }
        else {
            $self->prompt;
        }
    }
}

=head2 function1

=cut

sub prompt {
    my ($self) = @_;
    
    if (exists $self->{rl}) {
        return;
    }
    
    $self->print($self->{prompt});
}

=head2 function1

=cut

sub set_prompt {
    my ($self, $prompt) = @_;
    
    $self->{prompt} = $prompt;

    if (exists $self->{rl}) {
        $self->{rl}->hide;
        $AnyEvent::ReadLine::Gnu::prompt = $prompt;
        $self->{rl}->show;
    }
    
    $self;
}

=head2 function1

=cut

sub unknown_command {
    my ($self, $cmd) = @_;
    
    $self->println('unknown command: ', $cmd);
    $self->prompt;
    
    $self;
}

=head2 function1

=cut

sub print {
    my $self = shift;
    
    if (exists $self->{rl}) {
        $self->{rl}->print(@_);
    }
    else {
        print @_;
    }
    
    $self;
}

=head2 function1

=cut

sub println {
    my $self = shift;
    
    if (exists $self->{rl}) {
        $self->{rl}->hide;
        $self->{rl}->print(@_, "\n");
        $self->{rl}->show;
    }
    else {
        print @_, "\n";
    }

    $self;
}

=head2 function1

=cut

sub Successful {
    my ($self) = @_;
    
    $self->{busy} = 0;
    if (exists $self->{current}) {
        $self->set_prompt('lim'.$self->{current}->{obj}->Prompt.'> ');
    }
    else {
        $self->set_prompt('lim> ');
    }
    $self->prompt;
    return;
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
    if (exists $self->{current}) {
        $self->set_prompt('lim'.$self->{current}->{obj}->Prompt.'> ');
    }
    else {
        $self->set_prompt('lim> ');
    }
    $self->prompt;
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
