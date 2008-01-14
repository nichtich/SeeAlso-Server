package SeeAlso::Server;

=head1 NAME

SeeAlso::Server - SeeAlso-API Webservice Implementation

=cut

use strict;
use Carp qw(croak);
use CGI;

use SeeAlso::Identifier;
use SeeAlso::Response;
use SeeAlso::Source;

use vars qw($VERSION);
$VERSION = "0.40";

=head1 DESCRIPTION

Basic module for a Webservice that implements the SeeAlso link server
Protocol. SeeAlso is a combination of unAPI and OpenSearch Suggestions
so this module implements the unAPI protocol version 1.

=head1 SYNOPSIS

You need instances of L<SeeAlso::Source> and L<SeeAlso::Identifier>
for usage of a SeeAlso Server.

  use SeeAlso::Server;

  my $server = SeeAlso::Server->new( cgi => $cgi );

  # ... set $identifier based on $cgi->param('id') and:
  my $http = $server->query( $source, $identifier );

  # ... or also set $format and $callback and:
  my $http = $server->query( $source, $identifier, $format, $callback );

  print $http;

To create a special server, you probably have to create subclasses
of L<SeeAlso::Source> and L<SeeAlso::Identifier>.

=head1 EXAMPLE

The following script implements a minimal SeeAlso service:

  use SeeAlso::Server;
  use SeeAlso::Source;

  sub query_method {
      my $identifier = shift;
      my $response = SeeAlso::Response->new($identifier);

      # depending on $identifier->value do zero or more:
      $response->add("..title..","..description..","..url..");

      return $response;
  }

  my $server = SeeAlso::Server->new();
  my @about = ( "ShortName" => "My simple SeeAlso service" );
  my $source = SeeAlso::Source->new( \&query_method, @about );

  print $server->query( $source );

The Service will also fullfill the SeeAlso specification if the query 
method breaks or does not return a L<SeeAlso::Response> object.

=head1 METHODS

=head2 new ( [%params] )

Creates a new L<SeeAlso::Server> object. You may specify the following
parameters:

=over

=item cgi

a L<CGI> object to print HTTP headers. If not specified,
a new L<CGI> object is created.

=item description

a string or function that contains or returns an
OpenSearch Description document. By default (osdec set to undef)
the method openSearchDescription is used. You can switch off support
of OpenSearch Description by setting opensearchdescription to the empty
string.

=back

=cut

sub new {
    my ($class, %params) = @_;

    my $cgi = $params{cgi};
    my $description = $params{description};

    croak('Parameter cgi must be a CGI object!')
        if defined $cgi and not UNIVERSAL::isa($cgi, 'CGI');
    croak('Parameter osd must either be a string, function or undef!')
        if defined $description and not ($description eq "" or ref($description) eq 'SCALAR' or ref($description) eq 'CODE');

    my $self = bless {
        cgi => $cgi || new CGI,
        description => $description
    }, $class;

    return $self;
}

=head2 listFormats ( $response [, @formats] )

Return a HTTP response that lists available formats according to the
unAPI specification version 1. You must provide a L<SeeAlso::Response>
object. If this response has no query then no unAPI parameter was provided
so HTTP status code 200 is returned. Otherwise the status code depends
on whether the response is empty (HTTP code 404) or not (HTTP code 300).

The optional second parameter may contain an array of additional formats,
each beeing a hash with 'name', 'type' and optional 'docs' field as
defined in the unAPI standard version 1.

=cut

sub listFormats {
    my ($self, $response, @formats) = @_;

    my $status = 200;
    if ($response->hasQuery) {
        $status = $response->size ? 300 : 404;
    }

    my $http = $self->{cgi}->header( -status => $status, -type => 'application/xml; charset: utf-8' );
    my @xml = ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");

    if ($response->hasQuery) {
        push @xml, "<formats id=\"" . xmlencode($response->{query}) . "\">";
    } else {
        push @xml, "<formats>";
    }

    push @formats, { name=>"seealso", type=>"text/javascript"};

    if ( (not defined $self->{description}) || $self->{description} ne "" ) {
        push @formats, { name=>"opensearchdescription",
             type=>"application/opensearchdescription+xml",
             docs=>"http://www.opensearch.org/Specifications/OpenSearch/1.1/Draft_3#OpenSearch_description_document" }
    }

    foreach my $format (@formats) {
        next unless ref($format) eq 'HASH';
        my %format = %{$format};
        next unless defined $format{name} and defined $format{type};
        my $fstr = "<format name=\"" . xmlencode($format{name}) . "\" type=\"" . xmlencode($format{type}) . "\"";
        $fstr .= " docs=\"" . xmlencode($format{docs}) . "\"" if defined $format{docs};
        push @xml, $fstr . " />";
    }

    push @xml, "</formats>\n";

    return $http . join("\n", @xml);
}

=head2 query ($source [, $identifier [, $format [, $callback ] ] ] )

Perform a query by a given source, identifier, format and (optional)
callback parameter. Returns a full HTTP message with HTTP headers.

If you do not provide one or more of the parameters C<$identifer>,
C<$format>, and C<$callback>, it is tried to get the parameters from
the server's L<CGI> object.

This is what the method actually does:
The source (of type L<SeeAlso::Source>) is queried for the
identifier (of type L<SeeAlso::Identifier>). Depending on
the response (of type L<SeeAlso::Response>) and the requested
format ('seealso' or 'opensearchdescription' for valid responses)
the right HTTP response is returned. This can be either a
list of formats in unAPI Response format (XML), or a list
of links in OpenSearch Suggestions Response format (JSON),
or an OpenSearch Description Document (XML).

