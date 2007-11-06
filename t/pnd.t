#!perl -Tw

use strict;

use Test::More tests => 3;

use SeeAlso::Identifier::PND;

my $pnd = SeeAlso::Identifier::PND->new();
ok( !$pnd->normalized() && !$pnd->indexed() && !$pnd->value() && !$pnd->valid(), "empty PND" );

$pnd = SeeAlso::Identifier::PND->new("118601121");
ok( $pnd->valid, "valid PND" );

$pnd = SeeAlso::Identifier::PND->new("118601123");
ok( !$pnd->valid, "invalid PND" );
