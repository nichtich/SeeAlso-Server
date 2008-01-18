package SeeAlso::Logger;

=head1 NAME

SeeAlso::Logger - log requests to a SeeAlso Simple service

=cut

use strict;
use Carp qw(croak);
use POSIX qw(strftime);

use vars qw($VERSION);
$VERSION = "0.40";

=head1 DESCRIPTION

This class provides the log method to log successful requests to a
SeeAlso Simple service. You can write logs to a file and/or handle
them by a filter method.

=head1 USAGE

To log requests to your SeeAlso services, create a logfile directory
that is writeable for the user your services runs as. If you run SeeAlso
as cgi-script, this script may help you to find out:

  #!/usr/bin/perl
  print "Content-Type: text/plain;\n\n" . `whoami`;

Create a L<SeeAlso::Logger> object with a filename of your choice and
assign it to the L<SeeAlso::Server> object:

   my $logger = SeeAlso::Logger->new("/var/log/seealso/seealso.log");
   $server->logger($logger);

To rotate logfiles you should use logrotate which is part of every linux
distribution. Specify the configuration for your seealso logfiles in a
configuration file where logrotate can find in (/etc/logrotate.d/seealso).

  # example logrotate configuration for SeeAlso
  /var/log/seealso/*.log {
      compress
      daily
      ifempty
      missingok
      rotate 365
  }

=head1 METHODS

=head2 new ( [ $file-or-handle ] {, $option => $value } )

Create a new parser. Gets a a reference to a file handle or a
file name or a handler function. You can specify the following options:

=over 4

=item file

Filename or reference to a file handle. If you give a file name, it
will immediately be opened (this may throw an error).

=item filter

Reference to a filter method. The methods gets an array
(datetime, host, referer, service, id, valid, size) for each
log event and is expected to return an array of same size.
If the filter method returns undef, the log message
will not be written to the log file.

Here is an example of a filter method that removes the query
part of each referer:

  my $logger = SeeAlso::Logger->new(
      file => "/var/log/seealso/seealso.log",
      filter => sub { $_[1] =~ s/\?.*$//; @_; }
  } );

=item privacy

Do not log remote host (remote host is always '-').
To also hide the referer, use a filter method.


=back

=cut

sub new {
    my $class = shift;
    $class = ref $class || $class;
    my ($file, %param);

    if (@_ % 2) {
        ($file, %param) = @_;
    } else {
        %param = @_;
    }
    $file = $param{file} unless defined $file;

    my $self = bless {
        counter => 0,
        filename => "",
        handle => undef,
        privacy => $param{privacy} || 0,
        filter => $param{filter} || undef,
    }, $class;

    croak("Filter parameter must be a code reference")
        if ($param{filter} and ref($param{filter}) ne 'CODE');

    $self->set_file($file) if defined $file;

    return $self;
}


=head2 set_file ( $file-or-handle )

Set the file handler or file name or function to log to.
May throw an error if opening the file failed.

=cut

sub set_file {
    my $self = shift;
    my $file = shift;

    my $ishandle = do { no strict; defined fileno($file); };
    if ($ishandle) {
        $self->{filename} = "";
        $self->{handle} = $file;
    } else {
        $self->{filename} = $file;
        $self->{handle} = eval { local *FH; open( FH, ">>$file" ) or die; binmode FH, ":utf8"; *FH{IO}; };
        if ( $@ ) {
            croak("Failed to open file for writing: $file");
        }
    }
}


=head2 log ( $cgi, $response, $service )

Log a request and response. The response must be a L<SeeAlso::Response> object,
the service is string. Each logging event is a line of tabulator seperated
values

=over 4

=item datetime

An ISO 8601 timestamp (YYYY-MM-DDTHH:MM:SS).

=item host

The remote host (usually an IP address) unless privacy is enabled.

=item referer

HTTP Referer.

=item service

Name of a service.

=item id

The requested search term (CGI parameter 'id')

=item valid

Whether the search term was a valid identifier (1) or not (0).
This will only give meaningful values of your query method does
not put invalid identifiers in the response.

=item size

Number of entries in the response content

=back

=cut

sub log {
    my ( $self, $cgi, $response, $service ) = @_;
    $self->{counter}++; # count every call (no matter if printed or not)

    return unless defined $self->{handle} || defined $self->{filter};

    my $datetime = strftime("%Y-%m-%dT%H:%M:%S", localtime);
    my $host = $cgi->remote_host() || "";
    my $referer = $cgi->referer() || "";
    # my $ident = $cgi->remote_ident() || "-";
    # my $user =  $cgi->remote_user() || "-";
    # my $user_agent = $cgi->user_agent();
    $service ||= "";

    my $id = $cgi->param('id') || '';

    my $valid = $response->hasQuery() ? '1' : '0';
    my $size = $response->size();

    my @values = (
        $datetime,
        $host,
        $referer,
        $service,
        $id,
        $valid,
        $size
    );

    if ( defined $self->{filter} ) {
        @values = $self->{filter}(@values);
    }
    if ( @values and defined $self->{handle} ) {
        print { $self->{handle} } join("\t", @values) . "\n";;
    }
}

1;
