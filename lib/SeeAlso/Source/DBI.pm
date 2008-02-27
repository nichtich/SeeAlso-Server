package SeeAlso::Source::DBI;

use strict;
use Carp qw(croak);
use DBI;

use SeeAlso::Source;

use vars qw( @ISA $VERSION );
@ISA = qw( SeeAlso::Source );
$VERSION = "0.44";

=head1 NAME

SeeAlso::Source::DBI - returns links stored in an SQL database (abstract class)

=head1 DESCRIPTION

This class wraps a SQL database that can deliver links for a given identifiers.
It is an abstract subclass of L<SeeAlso::Source> and should not used directly.
Instead you should define a subclass that implements the following methods:

=over 4

=item mQuery

The query method as required by L<SeeAlso::Source>. The method gets a
L<SeeAlso::Identifier> object and returns a L<SeeAlso::Response> object.
The method should croak on errors.

=item createTable

Purges and (re)create the database table(s). Usually this is done via a
<tt>DROP TABLE IF EXISTS ...</tt> followed by a <tt>CREATE TABLE ...</tt>.

=item insertQuery

Returns a prepared statement to insert a row into the database. You
should either implement this method or set the property insertQuery.

=item loadTable

Returns the name of the standard table to load data into.
By default returns the propery loadTable.

=back

=head1 METHODS

=head2 new ( %options )

Create a new SeeAlso server with a given database connection.
Subclasses should set the property dbh with L<DBI> connect.
It is recommended to support the following options:

=over 4

=item dsi

First parameter for L<DBI> connect method

=item user

Database user

=item password

Database Password

=item limit

A numerical limit for queries

=back

Putting passwords into scripts is not recommended, so you should better
use places like pg_service.conf (Postgres) or my.cfg (MySQL).

=cut

sub new {
    my ($class, %options) = @_;

    my $self = bless {
    }, $class;

    return $self;
}

=head2 connected

Return whether a database connection has been established.
By default returns the propery dbh.

=cut

sub connected {
    my $self = shift;
    return $self->{dbh};
}

=head2 insertQuery

Returns a prepared statement to insert a row into the database.
By default returns the  property insertQuery.

=cut

sub insertQuery {
    my $self = shift;
    return $self->{insertQuery};
}

=head2 loadTable

Returns the name of the standard table to load data into.
By default returns the propery loadTable.

=cut

sub loadTable {
    my $self = shift;
    return $self->{loadTable};
}

=head2 loadFile ( %options )

Load data from a local file 'file' into the database. By default
the prepared statement returned by insertQuery will be used for
each line of the file. If the 'bulk' option is set, a much
faster bulk import is tried and data is loaded into the table
specified by loadTable.
Usage example:

  $db->loadFile( file => "links.tab", bulk => 1 );

The file must contain tabular seperated data.

Up to now bulk import is only implemented for MySQL.

=cut

sub loadFile {
    my ($self, %options) = @_;
    my $filename = $options{file} || "";
    my $bulk = $options{bulk} || 0;

    croak("Not connected") unless $self->connected;
    croak("Cannot read input file $filename!")
        unless defined $filename and (-r $filename);

    my $dbh = $self->{dbh};
    my $table = $self->{loadTable} || "seealso"; # TODO: check valid table name

    $bulk = 0 if not defined $self->{driver};
    if ($bulk) {
        $bulk = 0 if $self->{driver} ne "mysql";
    }
    if ($bulk) {
        if ($self->{driver} eq "mysql") { # MySQL
            my $rows = $dbh->do(
                "LOAD DATA LOCAL INFILE " 
                . $dbh->quote($filename) . " INTO TABLE $table"
            );
            # TODO: bulk import via STDIN instead of local file
            return $rows;
        } elsif ($self->{driver} eq "pg") { # PostgreSQL
            # TODO:  COPY $table FROM STDIN
            # See http://www.postgresql.org/docs/current/interactive/sql-copy.html
        }
    } else {
        open (FH, $filename) or croak("Failed to open $filename");
        my $query = $self->insertQuery;
        croak ("insertQuery not available in loadFile") unless $query;
        my $rows = 0;
        my $invalidRows = 0;
        while (<FH>) {
            if ( my @data = $self->parseInsertString($_) ) {
                $query->execute( @data ) && $rows++;
            } else {
                $invalidRows++;
            }
        }
        close FH;
        $self->errors("loadFile skipped $invalidRows invalid rows") if $invalidRows;
        return $rows;
    }
}

=head2 parseInsertString ( $string )

Parse a string to be inserted into the loadTable with insertQuery.
Implementations of this method must return undef (on error) or an
array that can directly be passed to insertQuery. By default
the method just removes a trailing newline and splits the line by
tabulators. Other implementations should also validate the data
for not to fill the database with junk.

=cut

sub parseInsertString {
    my $self = shift;
    my $line = shift;
    chomp $line;
    return split("\t",$line);
}

=head2 createTable

Purge and (re)create the table table(s). Usually this is done via a
<tt>DROP TABLE IF EXISTS ...</tt> followed by a <tt>CREATE TABLE ...</tt>.
This method is abstract and will always croak. Any implementation of
a subclass should return true on success.

=cut

sub createTable {
    my $self = shift;
    croak("createTable is not implemented");
}

=head2 insertResponse ( $response )

Insert links from a L<SeeAlso::Response> object. Not implemented by default.

=cut

sub insertResponse {
    my $self = shift;
    croak("insertResponse is not implemented");
}

1;
