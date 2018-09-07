use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'GatlingReport',
    AUTHOR           => q{Marco Masetti <marco.masetti@sky.uk>},
    VERSION_FROM     => 'lib/GatlingReport.pm',
    ABSTRACT_FROM    => 'lib/GatlingReport.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'JSON::Syck'        => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'GatlingReport-*' },
);
