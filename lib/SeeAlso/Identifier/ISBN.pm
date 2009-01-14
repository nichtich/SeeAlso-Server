package SeeAlso::Identifier::ISBN;

use strict;
use warnings;
use utf8;

=head1 NAME

SeeAlso::Identifier::ISBN - International Standard Book Number Identifier

=cut

use Business::ISBN;
use Carp;

use base qw( SeeAlso::Identifier );
our $VERSION = "0.6";

=head1 DESCRIPTION

This module handles International Standard Book Numbers as identifiers.
Unlike L<Business::ISBN> the constructor of SeeAlso::Identifier::ISBN 
always returns an defined object. The 'valid' method derived from 
L<SeeAlso::Identifier> returns whether the ISBN is valid. The methods
'value', 'normalized', 'indexed' and 'int32' can be used on valid ISBNs 
to get different representations. 'value' and 'int32' can also be used 
to set the ISBN. ISBN-10 are converted to ISBN-13.

=head1 METHODS

=head2 new ( [ $value ] )

Create a new ISBN identifier.

=cut

sub new {
    my $class = shift;
    my $self = bless {
        value => undef
    }, $class;
    $self->value( shift );
    return $self;
}

=head2 value ( [ $value ] )

Get and/or set the value of the ISBN. Returns undef or the valid
ISBN-13 value with hyphens. Validity and positition of hyphens are
determined with L<Business::ISBN>.

=cut

sub value {
    my $self = shift;
    my $value = shift;

    if (defined $value) {
        $value =~ s/^urn:isbn://i;
        $self->{value} = Business::ISBN->new( $value );
        return unless defined $self->{value};

        my $error = $self->{value}->error;
        if ( $error != Business::ISBN::GOOD_ISBN && 
             $error != Business::ISBN::INVALID_GROUP_CODE &&
             $error != Business::ISBN::INVALID_PUBLISHER_CODE ) {
            undef $self->{value};
            return;
        }

        $self->{value} = $self->{value}->as_isbn13
            unless ref($self->{value}) eq "Business::ISBN13";
    }

    return $self->{value}->as_string if $self->valid;
}

=head2 normalized ( )

Returns a Uniform Resource Identifier (URI) for this ISBN if the ISBN is valid.

This is an URI according to RFC 3187 ("urn:isbn:..."). Unfortunately RFC 3187
is broken, because it does not oblige normalization - this method does: first 
only valid ISBN (with valid checkdigit) are allowed, second all ISBN are 
converted to ISBN-13 notation without hyphens (URIs without defined 
normalization and valitidy check are pointless).

Instead of RFC 3187 you could also use "http://purl.org/isbn/".

=cut

sub normalized {
    my $self = shift;
    return "urn:isbn:" . $self->{value}->isbn if $self->valid;
}

=head2 indexed ( )

Return the valid ISBN-13 without hyphens or undef. This variant is
usual because it is always 13 characters. An even more performant
format of the ISBN is a long integer value as returned by C<int32>.

=cut

sub indexed {
    my $self = shift;
    return $self->{value}->isbn if $self->valid; 
}

=head2 int32 ( [ $value ] )

Returns or sets a space-efficient representation of the ISBN as integer.
An ISBN-13 always starts with '978' or '979' and ends with a check digit.
This makes 2,000,000,000 which fits in a 32 bit (signed or unsigned) 
integer value. The integer value is calculated from an ISBN-13 by removing
the check digit and subtracting 978,000,000,000.

Please note that '0' is a valid value representing ISBN-13 978-0-00-000000-2 
and ISBN-10 0-00-000000-0, but in practise it is only used erroneously. This
methods uses '0' as equal to undefined, so int32() for an invalid ISBN returns
'0' and int32(0) sets the ISBN to undefined.

=cut

sub int32 {
    my $self = shift;
    my $value = shift;
    my $int = 0;

    if (defined $value) {
        $int = int($value);
        if (!$int || $int < 0 || $int >= 2000000000) {
            $self->value("");
            return 0;
        } else {
            my $isbn = Business::ISBN->new( ($int+978000000000) . "X" );
            $isbn->fix_checksum;
            $self->value( $isbn->isbn );
            return $int;
        }
    } else {
        my $int = $self->indexed || return 0;
        return substr($int, 2, 10 ) - 8000000000;
    }
}

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2007-2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
