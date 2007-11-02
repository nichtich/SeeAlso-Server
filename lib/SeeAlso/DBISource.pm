package SeeAlso::DBISource;

use strict;
use Carp qw(croak);
use DBI;

=head1 NAME

SeeAlso::DBISource - Returns links stored in an SQL database

=cut

use vars qw(@ISA);
@ISA = qw( SeeAlso::Source );

=head2 new ($dsi, $username, $auth, %attr)

Create a new SeeAlso server with a given database connection.

=cut

sub new {
    my ($class, $dsi, $table, $username, $auth, %attr) = @_;

    my $self = bless {
        dbh => undef,
        sth => undef,
        new => $attr{new}
    }, $class;

    undef $attr{new} if defined $attr{new}; # ?

    # database connection
    $self->{dbh} = DBI->connect($dsi, $username, $auth, %attr);
    croak("Failed to establish DBI connection") unless $self->{dbh};

    # prepared statement
    # TODO: check '$table' and LIMIT $limit
    my $query = "SELECT DISTINCT title, url FROM $table WHERE identifier = ?";  
    if ($self->{new}) {
        $query = "SELECT DISTINCT title, description, url FROM $table WHERE identifier = ?";
    }
    $self->{sth} = $self->{dbh}->prepare($query);
    croak("Failed to create prepared statement") unless $self->{sth};

    return $self;
}

=head2 query ( $identifier )

Gets a L<SeeAlso::Identifier> object and returns
a L<SeeAlso::Response> object or undef.

Mayb raise an error!

=cut

sub query {
    my ($self, $identifier) = @_;

    my $response = SeeAlso::Response->new( $identifier->normalized );
    return $response unless $response->hasQuery;

    my $sth = $self->{sth};

    # TODO: try, catch
    $sth->execute( $identifier->indexed );

    # TODO: or return $result; # TODO: log $sth->errstr / "RaiseError"

    while ( my @row = $sth->fetchrow_array ) {
        if ($self->{new}) {
          $response->add($row[0],$row[1],$row[2]);
        } else {
          $response->add($row[0],"",$row[1]);
        }
    }

    return $response;
 }

1;