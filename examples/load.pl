#!/usr/bin/perl -w

=head1 NAME

load-mysql - load link data into a SeeAlso MySQL database

=cut

use utf8;
use strict;

use Getopt::Long;
use Pod::Usage;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use SeeAlso::Source::DBI;

my ($man, $help);
my ($testmode);

my ($logfile, $errorfile, $quietmode);

# parse command line options
GetOptions(
    "help|?" => \$help,
    "man" => \$man,
    "test" => \$testmode,
    "log:s" => \$logfile,
    "quiet" => \$quietmode
) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) if @ARGV < 2;

my ($infile, $database) = @ARGV;

(-r $infile) || pod2usage("Cannot read input file $infile");

($database =~ /^([^:@]+)(:[^@]+)?@([^:]+):([^:]+)(:.*)?$/)
#($database =~ /^([^:@]+)()@([^:]+):([^:]+)(:.*)?$/)
    || pod2usage("Second argument must specify a full database connection");

print "1: " . ($1||"") . "\n";
print "2: " . ($2||"") . "\n";
print "3: " . ($3||"") . "\n";
print "4: " . ($4||"") . "\n";
print "5: " . ($5||"") . "\n";

#exit;
my $mysql_user = $1;
my $mysql_pw = $2 || ""; $mysql_pw =~ s/^://;

my ($mysql_host, $mysql_db, $mysql_table) = ("localhost", $3, $4);
#if (defined $5) {
#($mysql_host, $mysql_db, $mysql_table)  = ($3, $4, $5) ;
#}

print "$mysql_user $mysql_pw $mysql_host $mysql_db $mysql_table\n";

exit;

($mysql_table && $mysql_table =~ /^[a-z0-9_]+$/) || pod2usage("Please specify a valid table name!");

$logfile = "-" if (not defined $logfile) and not $quietmode;

if (defined $logfile) {
    if ($logfile eq "-") {
        *LOG = *STDOUT;
    } else {
        open LOG, ">>$logfile" or die "Failed to open $logfile";
    }
}

# TODO: parse mysql connection parameter
# TODO: mysql-conf aus versch. quellen lesen

# TODO: get from command line

# TODO: mysql injection!
# for testing only
$mysql_host = "localhost";
$mysql_user = "seealso";
$mysql_db = "seealso";
$mysql_pw = "";

use DBI;

#my($dsi, $username, $auth, %attr)

my $db = SeeAlso::Source::DBI->new( "DBI:mysql:database=$mysql_db;host=$mysql_host", $mysql_user, $mysql_pw );
if ($db->connected) {
# TODO: validate mode (elements, length, URL-regexp...);
print LOG "loading data from $infile\n" if $logfile;

$db->load_file($infile);
} else {
    print STDERR "Failed to connect to database\n";
}

exit;

#print LOG "loading link data\n" if $logfile;

# TODO: print number of loaded links


__END__

=head1 SYNOPSIS

load [options] inputfile user[:password]@[host:]database

=head1 OPTIONS

 -help       Show this help
 -man        More detailed documentation
 -test       Do not load but test input and database
 -log FILE   Print logging to a file (default is '-' for STDOUT)

=head1 DESCRIPTION

This script loads link data into a SeeAlso server. You must at least
specify an input file with link data and a MySQL database connection.
The database table will be (re)created, all previous data will get lost!

The input file must be an utf8 encoded tabulator seperated file with 
the following 2 to 4 fields:

=over

=item Identifier

=item URL

=item Title

=item Description

=back



