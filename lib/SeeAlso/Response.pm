package SeeAlso::Response;

use JSON::XS;

use vars qw( $VERSION );
$VERSION = "0.52";

=head1 NAME

SeeAlso::Response - SeeAlso Simple Response

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

    my $jsonstring = JSON::XS->new->encode($response);
    return $callback ? "$callback($jsonstring);" : $jsonstring;
}

1;
