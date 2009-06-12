#!perl -Tw

use strict;

use Test::More tests => 18;
use SeeAlso::Source;
use SeeAlso::Identifier;

use Data::Dumper;

my ($source, $response);

$source = SeeAlso::Source->new();
ok ( ! %{ $source->description() }, "no description" );
ok ( ! defined $source->description("ShortName") , "no description (2)" );

$source->description("ShortName","Foo");
ok ( $source->description("ShortName") eq "Foo", "set description" );
ok ( ! defined $source->description("XXX") , "not a description value" );
$source->description("LongName","Foobar");
ok ( $source->description("LongName") eq "Foobar", "set description (2)" );
$source->description("ShortName","doz");
ok ( $source->description("ShortName") eq "doz", "set description (3)" );

$source = SeeAlso::Source->new();
$source->description( "ShortName" => "X", "LongName" => "Y" );
ok ( $source->description("ShortName") eq "X" &&
     $source->description("LongName") eq "Y", "set description (4)" );
my $about = [ $source->about() ];
is_deeply( $about, ["X","",""], "about (1)" );

$source = SeeAlso::Source->new( "BaseURL" => "http://example.com", Description => "Hello" );
$about = [ $source->about() ];
is_deeply( $about, ["","Hello","http://example.com"], "about (2)" );

$source = SeeAlso::Source->new(
    sub {
        my $id = shift;
        my $r = SeeAlso::Response->new( $id->normalized );
        $r->add("test") if $id->value eq "xxx" or $id->value eq "";
        return $r;
    }
);

$response = $source->query( SeeAlso::Identifier->new("xxx") );
is( $response->size(), 1, "query method with identifier (1)" );
$response = $source->query( SeeAlso::Identifier->new("yyy") );
is( $response->size(), 0, "query method with identifier (2)" );
$response = $source->query( SeeAlso::Identifier->new() );
is( $response->size(), 1, "query method with empty identifier" );
$response = $source->query( "xxx" );
is( $response->size(), 1, "query method with string as identifier" );

$source = SeeAlso::Source->new( sub { shift }, ("ShortName" => "Test") );
is( $source->description("ShortName"), "Test", "ShortName");

$source = SeeAlso::Source->new( sub { shift }, ("LongName" => "Test source", "ShortName" => "Test") );
is( $source->description("ShortName"), "Test", "ShortName");
is( $source->description("LongName"), "Test source", "LongName");

my $descr = $source->description();
is( $descr->{ShortName}, "Test", "ShortName (2)");
is( $descr->{LongName}, "Test source", "LongName (2)");


