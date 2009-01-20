package SeeAlso::Source::ThingISBN;

use strict;
use utf8;
use Carp qw(croak);
use DBI;

use base qw( SeeAlso::Source::DBI );
our $VERSION = "0.3";

=head1 NAME

SeeAlso::Source::ThingISBN - thingISBN stored in a SQL database

=head1 DESCRIPTION

This class is a L<SeeAlso::Source> that contains thingISBN data.
See http://www.librarything.com/thingology/labels/thingisbn.php
for more information about thingISBN. Please note that usage of
the data provided by LibraryThing is not allowed for commercial
use (as far as I know). The current version works as a
L<SeeAlso::Source::DBI> that means you have to download
thingISBN.xml.gz and import it to your database. You could
also write a wrapper for the REST-based API.

=head1 METHODS

=head2 new ( %options )

Constructor.

=cut

sub new {
    my ($class, %options) = @_;

    my $dsn = $options{dsn};
    my $user = $options{user};
    my $password = $options{password};
    my $tld = $options{tld} || "com"; # Top level domain for links to LibrayThing

    my $loadTable = "isbn2ltwork";

    my $self = bless {
        loadTable => $loadTable,
        tld => $tld
    }, $class;

    if ($dsn) {
        $self->{dbh} = DBI->connect($dsn, $user, $password, {PrintError => 0})
        or $self->errors($DBI::errstr);
        $self->{driver} = lc($1) if $dsn =~ /^DBI:([^:]+):/i;
    }

    my $insertQuery = "INSERT INTO $loadTable VALUES (?,?)";
    my $isbn2workQuery = "SELECT work FROM $loadTable WHERE isbn=?";
    my $isbn2isbnQuery = "SELECT a.isbn FROM $loadTable AS a, $loadTable AS b WHERE a.work=b.work AND b.isbn=?";

    if ($self->{dbh}) {
        $self->{insertQuery} = $self->{dbh}->prepare($insertQuery);
        $self->{isbn2workQuery} = $self->{dbh}->prepare($isbn2workQuery);
        $self->{isbn2isbnQuery} = $self->{dbh}->prepare($isbn2isbnQuery);
    }

    return $self;
}

=head2 createTable

Purge and create database table.

=cut

sub createTable {
    my $self = shift;

    croak("Not connected") unless $self->connected;

    my $dbh = $self->{dbh};
    my $table = $self->{loadTable};

    $dbh->do( "DROP TABLE IF EXISTS $table" );
    my $sql = "CREATE TABLE $table ("
       . " isbn char(13),"
       . " work integer "
       . ")" ;
    $dbh->do($sql);
    $dbh->do( 'CREATE INDEX '.$table.'_isbn_idx ON '.$table.' (isbn)' );
    $dbh->do( 'CREATE INDEX '.$table.'_work_idx ON '.$table.' (work)' );
    # TODO: create indexes for isbn2isbnQuery (?)

    return 1;
}

=head2 mQuery ( $isbn )

Internal query method for a isbn-to-LibrayThing-work service

=cut

sub mQuery {
    my $self = shift;
    my $isbn = shift;

    croak("Not connected") unless $self->connected;
    croak("Invalid ISBN") unless $isbn->valid;

    my $tld = $self->{tld};

    my $query = $self->{isbn2workQuery};
    croak("query failed") unless $query->execute( $isbn->indexed );

    my $response = SeeAlso::Response->new( $isbn->normalized );

    while ( my @row = $query->fetchrow_array ) {
        my $work = $row[0];
        my $link = "http://www.librarything.$tld/work/$work";
        $response->add("LibraryThing","",$link);
    }

    return $response;
}

1;