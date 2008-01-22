#!/usr/bin/perl

=head1 NAME

i2ltconf.pl - configure ISBN to LibraryThing database

=head1 USAGE

Download thingISBN.xml.gz

  wget --timestamping --progress=dot:mega \
  http://www.librarything.com/feeds/thingISBN.xml.gz

Extract ISBNs with thingISBNextract.pl (will take some minutes)

  ./thingISBNextract.pl > isbn2lt

Create a database, for instance 'seealso' at MySQL at localhost
with user 'USER' and password 'PW'. Load link data into the database:

  ./i2ltconf.pl -d mysql:seealso -u USER -p PW -n -a isbn2lt -s -b

Change database settings in i2lt.pl and put it into your cgi-bin or
directly call it from the command line

  ./i2lt.pl id=9789026836787 format=seealso && echo

To make use of the service you can use the JavaScript client
that is available at http://ws.gbv.de/seealso/javascript-client/

=cut

use strict;

use Getopt::Long;
use Pod::Usage;
use POSIX;

use FindBin;
use lib "$FindBin::RealBin/lib";

use SeeAlso::Source::ThingISBN;
use SeeAlso::Identifier::ISBN;

my ($help,$status,$new,$add,$logfile,$database,$user,$password,$bulk);
GetOptions(
    "help|?" => \$help,
    "status" => \$status,
    "new" => \$new,
    "add:s" => \$add,
    "database:s" => \$database,
    "user:s" => \$user,
    "password:s" => \$password,
    "log:s" => \$logfile,
    "bulk" => \$bulk
) or pod2usage(2);

pod2usage(1) if $help or not ($status||$new||$add);

if (!$database) {
    print STDERR "You should specify a database!\n";
    print STDERR "Try 'mysql:DB' with your database DB and give user/password\n";
    exit;
}

#if ($logfile) {
#    open LOG, ">$logfile" || die("Failed to open logfile $logfile");
#}
*LOG = *STDERR;

sub logmsg {
    my $msg = shift;
    # print "$msg\n";
    #if ($logfile) {
        my $timestamp = strftime "[%Y-%m-%dT%H:%M:%S]", localtime;
        print LOG "$timestamp: $msg\n";
    #}
}

my $dsn;
if ($database =~ /^mysql:(.*)/i) {
    $dsn = "dbi:$database";
} elsif ($database =~ /^pg:(.*)/i) {
    $dsn = "dbi:$database";
    $bulk = 0; # not supported yet
} else {
    print STDERR "Unknown database type $database\n";
    exit;
}

my $i2lt = SeeAlso::Source::ThingISBN->new( dsn => $dsn, user => $user, password => $password );

if ($new) {
    logmsg("Creating table");
    $i2lt->createTable();
}

if ($add) {
    logmsg("Loading data into table" . ($bulk ? " (bulk import)" : ""));
    $i2lt->loadFile( file => $add, bulk => $bulk );
}

if ($status) {
    print "\nDatabase ";
    if ($i2lt->connected) {
        print "connected.\n";
        my $dbh = $i2lt->{dbh};
        my ($count) = $dbh->selectrow_array("SELECT COUNT(*) FROM " . $i2lt->{loadTable});
        print "  database ";
        print $count ? "contains $count mappings.\n" : "is empty.\n";
    } else {
        print "not connected\n";
    }
}

=head1 SYNOPSIS

i2ltconf.pl [options]

=head1 OPTIONS

 -help                brief help message
 -status              show database status information
 -new                 purge and/or create new database table
 -add FILE            add ISBN-workcode mappings from a tab-seperated file
 -database DB         database settings (stuff after 'dbi:' in perl's DBI->new)
 -user USERNAME       database user
 -password PASSWORD   database password
 -log LOGFILE         append messages to logfile (not implemented yet)

=head1 AUTHOR

Jakob Voss C<< jakob.voss@gbv.de >>