=cut

sub query {
    my ($self, $source, $identifier, $format, $callback) = @_;
    my $cgi = $self->{cgi};
    my $http = "";

    croak('First parameter must be a SeeAlso::Source object!')
        unless defined $source and UNIVERSAL::isa($source, 'SeeAlso::Source');

    if (not defined $identifier) {
        $identifier = SeeAlso::Identifier->new( $cgi->param('id') );
    } else {
        croak('Second parameter must be a SeeAlso::Identifier object!')
          unless defined $source and UNIVERSAL::isa($identifier, 'SeeAlso::Identifier');
    }

    $format = $cgi->param('format') unless defined $format;
    $callback = $cgi->param('callback') unless defined $callback;

    if ($format eq 'opensearchdescription') {
        $http = $self->openSearchDescription( $source );
        if ($http) {
            $http = $cgi->header( -status => 200, -type => 'application/opensearchdescription+xml; charset: utf-8' ) . $http;
            return $http;
        }
    }

    # If everything is ok up to here, there must not be an error thrown

    my ($response, $error);
    eval {
        $response = $source->query($identifier);
    };
    $error = $@;
    if (not defined $error and $source->hasErrors()) {
        $error = $source->errors();
    }
    if ($error) {
        undef $response;
    } else {
        if (defined $response && !UNIVERSAL::isa($response, 'SeeAlso::Response')) {
            $error = ref($source) . "->query must return a SeeAlso::Response object but it did return '" . ref($response) . "'";
            undef $response;
        }
    }

    # TODO: where to write/log the error to?

    $response = SeeAlso::Response->new() unless defined $response;

    my $status = 200;
    if ($callback && !$callback =~ /^[a-zA-Z0-9\._\[\]]+$/) {
        undef $callback;
        $status = 400;
    }

    if ( $format eq "seealso" ) {
        $http .= $cgi->header( -status => $status, -type => 'text/javascript; charset: utf-8' );
        $http .= $response->toJSON($callback);
    } elsif ( $format eq "debug") {
        use Data::Dumper;
        $http .= $cgi->header( -type => 'text/javascript; charset: utf-8' );
        $http .= "Status: $status\n";
        $http .= "Response: " . Dumper($response) . "\n";
        $http .= "JSON Response: " . $response->toJSON($callback) . "\n";
        if ($source->hasErrors) {
            $http .= "Errors:\n* " . join("\n* ", @{ $source->errors() }) . "\n";
        }
    } else {
        $http = $self->listFormats($response);
    }
    return $http;
}

=head2 openSearchDescription ( [$source] )

Returns an OpenSearch Description document.
If you pass a L<SeeAlso::Source> instance,
additional information will be printed.

=cut

sub openSearchDescription {
    my $self = shift;
    my $source = shift;

    return if defined $self->{description} && $self->{description} eq ""; # switched off
    return $self->{description} if ref($self->{description}) eq "SCALAR"; # fixed string

    my $xml;
    if (ref($self->{description}) eq 'CODE') {
        eval {
            $xml = &{$self->{description}}();
        };
        return "" if ($@); # TODO: where to put error message?
        return "$xml";     # TODO: if scalar?
    }

    my $cgi = $self->{cgi};
    my $domain = $cgi->virtual_host() || $cgi->server_name();
    my $baseURL = "http://" . $domain . $cgi->script_name(); # TODO: what about https?

    my @xml = '<?xml version="1.0" encoding="UTF-8"?>';
    push @xml, '<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/">';

    if ($source and UNIVERSAL::isa($source, "SeeAlso::Source")) {
        my %descr = %{ $source->description() };

        my $shortName = $descr{"ShortName"}; # TODO: shorten to 16 chars maximum
        push @xml, "  <ShortName>" . xmlencode( $shortName ) . "</ShortName>"
            if defined $shortName;

        my $longName = $descr{"LongName"}; # TODO: shorten to 48 chars maximum
        push @xml, "  <LongName>" . xmlencode( $longName ) . "</LongName>"
            if defined $longName;

        my $description = $descr{"Description"}; # TODO: shorten to 1024 chars maximum
        push @xml, "  <Description>" . xmlencode( $description ) . "</Description>"
            if defined $description;

        $baseURL = $descr{"BaseURL"}
            if defined $descr{"BaseURL"};

        my $modified = $descr{"DateModified"};
        push @xml, "  <dcterms:modified>" . xmlencode( $shortName ) . "</dcterms:modified>"
            if defined $modified;

        my $source = $descr{"Source"};
        push @xml, "  <dc:source" . xmlencode( $shortName ) . "</dc:source>"
            if defined $source;
    }
    my $template = $baseURL . (($baseURL =~ /\?/) ? '&' : '?')
                 . "id={searchTerms}&format=seealso&callback={callback}";
    push @xml, "  <Url type=\"text/javascript\" template=\"$template\"/>";
    push @xml, "</OpenSearchDescription>";

    return join("\n", @xml);
}

=head1 ADDITIONAL FUNCTIONS

=head2 xmlencode ( $string )

Replace &, <, >, " by XML entities

=cut

sub xmlencode {
    my $data = shift;
    if ($data =~ /[\&\<\>"]/) {
      $data =~ s/\&/\&amp\;/g;
      $data =~ s/\</\&lt\;/g;
      $data =~ s/\>/\&gt\;/g;
      $data =~ s/"/\&quot\;/g;
    }
    return $data;
}

1;
