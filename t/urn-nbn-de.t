#!perl -Tw

use strict;

use Test::More tests => 3;

use SeeAlso::Identifier::NBNDE qw(calc_check_digit);

#my $urn = SeeAlso::Identifier::NBNDE->new();

#ok ( defined calc_check_digit("urn:nbn:de:") );
ok ( calc_check_digit("urn:nbn:de:0123-456789abcdefghijklmnopqrstuvwxyz") == 2 );
ok ( calc_check_digit("urn:nbn:de:0001-0001") == 6 );
ok ( calc_check_digit("urn:nbn:de:gbv:089-332175294") == 5 );
