package SeeAlso::Server;

use strict;
use warnings;
use utf8;

=head1 NAME

SeeAlso::Server - SeeAlso Linkserver Protocol Server

=cut

use Carp qw(croak);
use CGI qw(-oldstyle_urls);

use SeeAlso::Identifier;
use SeeAlso::Response;
use SeeAlso::Source;

use base qw( Exporter );
our $VERSION = "0.57";

=head1 DESCRIPTION

Basic module for a Webservice that implements the SeeAlso link server
Protocol. SeeAlso is a combination of unAPI and OpenSearch Suggestions,
so this module also implements the unAPI protocol version 1.

=head1 SYNOPSIS

The core of every SeeAlso linkserver is a query method that gets a 
L<SeeAlso::Identifier> and returns a L<SeeAlso::Response>.

  use SeeAlso::Server;
  use SeeAlso::Response;

  sub query {
      my $identifier = shift;

      my $response = SeeAlso::Response->new( $identifier );
      $response->add( $label, $description, $uri );

      return $response;
  }

  my @description = ( "ShortName" => "MySimpleServer" );
  my $server = SeeAlso::Server->new( description => \@description );
  my $http = $server->query( \&query );
  print $http;

Instead of providing a simple query method, you can also use a
L<SeeAlso::Source> object. Identifiers can be validated and normalized 
with a validation method or a L<SeeAlso::Identifier> object.

  # get responses from a database (not implemented yet)
  my $source = SeeAlso::Source::DBI->new( $connection, $sqltemplate );

  # automatically convert identifier to uppercase
  print $server->query( $source, sub { return uc($_[0]); } );

=head1 METHODS

=head2 new ( [ %params ] )

Creates a new SeeAlso::Server object. You may specify the following
parameters:

=over

=item cgi

a L<CGI> object. If not specified, a new L<CGI> object is created.

=item xslt

the URL (relative or absolute) of an XSLT script to display the unAPI
format list. It is recommended to use the XSLT client 'showservice.xsl'
that is available in the 'client' directory of this package.

=item clientbase

the base URL (relative or absolute) of a directory that contains
client software to access the service. Only needed for the XSLT 
script so far.

=item description

By default the openSearchDescription method is used to create the
self-description of a server based on a L<SeeAlso::Source>. You 
can disable support of OpenSearch Description by setting this parameter
to false or override the description by setting this parameter to
an array reference.

=item expires

Send HTTP "Expires" header for caching (see the setExpires method for details).

=item debug

Debug level. By default (0) format=debug adds debugging information
as JavaScript comment in the JSON response. You can force this with
C<debug = 1> and prohibit with C<debug = -1>.

=item logger

set a L<SeeAlso::Logger> for this server. See the method C<logger> below.

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
    my $logger = $params{logger};

    my $description = 1;
    if ( exists $params{description} ) {
        $description = $params{description} || 0;
    }

    croak('Parameter cgi must be a CGI object!')
        if defined $cgi and not UNIVERSAL::isa($cgi, 'CGI');

    my $self = bless {
        cgi => $cgi || new CGI,
        description => $description,
        logger => $logger,
        xslt => $params{xslt} || undef,
        clientbase => $params{clientbase} || undef,
        debug => $params{debug} || 0,
        formats => { 'seealso' => { type => 'text/javascript' } },
        errors => undef,
    }, $class;

    $self->setExpires($params{expires}) if $params{expires};

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

=head2 query ( $source [, $identifier [, $format [, $callback ] ] ] )

Perform a query by a given source, identifier, format and (optional)
callback parameter. Returns a full HTTP message with HTTP headers.
Missing parameters are tried to get from the server's L<CGI> object.

This is what the method actually does:
The source (of type L<SeeAlso::Source>) is queried for the
identifier (of type L<SeeAlso::Identifier> or a plain string or function).
Depending on the response (of type L<SeeAlso::Response>) and the requested
format ('seealso' or 'opensearchdescription' for valid responses)
the right HTTP response is returned. This can be either a
list of formats in unAPI Response format (XML), or a list
of links in OpenSearch Suggestions Response format (JSON),
or an OpenSearch Description Document (XML).

This method catches all warnings and errors that may occur in the query 
method and appends them to the error list that can be accessed by the
errors method. The error list is cleaned before each call of query.

