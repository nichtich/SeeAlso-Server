#!perl -Tw

use strict;

use Test::More qw(no_plan);

use SeeAlso::Response;

# serializing BEACON

my $r = SeeAlso::Response->new( "|x|" );
$r->add( "a||", "|b", "http://example.com|" );
is( $r->toBEACON(), "x|a|b|http://example.com" );

$r->add( "y", "z|", "foo:bar" );
is( $r->toBEACON(), "x|a|b|http://example.com\nx|y|z|foo:bar" );

$r = SeeAlso::Response->new( "x" );
$r->add( "a||", "", "http://example.com|" );
$r->add( "", "d", "foo:bar" );
$r->add( "", "", "http://example.com" );
is( $r->toBEACON(), join("\n",
  "x|a|http://example.com",
  "x||d|foo:bar",
  "x|http://example.com"
) );

$r = SeeAlso::Response->new( "x" );
$r->add( "", "", "" );
$r->add( "a", "b" ); # no URI
#$r->add( "", "", "http://example.com" );
is( $r->toBEACON(), join("\n", 
  "x|a|b",
 # "x||d|foo:bar",
 # "x|http://example.com"
) );


#is( $r->toBEACON(), "x||d|http://example.com" );