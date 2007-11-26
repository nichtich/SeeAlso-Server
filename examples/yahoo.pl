#!/usr/bin/perl

#
# Since July 2007 Yahoo provides search suggestions called 'Search Suggest'.
# See http://www.ysearchblog.com/archives/000469.html for the announcement.
# Suggestions are delivered in a format similar to OpenSearch Suggestions
# but not the same. This script parses Yahoo's search suggestions, adds
# links to Yahoo and cleanly wrapped provides a SeeAlso service.
#
# Please note that Yahoo might not want you to query their server via this
# method, and they might change their server, so also consider
# http://developer.yahoo.com/search/web/V1/relatedSuggestion.html
#
# A similar service for Google is available at
# http://google.com/complete/search?output=toolbar&q=...
#

use strict;
use LWP::Simple;
use URI::Escape qw(uri_escape);
use JSON;
use utf8;

use FindBin;
use lib "$FindBin::RealBin/../lib";

use SeeAlso::Server;
use SeeAlso::Source;

sub query_method {
    my $identifier = shift;
    return unless $identifier->valid;

    my $urlbase = "http://search.yahoo.com/search?p=";
    my $url = 'http://sugg.search.yahoo.com/sg/?output=fxsearch&nresults=10&command='
            . uri_escape($identifier->value);

    my $json = get($url);
    $json =~ s/^fxsearch\(//;
    $json =~ s/\)\s*(<!--.*-->)?\s*$//m; 

    # Parse JSON data (you should NEVER trust a web service whithout checking)
    my $obj = jsonToObj($json); 
    for (my $i=0; $i < @{$obj->[1]}; $i++) {
        $obj->[3][$i] = $urlbase . uri_escape($obj->[1][$i]);
    }

    return SeeAlso::Response->new( @$obj );
}

my $server = SeeAlso::Server->new();
my $source = SeeAlso::Source->new( \&query_method, 
    ( "ShortName" => "Yahoo Search Suggest" )
);
print $server->query( $source );
