#!perl -Tw

use strict;

use Test::More tests => 12;
use SeeAlso::Source;
use SeeAlso::Identifier;

use Data::Dumper;

my $source = SeeAlso::Source->new();
ok ( ! $source->hasErrors(), "no errors" );
ok ( ! %{ $source->description() }, "no description" );
ok ( ! defined $source->description("ShortName") , "no description" );

$source->description("ShortName","Foo");
ok ( $source->description("ShortName") eq "Foo", "set description" );
$source->description("LongName","Foobar");
ok ( $source->description("LongName") eq "Foobar", "set description (2)" );
$source->description("ShortName","doz");
ok ( $source->description("ShortName") eq "doz", "set description (3)" );

$source = SeeAlso::Source->new( sub { return 99; } );
my $item = SeeAlso::Identifier->new();
ok( $source->query( $item ) == 99, "query method" );

$source = SeeAlso::Source->new( sub { shift }, ("ShortName" => "Test") );
ok( $source->description("ShortName") eq "Test", "ShortName");

$source = SeeAlso::Source->new( sub { shift }, ("LongName" => "Test source", "ShortName" => "Test") );
ok( $source->description("ShortName") eq "Test", "ShortName");
ok( $source->description("LongName") eq "Test source", "LongName");

my $descr = $source->description();
ok( $descr->{ShortName} eq "Test", "ShortName (2)");
ok( $descr->{LongName} eq "Test source", "LongName (2)");

# TODO: errors, more on query method



