package SeeAlso::Identifier::ISBN;

use strict;
use warnings;

=head1 NAME

SeeAlso::Identifier::ISBN - international standard book number identifier

=cut

use Business::ISBN;
use SeeAlso::Identifier;
use Carp;

use vars qw( $VERSION @ISA );
@ISA = qw( SeeAlso::Identifier );
$VERSION = "0.5";

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

Get and/or set the value of this identifier.
Returns undef or the valid value ISBN-13 with hyphens.

=cut

sub value {
    my $self = shift;
    my $value = shift;

    if (defined $value) {
        $value =~ s/^[uU][rR][nN]:[iI][sS][Bb][Nn]//;
        $self->{value} = Business::ISBN->new( $value );
        return unless defined $self->{value};

        $self->{value} = $self->{value}->as_isbn13
            unless ref($self->{value}) eq "Business::ISBN13";
    }

    return $self->{value}->as_string if $self->valid();
}

=head2 indexed

Return undef or the valid ISBN-13 without hyphens.

=cut

sub indexed {
    my $self = shift;
    return $self->{value}->isbn if $self->valid(); 
}

=head2 uri

Returns a Uniform Resource Identifier (URI) for this ISBN if possible.

Unfortunately RFC 3187 broken, because it does not oblige normalization.
But this method does: first only valid ISBN (with valid checkdigit)
are allowed, second all ISBN are converted to ISBN-13 notation without
hyphens. URIs without defined normalization and valitidy check are pointless.

Up to now the "urn:isbn"-flavor of URI for ISBN is used but you could
also use "http://purl.org/isbn/" instead.

=cut

sub uri {
    my $self = shift;
    return unless $self->valid();
    return "urn:isbn:" . $self->{value}->isbn;
}

=head2 normalized

Normalize to the URI.

=cut

sub normalized {
    my $self = shift;
    return $self->uri;
}

=head2 valid

Returns whether the ISBN is valid.

=cut

sub valid {
    my $self = shift;
    return defined $self->{value} && $self->{value}->is_valid;
}

1;