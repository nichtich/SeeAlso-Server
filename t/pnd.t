#!perl -Tw

use strict;

use Test::More; # tests => 3;

use SeeAlso::Identifier::GND;

my $gnd = SeeAlso::Identifier::GND->new();
ok( !$gnd->normalized() && !$gnd->indexed() &&
    !$gnd->value() && !$gnd->valid(), "empty GND" );

my @valid = ('95980479X','95980479-X','040303187',
    '95980479-1','04030318-4', # SWD/GKD
    '118601121'
);

foreach my $n (@valid) {
    $gnd->value( $n );
    ok( $gnd->valid, "GND '$n' tested as valid" );
}

my @invalid = ("118601123");

foreach my $n (@valid) {
    $gnd = SeeAlso::Identifier::GND->new($n);
    ok( !$gnd->valid, "invalid GND '$n'" );
}
