package Lim::Plugin::SoftHSM::CLI;

use common::sense;

use Getopt::Long ();
use Scalar::Util qw(weaken);

use Lim::Plugin::SoftHSM ();

use base qw(Lim::Component::CLI);

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::Plugin::SoftHSM::VERSION;

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub configs {
    my ($self) = @_;
    my $softhsm = Lim::Plugin::SoftHSM->Client;
    
    weaken($self);
    $softhsm->ReadConfigs(sub {
		my ($call, $response) = @_;
		
		if ($call->Successful) {
		    $self->cli->println('SoftHSM config files found:');
		    if (exists $response->{file}) {
		        unless (ref($response->{file}) eq 'ARRAY') {
		            $response->{file} = [ $response->{file} ];
		        }
		        foreach my $file (@{$response->{file}}) {
		            $self->cli->println($file->{name},
		              ' (readable: ', ($file->{read} ? 'yes' : 'no'),
		              ' writable: ', ($file->{read} ? 'yes' : 'no'),
		              ')'
		              );
		        }
		    }

			$self->Successful;
		}
		else {
			$self->Error($call->Error);
		}
		undef($softhsm);
    });
}

=head2 function1

=cut

sub config {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);
    
    unless ($getopt and scalar @$args) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'view') {
        if (defined $args->[1]) {
            my $softhsm = Lim::Plugin::SoftHSM->Client;
            weaken($self);
            $softhsm->ReadConfig({
                file => {
                    name => $args->[1]
                }
            }, sub {
                my ($call, $response) = @_;
                
                if ($call->Successful) {
                    $self->cli->println($response->{file}->{content});
                	$self->Successful;
                }
                else {
                	$self->Error($call->Error);
                }
                undef($softhsm);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'edit') {
        if (defined $args->[1]) {
            my $softhsm = Lim::Plugin::SoftHSM->Client;
            weaken($self);
            $softhsm->ReadConfig({
                file => {
                    name => $args->[1]
                }
            }, sub {
                my ($call, $response) = @_;
                
                if ($call->Successful) {
                    my $w; $w = AnyEvent->timer(
                        after => 0,
                        cb => sub {
                            if (defined (my $content = $self->cli->Editor($response->{file}->{content}))) {
                                my $softhsm = Lim::Plugin::SoftHSM->Client;
                                $softhsm->UpdateConfig({
                                    file => {
                                        name => $args->[1],
                                        content => $content
                                    }
                                }, sub {
                                    my ($call, $response) = @_;
                                    
                                    if ($call->Successful) {
                                        $self->cli->println('Config updated');
                                    	$self->Successful;
                                    }
                                    else {
                                    	$self->Error($call->Error);
                                    }
                                    undef($softhsm);
                                });
                            }
                            else {
                                $self->cli->println('Config not update, no change');
                            	$self->Successful;
                            }
                            undef($w);
                        });
                }
                else {
                	$self->Error($call->Error);
                }
                undef($softhsm);
            });
            return;
        }
    }
    $self->Error;
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

1; # End of Lim::Plugin::SoftHSM::CLI
