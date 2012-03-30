package Lim::Plugin::SoftHSM;

use common::sense;
use Carp;

use Log::Log4perl ();
use Fcntl qw(:seek);

use Lim::Manager ();
use Lim::Manage::Config ();
use Lim::Manage::Program ();

use base qw(Lim::Plugin);

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

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
    
    foreach my $config (keys %ConfigFiles) {
        foreach my $file (@{$ConfigFiles{$config}}) {
            my $real_file;
            
            if (defined ($real_file = $self->FileWritable($file))) {
                Lim::Manager->instance->Manage(
                    Lim::Manage::Config->new(
                        name => $config,
                        file => $real_file,
                        plugin => 'Lim::Plugin::SoftHSM',
                        action => [
                            Lim::Manage::Config::VIEW,
                            Lim::Manage::Config::EDIT
                        ]
                    ));
            }
            elsif (defined ($real_file = $self->FileReadable($file))) {
                Lim::Manager->instance->Manage(
                    Lim::Manage::Config->new(
                        name => $config,
                        file => $real_file,
                        plugin => 'Lim::Plugin::SoftHSM',
                        action => Lim::Manage::Config::VIEW
                    ));
            }
        }
    }
}

=head2 function1

=cut

sub Manage {
    my ($self, $manage, $action) = @_;
    
    if ($manage->isa('Lim::Manage::Config')) {
        if ($action == Lim::Manage::Config::VIEW) {
            unless (open(CONFIG, $manage->file)) {
                return;
            }
            
            my ($tell, $config);
            seek(CONFIG, 0, SEEK_END);
            $tell = tell(CONFIG);
            seek(CONFIG, 0, SEEK_SET);
            unless (read(CONFIG, $config, $tell) == $tell) {
                close(CONFIG);
                return;
            }
            close(CONFIG);
            
            return $config;
        }
    }
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

1; # End of Lim::Plugin::SoftHSM
