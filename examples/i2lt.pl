#!/usr/bin/perl

=head1 NAME

i2lt.pl  - ISBN to LibraryThing SeeAlso service

=cut

use strict;
use CGI::Carp qw(fatalsToBrowser);
use utf8;

use FindBin;
use lib "$FindBin::RealBin/lib";

use SeeAlso::Source::ThingISBN;
use SeeAlso::Server;
use SeeAlso::Identifier::ISBN;
use SeeAlso::Logger;

my $cgi = new CGI;
my $server = SeeAlso::Server->new( cgi => $cgi );

# specify you database connection here
my $dsn = "dbi:mysql:seealso";
my $user = "seealso";
my $password;

my $source = SeeAlso::Source::ThingISBN->new(  dsn => $dsn, user => $user, password => $password );

$source->description("ShortName","isbn2librarything");

my $server = SeeAlso::Server->new(
    logger => SeeAlso::Logger->new("/var/log/seealso/seealso.log")
);

my $isbn = SeeAlso::Identifier::ISBN->new( $cgi->param("id") );
print $server->query( $source, $isbn );
