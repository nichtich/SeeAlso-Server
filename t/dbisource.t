#!perl -Tw

use strict;

use Test::More;
use SeeAlso::Source::DBI;
use SeeAlso::Identifier;

eval "use DBD::SQLite2";
plan skip_all => "DBD::SQLite2 required for testing SeeAlso::Source::DBI" if $@;

# tests => 1

ok (1);
# TODO: create a SQLite database and access it for testing
my $source;
my $dbfile;
# $source = SeeAlso::Source::DBI->new("DBI:SQLite2:dbname=$dbfile","","","");
# ok( ref($source) eq "SeeAlso::Source::DBI", "constructor" );





