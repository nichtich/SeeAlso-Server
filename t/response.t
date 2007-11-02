#!perl -Tw

use strict;

use Test::More tests => 7;

use SeeAlso::Response;

my $r = SeeAlso::Response->new();
ok( $r->toJSON() eq '["",[],[],[]]', 'empty response');

ok ( !$r->size, 'test empty' );

ok( $r->toJSON('call-me') eq 'call-me(["",[],[],[]]);', 'callback');

$r = SeeAlso::Response->new("123");
ok( $r->toJSON() eq '["123",[],[],[]]', 'empty response with query');

$r->add("foo","baz","bar");
ok( $r->toJSON() eq '["123",["foo"],["baz"],["bar"]]', 'simple response');

$r->add("faz");
ok( $r->toJSON() eq '["123",["foo","faz"],["baz",""],["bar",""]]', 'simple response');

ok ( $r->size == 2, 'test size' );

