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
    || pod2usage("Second argument must specify a full database connection");

my $mysql_user = $1;
my $mysql_pw   = $2 || "";
my $mysql_host = "localhost";
my $mysql_db = $3;
my $mysql_table = $4;
if (defined $5) {
  $mysql_host = $3;
  $mysql_db = $4;
  $mysql_table = $5;
}
$mysql_pw =~ s/^://;

($mysql_table && $mysql_table =~ /^[a-z0-9_]+$/) 
    || pod2usage("Please specify a valid table name!");

$logfile = "-" if (not defined $logfile) and not $quietmode;

if (defined $logfile) {
    if ($logfile eq "-") {
        *LOG = *STDOUT;
    } else {
        open LOG, ">>$logfile" or die "Failed to open $logfile";
    }
}

use DBI;

my $db = SeeAlso::Source::DBI->new( "DBI:mysql:database=$mysql_db;host=$mysql_host", $mysql_user, $mysql_pw );
if ($db->connected) {
    print LOG "loading data from $infile\n" if $logfile;
    $db->load_file($infile);
} else {
    print STDERR "Failed to connect to database\n";
}


__END__

=head1 SYNOPSIS

load [options] inputfile user[:password]@[host:]database:table

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

=head1 TODO

Get DBI data from a configuration file. Add a validation mode/rum
(elements, length, URL-regexp...). Log the number of loaded links.

