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

my $source;
my (undef,$file) = tempfile;

my $dbh = eval { DBI->connect("dbi:SQLite:dbname=$file","",""); };

if ( $dbh ) {
    plan( 'no_plan' );
} else {
    plan( skip_all => 'DBD::SQLite required to test SeeAlso::DBI' );
    exit;
}

$source = SeeAlso::DBI->new( dbh => $dbh, build => 1 );
isa_ok( $source, 'SeeAlso::DBI' );

my $r = SeeAlso::Response->new("x",["a"],["b"],["x:c"]);
#print Dumper($r) , "$source\n";

$source->insert($r);

my $r2 = $source->query("x");
is_deeply( $r2, $r , 'insert and query' );

my $src2 = SeeAlso::Source->new( $source );
is_deeply( $src2->query("x"), $r, 'wrapped source' );

#### Read from config file
my $cfg = <<CFG;
[DBI]
dbi=SQLite:dbname=$file
CFG
$source = SeeAlso::DBI->new( config => \$cfg );
is_deeply( $source->query("x"), $r, 'from config file' );


#### SeeAlso::DBI as cache
my $s2 = SeeAlso::DBI->new( dbh => $dbh );
my $s1 = SeeAlso::Source->new( 
    sub { SeeAlso::Response->new( $_[0], ['x'], [''], [''] ); },
    cache => $s2
);

$r = $s1->query('foo');
is_deeply( $s2->query('foo'), $r, 'SeeAlso::DBI as cache' );

### import
# t/isbn.csv
$source->clear;
$source->bulk_import( file => 't/isbn-dump.csv', uri => 'http://de.wikipedia.org/wiki/#2' );

# SeeAlso::Identifier::ISBN->new(...)->hash

$r = $source->query( '377760736' );
is_deeply( [ sort $r->labels ], ["Actinium","Aluminium","Antimon","Argon","Arsen","Astat"], "bulk_import" );



