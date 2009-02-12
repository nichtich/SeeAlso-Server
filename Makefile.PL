use 5.8.2;
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
        'JSON::XS' => '2.0',
        'CGI' => '3.0',
        'Carp' => '1.01',
	'URI' => '1.35',
        'DBI' => '1.54',
        'Date::Parse' => '2.27',
        'Business::ISBN' => '2.02',
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
