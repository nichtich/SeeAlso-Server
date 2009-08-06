package SeeAlso::Identifier::ISBN;

=head1 NAME

SeeAlso::Identifier::VIAF - Identifier of VIAF or other authority file record

=cut

# TODO: rewrite and use a Factory instead!

use strict;
use warnings;

use Exporter;
our base 'SeeAlso::Identifier';
our @EXPORT_OK = qw( %VIAF_FILES guess_viaf_id );

=head1 DESCRIPTION

The Virtual International Authority File (VIAF) contains a mapping of
records about people in different national name authority files - see
L<http://viaf.org>.


=head1 SYNOPSIS

  # parse a possible identifier
  $id = SeeAlso::VIAF::Identifier->new( $string )

  $id->type() / $id->file()
  $id->value()   # return core part
  $id->indexed() # returns indexed core part
  $id->valid() ?
  $id->parse  == $id->new  ?
  $id->uri

=cut

=head1 METHODS

=head2 new ( [ $value [, @types ] ] )

...

=cut

sub new {
}

=head1 FUNCTIONS

=head2 guess_viaf_id ( $value )

# find out in which authority file of VIAF an identifier may fit

=cut

sub guess_viaf_id {
    my ($id) = @_;
    return unless defined $id and $id ne "";

    foreach my $file (keys %VIAF_FILES) {
        my $a = $VIAF_FILES{$file};

        my $prefix = $a->{prefix};

        if (substr($id,0,length($prefix)) eq $prefix) {
            # full URI
            $id = substr($id,length($prefix));
        } elsif (uc($id) =~ /^([A-Z]+)[:|]/i and $1 eq $file) {
            # FILE|... or FILE:...
            $id = substr($id,length($file)+1);
        } else {
            next;
        }

        $id = $a->{parse}($id);

        return ($file, $id) if defined $id;
    }
}

# return a SeeAlso::Identifier
# example:
# only DNB authority file numbers:
# new SeeAlso::VIAF::Identifier( $id, "DNB" )

#sub viaf_identifier(
#sub new {
#    my $class = shift;
#    my $
#}

# http://de.wikipedia.org/wiki/Wikipedia_Diskussion:Normdaten#.C3.9Cberfl.C3.BCssiger_Mehraufwand

sub file {
}

=head1 DATA

=head2 %VIAF_FILES

This hash is used internally but can also be exported to use Identifiers
of specific authority files that participate in VIAF. It is indexed by the
VIAF prefix of ach authority file or VIAF itself. Each authority file is
encoded as a hash with the following values:

=over 4

=item name

The name of the authority file

=item prefix

URI prefix of records of the authority file

=item parse

Reference to a function that parses a possible authority record identifier
without prefix as string and returns its core part - or undef if the string
does not look like a valid authority record identifier.

=item uri (optional)

Reference to a function that gets the core part of an identifier and returns
a URI part that can be appended to the URI prefix to form a full URI.

=item indexed (optional)

Reference to a function that gets the core part of an identifier and returns
a string part that can be appended to the VIAF prefix to form a full VIAF
index entry to search for a record in VIAF.

=back

...

=cut

my %VIAF_FILES = (
    BNF => {
        name => "Bibliothèque nationale de France",
        prefix => "http://catalogue.bnf.fr/",
        uri => sub { "ark:/12148/cb" . $_[0] . "t"; },
        parse => sub {
            $1 if $_[0] =~ /^ark:\/12148\/cb([0-9]+)[t]?$/;
        },
    },
    DNB => {
        name => "Deutsche Nationalbibliothek",
        prefix => "http://d-nb.info/gnd/",
        parse => sub { $1 if $_[0] =~ /^([0-9]+)$/; },
    },
    LC => {
        name => "Library of Congress",
        prefix => "info:lccn/",
        parse => sub { "$1$2" if $_[0] =~ /^(n) ?([0-9]+)$/ },
        indexed => sub { "$1 $2" if $_[0] =~ /^(n) ?([0-9]+)$/ },
        # => LC|n 50034328 
    },
    # TODO: SELIBR
    VIAF => {
        name => "Virtual International Authority File",
        prefix => "http://viaf.org/",
        parse => sub { $1 if $_[0] =~ /^([0-9]+)$/; },
        indexed => sub { $_[0]; } # TODO: this does not work!
    }
);

1;

=head1 TODO

Check whether we better subclass L<URI>.

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2007-2009 by Verbundzentrale Göttingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
