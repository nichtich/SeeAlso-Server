#!perl -Tw

use strict;

use Test::More tests => 7;

use SeeAlso::Identifier;

my $id = SeeAlso::Identifier->new();
ok( !$id->normalized() && !$id->indexed() && !$id->value() && !$id->valid(), "empty identifier" );

$id = SeeAlso::Identifier->new("0");
ok( $id->normalized() eq "0" && $id->indexed() eq "0" && $id->value() eq "0" && $id->valid(), "identifier = '0'" );

$id = SeeAlso::Identifier->new("xy");
ok( $id->normalized() eq "xy" && $id->indexed() eq "xy" && $id->value() eq "xy" && $id->valid(), "identifier = 'xy'" );

my $s = \*STDOUT;
$id = SeeAlso::Identifier->new($s);
ok( $id->normalized() == $s && $id->indexed() == $s && $id->value() == $s && $id->valid(), "non-string identifier" );

$id = SeeAlso::Identifier->new( 'valid' => sub { return 1; } );
ok( $id->value eq "" , "undefined value with handler" );

# lowercase alpha only
sub lcalpha {
   my $v = shift;
   $v =~ s/[^a-zA-Z]//g;
   return lc($v);
}
$id = SeeAlso::Identifier->new(
  'valid' => sub {
     my $v = shift;
     return $v =~ /^[a-zA-Z]+$/;
  },
  'normalized' => \&lcalpha
);
$id->value("AbC");

ok( $id->valid , "extension: valid");
ok( $id->normalized eq "abc" && $id->indexed eq "abc", "extension: normalized and indexed" );
