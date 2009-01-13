#!perl -Tw

use strict;

my @valid = ('95980479X','95980479-X','040303187',
    '95980479-1','04030318-4', # SWD/GKD
    '118601121','118578537','118562347',
);
my @invalid = ("118601123","123");
my @prefixes = ("est ","PND","GND ","gkd ","swd ","pnd","http://d-nb.info/gnd/");

my $sum = (@valid + @invalid + @prefixes + 1);

use Test::More qw(no_plan);;

use SeeAlso::Identifier::GND;

my $gnd = SeeAlso::Identifier::GND->new();
ok( !$gnd->normalized() && !$gnd->indexed() &&
    !$gnd->value() && !$gnd->valid(), "empty GND" );

foreach my $n (@valid) {
    $gnd->value( $n );
    ok( $gnd->valid, "GND '$n' tested as valid" );
}

foreach my $n (@invalid) {
    $gnd = SeeAlso::Identifier::GND->new($n);
    ok( !$gnd->valid, "GND '$n' tested as invalid" );
}

$gnd = SeeAlso::Identifier::GND->new("GND 118601121");

foreach my $p (@prefixes) {
    $gnd->value( $p . "118601121" );
    ok( $gnd->normalized eq "http://d-nb.info/gnd/118601121", "possible prefix '$p'");
}