package SeeAlso::Identifier;

use strict;
use warnings;

=head1 NAME

SeeAlso::Identifier - An identifier passed to a SeeAlso-Server

=cut

use Carp;
our $VERSION = "0.45";

=head1 DESCRIPTION

The query to a SeeAlso (and other unAPI) server is just an identifier.
By default an identifier is just a string but identifiers may also have
special properties like checksums and canonical forms.

L<SeeAlso::Identifier> models identifiers that are passed to and
processed by a L<SeeAlso::Server> and a L<SeeAlso::Source>. To
model more complex identifiers you can either derive a subclass or
provide additional methods to the constructor. These are a
method to check whether the identifier is valid or not, a method
to create a normalized form of an identifier, and a method to
create an index entry of an identifier.

The concept is best explained with an example: The International
Standard Serial Number (ISSN) is used to identify periodical
publications. The format of the ISSN is an eight digit number,
divided by a hyphen into two four-digit numbers. The last digit
is a check digit which may be 0-9 or an X. In practise the hyphen
may be missing and the check digit may also be provided lowercase.

When used as an identifier, the different forms of an ISSN as
used in the model of L<SeeAlso::Identifier> are:

=over

=item value

The string value as provided, for instance 'ISSN 0002-936X',
'0002-936x', '0002936x' (which all refer to the same ISSN in
this example)

=item normalized

The canonical form whith hyphem and uppercase X: '0002-936X'

=item valid

The ISSN is checked by testing for invalid or missing
characters and the check digit is computed.

=back

The constructor C<new> contains an example.

If you provide a normalizing method C<n> then this method
should behave like a normalizing is expected. That is for
every possible input C<s> the condition C<n(s) == n(n(s))>
must be true.

=cut

use overload (
    '""' => sub { $_[0]->canonical },
    '==' => sub { $_[0]->hash eq $_[1]->hash },
    '!=' => sub { $_[0]->hash ne $_[1]->hash },
    'eq' => sub { $_[0]->hash eq $_[1]->hash },
    'ne' => sub { $_[0]->hash ne $_[1]->hash }
);

=head1 METHODS

=head2 new ( [ $value | %params ] )

Creates a new identifier. You can either pass either identifier's 
value or a hash of methods with the following parameter names:

=over

=item valid

A method to check whether the identifier is valid.

=item normalized

A method that returns a normalized representation of the identifier.

=item indexed

A method that returns an indexed representation of the identifier.

=back

The methods C<valid>, C<normalized>, and C<indexed> get the
identifier's value as parameter when called.

For instance the following code fragment creates an identifier
that contains of letters only and is normalized to lowercase:

  sub lcalpha {
    my $v = shift;
    $v =~ s/[^a-zA-Z]//g;
    return lc($v);
  }
  $id = SeeAlso::Identifier->new(
    'valid' => sub {
      my $v = shift;
      return $v =~ /^[a-zA-Z]+$/;
    },
    'normalized' => \&lcalpha
  );
  $id->value("AbC");

=cut

sub new {
    my ($class) = shift;

    if ($#_ <= 0) {
        my $self = bless {
            value => ""
        }, $class;
        $self->value( shift );
        return $self;
    }

    my %params = @_;
    my $normalized = $params{normalized};
    my $valid = $params{valid} || $params{parse};

    # TODO: we don't need this:

    croak("normalized must be a method")
        if defined $normalized and ref($normalized) ne "CODE";
    croak("valid must be a method")
        if defined $valid and ref($valid) ne "CODE";

    my $self = bless {
        value => '',
        mValid => $valid,
        mNormalized => $normalized,
    }, $class;

    return $self;
}

=head2 value ( [ $value ] )

Get and/or set the value of this identifier. If you specify a defined 
value, it will be passed to the 'parse' function and used as new value.

=cut

sub value {
    my ($self, $value) = @_;

    if (defined $value) {
        my $v = $self->parse( $value );
        $self->{value} = defined $v ? "$v" : "";
    }

    return $self->{value};
}

=head2 canonical ()

Returns a normalized version of the identifier. For most identifiers the
normalized version should be an absolute URI. The default implementation
of this method just returns the full value, so if the 'value' method already
does normalization, you do not have to implement 'canonical'.

=cut

sub canonical {
    my $self = shift;
    if (defined $self->{mNormalized}) {
        return &{$self->{mNormalized}}($self->{value});
    } else {
        return $self->value();
    }
}

=head2 normalized () 

Alias for canonical. Do not override this method but 'canonical' if needed.

=cut

sub normalized { return $_[0]->canonical; }

=head2 hash ()

Return a compact form of this identifier that can be used for indexing. 
A usual compact form is the local part without namespace prefix or a 
hash value. The default implementation of this method just returns the 
full value of the identifier.

=cut

sub hash {
    my $self = shift;
    return $self->canonical;
}

=head2 indexed ()

Alias for hash. Do not override this method but 'hash' if needed.

=cut

sub indexed { return $_[0]->hash; }

=head2 valid ()

Returns whether this identifier is valid. By default all non-empty
identifiers (everything but '' and undef) are valid but you can add 
additional checks. For most applications is is recommended to implement
validation in the parse method instead, so invalid identifiers cannot be
created.

=cut

sub valid {
    my $self = shift;
    return (defined $self->{value} and $self->{value} ne '');
}

=head2 parse ( $string )

Parses a string to an identifier value of this class. This function
should always return a string. Override this method in derived classes.

=cut

sub parse {
    my $s = shift;
    $s = shift if ref($s) and defined $_[0];
    $s = defined $s ? "$s" : '';
    return $s;
}

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2007-2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