=cut

sub query {
    my ($self, $source, $identifier, $format, $callback) = @_;
    my $cgi = $self->{cgi};
    my $http = "";

    if (ref($source) eq "CODE") {
        $source = new SeeAlso::Source( $source );
    }
    croak('First parameter must be a SeeAlso::Source object!')
        unless defined $source and UNIVERSAL::isa($source, 'SeeAlso::Source');

    if ( ref($identifier) eq 'CODE' ) {
        $identifier = &$identifier( $cgi->param('id') );
    } elsif (not defined $identifier) {
        $identifier = $cgi->param('id');
    }
    $identifier = new SeeAlso::Identifier( $identifier )
        unless UNIVERSAL::isa( $identifier, 'SeeAlso::Identifier' );

    $format = $cgi->param('format') unless defined $format;
    $format = "" unless defined $format;
    $callback = $cgi->param('callback') unless defined $callback;
    $callback = "" unless defined $callback;

    # If everything is ok up to here, we should definitely return some valid stuff
    $format = "seealso" if ( $format eq "debug" && $self->{debug} == -1 ); 
    $format = "debug" if ( $format eq "seealso" && $self->{debug} == 1 ); 

    if ($format eq 'opensearchdescription') {
        $http = $self->openSearchDescription( $source );
        if ($http) {
            $http = $cgi->header( -status => 200, -type => 'application/opensearchdescription+xml; charset: utf-8' ) . $http;
            return $http;
        }
    }

    $self->{errors} = (); # clean error list
    my $response;
    my $status = 200;

    if ( not $identifier ) {
        $self->errors( "invalid identifier" );
        $response = SeeAlso::Response->new;
    } elsif ($format eq "seealso" or $format eq "debug" or !$self->{formats}{$format}) {
        eval {
            local $SIG{'__WARN__'} = sub {
                $self->errors(shift);
            };
            $response = $source->query( $identifier );
        };
        if ($@) {
            $self->errors( $@ );
            undef $response;
        } else {
            if (defined $response && !UNIVERSAL::isa($response, 'SeeAlso::Response')) {
                $self->errors( ref($source) . "->query must return a SeeAlso::Response object but it did return '" . ref($response) . "'");
                undef $response;
            }
        }

        $response = SeeAlso::Response->new() unless defined $response;

        if ($callback && !($callback =~ /^[a-zA-Z0-9\._\[\]]+$/)) {
            $self->errors( "Invalid callback name specified" );
            undef $callback;
            $status = 400;
        }
    } else {
        $response = SeeAlso::Response->new( $identifier );
    }


    if ( $self->{logger} ) {
        # TODO: if you override the description, this is not taken!
        my $service = $source->description( "ShortName" );
        eval {
            $self->{logger}->log( $cgi, $response, $service )
            || $self->errors("Logging failed");
        };
        $self->errors( $@ ) if $@;
    }

    if ( $format eq "seealso" ) {
        my %headers =  (-status => $status, -type => 'text/javascript; charset: utf-8');
        $headers{"-expires"} = $self->{expires} if ($self->{expires});
        $http .= $cgi->header( %headers );
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
        $http .= "\nInternally the following errors occured:\n- "
              . join("\n- ", @{ $self->errors() }) . "\n" if $self->errors();
        $http .= "*/\n";
        $http .= $response->toJSON($callback) . "\n";
    } else { # other unAPI formats
        # TODO is this properly logged?
        # TODO: put 'seealso' as format method in the array
        my $f = $self->{formats}{$format};
        if ($f) {
            my $type = $f->{type} . "; charset: utf-8";
            my $header = $cgi->header( -status => $status, -type => $type );
            $http = $f->{method}($identifier); # TODO: what if this fails?!
            $http = $header . $http; # TODO: omit headers if already in HTTP
        } else {
            $http = $self->listFormats($response);
        }
    }
    return $http;
}

=head2 logger ( [ $logger ] )

Get/set a logger for this server. The logger must be of class L<SeeAlso::Logger>
or it will be passed to its constructor. This means you can also use references to
file handles and L<IO::Handle> objects.

=cut

