package SeeAlso::Response;

use JSON;
my $json = JSON->new(autoconv=>0);

=head1 NAME SeeAlso::Response - Open Search Suggestion Response

=head1 DESCRIPTION

This class models an OpenSearch Suggestions Response.

=head1 METHODS

=head2 new ( [ $query [, $completions, $descriptions, $urls ] )

Creates a new L<SeeAlso::Response> object (this is the same as an 
OpenSearch Suggestions Response object). If the passed query parameter
is an instance of L<SeeAlso::Identifier>, the return of its C<normalized> 
method is used.

=cut

sub new {
    my ($class, $query, $completions, $descriptions, $urls) = @_;

    $query = "" unless defined $query;
    if (UNIVERSAL::isa( $query, 'SeeAlso::Identifier' )) {
        $query = $query->normalized();
    } else {
        $query = "$query"; # convert to string
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


=head2 add ( $completion [, $description [, $url ] ] )

Add an item to the result set. All parameters must be strings.

=cut

sub add {
    my ($self, $completion, $description, $url) = @_;

    $completion = "" unless defined $completion;
    $description = "" unless defined $description;
    $url = "" unless defined $url;

    push @{ $self->{completions} }, $completion;
    push @{ $self->{descriptions} }, $description;
    push @{ $self->{urls} }, $url;
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

Return the response in JSON format and a non-mandatory callback
wrapped around.

=cut

sub toJSON {
    my ($self, $callback) = @_;

    my $response = [
        $self->{query},
        $self->{completions},
        $self->{descriptions},
        $self->{urls}
    ];

    my $jsonstring = $json->encode( $response );
    return $callback ? "$callback($jsonstring);" : $jsonstring;
}

1;
