#!perl -Tw

use Test::More qw(no_plan);
use strict;

ok(1);
exit;

require_ok("SeeAlso::Identifier::VIAF");

__END__

#!/usr/bin/perl
#use CGI;
#use Data::Dumper;


# Moving authority files to the Semantic Web with VIAF


# test cases
my %examples = (
    #'BNF|11887730' => ['',''],
    'http://d-nb.info/gnd/118642944'
        => ['http://d-nb.info/gnd/118642944','DNB|118642944'],
    'DNB|118642944'
        => ['http://d-nb.info/gnd/118642944','DNB|118642944'],
    'dnb|118642944'
        => ['http://d-nb.info/gnd/118642944','DNB|118642944'],
    'LC|n 50034328' => ['','LC|n 50034328'], # TODO...
    'LC|n50034328' => ['','LC|n 50034328'],
    'LC|n50-034328' => ['','LC|n 50034328'],
    # 'SELIBR|228480' =>  ['http://libris.kb.se/auth/228480','SELIBR|228480']
    # Schwedische Nationalbibliothek  
    # SELIBR|228480   http://libris.kb.se/auth/228480
    # info:lccn/n50066182 / http://errol.oclc.org/laf/n50-066182.html
);

# replace SeeAlso::Identifier::GND with SeeAlso::Identifier::VIAF

# TODO: add atom:content for a long description (including HTML with <div>)
# see http://www.atompub.org/rfc4287.html#element.content
# FullDescription type="text" or type="xhtml" or type="MIME..." and src="..."

# regression tests
foreach my $input (keys %examples) {
    print "$input -- ";
    my $result = $examples{$input};
    my ($file, $id) = guess_viaf_id($input);
    if (defined $file) {
        my $a = $VIAF_FILES{$file};
        $search = $file . '|' . ($a->{indexed} ? $a->{indexed}($id) : $id);
        $uri = $a->{prefix} . ($a->{uri} ? $a->{uri}($id) : $id);
        print " uri" if $uri eq $result->[0];
        print " sr" if $search eq $result->[1];
    }
    print "\n";
}

exit;
# Search ID:
# a) a full URI of any of the participating authority files or VIAF
#    => iterate over prefixes and test each file
# b) a local authority ID prefixed by its name (any case) and possible space and/or # bar and/or ":"

# d) a VIAF ID without prefix

my $cgi = new CGI;
# my $id = ;
# $id = "" unless defined $id;

# my $id = SeeAlso::Identifier::VIAF->new( $cgi->param('id') );
# if starts with viaf... => directly
# otherwise: search in VIAF, get and parse result, exract list of ids
# ...
