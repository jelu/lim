#!/usr/bin/env perl

use common::sense;
use Getopt::Long ();
use Pod::Usage ();
use Log::Log4perl ();
use Log::Log4perl::Appender::Lim::CLI ();

use Lim ();
use Lim::Plugins ();
use Lim::RPC::Value ();
use Lim::RPC::Value::Collection ();

my $help = 0;
my $conf;
my $log4perl;
my $module;

Getopt::Long::GetOptions(
    'help|?' => \$help,
    'conf:s' => \$conf,
    'log4perl:s' => \$log4perl
) or Pod::Usage::pod2usage(2);
Pod::Usage::pod2usage(1) if $help;

unless (@ARGV >= 1) {
    Pod::Usage::pod2usage(1);
}

if (defined $conf) {
    unless (-r $conf and Lim::LoadConfig($conf)) {
        print STDERR 'Unable to read configuration file: ', $conf, "\n";
        exit(1);
    }
    Lim::Config->{cli}->{config_file} = $conf;
}
else {
    Lim::LoadConfig(Lim::Config->{cli}->{config_file});
}

if (defined $log4perl and -f $log4perl) {
    Log::Log4perl->init($log4perl);
}
else {
    Log::Log4perl->init( \q(
    log4perl.logger                   = DEBUG, Screen, LimCLI
    log4perl.appender.Screen          = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr   = 1
    log4perl.appender.Screen.layout   = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Screen.layout.ConversionPattern = %d %F [%L] %p: %m%n
    
    log4perl.appender.LimCLI          = Log::Log4perl::Appender::Lim::CLI
    log4perl.appender.LimCLI.stderr   = 1
    log4perl.appender.LimCLI.layout   = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.LimCLI.layout.ConversionPattern = %d %F [%L] %p: %m%n
    ) );
}

foreach (Lim::Plugins->instance->LoadedModules) {
    if ($ARGV[0] eq $_) {
        $module = $ARGV[0];
        last;
    }
}
unless (defined $module) {
    exit -1;
}

my %crud = (
    Create => 1,
    Read => 2,
    Update => 3,
    Delete => 4
);

my %sort_calls;
my %sort_cmds;
my $inc = $module;
$inc =~ s/::/\//go;
$inc .= '.pm';
if (-f $INC{$inc}) {
    if (open(PM, $INC{$inc})) {
        while (<PM>) {
            if (/^\s*sub Calls/o) {
                my $sort = 0;
                while (<PM>) {
                    s/[\r\n]+//go;
                    if (/((?:Create|Read|Update|Delete)\S+)\s+=>/o) {
                        $sort_calls{$1} = $sort++;
                    }
                    elsif (/};/o) {
                        last;
                    }
                }
            }
            elsif (/^\s*sub Commands/o) {
                my $sort = 0;
                my @sort;
                while (<PM>) {
                    s/[\r\n]+//go;
                    if (/^\s*(\S+)\s+=>/o) {
                        my $this = $1;
                        $sort_cmds{join(' ', @sort, $this)} = $sort++;
                        if (/{/o) {
                            push(@sort, $this);
                        }
                    }
                    elsif (/};/o) {
                        last;
                    }
                    elsif (/}/o) {
                        pop(@sort);
                    }
                }
            }
        }
        close(PM);
    }
}

my $calls = $module->Calls;
foreach my $call (sort {
    if (exists $sort_calls{$a} and exists $sort_calls{$b}) {
        $sort_calls{$a} <=> $sort_calls{$b};
    }
    else {
        if ($a =~ /^(Create|Read|Update|Delete)(.+)/o) {
            my ($ac,$an) = ($1,$2);
            if ($b =~ /^(Create|Read|Update|Delete)(.+)/o) {
                my ($bc,$bn) = ($1,$2);
                
                if ($an eq $bn) {
                    $crud{$ac} <=> $crud{$bc};
                }
                else {
                    $an cmp $bn;
                }
            }
            else {
                die;
            }
        }
        else {
            die;
        }
    }
} keys %$calls) {
    my ($in, $out) = (undef, undef);
    
    if (exists $calls->{$call}->{in}) {
        $in = $calls->{$call}->{in};
    }
    if (exists $calls->{$call}->{out}) {
        $out = $calls->{$call}->{out};
    }
    
    print '=item $client->', $call, '(', (defined $in ? '$input, ' : ''), 'sub { my ($call) = @_; })', "\n\n...\n\n";
    
    if (defined $in) {
        print '  $input = {', "\n";
        print_schema($in, 4, 0);
        print '  };', "\n\n";
    }

    if (defined $out) {
        print '  $response = {', "\n";
        print_schema($out, 4, 1);
        print '  };', "\n\n";
    }
}

