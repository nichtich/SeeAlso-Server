package SeeAlso::Response;

use strict;
use warnings;

=head1 NAME

SeeAlso::Response - SeeAlso Simple Response

=cut

use JSON::XS qw(encode_json);

our $VERSION = "0.53";

=head1 DESCRIPTION

This class models a SeeAlso Simple Response which is practically the
same as am OpenSearch Suggestions Response.

=head1 METHODS

=head2 new ( [ $query [, $completions, $descriptions, $urls ] )

Creates a new L<SeeAlso::Response> object (this is the same as an 
OpenSearch Suggestions Response object). If the passed query parameter
is an instance of L<SeeAlso::Identifier>, the return of its C<normalized> 
method is used.

=cut

sub new {
    my ($class, $query, $completions, $descriptions, $urls) = @_;

    if (UNIVERSAL::isa( $query, 'SeeAlso::Identifier' )) {
        $query = $query->normalized();
    } else {
        $query = defined $query ? "$query" : ""; # convert to string
    }

    my $self = bless {
        'query' => $query,
        'completions' => [],
        'descriptions' => [],
        'urls' => []
    }, $class;

    if (defined $completions) {
        croak ("bad arguments to SeeAlso::Response->new")
            unless ref($completions) eq "ARRAY"
                and defined $descriptions and ref($descriptions) eq "ARRAY"
                and defined $urls and ref($urls) eq "ARRAY";
        # TODO: check length and content of $completions, $descriptions, $urls
        for (my $i=0; $i < @{$completions}; $i++) {
            $self->add($$completions[$i], $$descriptions[$i], $$urls[$i]);
        }
    }

    return $self;
}


=head2 add ( $label [, $description [, $uri ] ] )

Add an item to the result set. All parameters must be strings.
The URI is not checked for well-formedness, so it is recommended
to use a specific URI class like C<URI> and pass a normalized
version of the URI:

  $uri = URI->new( $uri_str )->canonical

=cut

sub add {
    my ($self, $label, $description, $uri) = @_;

    $label = "" unless defined $label;
    $description = "" unless defined $description;
    $uri = "" unless defined $uri;

    # TODO: check URI

    push @{ $self->{completions} }, $label;
    push @{ $self->{descriptions} }, $description;
    push @{ $self->{urls} }, $uri;
}

=head2 size

Get the number of entries in this response.

=cut

sub size {
    my $self = shift;
    return scalar @{$self->{completions}};
}

=head2 hasQuery

Returns whether a non-empty query has been provided.

=cut

sub hasQuery {
    my $self = shift;
    return $self->{query} ne "";
}

=head2 toJSON ( [ $callback ] )

Return the response in JSON format and a non-mandatory 
callback wrapped around. There is no test whether the 
callback name is valid so far. The encoding will not
be changed, please only feed response objects with
UTF-8 strings to get UTF-8 JSON with this method!

=cut

sub toJSON {
    my ($self, $callback) = @_;

    # TODO: check callback name

    my $response = [
        $self->{query},
        $self->{completions},
        $self->{descriptions},
        $self->{urls}
    ];

    my $jsonstring = encode_json($response);
    return $callback ? "$callback($jsonstring);" : $jsonstring;
}

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2007-2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
