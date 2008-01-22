#!perl -Tw

use strict;

use Test::More tests => 1;
use SeeAlso::Source::ThingISBN;

my $source = SeeAlso::Source::ThingISBN->new();
ok( ref($source) eq "SeeAlso::Source::ThingISBN", "constructor" );

# TODO: do real tests