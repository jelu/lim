package Lim::Util;

use common::sense;
use Carp;

use Log::Log4perl ();
use File::Temp ();

use AnyEvent ();
use AnyEvent::Util ();

use Lim ();

=head1 NAME

Lim::Util - Utilities for plugins

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;
our %CALL_METHOD = (
    Create => 'PUT',
    Read => 'GET',
    Update => 'POST',
    Delete => 'DELETE'
);

=head1 SYNOPSIS

=over 4

use Lim::Util;

=back

=head1 METHODS

=over 4

=item $full_path = Lim::Util::FileExists($file)

Check if C<$file> exists by prefixing L<Lim::Config>->{prefix} and returns the
full path to the file or undef if it does not exist.

=cut

sub FileExists {
    my ($file) = @_;
    
    if (defined $file) {
        $file =~ s/^\///o;
        foreach (@{Lim::Config->{prefix}}) {
            my $real_file = $_.'/'.$file;
            
            if (-f $real_file) {
                return $real_file;
            }
        }
    }
    return;
}

=item $full_path = Lim::Util::FileReadable($file)

Check if C<$file> exists by prefixing L<Lim::Config>->{prefix} and if it is
readable. Returns the full path to the file or undef if it does not exist.

=cut

sub FileReadable {
    my ($file) = @_;
    
    if (defined $file) {
        $file =~ s/^\///o;
        foreach (@{Lim::Config->{prefix}}) {
            my $real_file = $_.'/'.$file;
            
            if (-f $real_file and -r $real_file) {
                return $real_file;
            }
        }
    }
    return;
}

=item $full_path = Lim::Util::FileWritable($file)

Check if C<$file> exists by prefixing L<Lim::Config>->{prefix} and if it is
writable. Returns the full path to the file or undef if it does not exist.

=cut

sub FileWritable {
    my ($file) = @_;
    
    if (defined $file) {
        $file =~ s/^\///o;
        foreach (@{Lim::Config->{prefix}}) {
            my $real_file = $_.'/'.$file;
            
            if (-f $real_file and -w $real_file) {
                return $real_file;
            }
        }
    }
    return;
}

=item $temp_file = Lim::Util::TempFileLikeThis($file)

Creates a temporary file that will have the same owner and mode as the specified
C<$file>. Returns a L<File::Temp> object or undef if the specified file did not
exist or if there where problems creating the temporary file.

=cut

sub TempFileLikeThis {
    my ($file) = @_;
    
    if (defined $file and -f $file) {
        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
            $atime,$mtime,$ctime,$blksize,$blocks)
            = stat($file);
        
        if (defined (my $tmp = File::Temp->new)) {
            if (chmod($mode, $tmp->filename) and chown($uid, $gid, $tmp->filename)) {
                return $tmp;
            }
        }
    }
    return;
}

=item ($method, $uri) = Lim::Util::URIize($call)

Returns an URI based on the C<$call> given and the corresponding HTTP method to
be used.

Example:

=over 4

use Lim::Util;
($method, $uri) = Lim::Util::URIize('ReadVersion');
print "$method $ur\n";
($method, $uri) = Lim::Util::URIize('CreateOtherCall');
print "$method $ur\n";

=back

Produces:

=over 4

GET /version
PUT /other_call

=back

=cut

sub URIize {
    my @parts = split(/([A-Z][^A-Z]*)/o, $_[0]);
    my ($part, $method, $uri);
    
    while (scalar @parts) {
        $part = shift(@parts);
        if ($part ne '') {
            last;
        }
    }
    
    unless (exists $CALL_METHOD{$part}) {
        confess __PACKAGE__, ': No conversion found for ', $part, ' (', $_[0], ')';
    }
    
    $method = $CALL_METHOD{$part};
    
    @parts = grep !/^$/o, @parts;
    unless (scalar @parts) {
        confess __PACKAGE__, ': Could not build URI (', $_[0], ')';
    }
    $uri = lc(join('_', @parts));
    
    return ($method, '/'.$uri);
}

