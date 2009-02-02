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
# use CGI qw(-oldstyle_urls);

use SeeAlso::Identifier;
use SeeAlso::Response;
# use SeeAlso::Source;

use base qw( SeeAlso::Source );
our $VERSION = "0.1";
our @EXPORT = qw( seealso_request );

=head1 DESCRIPTION

...TODO...

=head1 METHODS

=head2 new ( $baseurl )

Creates a new SeeAlso client. You must specify a base URL.

=cut

sub new {
    my $class = shift;
    my $baseurl = shift;
    # my (%options) = @_;

    my $self = bless {
        'baseurl' => $baseurl || ""
    }, $class;

    return $self;

}

=head2 query ( $identifier )

Given an identifier (either a L<SeeAlso::Identifier> object or just a 
plain string) queries the SeeAlso Server that is specified with its 
base URL and returns a L<SeeAlso::Response> object on success.

TOOD: on failure: catch/trow

=cut

sub query {
    my ($self, $identifier) = @_;

    $identifier = SeeAlso::Identifier->new($identifier)
        unless UNIVERSAL::isa($identifier,"SeeAlso::Identifier");

    my $url = $self->{baseurl} . (index($self->{baseurl},'?') == -1 ? '?' : '&');
    $url .= "format=seealso&" unless $url =~ /format=/;
    $url .= "id=" . $identifier->normalized; # TODO urlescape
    # if (callback) url += "&callback=" + callback;
#print STDERR "$url\n";
    my $json = get($url);

    if (defined $json) {
        # TODO: this may croak!
        my $r = SeeAlso::Response->fromJSON( $json );
        use Data::Dumper;
        print STDERR Dumper($r) . "\n";;
        print STDERR $r->toJSON() . "\n";
    } else {
        # todo
        print STDERR "no json!\n";
    }
}

=head2 baseURL ( [ $url ] )

Get or set the base URL of the SeeAlso server to query by this client. If the
URL contains the 'format=seealso' parameter, it is treated as a SeeAlso Simple
server (plain JSON response), otherwise it is a SeeAlso Full server (unAPI 
support and OpenSearch description).

=cut

sub baseURL {
    my ($self, $url) = @_;
    if (defined $url) {
        $self->{baseurl} = $url; # TODO: check URL
    }

    # remove id, format, and callback parameter
    # my $q = "&" . $cgi->query_string();
    # $q =~ s/&(id|format|callback)=[^&]*//g;
    # $q =~ s/^&//;
    #return $cgi->url . "?$q" if $q;
    # return $cgi->url;

    return $self->{baseurl};
}

=head1 ADDITIONAL FUNCTIONS

=head2 seealso_request ( $baseurl, $identifier )

Equivalent to

  SeeAlso::Client->new($baseurl)->query($identifier)

=cut

sub seealso_request {
    my ($baseurl, $identifier) = @_;
    return SeeAlso::Client($baseurl)->query($identifier);
}

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2007-2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
