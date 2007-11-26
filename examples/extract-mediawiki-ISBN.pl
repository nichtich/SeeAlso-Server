#!/usr/bin/perl -w

=head1 NAME

extract - extract templates, ISBN and RFC data from MediaWiki XML article dumps

=cut

use strict;
use utf8;
use POSIX;

use Getopt::Long;
use Pod::Usage;

my ($man, $help, $logfile);
my ($infile, $outfile);

# parse command line options
GetOptions(
    "log:s" => \$logfile,
    "help|?" => \$help,
    "man" => \$man,
) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;

$infile = shift @ARGV if @ARGV;
$outfile = shift @ARGV if @ARGV;


# open input, output, and logfile
if (!$infile or $infile eq "-") {
  *IN = *STDIN;
} else {
  (-r $infile) || die "Cannot read input file $infile";
  if ($infile =~ /\.bz2$/) {
    open IN, "bzcat $infile |" or die "Failed to open $infile";
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



# Parse arguments of one template call
sub template () {
    my ($tempname, $pagename, $seqno, $args) = @_;

    # {{foo bar}} calls Template:Foo_bar with upper case F.
    # Might not work for non-ASCII characters.
    $tempname = ucfirst($tempname);
    $tempname =~ s/ /_/g;

    if  (defined ($args)) {
        my ($field, $value);
        my $argc = 0;
        $args =~ s/^\|\s*(.*?)\s*$/$1/;
        foreach my $arg (split(/\s*\|\s*/, $args)) {
            $argc++;
            if ($arg =~ /^([^=]*?)\s*=\s*(.*)$/) {
                $field = $1;
                $value = $2;
            } else {
                $field = $argc;
                $value = $arg;
            }
            print OUT "$tempname|$pagename|$seqno|$field|$value\n";
        }
    } else {
        # Template call without parameters. Only print three fields
        print OUT "$tempname|$pagename|$seqno\n";
    }
    return "\@($tempname:$seqno)";
}

# This is like sub template() but for magic keywords RFC and ISBN that
# are followed by just one argument.
sub magicword () {
    my ($tempname, $pagename, $seqno, $arg) = @_;
    print OUT "$tempname|$pagename|$seqno|1|$arg\n";
    return "$tempname $arg";
}

# Parse MediaWiki pages-articles XML dump
my ($title, $text, $append) = ("", "", 0);
while (<IN>) {
    if (/\<title\>(.*)\<\/title\>/) {
        $title = $1;
        $text = "";
        next;
    }
    $append = 1 if /\<text/;
    $text .= $_ if $append;
    if (/\<\/text\>/) {
        my $i;
        $append = 0;
        $text =~ s/\n/ /g;

        $text =~ s/.*\<text[^\>]*\>(.*)\<\/text\>.*/$1/;

        # Perform various substitutions to get rid of troublesome
        # wiki markup.  In its place, leave $something

        # silently drop HTML comments
        $text =~ s/&lt;!--.*?--&gt;//g;

        # ignore nowiki, non-greedy match, leave $nowiki
        $text =~ s/&lt;nowiki&gt;.*?&lt;\/nowiki&gt;/\$nowiki/g;

        # ignore math, non-greedy match, leave $math
        $text =~ s/&lt;math&gt;.*?&lt;\/math&gt;/\$math/g;

        # wiki link with alternative text, leave $!
        # multiple passes handle image thumbnails
        for ($i = 0; $i < 5; $i++) {
            $text =~ s/(\[\[[^\]\|{}]*)\|([^\]{}]*\]\])/$1\$!$2/g;
        }

        # These are not real template calls, leave $pagename
        $text =~ s/{{(CURRENT(DAY|DOW|MONTH|TIME(STAMP)?|VERSION|WEEK|YEAR)(ABBREV|NAME(GEN)?)?|(ARTICLE|NAME|SUBJECT|TALK)SPACE|NUMBEROF(ADMINS|ARTICLES|FILES|PAGES|USERS)(:R)?|(ARTICLE|BASE|FULL|SUB|SUBJECT|TALK)?PAGENAMEE?|REVISIONID|SCRIPTPATH|SERVER(NAME)?|SITENAME)}}/\$$1/g;

        # template parameter value with default, leave $!
        $text =~ s/{{{([^\|{}]*)\|([^{}]*)}}}/\$($1\$!$2)/g;

        # template parameter values, leave $parameter
        $text =~ s/{{{([^{}]*)}}}/\$($1)/g;

        # template bang escape, leave $!
        $text =~ s/{{!}}/\$!/g;

        my $seqno = 1;
        $text =~ s/(ISBN) ([-0-9Xx]+)/&magicword($1,$title,$seqno++,$2)/eg;
        $text =~ s/(RFC) ([0-9]+)/&magicword($1,$title,$seqno++,$2)/eg;
        # multiple passes handle nested template calls
        for ($i = 0; $i < 5; $i++) {
            $text =~ s/{{\s*([^\|{}]*?)\s*(\|[^{}]*)?}}/&template($1,$title,$seqno++,$2)/eg;
        }

        # Debugging
        # print "$title<>$text\n";
    }
}

__END__

=head1 SYNOPSIS

extract [options] [infile [outfile]]

=head1 OPTIONS

 -help          brief help message
 -man           full documentation
 -log FILE      print messages to a given file (use '-' for STDOUT)

=head1 DESCRIPTION

This script reads a MediaWiki article dump file and extracts template
information and ISBN/RFC occurrences. If no input/output files parameter
is specified then data is read from STDIN and written to STDOUT. Input 
files with file extension C<.bz2> will be decompressed if the C<bzcat> 
command is available. Output files with file extension C<.gz> will be 
compressed. You may also specify a file to append logging messages to 
with the C<-log> option. The special file name '-' is used for STDIN/STDOUT.

The output contains one line for each parameter of a template. Elements 
on a line are seperated by pipe ('|') characters. The first element is 
the name of the template, the second element is the name of the page.
The "magic keywords" ISBN and RFC are treated as templates named "ISBN"
and "RFC".

See http://meta.wikimedia.org/wiki/User:LA2/Extraktor for the 
original script, further examples and discussion.

=head TODO

The extraction of templates does not really cover template programming 
and similar dirty MediaWiki wiki syntax tricks.

=head AUTHOR

Based on a script by Erik Zachte, modified by Jakob Voss

