#!perl -Tw

use lib "./lib";
use strict;

use Test::More tests => 12;
use File::Temp;
use CGI;
use Data::Dumper;
use SeeAlso::Logger;


my $logger = SeeAlso::Logger->new();
ok ( ! $logger->{privacy} , "default setting" );
$logger = SeeAlso::Logger->new( privacy => 1 );
ok ( $logger->{privacy} , "additional option set" );
$logger = SeeAlso::Logger->new( \*STDOUT, privacy => 1 );
ok ( $logger->{privacy} , "filehandle and additiona option set" );

# close a temporary file and get its content
sub finish_tmpfile {
    my $fh = shift;
    my $fname = $fh->filename;
    close $fh;
    open (TMP, $fname) && return join("\n",<TMP>);
    return "";
}

my $cgi = CGI->new;
my $fh = File::Temp->new( UNLINK => 1 );
$logger = SeeAlso::Logger->new($fh);

my $response = SeeAlso::Response->new("123");
$response->add("foo","baz","uri:bar");
$response->add("doz","baz","uri:bar");

$logger->log( $cgi, $response, "testservice" );

my $logline = finish_tmpfile($fh);
ok( $logline, "Logger logged something");
my @fields = split("\t",$logline);
ok( scalar @fields == 7, "Logger logged 7 fields");
ok( $fields[0] =~ /^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d/, "timestamp");
ok( $fields[3] eq "testservice", "service name");
ok( $fields[5] == 1 && $fields[6] == 2, "valid and size");

#### next 

$fh = File::Temp->new( UNLINK => 1 );
$logger->set_file( $fh );
use SeeAlso::Server;
use SeeAlso::Source;
my $server = SeeAlso::Server->new( cgi => $cgi, logger => $logger );
my $source = SeeAlso::Source->new( sub { 
    my $r = SeeAlso::Response->new(shift);
    $r->add("foo","baz","uri:bar");
    return $r;
}, "ShortName" => "testsource" );
$cgi->param('format','seealso');
$cgi->param('id','456');
$server->query( $source );

$logline = finish_tmpfile($fh);
@fields = split("\t",$logline);
ok( $fields[3] eq "testsource", "service name (2)");
ok( $fields[4] eq "456", "search term");
ok( $fields[5] == 1 && $fields[6] == 1, "valid and size (2)");

#### next: filter method

$fh = File::Temp->new( UNLINK => 1 );
$logger = SeeAlso::Logger->new(
    file => $fh,
    filter => sub { $_[1] =~ s/\?.*$//; @_; }
);
#$logger->set_file( $fh );
$ENV{'REMOTE_HOST'} = "http://example.com?query";
$logger->log( $cgi, $response );
$logline = finish_tmpfile($fh);
@fields = split("\t",$logline);
ok ( $fields[1] eq "http://example.com", "filter method" );

