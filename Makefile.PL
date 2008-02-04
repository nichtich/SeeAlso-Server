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
        'CGI' => '3.0',
        'Carp' => '1.01',
        'DBI' => '1.54',
        'Business::ISBN' => '2.02',
        'Date::Parse' => '2.27'
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