=item $camelized = Lim::Util::Camelize($underscore)

Convert underscored text to camelized, used for translating URI to calls.

Example:

=over 4

use Lim::Util;
print Lim::Util::Camelize('long_u_r_i_call_name'), "\n";

=back

Produces:

=over 4

LongURICallName

=back

=cut

sub Camelize {
    my ($underscore) = @_;
    my $camelized;
    
    foreach (split(/_/o, $underscore)) {
        $camelized .= ucfirst($_);
    }
    
    return $camelized;
}

=head2 [$cv =] Lim::Util::run_cmd $cmd, key => value...

This function extends L<AnyEvent::Util::run_cmd> with a timeout and will also
set C<close_all> option.

=over 4

=item timeout => $seconds

Creates a timeout for the running command and will try and kill it after the
specified C<$seconds>, see below how you can change the kill functionallity.

Using C<timeout> will set C<$$> option to L<AnyEvent::Util::run_cmd> so you
won't be able to use that option.

=item cb => $callback->($cv)

This is required if you'r using C<timeout>.

Call the given C<$callback> when the command finish or have timed out with the
condition variable returned by L<AnyEvent::Util::run_cmd>. If the command timed
out the condition variable will be set as if the command failed.

=item kill_sig => 15

Signal to use when trying to kill the command.

=item kill_try => 3

Number of times to try and kill the command with C<kill_sig>.

=item interval => 1

Number of seconds to wait between each attempt to kill the command.

=item kill_kill => 1

If true (default) kill the command with signal KILL after trying to kill it with
C<kill_sig> for the specified number of C<kill_try> attempts.

=back

=cut

sub run_cmd {
    my $cmd = shift;
    my %args = (
        kill_try => 3,
        kill_kill => 1,
        kill_sig => 15,
        interval => 1,
        @_
    );
    my ($pid, $timeout) = (0, undef);

    my %pass_args = %args;
    foreach (qw(kill_try kill_kill timeout interval cb)) {
        delete $pass_args{$_};
    }
    $pass_args{close_all} = 1;
    
    if (exists $args{timeout}) {
        $pass_args{'$$'} = \$pid;

        unless (exists $args{cb} and ref($args{cb}) eq 'CODE') {
            confess __PACKAGE__, ': must have cb with timeout or invalid';
        }
        
        unless ($args{timeout} > 0) {
            confess __PACKAGE__, ': timeout invalid';
        }

        unless ($args{interval} > 0) {
            confess __PACKAGE__, ': interval invalid';
        }
        
        unless ($args{kill_try} >= 0) {
            confess __PACKAGE__, ': kill_try invalid';
        }
        
        $timeout = AnyEvent->timer(
            after => $args{timeout},
            interval => $args{interval},
            cb => sub {
                unless ($pid) {
                    undef($timeout);
                    return;
                }
                
                if ($args{kill_try}--) {
                    kill($args{kill_sig}, $pid);
                }
                else {
                    if ($args{kill_kill}) {
                        kill(9, $pid);
                    }
                    undef($timeout);
                }
            });

        Lim::DEBUG and Log::Log4perl->get_logger->debug('run_cmd [timeout ', $args{timeout},'] ', (ref($cmd) eq 'ARRAY' ? join(' ', @$cmd) : $cmd));

        my $cv = AnyEvent::Util::run_cmd
            $cmd,
            %pass_args;
        $cv->cb(sub {
            undef($timeout);
            $args{cb}->(@_);
        });
        return;
    }
    
    Lim::DEBUG and Log::Log4perl->get_logger->debug('run_cmd ', (ref($cmd) eq 'ARRAY' ? join(' ', @$cmd) : $cmd));

    return AnyEvent::Util::run_cmd
        $cmd,
        %pass_args;
}

=back

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

1; # End of Lim::Util
