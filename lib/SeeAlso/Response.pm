package SeeAlso::Response;

use JSON;
my $json = JSON->new(autoconv=>0);

=head1 NAME SeeAlso::Response - Open Search Suggestion Response

=head1 DESCRIPTION

...

=head1 METHODS

=head2 new ( [ $query ] )

Creates a new L<SeeAlso::Response> object. You may
provide a query string as parameter.

=cut

sub new {
    my ($class, $query) = @_;

    my $self = bless {
        'query' => defined $query ? "$query" : "",
        'completions' => [],
        'descriptions' => [],
        'urls' => []
    }, $class;

    return $self;
}


=head2 add ( $completion [, $description [, $url ] ] )

...

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

    my $jsonstring = $json->objToJson( $response );
    return $callback ? "$callback($jsonstring);" : $jsonstring;
}

1;
