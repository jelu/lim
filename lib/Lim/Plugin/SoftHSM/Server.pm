package Lim::Plugin::SoftHSM::Server;

use common::sense;

use Fcntl qw(:seek);

use Lim::Plugin::SoftHSM ();

use Lim::Util ();

use base qw(Lim::Component::Server);

=head1 NAME

...

=head1 VERSION

Version 0.1

=cut

our $VERSION = $Lim::Plugin::SoftHSM::VERSION;
our %ConfigFiles = (
    'softhsm.conf' => [
        '/etc/softhsm/softhsm.conf',
        '/etc/softhsm.conf',
        'softhsm.conf'
    ]
);

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub Init {
    my $self = shift;
    my %args = ( @_ );
    
    $self->{config} = {};
}

=head2 function1

=cut

sub Destroy {
}

=head2 function1

=cut

sub _ScanConfig {
    my ($self) = @_;
    my %file;
    
    foreach my $config (keys %ConfigFiles) {
        foreach my $file (@{$ConfigFiles{$config}}) {
            if (defined ($file = Lim::Util::FileWritable($file))) {
                if (exists $file{$file}) {
                    $file{$file}->{write} = 1;
                    next;
                }
                
                $file{$file} = {
                    name => $file,
                    write => 1,
                    read => 1
                };
            }
            elsif (defined ($file = Lim::Util::FileReadable($file))) {
                if (exists $file{$file}) {
                    next;
                }
                
                $file{$file} = {
                    name => $file,
                    write => 0,
                    read => 1
                };
            }
        }
    }
    
    return \%file;
}

=head2 function1

=cut

sub ReadConfigs {
    my ($self, $cb) = @_;
    my $files = $self->_ScanConfig;
    
    $self->Successful($cb, {
        file => [ values %$files ]
    });
}

=head2 function1

=cut

sub CreateConfig {
    my ($self, $cb) = @_;
}

=head2 function1

=cut

sub ReadConfig {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig;

    if (exists $files->{$q->{file}->{name}}) {
        my $file = $files->{$q->{file}->{name}};
        
        if ($file->{read} and open(CONFIG, $file->{name})) {
            my ($tell, $config);
            seek(CONFIG, 0, SEEK_END);
            $tell = tell(CONFIG);
            seek(CONFIG, 0, SEEK_SET);
            if (read(CONFIG, $config, $tell) == $tell) {
                close(CONFIG);
                $self->Successful($cb, {
                    file => {
                        name => $file->{name},
                        content => $config
                    }
                });
                return;
            }
            close(CONFIG);
        }
    }
    $self->Error($cb);
}

=head2 function1

=cut

sub UpdateConfig {
    my ($self, $cb) = @_;
}

=head2 function1

=cut

sub DeleteConfig {
    my ($self, $cb) = @_;
}

=head2 function1

=cut

sub ReadShowSlots {
    my ($self, $cb) = @_;
}

=head2 function1

=cut

sub CreateInitToken {
    my ($self, $cb) = @_;
}

=head2 function1

=cut

sub CreateImport {
    my ($self, $cb) = @_;
}

=head2 function1

=cut

sub ReadExport {
    my ($self, $cb) = @_;
}

=head2 function1

=cut

sub UpdateOptimize {
    my ($self, $cb) = @_;
}

=head2 function1

=cut

sub UpdateTrusted {
    my ($self, $cb) = @_;
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

1; # End of Lim::Plugin::SoftHSM::Server
