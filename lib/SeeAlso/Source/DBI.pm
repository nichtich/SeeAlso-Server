package SeeAlso::Source::DBI;

use strict;
use Carp qw(croak);
use DBI;

=head1 NAME

SeeAlso::Source::DBI - returns links stored in an SQL database

=cut

use SeeAlso::Source;

use vars qw( @ISA $VERSION );
@ISA = qw( SeeAlso::Source );
$VERSION = "0.40";

=head2 new ($dsi, $username, $auth, %attr)

Create a new SeeAlso server with a given database connection.

=cut

sub new {
    my ($class, $dsi, $table, $username, $auth, %attr) = @_;

    croak("database table must only contain letters, digitas and/or underscore")
        unless $table =~ /[a-z0-9_]+/;

    my $self = bless {
        errors => undef,
        table => $table
    }, $class;

    # TODO: remove this ugly code
    $self->{mQuery} = \&SeeAlso::Source::DBI::db_query;
    $self->{mQuerySelf} = 1;

    # database connection (TODO: stop messages to STDERR (by {'RaiseError' => 1}?))
    $self->{dbh} = DBI->connect($dsi, $username, $auth, %attr);
    if (not $self->{dbh}) {
        $self->errors("Failed to establish DBI connection");
        return $self;
    }

    # prepared statement
    # TODO: check '$table' and add LIMIT $limit
    my $query = "SELECT DISTINCT label, description, uri FROM $table WHERE identifier = ?";
    $self->{sth} = $self->{dbh}->prepare($query);
    if (not $self->{sth}) {
        $self->errors("Failed to create prepared statement");
        return $self;
    }

    # add insert into statement for single inserts (TODO: check this)
    $query = "INSERT INTO $table VALUES (?,?,?,?)";
    $self->{insert_sth} = $self->{dbh}->prepare($query);

    return $self;
}

=head2 db_query ( $identifier )

Gets a L<SeeAlso::Identifier> object and returns a L<SeeAlso::Response> object
or may throw an error. Do not directly call this but with the method C<query>!

=cut

sub db_query {
    my $self = shift;
    my $identifier = shift;

    my $response = SeeAlso::Response->new( $identifier->normalized );
    return $response unless $response->hasQuery;
    return $response unless $self->connected();

    my $sth = $self->{sth};

    $sth->execute( $identifier->indexed );
    while ( my @row = $sth->fetchrow_array ) {
        $response->add($row[0],$row[1],$row[2]);
    }

    return $response;
 }

=head2 connected

Return whether the database connection is established.

=cut

sub connected {
    my $self = shift;
    return $self->{dbh} && $self->{sth};
}

=head2 load_file ( $filename )

Load a local file into the database. Currently only MySQL is supported.
The local file must contain on each line identifier, label, description, 
and uri seperated by tabulator. The local file is not tested to conform
to this requirement, you can use the check_load_file method for this.
Returns the number of loaded records.

=cut

sub load_file {
    my $self = shift;
    my $filename = shift;

    croak("Not connected") unless $self->connected;
    croak("Cannot read input file $filename!")
        unless defined $filename and (-r $filename);

    my $dbh = $self->{dbh};
    my $table = $self->{table};

    $self->create_table();

    my $rows = $dbh->do( "LOAD DATA LOCAL INFILE " . $dbh->quote($filename) . " INTO TABLE $table" );

    return $rows;
}

=head2 create_table

purge and create table.

=cut

sub create_table {
    my $self = shift;

    croak("Not connected") unless $self->connected;

    my $dbh = $self->{dbh};
    my $table = $self->{table};

    $dbh->do( "DROP TABLE IF EXISTS $table" );
    $dbh->do( "CREATE TABLE $table (
        identifier  varchar(255) not null default '',
        label       varchar(255) not null default '',
        description varchar(255) not null default '',
        uri         varchar(255) not null default ''
      ) engine=InnoDB");
}

=head2 check_load_file ( $filename )

Test a local file whether it can be load into the database. Does not test 
whether the database connection is available but the integrity of the file
to be load with the load_file method. Each line must consists of identifier, 
label, description, and uri seperated by tabulator. 

Up to now this method is experimental. Only the existence of four values 
is checked, empty strings are allowed as well as malformed uris and 
duplicates.

This metod returns the number of malformed lines, so it returns 0 if 
the file is valid.

=cut

sub check_load_file {
    my $self = shift;
    my $filename = shift;

    croak("Cannot read input file $filename!")
        unless defined $filename and (-r $filename);

    my $errors = 0;

    open FILE, $filename or croak("Error openig $filename");
    while (<FILE>) {
        chomp;
        my @values = split "\t";
        $errors++ unless scalar(@values) == 4;
    }
    close FILE; 

    return $errors;
}

=head2 insert ( identifier, label, description, uri )

Inserts a single response content (experimental).

=cut

sub insert {
    my $self = shift;

    # TODO: use a SeeAlso::Response object instead
    my ($identifier, $label, $description, $uri) = @_;

    return unless $self->connected();
    my $insert_sth = $self->{insert_sth};

    return $insert_sth->execute( $identifier, $label, $description, $uri );
}

1;
