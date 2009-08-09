package SeeAlso::Source;

use strict;
use Carp qw(croak);
use SeeAlso::Response;

our $VERSION = '0.562';

=head1 NAME

SeeAlso::Source - Provides OpenSearch Suggestions reponses

=head1 SYNOPSIS

  $source = SeeAlso::Source->new;
  $source = SeeAlso::Source->new( sub { ... } );
  $source = SeeAlso::Source->new( QueryMethod => sub { ... } );
  ...
  $source->description( "ShortName" => "My source" ... );
  ...
  $response = $source->query( $identifier );

=head2 new ( [ $callback ] [ $cache ] [ %parameters ] )

Create a new source. If the first parameter is a code reference or another
L<SeeAlso::Source> parameter, it is used as C<callback> parameter. If the
first or second parameter is a L<Cache> object, it is used as C<cache>
parameter. Other parameters are passed to the C<description> method.

=cut

sub new {
    my $class = shift;
    my ($callback, $cache);

    $callback = shift
        if ref($_[0]) eq 'CODE' or UNIVERSAL::isa($_[0],'SeeAlso::Source');
    $cache = shift if UNIVERSAL::isa($_[0], 'Cache');

    my (%params) = @_;
    my $self = bless { }, $class;

    $callback = $params{callback} unless defined $callback;
    $cache = $params{cache} unless defined $cache;

    $self->callback( $callback ) if $callback;
    $self->cache( $cache ) if $cache;
    $self->description( %params ) if %params;

    return $self;
}

=head2 callback ( [ $code | $source | undef ] )

Get or set a callback method or callback source.

=cut

sub callback {
    my $self = shift;

    if ( scalar @_ ) {
        my $callback = $_[0];

        croak('callback parameter must be a code reference or SeeAlso::Source')
            if defined $callback and ref( $callback ) ne 'CODE'
               and not UNIVERSAL::isa( $callback, 'SeeAlso::Source' );

        $self->{callback} = $callback;
    }

    return undef unless defined $self->{callback};
    return $self->{callback} if ref($self->{callback}) eq 'CODE';
    return sub { $self->{callback}->query( $_[0] ) };
}

=head2 cache ( [ $cache | undef ] )

Get or set a cache for this source. The parameter must be a L<Cache> object
or undef - the latter disables caching and is the default. Returns the cache 
object or undef.

=cut

sub cache {
    my $self = shift;

    if ( scalar @_ ) {
        croak 'Cache must be a Cache object' 
            unless not defined $_[0]
                   or UNIVERSAL::isa( $_[0], 'Cache' )
                   or UNIVERSAL::isa( $_[0], 'SeeAlso::Source' );
        $self->{cache} = $_[0];
    }

    return $self->{cache};
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
        if ( UNIVERSAL::isa( $self->{cache}, 'Cache' ) ) {
            my $response = $self->{cache}->thaw( $key );
            return $response if defined $response;
        } else {
            my $response = $self->{cache}->query( $identifier );
            return $response if $response->size;
        }
    }

    my $response = $self->query_callback( $identifier );

    $response = SeeAlso::Response->new( $identifier )
        unless UNIVERSAL::isa( $response, 'SeeAlso::Response' );

    if ( $self->{cache} ) {
        if ( UNIVERSAL::isa( $self->{cache}, 'Cache' ) ) {
            $self->{cache}->freeze( $key, $response );
        } else {
            $self->{cache}->store( $response );
        }
    }

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
    return $self->{callback} ?
           $self->callback->( $identifier ) :
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
