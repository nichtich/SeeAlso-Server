package SeeAlso::Identifier::ISIL;

use strict;
use warnings;
use utf8;

=head1 NAME

SeeAlso::Identifier::ISIL - International Standard Identifier for Libraries
and Related Organisations

=head1 DESCRIPTION

The purpose of ISIL is to define and promote the use of a set of 
standard identifiers for the unique identification of libraries 
and related organizations with a minimum impact on already existing 
systems. ISILs are mostly based on existing MARC Organisation Codes 
(also known as National Union Catalogue symbols (NUC)) or similar 
existing identifiers. ISIL is defined in ISO 15511:2003.

The ISIL is a variable length identifier. The ISIL consists of a maximum 
of 16 characters, using digits (arabic numerals 0 to 9), unmodified letters 
from the basic latin alphabet and the special marks solidus (/), 
hyphen-minus (-) and colon (:). An ISIL is made up by two components:
a prefix and a library identifier, in that order, separated by a hyphen-minus.

ISIL prefixes are managed by the ISIL Registration Authority 
at http://www.bs.dk/isil/ . An ISIL prefix can either be a 
country code or a non country-code.

A country code identifies the country in which the library or 
related organization is located at the time the ISIL is assigned. 
The country code shall consist of two uppercase letters in
accordance with the codes specified in ISO 3166-1.

A non-country code prefix is any combination of Latin alphabet 
characters (upper or lower case) or digits (but not special marks). 
The prefix may be one, three, or four characters in length. 
The prefix is registered at a global level with the ISIL 
Registration Authority.

=cut

use SeeAlso::Identifier;
use Carp;

require Exporter;

use base qw( SeeAlso::Identifier Exporter );
our $VERSION = "0.1";
our @EXPORT_OK = qw( sigel2isil );

=head1 METHODS

=head2 new ( [ $value ] )

Create a new ISIL and optionally set its value..

=cut

sub new {
    my $class = shift;
    my $self = bless { }, $class;
    $self->value( shift || "" );
    return $self;
}

=head2 value ( [ $value ] )

Get and/or set the value of the ISIL. The ISIL must consist of a
prefix and a local library identifier seperated by hypen-minus (-).
Additionally it can be preceeded by "ISIL ".

The method returns undef or the valid, normalized ISIL.

=cut

sub value {
    my $self = shift;
    my $value = shift;

    if (defined $value) {
        $self->{value} = undef;
        $value =~ s/^\s+|\s+$//g;
        $value =~ s/^ISIL |^info:isil\///;

        # ISIL too long
        return unless length($value) <= 16;

        # Does not look like an ISIL
        return unless $value =~ /^([A-Z0-9]+)-(.+)$/;

        my ($prefix, $local) = ($1, $2);

        # Invalid prefix
        return unless ($prefix =~ /^[A-Z]{2}$/ or 
                       $prefix =~ /^[A-Z0-9]([A-Z0-9]{1-3})?$/);

        # Invalid characters in local library identifier
        return unless ($local =~ /^[a-zA-Z0-9:\/-]+$/);

        $self->{value} = $value;
    }

   return $self->{value};
}


=head2 prefix ( )

Returns the ISIL prefix.

=cut

sub prefix {
    my $self = shift;
    return $1 if (defined $self->{value} and $self->value =~ /^([A-Z0-9]+)-(.+)$/);
}

=head2 local ( )

Returns the ISIL local library identifier.

=cut

sub local {
    my $self = shift;
    return $2 if (defined $self->{value} and $self->value =~ /^([A-Z0-9]+)-(.+)$/);
}

=head2 normalized ( )

Returns a normalized form as URI.

=cut

sub normalized {
    my $self = shift;
    return "info:isil/" . $self->{value} if $self->valid();
}

=head1 UTILITY FUNCTIONS

=head2 sigel2isil ( $sigel )

Creates an ISIL from an old German library identifier ("Sigel")

=cut

sub sigel2isil {
    my $sigel = shift;

    # Falls das Sigel mit einem Buchstaben beginnt, 
    # wird dieser in einen Großbuchstaben umgewandelt
    my $isil = ucfirst($sigel);

    # Bindestriche und Leerzeichen werden entfernt
    $isil =~ s/[- ]//g;

    # Umlaute und Eszett (Ä,Ö,Ü,ä,ö,ü,ß) werden durch 
    # einfache Buchstaben ersetzen (AE,ÖE,UE,ae,oe,ue,ss).
    $isil =~ s/Ä/AE/g;
    $isil =~ s/Ö/OE/g;
    $isil =~ s/Ü/UE/g;
    $isil =~ s/ä/ae/g;
    $isil =~ s/ö/oe/g;
    $isil =~ s/ü/ue/g;
    $isil =~ s/ß/ss/g;

    return SeeAlso::Identifier::ISIL->new("DE-$isil");
}

1;

=head1 NOTES

We could add validity check on prefixes with an additional prefix list.
Note the usage of ISO 3166-2:1998 codes is only a recommendation in
ISO 15511:2003. Moreover some country subdivision have changed since
1998 and National ISIL Agencies may have other reasons not to use the
same codes as provided by L<Locale::SubCountry>. You can find a list
of prefixes in the source code of this package.

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2007-2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.

=cut

__END__

our %ISIL_prefixes = (
  'AU' => ['Australia', undef],
  'CA' => ['Canada', undef],
  'CY' => ['Cyprus', undef],
  'DE' => ['Germany', undef],
  'DK' => ['Denmark', undef],
  'EG' => ['Egypt', undef],
  'FI' => ['Finland', undef],
  'FR' => ['France', undef],
  'GB' => ['United Kingdom', undef],
  'IR' => ['Islamic Republic of Iran', undef],
  'KR' => ['Republic of Korea', undef],
  'NL' => ['The Netherlands', undef],
  'NZ' => ['New Zealand', undef],
  'NO' => ['Norway', undef],
  'CH' => ['Switzerland', undef],
  'US' => ['United States of America', undef],

  # in preperation (2006)
  'M' => ['Library of Congress - outside US', undef],
  'ZDB' => ['Staatsbibliothek zu Berlin - Zeitschriftendatenbank', undef],
  'OCLC' => ['OCLC WorldCat Registry', undef],
);
