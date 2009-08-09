#!perl -Tw

use strict;

use Test::More;
use SeeAlso::DBI;
use SeeAlso::Identifier;
use SeeAlso::Response;
use SeeAlso::Source;
use Data::Dumper;
use File::Temp qw(tempfile);
use DBI;

my (undef,$file) = tempfile;

my $dbh = eval { DBI->connect("dbi:SQLite:dbname=$file","",""); };

if ( $dbh ) {
    plan( 'no_plan' );
} else {
    plan( skip_all => 'DBD::SQLite required to test SeeAlso::DBI' )
}

my $source = SeeAlso::DBI->new( dbh => $dbh, create_table => 1 );
isa_ok( $source, 'SeeAlso::DBI' );

my $r = SeeAlso::Response->new("x",["a"],["b"],["x:c"]);
#print Dumper($r) , "$source\n";

$source->store($r);

my $r2 = $source->query("x");
is_deeply( $r2, $r , 'store and query' );

my $src2 = SeeAlso::Source->new( $source );
is_deeply( $src2->query("x"), $r, 'wrapped source' );


#### SeeAlso::DBI as cache
my $s2 = SeeAlso::DBI->new( dbh => $dbh );
my $s1 = SeeAlso::Source->new( 
    sub { SeeAlso::Response->new( $_[0], ['x'], [''], [''] ); },
    cache => $s2
);

$r = $s1->query('foo');
is_deeply( $s2->query('foo'), $r, 'SeeAlso::DBI as cache' );



