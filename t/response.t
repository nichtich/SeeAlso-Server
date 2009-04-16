#!perl -Tw

use strict;

use Test::More tests => 22;

use SeeAlso::Response;

my $r = SeeAlso::Response->new();
is( $r->toJSON(), '["",[],[],[]]', 'empty response');
is( $r->size(), 0, 'test empty' );
is( $r->toJSON('callme'), 'callme(["",[],[],[]]);', 'callback');
is( $r->query(), "", 'empty query' );

$r = SeeAlso::Response->new("123");
is( $r->toJSON(), '["123",[],[],[]]', 'empty response with query');
is( $r->query(), "123", 'query' );

$r->add("foo","baz","uri:bar");
my $json = '["123",["foo"],["baz"],["uri:bar"]]';
is( $r->toJSON(), $json, 'simple response');

$r->add("faz");
ok( $r->toJSON() eq '["123",["foo","faz"],["baz",""],["uri:bar",""]]', 'simple response');
is( $r->size, 2, 'test size' );

$r = $r->new("123");
is( $r->toJSON(), '["123",[],[],[]]', '$obj->new');

$r->add("x","",""); # empty description and URI
is( $r->toJSON(), '["123",["x"],[""],[""]]', '$obj->add');

$r = SeeAlso::Response->fromJSON($json);
is( $r->toJSON(), $json, 'fromJSON');

$r = SeeAlso::Response->new("a",["b"],["c"],["uri:doz"]);
is( $r->size, 1, 'new with size 1' );

$r->fromJSON($json); # call as method
is( $r->toJSON(), $json, 'fromJSON');

$r->set("xyz");
is( $r->size, 1, 'set with only setting the query' );
is( $r->query(), "xyz", 'set with only setting the query' );

$r = SeeAlso::Response->new("a",["b"],["c"],["uri:doz"]);
is( $r->query("xyz"), "xyz", 'set with the query method' );

eval { $r->add("a","b","abc"); };
ok( $@, 'invalid URN detected' );

eval { $r->fromJSON("["); };
ok( $@, 'invalid JSON detected' );

eval { $r = SeeAlso::Response->new("a",["b"],["c","d"],["uri:doz"]); };
ok( $@, 'invalid array sizes detected' );

$r = SeeAlso::Response->new( ["foo"] );
ok( $r->query() =~ /ARRAY/, 'query made string' );

use SeeAlso::Identifier;
my $id = SeeAlso::Identifier->new( 'normalized' => sub { lc shift; } );
$id->value("Hallo");
$r = SeeAlso::Response->new( $id );
is( $r->toJSON(), '["hallo",[],[],[]]', 'SeeAlso::Identifier as parameter');

my $utf8 = "a\x{cc}\x{88}"; # small a umlaut

$r = SeeAlso::Response->new( "a" );
$r->add($utf8);

# TODO: Unicode::Normalize needed for utf8 testing
# print STDERR $r->toJSON() . "\n";
# is ( $r->toJSON, '["a",["a\x{cc}\x{88}"],[""],[""]]', "utf8" );
