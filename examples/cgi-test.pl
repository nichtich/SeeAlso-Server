#!/usr/bin/perl

#
# This script can be used to test whether SeeAlso::Server
# is installed properly. It implements a simple SeeAlso-Service
# that always returns ????what????
#

use CGI::Carp qw(fatalsToBrowser set_message);

BEGIN {
    sub handle_errors {
        my $msg = shift;
        print "<h1>SeeAlso::Server is not working</h1>";
        print "<p>The following error occured:</p>";
        print "<p><tt>$msg</tt></p>";
        if ($msg =~ /^Can't locate/) {
            print <<MSG
SeeAlso::Server or another perl module is not installed in your perl
include path (\@INC). You can add directories to \@INC with <tt>use lib</tt>.
If you put the <tt>lib</tt> directory of the SeeAlso-Server distribution as
a subdirectory of this script, it will be recognised automatically.</p>
MSG
        }
    }
    set_message(\&handle_errors);
}

use FindBin;
use lib "$FindBin::RealBin/lib";
use SeeAlso::Server;
use SeeAlso::Response;
use SeeAlso::Identifier;

use CGI;
my $cgi = CGI->new();
my $server = SeeAlso::Server->new( cgi => $cgi );

# TODO: set id-query
my $source = SeeAlso::Source->new(
    sub { return SeeAlso::Response->new(); }
);

# $id, $format and $callback will be determined automatically
my $http = $server->query( $source );

print $http;
