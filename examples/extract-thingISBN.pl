#!/usr/bin/perl

use strict;

=head1 NAME

extract-thingISBN.pl  - extract ISBN to LibraryThing mappings from thingISBN

=head1 DESCRIPTION

This script reads a thingISBN XML file (provided by LibraryThing) 
and extracts a tabulator seperated data that can be loaded into
a SeeAlso::Source::DBI database. You must set the preferred language 
in the source code (default is German). Extracted data is written to
standard output so you probably want to pipe it to a file. 

=cut

use lib "../lib";
use SeeAlso::Identifier::ISBN;

# pleasy select the language of your choice (by default it is German)
my $base_url = "http://www.librarything.de";

my $file = shift @ARGV;
if (not defined $file) {
    print STDERR "Please specify a filename (probably 'thingISBN.xml.gz')!\n";
    exit;
}

open (FILE, "zcat $file |") or die "Failed to read file: $!\n";

use XML::SAX;
use XML::SAX::ParserFactory;
my $parser = XML::SAX::ParserFactory->parser( Handler => MySAXHandler->new );
$parser->parse_file(\*FILE);
close(FILE);


# TODO: Same as extract-mediawiki-ISBN: directly use Result-sets or sources that get a line/data and deliver a result!

package MySAXHandler;
use base qw(XML::SAX::Base);

use Data::Dumper;

sub start_element {
    my ($self, $el) = @_;
    if ($el->{Name} eq "work") {
        $self->{work} = $el->{Attributes}{"{}workcode"}->{Value};
    } else {
        $self->{text} = "";
    }
}

sub end_element {
    my ($self, $el) = @_;
    return unless $el->{Name} eq "isbn";

    my $data = $self->{text};

    #$c_ean++ if $data =~ /^97[89]/;
    my $isbn = SeeAlso::Identifier::ISBN->new( $data );

    if (defined $isbn and $isbn->valid) {
        #$c_valid++;
        my @seealso = (
            $isbn->indexed,
            "LibraryThing",
            "",
            $base_url . "/work/" . $self->{work},
        );
        print join("\t", @seealso). "\n";
    } else {
        #$c_invalid++;
        # print INVALID "$data\n" if $invalidfile;
    }
}

sub characters {
    my ($self, $c) = @_;
    $self->{text} .= $c->{Data};
}
