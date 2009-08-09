#!/usr/bin/perl

use SeeAlso::Source;
use LWP::Simple qw(get);
use URI::Escape;
use DBI;
use Data::Dumper;

# Query sameas.org by URI and return a SeeAlso::Response object
sub lookup {
    my ($id) = @_;
    my $url = "http://sameas.org/text?uri=" . uri_escape( "$id" );

    my $content = get($url);
    die "Failed to query sameas.org via HTTP" unless defined $content;

    my @uris = grep { defined $_ and $_ ne $id } 
        map { uri_unescape($1) if /^\s*<([^>]+)>\s*$/; } 
        split(/\n/, $content);

    return new SeeAlso::Response
        $id,
        [ ('') x scalar @uris ], 
        [ ('http://www.w3.org/2002/07/owl#sameAs') x scalar @uris ],
        \@uris ;
}

#use CHI;
#my $cache = CHI->new( driver => 'File', cache_root => '/tmp/sameas/' );
use Cache::File;
my $cache = Cache::File->new( cache_root => '/tmp/sameas/' );
my $source = SeeAlso::Source->new( \&lookup, cache => $cache );
my $r = $source->query('http://dbpedia.org/resource/London');

print Dumper($r);

# TODO: as sameAs is transitive, we can store bundles instead of ...
# id => get_bundle
#       => 
__END__

my $sql = {
    create => q{CREATE TABLE IF NOT EXIST sameas (
                  'set' INTEGER, uri VARCHAR(128) );}
    fetch => q{SELECT '','',x.uri FROM sameas x, y WHERE x.set=y.set AND y.uri=?},
    store => q{INSERT INTO sameas (uri,set,)
);

- set-ID, member