package Lim;

use common::sense;
use Carp;

use YAML::Any ();

=head1 NAME

Lim - Framework for RESTful JSON/XML, JSON-RPC, XML-RPC and SOAP

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';
our $CONFIG;

sub OBJ_DEBUG (){ 1 }
sub RPC_DEBUG (){ 1 }
sub DEBUG (){ 1 }
sub INFO (){ 1 }
sub WARN (){ 1 }
sub ERR (){ 1 }

sub SRV_LISTEN (){ 10 }

=head1 SYNOPSIS

=over 4

use Lim;

=back

=head1 DESCRIPTION

L<Lim> provides a framework for calling plugins over multiple protocols.

It uses AnyEvent for async operations and SOAP::Lite, XMLRPC::Lite and JSON::XS
for processing protocol messages.

There are 3 parts in Lim that can work independenly, a Server part, a Client
part and a CLI part.

All plugins are also divded into these 3 parts and use the base classes
L<Lim::Component::Server>, L<Lim::Component::Client> and L<Lim::Component::CLI>.

The built in Server part is called L<Lim::Agent> and can be started with
lim-agentd. It will use L<Lim::Plugins> to load all available plugins on
the system and serve their Server part to L<Lim::Server> if available.

The built in CLI part is called L<Lim::CLI> and can be started with lim-cli.
It will use L<Lim::Plugins> to load all available plugins on the system and
use their CLI part if available.

=head1 METHODS

=over 4

=item Lim::Config->{}

Return a hash reference to the configuration.

=cut

sub Config {
    $CONFIG ||= {
        prefix => ['', '/usr', '/usr/local'],
        rpc => {
            timeout => 30,
            call_timeout => 300
        },
        cli => {
            history_length => 1000,
            history_file => defined $ENV{HOME} ? $ENV{HOME}.($ENV{HOME} =~ /\/$/o ? '' : '/').'.lim_history' : '',
            config_file => defined $ENV{HOME} ? $ENV{HOME}.($ENV{HOME} =~ /\/$/o ? '' : '/').'.limrc' : '',
            editor => $ENV{EDITOR}
        }
    };
}

=item Lim::MergeConfig($config)

Try and merge the given hash reference C<$config> into Lim's configuration.

=cut

sub MergeConfig {
    if (ref($_[0]) eq 'HASH') {
        my @merge = ([$_[0], $CONFIG]);

        while (defined (my $merge = shift(@merge))) {
            my ($from, $to) = @$merge;
            foreach my $key (keys %$from) {
                if (exists $to->{$key}) {
                    unless (ref($from->{$key}) eq ref($to->{$key})) {
                        # TODO display what entry is missmatching
                        confess __PACKAGE__, 'Can not merge config, entries type missmatch';
                    }
                    if (ref($from->{$key}) eq 'HASH') {
                        push(@merge, [$from->{$key}, $to->{$key}]);
                        next;
                    }
                }
                $to->{$key} = $from->{$key};
            }
        }
    }
    return;
}

=item Lim::LoadConfig($filename)

Load the given configuration C<$filename> in YAML format and merge it into Lim's
configuration.

=cut

sub LoadConfig {
    my ($config) = @_;
    
    if (defined $config and -r $config) {
        my $yaml;
        
        eval {
            $yaml = YAML::Any::LoadFile($config);
        };
        if ($@) {
            confess __PACKAGE__, ': Unable to read configuration file ', $config, ': ', $@, "\n";
            exit(1);
        }
        Lim::MergeConfig($yaml);
        return 1;
    }
    return;
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim
