package SeeAlso::Server;

=head1 NAME

SeeAlso::Server - SeeAlso Linkserver Protocol Server

=cut

use strict;
use Carp qw(croak);
use CGI qw(-oldstyle_urls);

use SeeAlso::Identifier;
use SeeAlso::Response;
use SeeAlso::Source;

use base qw( Exporter );
our $VERSION = "0.53";
our @EXPORT = qw( query_seealso_server );

=head1 DESCRIPTION

Basic module for a Webservice that implements the SeeAlso link server
Protocol. SeeAlso is a combination of unAPI and OpenSearch Suggestions,
so this module also implements the unAPI protocol version 1.

=head1 SYNOPSIS

To implement a SeeAlso linkserver, you need instances of C<SeeAlso::Server>,
and L<SeeAlso::Source>. The Source object must return a L<SeeAlso::Response> 
object:

  use SeeAlso::Server;
  my $server = SeeAlso::Server->new( cgi => $cgi );

  use SeeAlso::Source;
  use SeeAlso::Response;
  my $source = SeeAlso::Source->new( sub {
      my $identifier = shift;
      return unless $identifier->valid;

      my $response = SeeAlso::Response->new( $identifier );

      # add response content depending on $identifier->value
      $response->add( $label, $description, $uri );
      # ...

      return $response;
  } );
  $source->description( "ShortName" => "MySimpleServer" );

  my $http = $server->query( $source );
  print $http;

Or even smaller with the exported function C<query_seealso_server>:

  use SeeAlso::Server;
  print query_seealso_server(
      sub {
          my $identifier = shift; 
          ....
          return $response; 
      },
      [ "ShortName" => "MySimpleServer" ]
  );

The examples directory contains a full example. For more specialised servers 
you may also need to use L<SeeAlso::Identifier> or one of its subclasses and
another subclass of L<SeeAlso::Source>.

=head1 METHODS

=head2 new ( [ %params ] )

Creates a new L<SeeAlso::Server> object. You may specify the following
parameters:

=over

=item cgi

a L<CGI> object. If not specified, a new L<CGI> object is created.

=item xslt

the URL (relative or absolute) of an XSLT script to display the unAPI
format list. An XSLT to display a full demo client is available.

=item clientbase

the base URL (relative or absolute) of a directory that contains
client software to access the service. Only needed for the XSLT 
script so far.

=item description

a string (or function) that contains (or returns) an
OpenSearch Description document as XML string. By default the
openSearchDescription method of this class is used. You can switch off 
support of OpenSearch Description by setting opensearchdescription to 
the empty string.

=item debug

set debug level. By default (0) format=debug adds debugging information
as JavaScript comment in the JSON response. You can force this with
debug=1 and prohibit with debug=-1.

=item logger

set a <SeeAlso::Logger> for this server. See the method C<logger> below.

=item formats

An additional hash of formats (experimental). The structure is:

  name => {
     type => "...",
     docs => "...",         # optional
     method => \&function
 }

You can use this parameter to provide more formats then 'seealso' and
'opensearchdescription' via unAPI (these two formats cannot be overwritten).

=back

=cut

sub new {
    my ($class, %params) = @_;

    my $cgi = $params{cgi};
    my $description = $params{description};
    my $logger = $params{logger};

    croak('Parameter cgi must be a CGI object!')
        if defined $cgi and not UNIVERSAL::isa($cgi, 'CGI');
    croak('Parameter description must either be a string, function or undef!')
        if defined $description and not ($description eq "" or 
           ref($description) eq 'SCALAR' or ref($description) eq 'CODE');

    my $self = bless {
        cgi => $cgi || new CGI,
        description => $description,
        logger => $logger,
        xslt => $params{xslt} || undef,
        clientbase => $params{clientbase} || undef,
        debug => $params{debug} || 0,
        formats => { 'seealso' => { type => 'text/javascript' } }
    }, $class;

    if ($params{formats}) {
        my %formats = %{$params{formats}};
        foreach my $name (keys %formats) {
            next if $name eq 'opensearchdescription' or $name eq 'seealso' or $name eq 'debug';
            my $format = $formats{$name};
            next unless ref($format) eq 'HASH';
            next unless defined $format->{type};
            next unless ref($format->{method}) eq 'CODE';
            $self->{formats}{$name} = {
                "type" => $format->{type},
                "docs" => $format->{docs},
                "method" => $format->{method}
            };
        }
    }

    $self->logger($params{logger}) if defined $params{logger};

    return $self;
}

=head2 logger ( [ $logger ] )

Get/set a logger for this server. The logger must be of class L<SeeAlso::Logger>.

=cut

