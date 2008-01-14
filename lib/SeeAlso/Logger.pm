package SeeAlso::Logger;

=head1 NAME

SeeAlso::Logger - log SeeAlso service requests

=cut

use strict;
use Carp qw(croak);
use POSIX qw(strftime);

use vars qw($VERSION);
$VERSION = "0.2";

=head1 DESCRIPTION

This class provides the log method to log requests of a SeeAlso service.
Each line in the log is a is tabulator seperated list of timestamp,
host, referer, service, search term (id), validity check, and the 
number of responses.

=head1 METHODS

=head2 new ( [ $file-or-handle ] )

Create a new parser. Gets a a reference to a file handle or a file name.

=cut

sub new {
    my $class = shift;
    $class = ref $class || $class;
    my $file = shift;

    my $self = bless {
        counter => 0,
        filename => "",
        filehandle => undef
    }, $class;

    $self->set_file($file) if defined $file;

    return $self;
}


=head2 set_file ( $file-or-handle )

Set the file handler or file name to log to.

=cut

sub set_file {
    my $self = shift;
    my $file = shift;

    my $ishandle = do { no strict; defined fileno($file); };
    if ($ishandle) {
        $self->{filename} = "";
        $self->{filehandle} = $file;
    } else {
        $self->{filename} = $file;
        $self->{filehandle} = eval { local *FH; open( FH, ">>$file" ) or die; binmode FH, ":utf8"; *FH{IO}; };
        if ( $@ ) {
            croak("Failed to open file for writing: $file");
        }
    }
}


=head2 log ( $cgi, $response, $service )

Log a request and response. The response must be a L<SeeAlso::Response> object, the service is string.

=cut

sub log {
    my ( $self, $cgi, $response, $service ) = @_;

    $self->{counter}++;

    return unless $self->{filehandle};

    my $host = $cgi->remote_host();
    my $referer = $cgi->referer();
    # my $ident = $cgi->remote_ident() || "-";
    # my $user =  $cgi->remote_user() || "-";
    # my $user_agent = $cgi->user_agent();

    my $datetime = strftime("%Y-%m-%dT%H:%M:%S", localtime);

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

    print { $self->{filehandle} } join('\t', @values);
}

1;
