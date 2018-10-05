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
    EXE_FILES        => [ 
        'scripts/update-gatling-report.pl',
        'scripts/get-gatling-report-dir.pl',
        'scripts/get-gatling-report.pl'
    ],
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Moose'             => 0,
        'Template'          => 0,
        'String::CamelCase' => 0,
        'HTML::TreeBuilder' => 0,
        'File::Slurp'       => 0,
        'Log::Log4perl'     => 0,
        'DateTime'          => 0,
        'JSON'              => 0,
        'JSON::Syck'        => 0,
        'String::CamelCase' => 0,
        'Time::ParseDate'   => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'GatlingReport-*' },
);
