#!perl -Tw

use strict;

use Test::More qw(no_plan);
use SeeAlso::Source;
use SeeAlso::Identifier;

use Data::Dumper;

my ($source, $response);

$source = SeeAlso::Source->new();
ok( ! %{ $source->description() }, "no description" );
ok( ! defined $source->description("ShortName") , "no description (2)" );

$source->description("ShortName","Foo");
is( $source->description("ShortName") , "Foo", "set description" );
ok( ! defined $source->description("XXX") , "not a description value" );
$source->description("LongName","Foobar");
is( $source->description("LongName"), "Foobar", "set description (2)" );
$source->description("ShortName","doz");
is( $source->description("ShortName"), "doz", "set description (3)" );

$source = SeeAlso::Source->new;
$source->description( "ShortName" => "X", "LongName" => "Y" );
is( $source->description("ShortName"), "X", "set description (4)" );
is( $source->description("LongName"), "Y", "set description (5)" );

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

### Caching
my $cache = eval { use Cache::Memory; Cache::Memory->new; };
if ($cache) {
    my $value = 1;
    my $query_method = sub {
        my $id = shift;
        my $r = SeeAlso::Response->new( $id );
        $r->add( $value );
        $value++;
        return $r;
    };
    $source = new SeeAlso::Source( $query_method, cache => $cache );
    is( $source->query('0'), '["0",["1"],[""],[""]]', 'cache (1)' );
    is( $source->query('0'), '["0",["1"],[""],[""]]', 'cache (2)' );
    is( $source->query('0', force => 1 ), '["0",["2"],[""],[""]]', 'cache (3)' );
    is( $source->query('0'), '["0",["2"],[""],[""]]', 'cache (4)' );
    $cache->clear;
    is( $source->query('0'), '["0",["3"],[""],[""]]', 'cache (5)' );
} else {
    diag('Test of caching skipped, please install Cache::Memory!');
}
