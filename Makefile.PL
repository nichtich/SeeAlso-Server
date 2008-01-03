use 5.005;
use strict;
use ExtUtils::MakeMaker;

&WriteMakefile(
    NAME            => 'SeeAlso::Server',
    DISTNAME        => 'SeeAlso-Server',
    VERSION_FROM    => 'lib/SeeAlso/Server.pm',
    ABSTRACT_FROM   => 'lib/SeeAlso/Server.pm',
    PMLIBDIRS       => [ qw( lib/ ) ],
    AUTHOR          => 'Jakob Voss <jakob.voss@gbv.de>',
    PREREQ_PM       => {
        'JSON' => '2.0',
        'CGI' => 0,
        'Carp' => 0,
        'DBI' => 0,
        'Business::ISBN' => '2.02'
    },
    dist            => {
        COMPRESS => 'gzip -9f',
        SUFFIX => 'gz',
    },
    depend          => {
        Makefile => '$(VERSION_FROM)'
    },
#    clean           => { FILES => 'xyz-*' },
);
