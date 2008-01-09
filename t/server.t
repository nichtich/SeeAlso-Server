#!perl -Tw

use strict;

use Test::More tests => 10;

use CGI;
my $cgi = CGI->new();

use SeeAlso::Server;
use SeeAlso::Response;

my $s = SeeAlso::Server->new( cgi=>$cgi );
my $r = SeeAlso::Response->new();

open XML, "t/listFormats200.xml";
my $xml200 = join('', <XML>);
ok( $s->listFormats($r) eq $xml200, 'listFormats => 200');
close XML;

$r = SeeAlso::Response->new("xyz");

open XML, "t/listFormats404.xml";
my $xml404 = join('', <XML>);
ok( $s->listFormats($r) eq $xml404, 'listFormats => 404');
close XML;

$r->add("test");

open XML, "t/listFormats300.xml";
my $xml300 = join('', <XML>);
ok( $s->listFormats($r) eq $xml300, 'listFormats => 300');
close XML;

$s = SeeAlso::Server->new( description=>"" );
$r = SeeAlso::Response->new();

open XML, "t/listFormats200noosd.xml";
my $xml200noosd = join('', <XML>);
ok( $s->listFormats($r) eq $xml200noosd, 'listFormats => 200 without OpenSearch Description');
close XML;


use SeeAlso::Source;
$s = SeeAlso::Server->new( cgi=>$cgi );
my $source = SeeAlso::Source->new();
my $identifier = SeeAlso::Identifier->new();
my $http = $s->query($source, $identifier, 'seealso');
ok ( $http =~ /^Status: 200[^\[]+\["",\[\],\[\],\[\]\]$/m, 'Empty response' );

$http = $s->query($source, $identifier, 'foo');
ok ( $http eq $xml200, 'List of formats (because no identifier)');

$source = SeeAlso::Source->new(
    sub { my $id = shift; return SeeAlso::Response->new( $id->normalized() ); }
);
$identifier = SeeAlso::Identifier->new("xyz");

$http = $s->query($source, $identifier, 'seealso');
ok ( $http =~ /^Status: 200[^\[]+\["xyz",\[\],\[\],\[\]\]$/m, 'No results' );

$http = $s->query($source, $identifier, 'foo');
ok ( $http eq $xml404, 'Result but not right format');

$source = SeeAlso::Source->new(
    sub {
        my $id = shift;
        my $r = SeeAlso::Response->new( $id->normalized );
        $r->add("test");
        return $r;
    }
);
$http = $s->query($source, $identifier, 'seealso');
ok ( not $source->hasErrors() and $http =~ /^Status: 200[^\[]+\["xyz",\["test"\],\[""\],\[""\]\]$/m, 'JSON Results' );

$http = $s->query($source, $identifier, 'foo');
ok ( $http eq $xml300, 'Result but not right format');


