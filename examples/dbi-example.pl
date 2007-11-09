#!/usr/bin/perl

use strict;
use CGI::Carp qw(fatalsToBrowser);
use utf8;

use FindBin;
use lib "$FindBin::RealBin/lib";
use SeeAlso::DBISource;
use SeeAlso::Server;

use CGI;
my $cgi = CGI->new();
my $server = SeeAlso::Server->new( cgi => $cgi );

my $source = SeeAlso::DBISource->new("DBI:mysql:database=undefined","","","");

my $http = $server->query( $source );
print $http;