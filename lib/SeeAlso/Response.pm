package SeeAlso::Response;

use strict;
use warnings;

=head1 NAME

SeeAlso::Response - SeeAlso Simple Response

=cut

use JSON::XS qw(encode_json);
use Text::CSV;
use Data::Validate::URI qw(is_uri);
use Carp;

our $VERSION = "0.57";

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
            $query = $query->canonical; 
        }
        $self->{query} = defined $query ? "$query" : "";
    }
    return $self->{query};
}

=head2 toJSON ( [ $callback [, $json ] ] )

Return the response in JSON format and a non-mandatory callback wrapped
around. The method will croak if you supply a callback name that does
not match C<^[a-z][a-z0-9._\[\]]*$>.

The encoding is not changed, so please only feed response objects with
UTF-8 strings to get JSON in UTF-8. Optionally you can pass a L<JSON>
object to do JSON encoding of your choice.

=cut

sub toJSON {
    my ($self, $callback, $json) = @_;

    my $response = [
        $self->{query},
        $self->{labels},
        $self->{descriptions},
        $self->{urls}
    ];

    return _JSON( $response, $callback, $json );
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

=head2 toCSV ( )

Returns the response in CSV format with one label, description, uri triple
per line. The response query is omitted. Please note that newlines in values
are allowed so better use a clever CSV parser!

=cut

sub toCSV {
    my ($self, $headers) = @_;
    my $csv = Text::CSV->new( { binary => 1, always_quote => 1 } );
    my @lines;
    for(my $i=0; $i<$self->size(); $i++) {
        my $status = $csv->combine ( $self->get($i) ); # TODO: handle error status
        push @lines, $csv->string();
    }    
    return join ("\n", @lines);
}

=head2 toRDF ( )

Returns the response as RDF triples in JSON/RDF structure.
Parts of the result that cannot be interpreted as valid RDF are omitted.

=cut

sub toRDF ( ) {
    my ($self) = @_;
    my $subject = $self->query();
    return { } unless is_uri($subject);
    my $values = { };

    for(my $i=0; $i<$self->size(); $i++) {
        my ($label, $predicate, $object) = $self->get($i);
        next unless is_uri($predicate); # TODO: use rdfs:label as default?

        if ($object) {
            next unless is_uri($object);
            $object = { "value" => $object, 'type' => 'uri' };
        } else {
            $object = { "value" => $label, 'type' => 'literal' };
        }

        if ($values->{$predicate}) {
            push @{ $values->{$predicate} }, $object;
        } else {
            $values->{$predicate} = [ $object ];
        }
    }

    return {
        $subject => $values
    };
}

=head2 toRDFJSON ( )

Returns the response as RDF triples in JSON/RDF format.

=cut

sub toRDFJSON {
    my ($self, $callback, $json) = @_;
    return _JSON( $self->toRDF(), $callback, $json );
}


=head2 toN3 ( )

Return the repsonse in RDF/N3 (including pretty print).

=cut

sub toN3 {
    my ($self) = @_;
    return "" unless $self->size();
    my $rdf = $self->toRDF();
    my ($subject, $values) = %$rdf;
    return "" unless $subject && %$values;
    my @lines;

    foreach my $predicate (keys %$values) {
        my @objects = @{$values->{$predicate}};
        if ($predicate eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type') {
            $predicate = 'a';
        } elsif ($predicate eq 'http://www.w3.org/2002/07/owl#sameAs') {
            $predicate = '=';
        } else {
            $predicate =  "<$predicate>";
        }
        @objects = map {
            my $object = $_;
            if ($object->{type} eq 'uri') {
                '<' . $object->{value} . '>';
            } else {
                _escape( $object->{value} );
            }
        } @objects;
        if (@objects > 1) {  
            push @lines, (" $predicate\n    " . join(" ,\n    ", @objects) );
        } else {
            push @lines, " $predicate " . $objects[0];
        }
    }

    my $n3 = "<$subject>";
    if (@lines > 1) {
        return "$n3\n " . join(" ;\n ",@lines) . " .";
    } else {
        return $n3 . $lines[0] . " .";
    }
}

=head1 INTERNAL FUNCTIONS

=cut

my %ESCAPED = ( 
    "\t" => 't', 
    "\n" => 'n', 
    "\r" => 'r', 
    "\"" => '"',
    "\\" => '\\', 
);
 
=head2 _escape ( $string )

Escape a specific characters in a UTF-8 string for Turtle syntax / Notation 3

=cut

sub _escape {
    local $_ = $_[0];
    s/([\t\n\r\"\\])/\\$ESCAPED{$1}/sg;
    return '"' . $_  . '"';
}

=head2 _JSON ( $object [, $callback [, $JSON ] ] )

Encode an object as JSON string, possibly wrapped by callback method.

=cut

sub _JSON {
    my ($object, $callback, $JSON) = @_;

    croak ("Invalid callback name")
        if ( $callback and !($callback =~ /^[a-z][a-z0-9._\[\]]*$/i));

    # TODO: change this behaviour (no UTF-8) ?
    $JSON = JSON::XS->new->utf8(0) unless $JSON;

    my $jsonstring = $JSON->encode($object); 

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
