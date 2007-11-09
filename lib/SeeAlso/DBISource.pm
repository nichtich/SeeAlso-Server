package SeeAlso::DBISource;

use strict;
use Carp qw(croak);
use DBI;

=head1 NAME

SeeAlso::DBISource - Returns links stored in an SQL database

=cut

use SeeAlso::Source;

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
        errors => ()
    }, $class;

    $self->{new} = $attr{new} if %attr;
    undef $attr{new} if defined $attr{new}; # ?

    # database connection (TODO: stop message to STDERR)
    $self->{dbh} = DBI->connect($dsi, $username, $auth, %attr);
    if (not $self->{dbh}) {
        $self->errors("Failed to establish DBI connection");
        return $self;
    }

    # prepared statement
    # TODO: check '$table' and LIMIT $limit
    my $query = "SELECT DISTINCT title, url FROM $table WHERE identifier = ?";  
    if ($self->{new}) {
        $query = "SELECT DISTINCT title, description, url FROM $table WHERE identifier = ?";
    }
    $self->{sth} = $self->{dbh}->prepare($query);
    if (not $self->{sth}) {
        $self->errors("Failed to create prepared statement");
        return $self;
    }

    return $self;
}

=head2 query ( $identifier )

Gets a L<SeeAlso::Identifier> object and returns
a L<SeeAlso::Response> object or undef.

=cut

sub query {
    my ($self, $identifier) = @_;

    my $response = SeeAlso::Response->new( $identifier->normalized );
    return $response unless $response->hasQuery;
    return $response unless $self->connected();

    my $sth = $self->{sth};


    eval {
        $sth->execute( $identifier->indexed );

        while ( my @row = $sth->fetchrow_array ) {
            if ($self->{new}) {
                $response->add($row[0],$row[1],$row[2]);
            } else {
                $response->add($row[0],"",$row[1]);
            }
        }
    };
    if ($@) {
        $self->errors($@);
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

1;