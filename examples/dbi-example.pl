#!/usr/bin/perl

use strict;
use CGI::Carp qw(fatalsToBrowser);
use utf8;

use FindBin;
use lib "$FindBin::RealBin/lib";
use SeeAlso::Source::DBI;
use SeeAlso::Server;

use CGI;
my $cgi = CGI->new();
my $server = SeeAlso::Server->new( cgi => $cgi );

my $source = SeeAlso::Source::DBI->new("DBI:mysql:database=undefined","","","");
$source->description("ShortName","Example server");

my $http = $server->query( $source );
print $http;