sub logger {
    my $self = shift;
    my $logger = shift;
    return $self->{logger} unless defined $logger;
    croak('Parameter cgi must be a SeeAlso::Logger object!')
        unless UNIVERSAL::isa($logger, 'SeeAlso::Logger');
    $self->{logger} = $logger;
}

=head2 listFormats ( $response )

Return a HTTP response that lists available formats according to the
unAPI specification version 1. You must provide a L<SeeAlso::Response>
object. If this response has no query then no unAPI parameter was provided
so HTTP status code 200 is returned. Otherwise the status code depends
on whether the response is empty (HTTP code 404) or not (HTTP code 300).

=cut

sub listFormats {
    my ($self, $response) = @_;

    my $status = 200;
    if ($response->hasQuery) {
        $status = $response->size ? 300 : 404;
    }

    my $http = $self->{cgi}->header( -status => $status, -type => 'application/xml; charset: utf-8' );
    my @xml = ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");

    if ($self->{xslt}) {
        push @xml, "<?xml-stylesheet type=\"text/xsl\" href=\"" . xmlencode($self->{xslt}) . "\"?>";
        push @xml, "<?seealso-query-base " . xmlencode($self->baseURL) . "?>";
    }
    if ($self->{clientbase}) {
        push @xml, "<?seealso-client-base " . xmlencode($self->{clientbase}) . "?>";
    }

    if ($response->hasQuery) {
        push @xml, "<formats id=\"" . xmlencode($response->{query}) . "\">";
    } else {
        push @xml, "<formats>";
    }

    my %formats = %{$self->{formats}};

    if ( (not defined $self->{description}) || $self->{description} ne "" ) {
        $formats{"opensearchdescription"} = {
            type=>"application/opensearchdescription+xml",
            docs=>"http://www.opensearch.org/Specifications/OpenSearch/1.1/Draft_3#OpenSearch_description_document"
        };
    }

    foreach my $name (sort({$b cmp $a} keys(%formats))) {
        my $format = $formats{$name};
        my $fstr = "<format name=\"" . xmlencode($name) . "\" type=\"" . xmlencode($format->{type}) . "\"";
        $fstr .= " docs=\"" . xmlencode($format->{docs}) . "\"" if defined $format->{docs};
        push @xml, $fstr . " />";
    }

    push @xml, "</formats>\n";

    return $http . join("\n", @xml);
}

=head2 query ( $source [, $identifier [, $format [, $callback ] ] ] )

