#!/usr/bin/perl -w

=head1 NAME

transform - collect and prepare identifiers extracted from MediaWiki dumps

=cut

use utf8;
use strict;

use Getopt::Long;
use Pod::Usage;

use lib "../lib";
use SeeAlso::Identifier::ISBN;
use SeeAlso::Identifier::PND;
use utf8;

my ($man, $help, $wikibase, $idtype, $logfile);
my ($infile, $outfile, $invalidfile);

# parse command line options
GetOptions(
    "log:s" => \$logfile,
    "invalid:s" => \$invalidfile,
    "help|?" => \$help,
    "man" => \$man,
    "type:s" => \$idtype,
    "wiki:s" => \$wikibase
) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;

if ($idtype ne "isbn" and $idtype ne "pnd") {
  print "please specify either 'isbn' or 'pnd' in parameter 'type'";
  exit;
}

if (defined $wikibase and $wikibase =~ /^([-a-z]+)wiki$/) {
    # TODO: finer test of wiki base
    $wikibase = "http://$1.wikipedia.org/wiki/";
} else {
    pod2usage("option -wiki must specify a wiki ('$wikibase' is not)");
}

$infile = shift @ARGV if @ARGV;
$outfile = shift @ARGV if @ARGV;

# open input, output, logfile, and errorfile
if (!$infile or $infile eq "-") {
  *IN = *STDIN;
} else {
  (-r $infile) || die "Cannot read input file $infile";
  if ($infile =~ /\.gz$/) {
    open IN, "zcat $infile |" or die "Failed to open $infile";
  } else {
    open IN, $infile or die "Failed to open $infile";
  }
}

if (!$outfile or $outfile eq "-") {
  *OUT = *STDOUT;
} elsif ($outfile =~ /\.gz$/) {
  open (OUT, "| gzip -cf >$outfile") or die "Failed to open $outfile";
} else {
  open OUT, ">$outfile" or die "Failed to open $outfile";
}

if ($logfile) {
  if ($logfile eq "-") {
    *LOG = *STDOUT;
  } else {
    open LOG, ">>$logfile" or die "Failed to open $logfile";
  }
}


if ($invalidfile) {
  if ($invalidfile eq "-") {
    *INVALID = *STDOUT;
  } else {
    open INVALID, ">$invalidfile" or die "Failed to open $invalidfile";
  }
}

# init statistics
my ($c_valid, $c_invalid, $c_ean) = (0,0,0);

# parse a single PND
sub parse_pnd {
    my $input = shift;
    return unless $input;
    $input =~ s/x/X/g;
    return unless $input =~ /[0-9]+[0-9X]/;
    return $input;
}

print LOG "transforming identifiers ...\n" if defined $logfile;
while(<IN>) {
    chomp;
    my ($template, $page, $seqno, $field, $data, $rest) = split('\|', $_);

    if ($idtype eq 'isbn') {
      # TODO: plugin different handlers here / transform framework
      next unless $template eq 'ISBN';

      $c_ean++ if $data =~ /^97[89]/;

      my $isbn = SeeAlso::Identifier::ISBN->new( $data );

      if (defined $isbn and $isbn->valid) {
          $c_valid++;
          print OUT $isbn->indexed . "\t$page\t\t$wikibase$page\n";
      } else {
          $c_invalid++;
          print INVALID "$data\n" if $invalidfile;
      }
    } elsif ($idtype eq 'pnd') {
        next unless $template eq 'PND';
        my $pnd = parse_pnd($data);
        if (defined $pnd) {
            $c_valid++;
            print OUT $pnd . "\t$page\t\t$wikibase$page\n";
        } else {
            $c_invalid++;
            print INVALID "$data\n" if $invalidfile;
        }
    }
}

my $c_total = $c_valid + $c_invalid;
if (defined $logfile and $c_total) {
    # TODO: print filenames and timestamp also
    print LOG "Identifier:   \t$c_total\n"
      . "Valid:  \t$c_valid (" . sprintf("%.2f",100*$c_valid/$c_total) . "%)\n"
      . "Invalid:\t$c_invalid (" . sprintf("%.2f",100*$c_invalid/$c_total) . "%)\n";
    print LOG "ISBN-13:\t$c_ean (" . sprintf("%.2f",100*$c_ean/$c_total) . "%)\n" if $idtype eq 'isbn';
}

__END__

=head1 SYNOPSIS

transform [options] [infile [outfile]]

This script is working but needs refactoring. Just don't look at the code :-(

=head1 OPTIONS

 -help          brief help message
 -man           full documentation
 -log FILE      print messages to a given file ('-' for STDOUT)
 -invalid FILE  print invalid identifiers to a file ('-' for STDOUT)
 -type TYPE     type of identifier to look for ('isbn' or 'pnd')
 -wiki WIKI     which wiki for linkbase 

=head1 DESCRIPTION

This script reads identifiers extracted from MediaWiki article dumps and 
prepares them for a SeeAlso server. If no input/output files parameter is 
specified then data is read from STDIN and written to STDOUT. Input files 
with file extension C<.gz> will be decompressed if the C<zcat> command is available. Output files with file extension C<.gz> will be compressed.
You may also specify a file to append logging messages to with the 
C<-log> option and a file to write invalid identifiers with the <-invalid>
option.  The special file name '-' is used for STDIN/STDOUT.

=head1 TODO

Up to now only ISBN identifiers can be handled. A framework to handle any
identifier (PND, links to other databases) could be useful.

=head AUTHOR

Jakob Voss
