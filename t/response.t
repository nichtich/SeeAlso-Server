#!perl -Tw

use strict;

use Test::More tests => 9;

use SeeAlso::Response;

my $r = SeeAlso::Response->new();
ok( $r->toJSON() eq '["",[],[],[]]', 'empty response');

ok ( $r->size == 0, 'test empty' );

ok( $r->toJSON('callme') eq 'callme(["",[],[],[]]);', 'callback');

$r = SeeAlso::Response->new("123");
ok( $r->toJSON() eq '["123",[],[],[]]', 'empty response with query');

$r->add("foo","baz","uri:bar");
ok( $r->toJSON() eq '["123",["foo"],["baz"],["uri:bar"]]', 'simple response');

$r->add("faz");
ok( $r->toJSON() eq '["123",["foo","faz"],["baz",""],["uri:bar",""]]', 'simple response');

ok ( $r->size == 2, 'test size' );

eval { $r->add("a","b","abc"); };
ok ( $@, 'invalid URN detected' );

use SeeAlso::Identifier;
my $id = SeeAlso::Identifier->new( 'normalized' => sub { lc shift; } );
$id->value("Hallo");
$r = SeeAlso::Response->new( $id );
ok( $r->toJSON() eq '["hallo",[],[],[]]', 'SeeAlso::Identifier as parameter');

my $utf8 = "a\x{cc}\x{88}"; # small a umlaut

$r = SeeAlso::Response->new( "a" );
$r->add($utf8);

# TODO: Unicode::Normalize needed for utf8 testing
# print STDERR $r->toJSON() . "\n";
# is ( $r->toJSON, '["a",["a\x{cc}\x{88}"],[""],[""]]', "utf8" );