Perform a query by a given source, identifier, format and (optional)
callback parameter. Returns a full HTTP message with HTTP headers.
Missing parameters are tried to get from the server's L<CGI> object.

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
    $format = "" unless defined $format;
    $callback = $cgi->param('callback') unless defined $callback;
    $callback = "" unless defined $callback;

    if ($format eq 'opensearchdescription') {
        $http = $self->openSearchDescription( $source );
        if ($http) {
            $http = $cgi->header( -status => 200, -type => 'application/opensearchdescription+xml; charset: utf-8' ) . $http;
            return $http;
        }
    }

    # If everything is ok up to here, we should definitely return some valid stuff
    $format = "seealso" if ( $format eq "debug" && $self->{debug} == -1 ); 
    $format = "debug" if ( $format eq "seealso" && $self->{debug} == 1 ); 

    my ($response, @errors);
    my $status = 200;
    if ($format eq "seealso" or $format eq "debug" or !$self->{formats}{$format}) {
        eval {
            $response = $source->query($identifier);
        };
        push @errors, $@ if $@;
        push @errors, @{ $source->errors() } if $source->errors();
        if (@errors) {
            undef $response;
        } else {
            if (defined $response && !UNIVERSAL::isa($response, 'SeeAlso::Response')) {
                push @errors, ref($source) . "->query must return a SeeAlso::Response object but it did return '" . ref($response) . "'";
                undef $response;
            }
        }

        $response = SeeAlso::Response->new() unless defined $response;

        if ($callback && !($callback =~ /^[a-zA-Z0-9\._\[\]]+$/)) {
            push @errors, "Invalid callback name specified";
            undef $callback;
            $status = 400;
        }
    } else {
        $response = SeeAlso::Response->new( $identifier );
    }

    if ( $self->{logger} ) {
        my $service = $source->description( "ShortName" );
        eval {
            $self->{logger}->log( $cgi, $response, $service )
            || push @errors, "Logging failed";
        };
        push @errors, $@ if $@;
    }

    if ( $format eq "seealso" ) {
        $http .= $cgi->header( -status => $status, -type => 'text/javascript; charset: utf-8' );
        $http .= $response->toJSON($callback);
    } elsif ( $format eq "debug") {
        $http .= $cgi->header( -status => $status, -type => 'text/javascript; charset: utf-8' );
        $http .= "/*\n";

        use Class::ISA;
        my %vars = ( Server => $self, Source => $source, Identifier => $identifier, Response => $response );
        foreach my $var (keys %vars) {
            $http .= "$var is a " .
                join(", ", map { $_ . " " . $_->VERSION; }
                Class::ISA::self_and_super_path(ref($vars{$var})))
            . "\n"
        }
        $http .= "\n";
        $http .= "HTTP response status code is $status\n";
        $http .= "\nInternally the following errors occured:\n- " . join("\n- ", map {chomp; $_;} @errors) . "\n" if @errors;
        $http .= "*/\n";
        $http .= $response->toJSON($callback) . "\n";
    } else {
        # TODO is this properly logged?
        # TODO: put 'seealso' as format method in the array
        my $f = $self->{formats}{$format};
        if ($f) {
            $http = $f->{method}($identifier); # TODO: what if this fails?!
        } else {
            $http = $self->listFormats($response);
        }
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
    my $baseURL = $self->baseURL;

    my @xml = '<?xml version="1.0" encoding="UTF-8"?>';
    push @xml, '<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:seealso="http://ws.gbv.de/seealso/schema/" >';

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

        $baseURL = $descr{"BaseURL"}  # overwrites standard
            if defined $descr{"BaseURL"};

        my $modified = $descr{"DateModified"};
        push @xml, "  <dcterms:modified>" . xmlencode( $shortName ) . "</dcterms:modified>"
            if defined $modified;

        my $source = $descr{"Source"};
        push @xml, "  <dc:source" . xmlencode( $shortName ) . "</dc:source>"
            if defined $source;

        if ($descr{"Examples"}) {
            foreach my $example ( @{ $descr{"Examples"} } ) {
                my $id = $example->{id};
                my $args = "searchTerms=\"" . xmlencode($id) . "\"";
                my $response = $example->{response};
                if (defined $response) {
                    $args .= " seealso:response=\"" . xmlencode($response) . "\"";
                }
                push @xml, "  <Query role=\"example\" $args />";
            }
        }
    }
    my $template = $baseURL . (($baseURL =~ /\?/) ? '&' : '?')
                 . "id={searchTerms}&format=seealso&callback={callback}";
    push @xml, "  <Url type=\"text/javascript\" template=\"" . xmlencode($template) . "\"/>";
    push @xml, "</OpenSearchDescription>";

    return join("\n", @xml);
}

=head2 baseURL

Return the full SeeAlso base URL of this server. Append the <tt>format=seealso</tt> parameter
to get a SeeAlso simple base URL.

=cut

sub baseURL {
    my $self = shift;
    my $cgi = $self->{cgi};

    # remove id, format, and callback parameter
    my $q = "&" . $cgi->query_string();
    $q =~ s/&(id|format|callback)=[^&]*//g;
    $q =~ s/^&//;
    return $cgi->url . "?$q" if $q;
    return $cgi->url;
}

=head1 ADDITIONAL FUNCTIONS

=head2 query_seealso_server ( $source [, \@description ] [, %params ] )

This function is a shortcut method to create and query a SeeAlso server 
in one command. It is exported by default. The following line is a
identifcal to the second:

  query_seealso_server( $source, %params );

  SeeAlso::Server->new( %params )->query( $source, $params{id} );

If C<$params{id}> is not set, the C<id> parameter of the C<CGI> object
(C<$param{cgi}> or C<CGI->new>) is used.

If you pass an array reference as C<$source> instead of a 
C<SeeAlso::Source> object, a new C<SeeAlso::Source> will be generated
with C<@{$source}> as parameters. The following line is a identifcal 
to three next commands:

  query_seealso_server( \&query_function, \@description, %params );

  $source = SeeAlso::Source->new( \&query_function, @description );
  $server = SeeAlso::Server->new( %params );
  $server->query( $source, $params{id} );

Please note that you must pass the optional @description parameter as an
array reference. Here is an example:

  query_seealso_server( 
     sub { ... }, 
     [ "ShortName" => "..." ],
     logger => SeeAlso::Logger->new(...)
  );

=cut

sub query_seealso_server {
    my $source = shift;

    if (ref($source) eq "CODE") {
        my @description;
        if (ref($_[0]) eq "ARRAY") {
            my $a = shift;
            @description = @{ $a };
        }
        $source = SeeAlso::Source->new( $source, @description );
    }

    my %params = @_;

    my $server = SeeAlso::Server->new( %params );

    return $server->query( $source, $params{id} );
}

=head2 xmlencode ( $string )

Replace &, <, >, " by XML entities.

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
