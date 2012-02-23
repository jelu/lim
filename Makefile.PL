use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lim',
    AUTHOR              => q{Jerry Lundström <lundstrom.jerry@gmail.com>},
    VERSION_FROM        => 'lib/Lim.pm',
    ABSTRACT_FROM       => 'lib/Lim.pm',
#    EXE_FILES           => [ 'bin/' ],
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PREREQ_PM => {
        'Test::More' => 0,
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
