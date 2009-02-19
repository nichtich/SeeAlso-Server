#!/usr/bin/perl

use SeeAlso::Server;
use SeeAlso::Response;
use CGI;

my $cgi = new CGI;
my $id = $cgi->param("id");

sub query {
  my $identifier = shift;
  return unless $identifier->valid;

  my $response = SeeAlso::Response->new( $identifier );

  $response->add( $identifier->value, "hallo", "http://www.example.com/" );

  return $response;
}

my %description = (
  "ShortName" => "MySimpleServer"
);
my %param = (
  id => $id
);

$response = query_seealso_server( \&query, \%description, \%params );
print $response;

