#!perl -Tw

use strict;

use Test::More tests => 16;

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

sub query_method {
    my $id = shift;
    my $r = SeeAlso::Response->new( $id->normalized );
    $r->add("test");
    return $r;
}
$source = SeeAlso::Source->new( \&query_method );

$http = $s->query($source, $identifier, 'seealso');
ok ( not $source->errors() and $http =~ /^Status: 200[^\[]+\["xyz",\["test"\],\[""\],\[""\]\]$/m, 'JSON Results' );

$http = $s->query($source, $identifier, 'foo');
is ( $http, $xml300, 'Result but not right format');

$http = $s->query($source, $identifier, 'seealso', 'a[1].b');
my $res = '^Status: 200[^\[]+a\[1\]\.b\(\["xyz",\["test"\],\[""\],\[""\]\]\);$';
ok ( not $source->errors() and $http =~ /$res/m, 'JSON Result with callback' );

$cgi = CGI->new;
$cgi->param('format'=>'seealso');
$cgi->param('callback'=>'a[1].b');
$http = query_seealso_server( $source, cgi => $cgi, id => $identifier );
ok ( $http =~ /$res/m, 'JSON Result with callback (query_seealso_server)' );

$http = query_seealso_server( \&query_method, cgi => $cgi, id => $identifier );
ok ( $http =~ /$res/m, 'JSON Result with callback (query_seealso_server, sub)' );

$http = query_seealso_server( \&query_method, ["ShortName"=>"foo"], cgi => $cgi, id => $identifier );
ok ( $http =~ /$res/m, 'JSON Result with callback (query_seealso_server, sub and description)' );

$http = $s->query($source, $identifier, 'seealso', '{');
ok ( $http =~ /^Status: 400/, 'invalid callback' );

sub quc {
    my $id = shift;
    return "UC:" . uc($id->value);
}
$s = SeeAlso::Server->new( formats => { "uc" => { type => "text/plain", method => \&quc } } );
$http = $s->query( $source, new SeeAlso::Identifier("abc"), "uc" );
ok ( $http eq "UC:ABC", "additional unAPI format" );

