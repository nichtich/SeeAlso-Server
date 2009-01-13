package SeeAlso::Identifier::ISBN;

use strict;
use warnings;

=head1 NAME

SeeAlso::Identifier::ISBN - international standard book number identifier

=cut

use Business::ISBN;
use SeeAlso::Identifier;
use Carp;

use base qw( SeeAlso::Identifier );
our $VERSION = "0.5";

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

Get and/or set the value of the ISBN.
Returns undef or the valid value ISBN-13 with hyphens.

- remove/add missing zeroes in ISBN?

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

=head2 indexed

Return undef or the valid ISBN-13 without hyphens.

=cut

sub indexed {
    my $self = shift;
    return $self->{value}->isbn if $self->valid; 
}

=head2 uri

Returns a Uniform Resource Identifier (URI) for this ISBN if possible.

Unfortunately RFC 3187 is broken, because it does not oblige normalization.
But this method does: first only valid ISBN (with valid checkdigit)
are allowed, second all ISBN are converted to ISBN-13 notation without
hyphens (URIs without defined normalization and valitidy check are pointless).

Up to now the "C<urn:isbn>"-flavor of URI for ISBN is used but you could
also use "http://purl.org/isbn/" instead.

=cut

sub uri {
    my $self = shift;
    return "urn:isbn:" . $self->{value}->isbn if $self->valid;
}

=head2 normalized

Normalize to the URI.

=cut

sub normalized {
    my $self = shift;
    return $self->uri;
}

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2007-2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
