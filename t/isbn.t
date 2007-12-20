#!perl -Tw

use strict;

use Test::More tests => 5;

use SeeAlso::Identifier::ISBN;

my $isbn = SeeAlso::Identifier::ISBN->new("978-0-596-52724-2");
ok ( $isbn->valid );

$isbn->value('0596527241');
ok( $isbn->value eq '978-0-596-52724-2', 'ISBN-10' );

$isbn->value('0-8044-2957-x');
ok ( $isbn->value eq '978-0-8044-2957-3', "value" );
ok ( $isbn->uri eq 'urn:isbn:9780804429573', "URI" );

# invalid ISBN-13
$isbn = SeeAlso::Identifier::ISBN->new('978-1-84545-309-3');
ok ( !$isbn->valid, "invalid ISBN-13" );