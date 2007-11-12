#!perl -Tw

use strict;

use Test::More tests => 1;
use SeeAlso::Source::DBI;
use SeeAlso::Identifier;

my $source;


$source = SeeAlso::Source::DBI->new("DBI:mysql:database=foo","","","");

ok( ref($source) eq "SeeAlso::Source::DBI", "constructor" );

# TODO: create a SQLite database and access it for testing
