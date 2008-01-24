#!perl -Tw

use strict;

use Test::More tests => 3;
use lib "./lib";
use SeeAlso::Identifier::ISIL qw(sigel2isil);

my $isil = SeeAlso::Identifier::ISIL->new("DE-7");
ok ( $isil->valid , "simple ISIL" );

$isil->value(" ISIL DE-7 ");
ok ( $isil->valid , "spaces and 'ISIL' before ISIL" );

$isil = sigel2isil("Gö 116");
ok ( $isil->value eq "DE-Goe116" , "sigel2isil" );