package Lim::RPC::URIMaps;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(blessed weaken);

use Lim ();

=encoding utf8

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
    my $self = {
        logger => Log::Log4perl->get_logger,
        maps => []
    };
    bless $self, $class;
    
    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
}

=head2 function1

=cut

sub add {
    my ($self, $map) = @_;
    my (@regexps, @variables, $regexp, $n, $code);
    
    #
    # Validate and pull out parts of the map used to generate regexp and code
    #
    
    foreach my $map_part (split(/\//o, $map)) {
        if ($map_part =~ /^\w+$/o) {
            push(@regexps, $map_part);
        }
        elsif ($map_part =~ /^((?:\w+\.)+\w+)=(.+)$/o) {
            push(@variables, $1);
            push(@regexps, '('.$2.')');
        }
        else {
            Lim::DEBUG and $self->{logger}->debug('Validation of map "', $map, '" failed');
            $@ = 'Map is not valid';
            return;
        }
    }
    
    #
    # Validate the regexp made from the map by compiling it with qr
    #

    $regexp = '^'.join('\/', @regexps).'$';
    eval {
        my $dummy = qr/$regexp/;
    };
    if ($@) {
        Lim::DEBUG and $self->{logger}->debug('Regexp compilation of map "', $map, '" failed: ', $@);
        return;
    }
    
    #
    # Generate the code that checked given URI with generated regexp and adds
    # data gotten by the regexp to the data structure defined by the map
    #

    $code = 'my (';

    $n = 1;
    while ($n <= scalar @variables) {
        $code .= '$v'.$n++;
    }
    
    $code .= ')=(';

    $n = 1;
    while ($n <= scalar @variables) {
        $code .= '$'.$n++;
    }
    
    $code .= ');';

    $n = 1;
    foreach my $variable (@variables) {
        $code .= '$data->{'.join('}->{', split(/\./o, $variable)).'} = $v'.($n++).';';
    }

    #
    # Create the subroutine from the generated code
    #
    
    eval '$code = sub { my ($uri, $data)=@_; if($uri =~ /'.$regexp.'/o) { '.$code.' return 1;} return; };';
    if ($@) {
        Lim::DEBUG and $self->{logger}->debug('Code generation of map "', $map, '" failed: ', $@);
        return;
    }
    
    #
    # Store the generated subroutine and return success
    #

    push(@{$self->{maps}}, $code);
    return 1;
}

=head2 function1

=cut

sub process {
    my ($self, $uri, $data) = @_;
    
    unless (ref($data) eq 'HASH') {
        confess '$data parameter is not a hash';
    }
    
    foreach my $map (@{$self->{maps}}) {
        if ($map->($uri, $data)) {
            return 1;
        }
    }
    return;
}

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

Copyright 2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::RPC::URIMaps