print "\n\n\n";

my $cmds = $module->Commands;
my @pre;
print_command($cmds, \@pre);

sub print_command {
    my ($cmds, $pre) = @_;
    
    foreach (sort {
        my $as = join(' ', @$pre, $a);
        my $bs = join(' ', @$pre, $b);
        
        if (exists $sort_cmds{$as} and exists $sort_cmds{$bs}) {
            $sort_cmds{$as} <=> $sort_cmds{$bs};
        }
        else {
            $a cmp $b;
        }
    } (keys %$cmds)) {
        if (ref($cmds->{$_}) eq 'HASH') {
            push(@$pre, $_);
            print_command($cmds->{$_}, $pre);
            pop(@$pre);
        }
        else {
            print '=item ', join(' ', @$pre, $_);
            
            if (ref($cmds->{$_}) eq 'ARRAY') {
                if (@{$cmds->{$_}} == 1) {
                    print "\n\n", $cmds->{$_}->[0], '.';
                }
                elsif (@{$cmds->{$_}} == 2) {
                    print ' ', $cmds->{$_}->[0], "\n\n", $cmds->{$_}->[1], '.';
                }
                else {
                    die;
                }
            }
            
            print "\n\n";
        }
    }
}

sub print_schema {
    my ($schema, $indent, $out) = @_;
    my $spaces = ' ' x $indent;
    my $comma = 0;
    my $length;
    my $comment;
    my $longest = 0;
    
    foreach (sort (keys %$schema)) {
        if ($_ eq '') {
            next;
        }
        if (ref($schema->{$_}) eq 'HASH') {
            next;
        }

        my $value = Lim::RPC::Value->new($schema->{$_});
        my $string = $_.' => '.$value->type;
        
        if (length($string) > $longest) {
            $longest = length($string);
        }
    }

    foreach (sort (keys %$schema)) {
        if ($_ eq '') {
            next;
        }
        if (ref($schema->{$_}) eq 'HASH') {
            next;
        }
        if ($comma) {
            print ',', (' ' x ($longest - $length)), (defined $comment ? ' # '.$comment : ''), "\n";
            $comment = undef;
        }

        my $value = Lim::RPC::Value->new($schema->{$_});
        my $string = $_.' => '.$value->type;
        $length = length($string);
        print $spaces, $string;
        $comment = '...'.($value->required ? '' : ' (optional)');
        $comma = 1;
    }

    foreach (sort (keys %$schema)) {
        if ($_ eq '') {
            next;
        }
        if (ref($schema->{$_}) ne 'HASH') {
            next;
        }
        if ($comma) {
            if (defined $length) {
                print ',', (' ' x ($longest - $length)), (defined $comment ? ' # '.$comment : ''), "\n";
                undef($length);
            }
            else {
                print ',', (defined $comment ? ' # '.$comment : ''), "\n";
            }
            $comment = undef;
        }

        my $value;
        if (exists $schema->{$_}->{''}) {
            $value = Lim::RPC::Value::Collection->new($schema->{$_}->{''});
        }
        print $spaces, $_, ' => # ', ((defined $value and $value->required) ? '' : (!$out ? '(optional) ' : '')), 'Single hash or an array of hashes as below:', "\n", $spaces, '{', "\n";
        print_schema($schema->{$_}, $indent+2, $out);
        print $spaces, '}';
        $comma = 1;
    }

    if ($comma and defined $comment) {
        if (defined $length) {
            print ',', (' ' x ($longest - $length)), (defined $comment ? ' # '.$comment : ''), "\n";
        }
        else {
            print ',', (defined $comment ? ' # '.$comment : ''), "\n";
        }
    }
    else {
        print "\n";
    }
}

__END__

=head1 NAME

generate_plugin_pod.pl - Tool to generate plugin pod documentation

=head1 SYNOPSIS

generate_plugin_pod.pl [options] <Lim::Plugin::Name to generate pod for>

=head1 OPTIONS

=over 8

=item B<--conf <file>>

Specify the configure file to use (default ~/.limrc).

=item B<--log4perl <file>>

Specify a Log::Log4perl configure file (default output to cli or stderr).

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

...

=cut
