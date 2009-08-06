package SeeAlso::Identifier;

use strict;
use warnings;

=head1 NAME

SeeAlso::Identifier - An identifier passed to a SeeAlso-Server

=cut

use Carp;
our $VERSION = '0.46';

=head1 DESCRIPTION

The query to a SeeAlso (and other unAPI) server is just an identifier.
By default an identifier is just a string but identifiers may also have
special properties like checksums and canonical forms.

B<SeeAlso::Identifier> models identifiers that are passed to and
processed by a L<SeeAlso::Server> and a L<SeeAlso::Source>. To
model more complex identifiers you can either derive a subclass of
SeeAlso::Identifier or create a new identifier class with
L<SeeAlso::Identifier::Factory>.

=cut

use overload (
    '""'   => sub { $_[0]->as_string },
    'bool' => sub { $_[0]->valid },
    '<=>' => sub { $_[0]->cmp( $_[1] ) },
    'cmp' => sub { $_[0]->cmp( $_[1] ) },
    fallback => 1
);

=head1 METHODS

=head2 new ( [ $value ] )

Creates a new identifier. A value will be used to set the identifier value
with the 'value' method with C<undef> as default value. This implies that
the 'parse' method is called for every new identifier.

=cut

sub new {
    my $class = shift;

    my $value = '';
    my $self = bless \$value, $class;
    $self->value( $_[0] );

    return $self;
}

=head2 value ( [ $value ] )

Get (and optionally set) the value of this identifier. If you provide a value
(including undef), it will be passed to the 'parse' function and stringified 
afterwards to be used as the new identifier value.

=cut

sub value {
    my $self = shift;
    if ( scalar @_ ) {
        my $value = $self->parse( $_[0] );
        $$self = defined $value ? "$value" : "";
    }
    return $$self;
}

=head2 canonical

Returns a normalized version of the identifier. For most identifiers the
normalized version should be an absolute URI. The default implementation
of this method just returns the full value, so if the 'value' method already
does normalization, you do not have to implement 'canonical'.

=cut

sub canonical {
    return ${$_[0]};
}

=head2 normalized

Alias for the 'canonical' method. Do not override this method but 'canonical'!

=cut

sub normalized { 
    return $_[0]->canonical;
}

=head2 as_string

Returns an identifier object as plain string which is the canonical form.
Identifiers are also converted to plain strings automatically by overloading.
This means you can use identifiers as plain strings in most Perl constructs.

=cut

sub as_string {
    return $_[0]->canonical;
}

=head2 hash

Return a compact form of this identifier that can be used for indexing. 
A usual compact form is the local part without namespace prefix or a 
hash value. The default implementation of this method returns the canonical form
of the identifier.

=cut

sub hash {
    return $_[0]->canonical;
}

=head2 indexed

Alias for the 'hash' method. Do not override this method but 'hash'!

=cut

sub indexed { 
    return $_[0]->hash; 
}

=head2 valid

Returns whether this identifier is valid - which is the case for all non-empty
strings. This method is automatically called by overloading to derive a boolean
value from an identifier. This means you can use identifiers as boolean values
in most Perl constructs. Please note that in contrast to default scalars the
identifier value '0' is valid!

=cut

sub valid {
    return ${$_[0]} ne '';
}

=head2 parse ( $value )

Parses a value to an identifier value of this class. This method should always
return a string - but the return value is stringified anyway. In most cases 
this and/or the 'canonical' method are the only methods to override in a
subclass of SeeAlso::Identifier.

This method can also be used as function. To allow the same in you subclasses' implementation, use the template:

sub parse {
    my $value = shift;
    $value = shift if ref($value) and scalar @_;

    # ... further processing of $value (validating and cleaning) ...

    return defined $value ? "$value" : "";
}

=cut

sub parse {
    my $value = shift;
    $value = shift if ref($value) and scalar @_;
    return defined $value ? "$value" : "";
}

=head2 cmp ( $identifier )

Compare two identifiers. If the supplied value is not an identifier, it
will be converted first. By default the canonical values are compared.

=cut

sub cmp {
    my $self = shift;
    my $second = shift;
    # TODO: use the same class as the first for comparing (and test this)!
    $second = SeeAlso::Identifier->new( $second )
        unless UNIVERSAL::isa( $second, 'SeeAlso::Identifier' );
    return $self->canonical cmp $second->canonical;
}

1;

=head2 SEE ALSO

See L<URI> for the more specific Uniform Resource Identifiers.

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
