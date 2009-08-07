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

=head2 new ( [ $query_callback ] [, %description ] ] )

Create a new source. You can provide a query method (query_callback). The query
callback gets a L<SeeAlso::Identifier> object and must return a L<SeeAlso::Response>.
The optional %description parameter is passed to the description method. Instead
of providing a query method by parameter you can also derive a subclass and define
the 'query_callback' method. Caching can be enabled by caching => $cache.

=cut

sub new {
    my $class = shift;
    my ($query_callback, %description);

    if (@_ % 2) {
        ($query_callback, %description) = @_;
    } else {
        %description = @_;
    }

    croak('parameter to SeeAlso::Source->new must be a method')
        if defined $query_callback and ref($query_callback) ne "CODE";

    my $self = bless {
        query_callback => $query_callback
    }, $class;

    if ( $description{cache} ) {
        $self->cache( $description{cache} );
        delete $description{cache};
    }

    $self->description( %description ) if %description;

    return $self;
}

=head2 cache ( [ $cache ] )

Get or set a cache for this source. The parameter must be a L<Cache> object
or undef - the latter disables caching and is the default. Returns the cache 
object or undef.

=cut

sub cache {
    my $self = shift;
    return $self->{cache} unless @_;
    my $cache = shift;

    croak 'Cache must be a Cache object' 
        unless (UNIVERSAL::isa( $cache, 'Cache' ) or not defined $cache);

    return $self->{cache} = $cache;
}

=head2 query ( $identifier [, force => 1 ] )

Given an identifier (either a L<SeeAlso::Identifier> object or just
a plain string) returns a L<SeeAlso::Response> object by calling the
query callback method or fetching the response from the cache unless
the $force parameter is specified.

=cut

sub query {
    my ($self, $identifier, %params) = @_;

    $identifier = SeeAlso::Identifier->new( $identifier )
        unless UNIVERSAL::isa( $identifier, 'SeeAlso::Identifier' );

    my $key = $identifier->hash;
  
    if ( $self->{cache} and not $params{force} ) {
        my $response = $self->{cache}->thaw( $key );
        return $response if defined $response;
    }

    my $response = $self->query_callback( $identifier );

    $response = SeeAlso::Response->new( $identifier )
        unless UNIVERSAL::isa( $response, 'SeeAlso::Response' );
        
    $self->{cache}->freeze( $key, $response )
        if $self->{cache};

    return $response;
}

=head2 query_callback ( $identifier )

Internal core method that maps a L<SeeAlso::Identifier> to a
L<SeeAlso::Response>. Clients should not call this metod but the
'query' method that includes type-checking and caching. Subclasses
should overwrite this method instead of the 'query' method. 

=cut

sub query_callback {
    my ($self, $identifier) = @_;
    return $self->{query_callback} ?
           $self->{query_callback}->( $identifier ) :
           SeeAlso::Response->new( $identifier );
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

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2007-2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
