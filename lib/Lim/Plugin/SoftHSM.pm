package Lim::Plugin::SoftHSM;

use common::sense;
use Carp;

use Log::Log4perl ();
use Fcntl qw(:seek);

use base qw(Lim::Component);

=head1 NAME

...

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS


=head2 function1

=cut

sub Module {
    'SoftHSM';
}

=head2 function1

=cut

sub Calls {
    {
        ReadConfigs => {
            out => {
                file => {
                    name => 'string',
                    write => 'integer',
                    read => 'integer'
                }
            }
        },
        CreateConfig => {
            in => {
                file => {
                    name => 'string',
                    content => 'string'
                }
            }
        },
        ReadConfig => {
            in => {
                file => {
                    name => 'string'
                }
            },
            out => {
                file => {
                    name => 'string',
                    content => 'string'
                }
            }
        },
        UpdateConfig => {
            in => {
                file => {
                    name => 'string',
                    content => 'string'
                }
            }
        },
        DeleteConfig => {
            in => {
                file => {
                    name => 'string'
                }
            }
        },
        ReadShowSlots => {
            out => {
                slot => {
                    slot => 'integer',
                    label => 'string',
                    token_present => 'bool',
                    token_initialized => 'bool',
                    user_pin_initialized => 'bool',
                }
            }
        },
        CreateInitToken => {
            in => {
                slot => {
                    slot => 'integer',
                    label => 'string',
                    so_pin => 'integer',
                    pin => 'integer'
                }
            }
        },
        CreateImport => {
            in => {
                key_pair => {
                    file_pin => 'integer',
                    slot => 'integer',
                    pin => 'integer',
                    label => 'string',
                    id => 'string'
                }
            }
        },
        ReadExport => {
            in => {
                key_pair => {
                    file_pin => 'integer',
                    slot => 'integer',
                    pin => 'integer',
                    id => 'string'
                }
            },
            out => {
                key_pair => {
                }
            }
        },
        UpdateOptimize => {
            in => {
                slot => {
                    slot => 'integer',
                    pin => 'integer'
                }
            }
        },
        UpdateTrusted => {
            in => {
                key_pair => {
                    trusted => 'bool',
                    slot => 'integer',
                    so_pin => 'integer',
                    type => 'string',
                    label => 'string',
                    id => 'string'
                }
            }
        }
    };
}

=head2 function1

=cut

sub Commands {
    {
        configs => 1,
        config => {
            view => 1,
            edit => 1
        }
    };
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