sub logger {
    my $self = shift;
    my $logger = shift;
    return $self->{logger} unless defined $logger;
    if (!UNIVERSAL::isa($logger, 'SeeAlso::Logger')) {
        $logger = SeeAlso::Logger->new($logger);
    }
    $self->{logger} = $logger;
}

=head2 setExpires( $expires )

Set "Expires" HTTP header for cache control. The parameter is expected to be
either a HTTP Date (better use L<HTTP::Date> to create it) or a string such as
"now" (immediately), "+180s" (in 180 seconds), "+2m" (in 2 minutes), "+12h" 
(in 12 hours), "+1d" (in 1 day), "+3M" (in 3 months), "+1y" (in 1 year), 
"-3m" (3 minutes ago).

The "Expires" header is only sent for responses in seealso format!

=cut

sub setExpires {
    my ($self, $expires) = @_;
    $self->{expires} = $expires;
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
    my $id = $response->query();
    if ($response->query() ne "") {
        $status = $response->size ? 300 : 404;
    }

    my $headers = $self->{cgi}->header( -status => $status, -type => 'application/xml; charset: utf-8' );
    $headers .= '<?xml version="1.0" encoding="UTF-8"?>' . "\n";

    if ($self->{xslt}) {
        $headers .= "<?xml-stylesheet type=\"text/xsl\" href=\"" . xmlencode($self->{xslt}) . "\"?>\n";
        $headers .= "<?seealso-query-base " . xmlencode($self->baseURL) . "?>\n";
    }
    if ($self->{clientbase}) {
        $headers .= "<?seealso-client-base " . xmlencode($self->{clientbase}) . "?>\n";
    }

    my %formats = %{$self->{formats}};

    if ( $self->{description} ) {
        $formats{"opensearchdescription"} = {
            type=>"application/opensearchdescription+xml",
            docs=>"http://www.opensearch.org/Specifications/OpenSearch/1.1/Draft_3#OpenSearch_description_document"
        };
    }

    return _unapiListFormats( \%formats, $id, $headers );
}

# $formats: hash reference
# $id : scalar (optional)
# $headers : scalar (optional, use undef to disable)
sub _unapiListFormats { # TODO: move this to HTTP::unAPI or such
    my ($formats, $id, $headers) = @_;

    $headers = '<?xml version="1.0" encoding="UTF-8"?>' unless defined $headers;
    my @xml;

    if ($id ne "") {
        push @xml, '<formats id="' . xmlencode($id) . '">';
    } else {
        push @xml, '<formats>';
    }

    foreach my $name (sort({$b cmp $a} keys(%$formats))) {
        my $format = $formats->{$name};
        my $fstr = "<format name=\"" . xmlencode($name) . "\" type=\"" . xmlencode($format->{type}) . "\"";
        $fstr .= " docs=\"" . xmlencode($format->{docs}) . "\"" if defined $format->{docs};
        push @xml, $fstr . " />";
    }

    push @xml, '</formats>';    

    return $headers . join("\n", @xml) . "\n";
}

=head2 errors ( [ $message ] )

Returns a list of errors and warning messages that have ocurred during the 
last query. You can also add an error message but this is only useful interally.

=cut

sub errors {
    my $self = shift;
    my $message = shift;
    if (defined $message) {
        chomp $message;
        push @{ $self->{errors} }, $message;
    }
    return $self->{errors};
}

=head2 openSearchDescription ( [ $source ] )

Returns an OpenSearch Description document.
If you pass a L<SeeAlso::Source> instance,
additional information will be added.

=cut

sub openSearchDescription {
    my $self = shift;
    my $source = shift;

    my $cgi = $self->{cgi};
    my $baseURL = $self->baseURL;

    return unless $self->{description};
    if ( ref($self->{description}) eq "ARRAY" ) {
        $source = SeeAlso::Source->new( sub {} );
        $source->description( @{$self->{description}} );
    }

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
        push @xml, "  <dcterms:modified>" . xmlencode( $modified ) . "</dcterms:modified>"
            if defined $modified;

        my $src = $descr{"Source"};
        push @xml, "  <dc:source>" . xmlencode( $src ) . "</dc:source>"
            if defined $src;

        if ($descr{"Examples"}) { # TODO: add more parameters
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

=head2 baseURL ( )

Return the full SeeAlso base URL of this server. 
You can append the 'format=seealso' parameter
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

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2007-2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
