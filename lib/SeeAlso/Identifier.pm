package SeeAlso::Identifier;

use Carp;

=head1 NAME

SeeAlso::Identifier - an identifier passed to a SeeAlso-Server

=cut

use vars qw($VERSION);
$VERSION = "0.40";

=head1 DESCRIPTION

The query to a SeeAlso (and other unAPI) server is just an identifier.
By default an identifier is just a string but identifiers may also have
special properties like checksums and normalized forms.

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

=item indexed 

The form that is used for indexing. This could be '0002936X'
or '0002936' because hyphen and check digit do not contain
information. You could also store the ISSN in the 32 bit
integer number '2996' instead of a string.

=item valid

The ISSN is checked by testing for invalid or missing
characters and the check digit is computed.

=back

The constructor C<new> contains an example.

If you provide a normalizing method C<n> then this method
should behave like a normalizing is expected. That is for
every possible input C<s> the condition C<n(s) == n(n(s))>
must be true.

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
    my $indexed = $params{indexed};
    my $valid = $params{valid};

    croak("normalized must be a method")
        if defined $normalized and ref($normalized) ne "CODE";
    croak("indexed must be a method")
        if defined $indexed and ref($indexed) ne "CODE";
    croak("valid must be a method")
        if defined $valid and ref($valid) ne "CODE";

    my $self = bless {
        value => "",
        mValid => $valid,
        mNormalized => $normalized,
        mIndexed => $indexed,
    }, $class;

    return $self;
}

=head2 value ( [ $value ] )

Get and/or set the value of this identifier.

=cut

sub value {
    my $self = shift;
    my $value = shift;

    if (defined $value) {
        $self->{value} = $value;
    }

    return $self->{value};
}

=head2 normalized

Return a normalized representation of this identifier.
By default this is what the value method returns.

=cut

sub normalized {
    my $self = shift;
    if (defined $self->{mNormalized}) {
        return &{$self->{mNormalized}}($self->{value});
    } else {
        return $self->value();
    }
}

=head2 indexed

Return the index value of this identifier.
By default this is the normalized form but you may
extend the identifier to use some kind of hash value.

=cut

sub indexed {
    my $self = shift;
    if (defined $self->{mIndexed}) {
        return &{$self->{mIndexed}}($self->{value});
    } else {
        return $self->normalized;
    }
}

=head2 valid

Returns whether this identifier is valid. By default
all non empty identifiers (everything but '' and undef)
are valid.

=cut

sub valid {
    my $self = shift;
    if (defined $self->{mValid}) {
        return &{$self->{mValid}}($self->{value});
    } else {
        return defined $self->{value} && $self->{value} ne "";
    }
}

1;