#!/usr/bin/perl

use strict;

=head1 NAME

extract-thingISBN.pl  - extract ISBN to LibraryThing mappings from thingISBN

=cut

# pleasy select the language of your choice (by default it is German)
my $base_url = "http://www.librarything.de";
my $description_string = "Dieses Werk bei LibraryThing";


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
    if ($el->{Name} eq "isbn") {
        my @seealso = (
            $self->{text},
            $base_url . "/work/" . $self->{work},
            $description_string,
            ""
        );
        print join("\t", @seealso). "\n";
    } else {

    }
}

sub characters {
    my ($self, $c) = @_;
    $self->{text} .= $c->{Data};
}
