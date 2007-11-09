#!perl -Tw

use strict;

use Test::More tests => 1;
use SeeAlso::DBISource;
use SeeAlso::Identifier;

my $source;


$source = SeeAlso::DBISource->new("DBI:mysql:database=foo","","","");

ok( ref($source) eq "SeeAlso::DBISource", "constructor" );