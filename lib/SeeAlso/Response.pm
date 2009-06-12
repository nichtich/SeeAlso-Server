package SeeAlso::Response;

use strict;
use warnings;

=head1 NAME

SeeAlso::Response - SeeAlso Simple Response

=cut

use JSON::XS qw(encode_json);
use Carp;

our $VERSION = "0.56";

=head1 DESCRIPTION

This class models a SeeAlso Simple Response which is practically the
same as am OpenSearch Suggestions Response.

=head1 METHODS

=head2 new ( [ $query [, $labels, $descriptions, $urls ] )

Creates a new L<SeeAlso::Response> object (this is the same as an
OpenSearch Suggestions Response object). The optional parameters
are passed to the set method, so this is equivalent:

  $r = SeeAlso::Response->new($query, $labels, $descriptions, $urls);
  $r = SeeAlso::Response->new->set($query, $labels, $descriptions, $urls);

To create a SeeAlso::Response from JSON use the fromJSON method.

=cut

sub new {
    my $this = shift;

    my $class = ref($this) || $this;
    my $self = bless {
        'query' => "",
        'labels' => [],
        'descriptions' => [],
        'urls' => []
    }, $class;

    $self->set(@_);

    return $self;
}

=head2 set ( [ $query [, $labels, $descriptions, $urls ] )

Set the query parameter or the full content of this response. If the
query parameter is an instance of L<SeeAlso::Identifier>, the return
of its C<normalized> method is used. This methods croaks if the passed
parameters do not fit to a SeeAlso response.

=cut

sub set {
    my ($self, $query, $labels, $descriptions, $urls) = @_;

    $self->query( $query );

    if (defined $labels) {
        croak ("bad arguments to SeeAlso::Response->new")
            unless ref($labels) eq "ARRAY"
                and defined $descriptions and ref($descriptions) eq "ARRAY"
                and defined $urls and ref($urls) eq "ARRAY";
        my $l = @{$labels};
        croak ("length of arguments to SeeAlso::Response->new differ")
            unless @{$descriptions} == $l and @{$urls} == $l;

        $self->{labels} = [];
        $self->{descriptions} = [];
        $self->{urls} = [];

        for (my $i=0; $i < @{$labels}; $i++) {
            $self->add($$labels[$i], $$descriptions[$i], $$urls[$i]);
        }
    }

    return $self;
}

=head2 add ( $label [, $description [, $uri ] ] )

Add an item to the result set. All parameters must be strings.
The URI is only partly checked for well-formedness, so it is 
recommended to use a specific URI class like C<URI> and pass 
a normalized version of the URI:

  $uri = URI->new( $uri_str )->canonical

Otherwise your SeeAlso response may be invalid. If you pass a 
non-empty URI without schema, this method will croak. If label,
description, and uri are all empty, nothing is added.

Returns the SeeAlso::Response object so you can chain method calls.

=cut

sub add {
    my ($self, $label, $description, $uri) = @_;

    if (defined $label) {
        croak("response label must be a string") if ref($label);
    } else {
        $label = "";
    }
    if (defined $description) {
        croak("response description must be a string") if ref($description);
    } else {
        $description = "";
    }
    if ( defined $uri && $uri ne "" ) {
        croak("irregular response URI") 
            unless $uri =~ /^[a-z][a-z0-9.+\-]*:/i;
    } else {
        $uri = "";
    }

    return $self unless $label ne "" or $description ne "" or $uri ne "";

    push @{ $self->{labels} }, $label;
    push @{ $self->{descriptions} }, $description;
    push @{ $self->{urls} }, $uri;

    return $self;
}

=head2 size ( )

Get the number of entries in this response.

=cut

sub size {
    my $self = shift;
    return scalar @{$self->{labels}};
}

=head2 get ( $index )

Get a specific triple of label, description, and url
(starting with index 0):

  ($label, $description, $url) = $response->get( $index )

=cut

sub get {
    my ($self, $index) = @_;
    return unless defined $index and $index >= 0 and $index < $self->size();
    
    my $label =  $self->{labels}->[$index];
    my $description = $self->{descriptions}->[$index];
    my $url =         $self->{urls}->[$index];

    return ($label, $description, $url);
}

=head2 query ( [ $query ] )

Get and/or set query parameter. If the query is a L<SeeAlso::Identifier>
it will be normalized, otherwise it will be converted to a string.

=cut

sub query {
    my $self = shift;
    if (@_) {
        my $query = shift;
        if (UNIVERSAL::isa( $query, 'SeeAlso::Identifier' )) {
            $query = $query->normalized() 
        }
        $self->{query} = defined $query ? "$query" : "";
    }
    return $self->{query};
}

=head2 toJSON ( [ $callback ] )

Return the response in JSON format and a non-mandatory callback wrapped
around. The method will croak if you supply a callback name that does
not match C<^[a-z][a-z0-9._\[\]]*$>.

The encoding is not changed, so please only feed response objects with
UTF-8 strings to get JSON in UTF-8.

=cut

sub toJSON {
    my ($self, $callback) = @_;

    croak ("Invalid callback name")
        if ( $callback and !($callback =~ /^[a-z][a-z0-9._\[\]]*$/i));

    my $response = [
        $self->{query},
        $self->{labels},
        $self->{descriptions},
        $self->{urls}
    ];

    # TODO: change this behaviour (no UTF-8)
    my $jsonstring = JSON::XS->new->utf8(0)->encode($response); 

    return $callback ? "$callback($jsonstring);" : $jsonstring;
}

=head2 toRDF ( )

Returns the response as RDF triples. This only works if the response query is
an URI (the triple subject) and all description elements are URIs (the triple 
subject). If for an entry both label and uri are specified, the label is ignored.

This method is not implemented yet and a fromRDF is also missing.

=cut

#sub toRDF ( ) {
#    my ($self) = @_;
#    # return [] unless $self->size();
#    return []
#}

=head2 toN3 ( )

Return the repsonse in RDF/N3. This method is experimental and 
only supports specific response types.

=cut

sub toN3 {
    my ($self) = @_;
    return "" unless $self->size();
    # TODO: rewrite using toRDF

    my @triples;
    for(my $i=0; $i<$self->size(); $i++) {
        my ($literal, $predicate, $object) = $self->get($i);
        # TODO: check whether URI, replace namespace prefixes etc.
        if ($object) {
            push @triples, "  <$predicate> <$object> ";
            # TODO: add <$object> rdfs:label '$literal'
        } else {
            # TODO: escape literal
            # push @triples, "  <$predicate> "$literal" ";
            # TODO: if no predicate is given, use rdfs:label
        }
    }
    my $n3 = "<" . $self->query() . ">";
    $n3 .= "\n" if (@triples > 1); 
    $n3 .= join(";\n",@triples) . ".\n";
    return $n3;
}

=head2 fromJSON ( $jsonstring )

Set this response by parsing JSON format. Croaks if the JSON string 
does not fit SeeAlso response format. You can use this method as
as constructor or as method;

  my $response = SeeAlso::Response->fromJSON( $jsonstring );
  $response->fromJSON( $jsonstring )

=cut

sub fromJSON {
    my ($self, $jsonstring) = @_;
    my $json = JSON::XS->new->decode($jsonstring);

    croak("SeeAlso response format must be array of size 4")
        unless ref($json) eq "ARRAY" and @{$json} == 4;

    if (ref($self)) { # call as method
        $self->set(@{$json});
        return $self;
    } else { # call as constructor
        return SeeAlso::Response->new(@{$json});
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
