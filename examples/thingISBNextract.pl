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

http://www.librarything.com/thingology/2007/03/thingisbn-data-in-one-file.php

=cut

use FindBin;
use lib "$FindBin::RealBin/lib";

use XML::SAX;
use XML::SAX::ParserFactory;
use SeeAlso::Identifier::ISBN;

my $file = shift @ARGV || "thingISBN.xml.gz";
$file = "zcat $file |" if $file =~ /\.gz$/;
open (FILE, $file) or die "Failed to read file $file: $!\n";

my $parser = XML::SAX::ParserFactory->parser( Handler => MySAXHandler->new );
$parser->parse_file(\*FILE);
close(FILE);


# Clean XML parser instead of regular expressions
package MySAXHandler;
use base qw(XML::SAX::Base);

sub start_element {
    my ($self, $el) = @_;
    if ($el->{Name} eq "work") {
        $self->{work} = $el->{Attributes}{"{}workcode"}->{Value};
    } elsif ($el->{Name} eq "isbn" and $el->{Attributes}{"{}workcode"}->{Value}) {
        $self->{uncertain} = $el->{Attributes}{"{}uncertain"}->{Value};
    } else {
        $self->{text} = "";
    }
}

sub end_element {
    my ($self, $el) = @_;
    return unless $el->{Name} eq "isbn";
    return if $self->{uncertain} eq "true"; # skip fuzzy ISBNs

    my $data = $self->{text};
    my $isbn = SeeAlso::Identifier::ISBN->new( $data );

    if (defined $isbn and $isbn->valid) {
        # $c_valid++;
        print $isbn->indexed . "\t" . $self->{work} . "\n";

    } else {
        print STDERR "invalid ISBN:\t$data\n";
    }
}

sub characters {
    my ($self, $c) = @_;
    $self->{text} .= $c->{Data};
}

__END__
