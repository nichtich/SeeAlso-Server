#!/usr/bin/perl

use strict;
use utf8;

use SeeAlso::Client qw(seealso_request);

my $baseurl = "http://ws.gbv.de/seealso/isbn2wikipedia/";
my $identifier = "3-499-16512-0";
$identifier = "3-86521-330-8";
my $client = SeeAlso::Client->new( $baseurl );


#my $r = seealso_request, $id);
my $r = $client->query($identifier);

__END__

use Test::More;
use LWP::Simple;

my $source = get_from_server( $source );
test_deeply( $source, $test_source );

test_server( $server, $source ); # source given
test_server( $server ); # get source from OSD

my $url = "...";

ok(defined($content), "Get worked on $url");

#seealso_request