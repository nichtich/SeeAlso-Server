package SeeAlso::Client;

use strict;
use warnings;
use utf8;

=head1 NAME

SeeAlso::Client - SeeAlso Linkserver Protocol Client

=cut

use Carp qw(croak);
use JSON::XS;
use LWP::Simple qw(get);
use URI;
# use CGI qw(-oldstyle_urls);

use SeeAlso::Identifier;
use SeeAlso::Response;

use base qw( SeeAlso::Source );
our $VERSION = "0.20";
our @EXPORT = qw( seealso_request );

=head1 DESCRIPTION

This class can be used to query a SeeAlso server. It can also be used
as L<SeeAlso::Source> to proxy another SeeAlso server.

=head1 METHODS

=head2 new ( $baseurl )

Creates a new SeeAlso client. You must specify a base URL as string
or L<URI> object. If the URL is not valid, this method returns undef.

=cut

sub new {
    my $class = shift;
    my $baseurl = shift;

    my $self = bless {
        'baseurl' => "",
        'is_simple' => 0 # unknown or no
    }, $class;

    eval { $self->baseURL($baseurl || "") };
    return $@ ? undef : $self;
}

=head2 query ( $identifier )

Given an identifier (either a L<SeeAlso::Identifier> object or just a 
plain string) queries the SeeAlso Server that is specified with its 
base URL and returns a L<SeeAlso::Response> object on success.

=cut

sub query {
    my ($self, $identifier) = @_;

    # TOOD: on failure catch/throw error(s)

    my $url = $self->queryURL( $identifier );
    my $json = get($url);

    if (defined $json) {
        # TODO: this may croak!
        my $r = SeeAlso::Response->fromJSON( $json );
        # use Data::Dumper;
        # print STDERR Dumper($r) . "\n";;
        # print STDERR $r->toJSON() . "\n";
    } else {
        # TODO: croak?
        # print STDERR "no json!\n";
    }
}

=head2 baseURL ( [ $url ] )

Get or set the base URL of the SeeAlso server to query by this client. You can
specify a string or a L<URI>/L<URI::http>/L<URI::https> object. If the URL 
contains a 'format' parameter, it is treated as a SeeAlso Simple server
(plain JSON response), otherwise it is a SeeAlso Full server (unAPI support 
and OpenSearch description). This method may croak on invalid URLs.

=cut

sub baseURL {
    my ($self, $url) = @_;
    if (defined $url) {
        $url = URI->new( $url ) unless UNIVERSAL::isa( $url, "URI" );
        croak("Not an URL")
            unless $url->scheme and $url->scheme =~ /^http[s]?$/;
        my %query = $url->query_form();
        croak("URL must not contain id or callback parameter")
            if defined $query{'id'} or defined $query{'callback'};
        $self->{is_simple} = defined $query{'format'};
        $self->{baseurl} = $url;
    }
    return $self->{baseurl}->canonical();
}

=head2 queryURL ( $identifier [, $callback ] )

Get the query URL with a given identifier and optionally callback parameter.
The query parameter can be a simple string or a L<SeeAlso::Identifier> object 
(its normalized representation is used). If no identifier is given, an empty
string is used. This method may croak if the callback name is invalid.

=cut

sub queryURL {
    my ($self, $identifier, $callback) = @_;
    $identifier = $identifier->normalized()
        if UNIVERSAL::isa($identifier,"SeeAlso::Identifier");
    $identifier = "" unless defined $identifier;

    my $url = URI->new( $self->{baseurl} );
    my %query = $url->query_form();

    $query{'format'} = "seealso" unless $self->{is_simple};
    $query{'id'} = $identifier;

    if (defined $callback) {
        $callback =~ /^[a-zA-Z0-9\._\[\]]+$/ or
            croak ( "Invalid callback name" );
        $query{callback} = $callback;
    }
    $url->query_form( %query );

    return $url->canonical();
}

=head1 ADDITIONAL FUNCTIONS

=head2 seealso_request ( $baseurl, $identifier )

Quickly query a SeeAlso server an return the L<SeeAlso::Response>.
This is almost equivalent to

  SeeAlso::Client->new($baseurl)->query($identifier)

but in contrast seealso_request never croaks on errors but may return undef.

=cut

sub seealso_request {
    my ($baseurl, $identifier) = @_;
    my $response = eval { SeeAlso::Client($baseurl)->query($identifier); };
    return $response;
}

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2007-2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
