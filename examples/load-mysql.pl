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
my ($testmode, $insertmode, $createmode); # TODO: test = check mode
my ($logfile, $errorfile, $quietmode);
# TODO: log number of loaded links (how?)

# parse command line options
GetOptions(
    "help|?" => \$help,
    "man" => \$man,
    "test" => \$testmode,
    "log:s" => \$logfile,
    "quiet" => \$quietmode,
    "insert" => \$insertmode, # add some results instead of loading all
    "create" => \$createmode
) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) if @ARGV < 2;

my ($infile, $database, $mysql_read_default_file) = @ARGV;

(-r $infile) || pod2usage("Cannot read input file $infile");

# TODO: better parse in two steps!
($database =~ /^([^:@]+)(:[^@]+)?@([^:]+):([^:]+)(:.*)?$/)
    || pod2usage("Second argument must specify a full database connection");

#print "1:$2 2:$2 3:$3 4:$4\n";
my ($mysql_user, $mysql_pw, $mysql_host, $mysql_db, $mysql_table) =
    ($1, $2||"", "localhost", $3, $4);
if (defined $5) {
  $mysql_table = $5;
  $mysql_host = $3;
  $mysql_db = $4;

}
$mysql_pw =~ s/^://;
$mysql_table =~ s/^://;

($mysql_table && $mysql_table =~ /^[a-z0-9_]+$/) 
    || pod2usage("Please specify a valid table name!");

if ($mysql_user eq "" and not defined $mysql_read_default_file and
    not -r $mysql_read_default_file) {
    pod2usage("You must specify user (and password) by parameter or config file");
}

$logfile = "-" if (not defined $logfile) and not $quietmode;


if (defined $logfile) {
    if ($logfile eq "-") {
        *LOG = *STDOUT;
    } else {
        open LOG, ">>$logfile" or die "Failed to open $logfile";
    }
}

use DBI;

my $dsn = "DBI:mysql:$mysql_db;host=$mysql_host";
if ($mysql_user eq "") {
    $dsn .= ";mysql_read_default_file=$mysql_read_default_file";
}

if ($testmode) {
    print "TESTMODE\n";
    print "mysql_db: $mysql_db\n";
    print "mysql_table: $mysql_table\n";
}

my $db = SeeAlso::Source::DBI->new( $dsn, $mysql_table, $mysql_user, $mysql_pw );
if ($db->connected) {

    if ($testmode) {
        print "connected\n";
        exit;
    }

    if ($createmode) {
        print LOG "creating table $mysql_table\n" if $logfile;
        $db->create_table();
    }
    # TODO: also log database name and table name!
    print LOG "loading data from $infile\n" if $logfile;
    if ($insertmode) { # TODO
        open FILE, $infile;
        while (<FILE>) {
            chomp;
            my @values = split "\t";
            next unless scalar(@values) == 4;
            $db->insert(@values);
        } # TODO: count
        close FILE;
    } else {
        $db->load_file($infile);
    }
} else {
    print STDERR "Failed to connect to database\n";
}


__END__

=head1 SYNOPSIS

load [options] input [[user[:password]@][host:]database:table [config]

=head1 OPTIONS

 -help       Show this help
 -man        More detailed documentation
 -test       Do not load but test input and database
 -log FILE   Print logging to a file (default is '-' for STDOUT)
 -insert     Add some links to an existing table
 -create     Create the table (deletes previous existing table!)

=head1 DESCRIPTION

This script loads link data into a SeeAlso server. You must specify an input
file with link data and a database configuration. The database configuration
must at least contain a database name and a table name. You can specify user
and password by command line paramater

  user_name:user_password@database:table

or in a MySQL configuration file

  [client]
  user=user_name
  password=user_password

On loading the database table will be (re)created, all previous data will 
get lost!

The input file must be an utf8 encoded tabulator seperated file with 
the following 2 to 4 fields:

=over

=item identifier

=item label

=item description

=item URI

=back
