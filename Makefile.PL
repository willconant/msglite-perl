use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Msglite',
    AUTHOR              => q{Will Conant <will.conant@gmail.com>},
    VERSION_FROM        => 'lib/Msglite.pm',
    ABSTRACT_FROM       => 'lib/Msglite.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Msglite-*' },
);
