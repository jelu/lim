use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lim',
    AUTHOR              => q{Jerry Lundström <lundstrom.jerry@gmail.com>},
    VERSION_FROM        => 'lib/Lim.pm',
    ABSTRACT_FROM       => 'lib/Lim.pm',
    EXE_FILES           => [ 'bin/lim-agentd', 'bin/lim-cli' ],
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PREREQ_PM => {
        'Test::More' => 0,
        'common::sense' => 3,
        'AnyEvent' => 5,
        'Digest::SHA' => 5,
        'File::Temp' => 0.2,
        'Getopt::Long' => 2,
        'HTTP::Request' => 5,
        'HTTP::Response' => 5,
        'HTTP::Status' => 5,
        'JSON::XS' => 2,
        'Log::Log4perl' => 1,
        'Log::Log4perl::Appender::Lim::CLI' => 0.12,
        'Module::Find' => 0,
        'Pod::Usage' => 1,
        'Scalar::Util' => 1,
        'SOAP::Lite' => 0.71,
        'SOAP::Transport::HTTP' => 0.71,
        'XMLRPC::Lite' => 0.71,
        'XMLRPC::Transport::HTTP::Server' => 0.12,
        'URI' => 1,
        'YAML::Any' => 0.71
    },
    META_MERGE => {
        recommends => {
            'AnyEvent::ReadLine::Gnu' => 1
        }
    },
    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
        (META_ADD => {
            resources => {
                homepage   => 'http://github.com/jelu/lim/wiki',
                repository => 'http://github.com/jelu/lim',
                bugtracker => 'http://github.com/jelu/lim/issues',
            },
        })
    ),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lim-*' },
);
