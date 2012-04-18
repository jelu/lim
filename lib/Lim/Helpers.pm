package Lim::Helpers;

use common::sense;
use Carp;

use Log::Log4perl ();

use Lim ();
use base qw(Lim::RPC);

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
        html => '/usr/share/lim/html'
    };
    bless $self, $class;

    if (defined $args{html}) {
        $self->{html} = $args{html};
    }
    unless (-d $self->{html} and -r $self->{html} and -x $self->{html}) {
        confess __PACKAGE__, ': Path to html "', $self->{html}, '" is invalid';
    }
    unless (-d $self->{html}.'/js' and -r $self->{html}.'/js' and -x $self->{html}.'/js') {
        confess __PACKAGE__, ': Path to js files "', $self->{html}.'/js', '" is invalid';
    }

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
}

=head2 function1

=cut

sub Module {
    'Helpers';
}

=head2 function1

=cut

sub ReadIndex {
    my ($self, $cb) = Lim::RPC::C(@_, undef);
    my @js;

    if (opendir(DIR, $self->{html}.'/js')) {
        while (my $entry = readdir(DIR)) {
            if ($entry =~ /^jquery\.lim\.helper\.\S+\.js$/o and -r $self->{html}.'/js/'.$entry) {
                if (open(FILE, $self->{html}.'/js/'.$entry)) {
                    my ($read, $buffer, $content) = (0, '', '');
                    
                    while (($read = read(FILE, $buffer, 64*1024))) {
                        $content .= $buffer;
                    }
                    close(FILE);
                    
                    unless (defined $read) {
                        Lim::WARN and $self->{logger}->warn('Unable to read content of js file "', $self->{html}, '/js/', $entry, '": ', $!);
                    }
                    else {
                        if ($content =~ /\$\.widget\(\'lim\.limHelper([^\']+)/mo) {
                            my $name = $1;
                            
                            push(@js, {
                                widget => 'limHelper'.$name,
                                name => lc($name),
                                file => $entry,
                                code => $content
                            });
                        }
                    }
                }
                else {
                    Lim::WARN and $self->{logger}->warn('Unable to read content of js file "', $self->{html}, '/js/', $entry, '": ', $!);
                }
            }
        }
        closedir(DIR);
    }
    else {
        Lim::WARN and $self->{logger}->warn('Unable to opendir() "', $self->{html}, '/js": ', $!);
    }
    
    Lim::RPC::R($cb, {
        helper => \@js
    }, {
        'base.helper' => [ 'name', 'widget', 'file', 'code' ]
    });
}

=head2 function1

=cut

sub ReadHelper {
    my ($self, $cb, undef, $helper) = Lim::RPC::C(@_, undef);
    my @js;

    if (defined $helper) {
        $helper = lc($helper);
        
        if (opendir(DIR, $self->{html}.'/js')) {
            while (my $entry = readdir(DIR)) {
                if ($entry =~ /^jquery\.lim\.helper\.\S+\.js$/o and -r $self->{html}.'/js/'.$entry) {
                    if (open(FILE, $self->{html}.'/js/'.$entry)) {
                        my ($read, $buffer, $content) = (0, '', '');
                        
                        while (($read = read(FILE, $buffer, 64*1024))) {
                            $content .= $buffer;
                        }
                        close(FILE);
                        
                        unless (defined $read) {
                            Lim::WARN and $self->{logger}->warn('Unable to read content of js file "', $self->{html}, '/js/', $entry, '": ', $!);
                        }
                        else {
                            if ($content =~ /\$\.widget\(\'lim\.limHelper([^\']+)/mo) {
                                my $name = $1;
                                
                                if ($helper eq lc($name)) {
                                    push(@js, {
                                        widget => 'limHelper'.$name,
                                        name => lc($name),
                                        file => $entry,
                                        code => $content
                                    });
                                }
                            }
                        }
                    }
                    else {
                        Lim::WARN and $self->{logger}->warn('Unable to read content of js file "', $self->{html}, '/js/', $entry, '": ', $!);
                    }
                }
            }
            closedir(DIR);
        }
        else {
            Lim::WARN and $self->{logger}->warn('Unable to opendir() "', $self->{html}, '/js": ', $!);
        }
    }
    
    Lim::RPC::R($cb, {
        helper => \@js
    }, {
        'base.helper' => [ 'name', 'widget', 'file', 'code' ]
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

1; # End of Lim::Helpers
