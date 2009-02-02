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

#seealso_request