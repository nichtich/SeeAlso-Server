package SeeAlso::Source;

use strict;
use Carp qw(croak);
use SeeAlso::Response;

=head1 NAME

SeeAlso::Source - An source of OpenSearch Suggestions reponses

=head1 SYNOPSIS

  my $source = SeeAlso::Source->new();
  my $source = SeeAlso::Source->new( sub { ... } );

=cut


=head2 new ( $query_method [, %description ] )

Create a new source. You can provide a query method (mQuery). The query method gets a
L<SeeAlso::Identifier> object and must return a L<SeeAlso::Response>.

=cut

sub new {
    my ($class, $query, %description) = @_; #shift;

    croak("parameter to SeeAlso::Source->new must be a method")
        if defined $query and ref($query) ne "CODE";

    my $self = bless {
        mQuery => $query,
        description => \%description,
        errors => undef
    }, $class;

    return $self;
}

=head2 query ( $identifier )

Gets a L<SeeAlso::Identifier> object and
returns a L<SeeAlso::Response> object or
undef.

TODO: what about failing query functions?
what if the result is not SeeAlso::Response?
Where to catch errors?

=cut

sub query {
    my $self = shift;
     if (defined $self->{mQuery}) {
        return &{$self->{mQuery}}(@_);
    } else {
        return SeeAlso::Response->new();
    }
}

=head2 description ( [ $key ] )

Returns additional description about this source in a hash (no key provided)
or a specific element of the description. The elements are defined according
to elements in an OpenSearch description document. Up to now they are:

=over

=item ShortName

A short name with up to 16 characters.

=item LongName

A long name with up to 48 characters.

=item Description

A description with up to 1024 characters.

=item BaseURL

URL of the script. Will be set automatically via L<CGI> if not defined.

=item DateModified

Qualified Dublin Core element Date.Modified.

=item Source

Source of the data (dc:source)

=back

=cut

sub description {
    my $self = shift;
    my $key = shift;

    if ( $self->{description} ) {
        return $self->{description}{$key} if defined $key;
        return $self->{description};
    } else { # this is needed if no description was defined
        my %hash;
        return \%hash;
    }


}

=head2 errors

get/add error messages

=cut

sub errors {
    my $self = shift;
    push @{ $self->{errors} }, @_ if @_;
    return $self->{errors};
}

=head2 hasErrors

Return whether errors occured

=cut

sub hasErrors {
    my $self = shift;
    return defined $self->{errors} and scalar @{ $self->{errors} };
}

1;