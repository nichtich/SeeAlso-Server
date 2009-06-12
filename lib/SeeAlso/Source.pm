package SeeAlso::Source;

use strict;
use Carp qw(croak);
use SeeAlso::Response;

our $VERSION = "0.56";

=head1 NAME

SeeAlso::Source - a source of OpenSearch Suggestions reponses

=head1 SYNOPSIS

  my $source = SeeAlso::Source->new();
  my $source = SeeAlso::Source->new( sub { ... } );
  ...
  $source->description( "key" => "value" ... );
 ...
  $response = $source->query( $identifier );

=head2 new ( [ $query_method ] [, %description ] ] )

Create a new source. You can provide a query method (mQuery). The query method
gets a L<SeeAlso::Identifier> object and must return a L<SeeAlso::Response>.
The optional @description parameter is passed to the description method. Instead
of providing a query method by parameter you can also derive a subclass and define
the mQuery method.

=cut

sub new {
    my $class = shift;
    my ($query_method, %description);

    if (@_ % 2) {
        ($query_method, %description) = @_;
    } else {
        %description = @_;
    }

    croak("parameter to SeeAlso::Source->new must be a method")
        if defined $query_method and ref($query_method) ne "CODE";

    my $self = bless {
        mQuery => $query_method || undef
    }, $class;

    $self->description( %description ) if %description;

    return $self;
}

=head2 description ( [ $key ] | $key => $value, $key => $value, ... )

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

=item Example[s]

An example query (a hash of 'id' and optional 'response').

=back

=cut

sub description {
    my $self = shift;
    my $key = $_[0];

    if (scalar @_ > 1) {
        my %param = @_;
        foreach my $key (keys %param) {
            my $value = $param{$key};
            if ($key =~ /^Examples?$/) {
                $value = [ $value ] unless ref($value) eq "ARRAY";
                # TODO: check examples (must be an array of a hash)
                $key = "Examples";
            } else {
                $value =~ s/\s+/ /g; # to string
            }
            if ($self->{description}) {
                $self->{description}{$key} = $value;
            } else {
                my %description = ($key => $value);
                $self->{description} = \%description;
            }
        }
    } elsif ( $self->{description} ) {
        return $self->{description}{$key} if defined $key;
        return $self->{description};
    } else { # this is needed if no description was defined
        return if defined $key;
        my %hash;
        return \%hash;
    }
}

=head2 about ( )

Return ShortName, Description, and BaseURL from the description of this
Source. Undefined fields are returned as empty string.

=cut

sub about {
    my $self = shift;

    my $name        = $self->description("ShortName");
    my $description = $self->description("Description");
    my $url         = $self->description("BaseURL");

    $name = "" unless defined $name;
    $description = "" unless defined $description;
    $url = "" unless defined $url;

    return ($name, $description, $url); 
}

=head2 query ( $identifier )

Given an identifier (either a L<SeeAlso::Identifier> object or just a
plain string) returns a L<SeeAlso::Response> object by calling the
query method.

=cut

sub query {
    my $self = shift;
    my $identifier = shift;
    my $response;

    $identifier = SeeAlso::Identifier->new($identifier)
        unless UNIVERSAL::isa($identifier,"SeeAlso::Identifier");

    if ( $self->{mQuery} ) {
        $response = &{$self->{mQuery}}($identifier);
    } else {
        $response = $self->mQuery($identifier);
    }

    return $response;
}

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2007-2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
