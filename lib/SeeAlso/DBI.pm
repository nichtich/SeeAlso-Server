package SeeAlso::DBI;

use strict;
use warnings;

=head1 NAME

SeeAlso::DBI - Store L<SeeAlso::Response> objects in database.

=cut

use DBI::Const::GetInfoType;
use Carp qw(croak);

use base qw( SeeAlso::Source );
our $VERSION = '0.46';

=head1 SYNOPSIS

   my $dbh   = DBI->connect(...);
   my $source = SeeAlso::DBI->new( dbh => $dbh );
   # OR
   my $source = SeeAlso::DBI->new( dbh => $dbh, dbh_ro => $dbh_ro );

=head1 DESCRIPTION

By default a database table accessed with this class stores the 
four values key, label, description, and uri in each row - but you
can also use other database schemas. The key is a hashed 
L<SeeAlso::Identifier> that is used to query results.

=head1 METHODS

=head2 new ( %properties )

Create a new database table access. Required properties include
'dbh'

=over

=item table

Optional table name to be used when no sql strings are supplied.
The default table name is C<seealso>.

=cut

sub new {
    my ($class, %attr) = @_;
    my $self = bless { }, $class;

#use Data::Dumper;
#print Dumper(\%attr) . "\n";

    croak('Parameter dbh required') 
        unless UNIVERSAL::isa( $attr{dbh}, 'DBI::db' );
    croak('Parameter dbh_ro must be a DBI object') 
        if defined $attr{dbh_ro} and not UNIVERSAL::isa( $attr{dbh_ro}, 'DBI::db' );

    $self->{dbh} = $attr{dbh};
    $self->{dbh_ro} = $attr{dbh_ro};
    $self->{table} = defined $attr{table} ? $attr{table} : 'seealso';
    $self->{sql} = $attr{sql} || $self->_build_sql_strings;

    # TODO: check $sql{ fetch | store | create }

    # TODO: do not automatically create table - only if not exist
    if ( $attr{create_table} or ($attr{sql} and $attr{sql}->{create}) ) {
        $self->{dbh}->do( $self->{sql}->{create} )
            or croak $self->{dbh}->errstr;
    }

    return $self;
}

=head2 query ( $identifier )

Fetch from DB, uses the hash value!

=cut

sub query_callback {
    my ($self, $identifier) = @_;

    my $key = $identifier->hash;

    my $dbh = $self->{dbh_ro} ? $self->{dbh_ro} : $self->{dbh};
    my $sth = $dbh->prepare_cached( $self->{sql}->{fetch} )
        or croak $dbh->errstr;
    $sth->execute($key) or croak $sth->errstr;
    my $result = $sth->fetchall_arrayref;

    my $response = SeeAlso::Response->new( $identifier );

    foreach my $row ( @{$result} ) {
        $response->add( @{$row} );
    }

    return $response;
}


=head2 create

Create the database table  if a creation statement is given.

=cut

sub create {
    # ...
}

=head2 clear

Delete all content in the database if a clear statement is given.

=cut

sub clear {
    # ...
}

=head2 remove ( $identifier )

Removes all rows associated with a given identifier.

=cut

sub remove {
    # ...
}

=head2 update ( $response )

...

=cut

sub update {
    # ...
}

# bulk_update: better clear and bulk_insert
# or create a new table and switch afterwards

=head2 insert ( $response )

Add a L<SeeAlso::Response> to the database (unless the response is empty).
Returns the number of affected rows or -1 if the database driver cannot
determine this number.

=cut

sub insert {
    my ($self, $response) = @_;

    croak('SeeAlso::Response object required') unless
        UNIVERSAL::isa( $response, 'SeeAlso::Response' );

    return 0 unless $response->size;

    my $key = $response->identifier->hash;
    my @rows;

    for(my $i=0; $i<$response->size; $i++) {
        my ($label, $description, $uri) = $response->get($i);
        push @rows, [$key, $label, $description, $uri];
    }

    return $self->bulk_insert( sub { shift @rows } );
}

=head2 bulk_insert ( $fetch_quadruple_sub )

Add a set of quadrupels to the database. The subroutine $fetch_quadruple_sub
is called unless without any parameters, until it returns a false value. It
is expected to return a reference to an array with four values (key, label,
description, uri) which will be added to the database. Returns the number
of affected rows or -1 if the database driver cannot determine this number.

=cut

sub bulk_insert {
    my ($self, $sub) = @_;

    croak('bulk_insert expects a code reference') unless ref($sub) eq 'CODE';

    my $sth = $self->{dbh}->prepare_cached( $self->{sql}->{store} );
    my $tuples = $sth->execute_for_fetch( $sub );
    $sth->finish;

    return $tuples;
}


sub _build_sql_strings {
    my ($self) = @_;

    my $table   = $self->{dbh}->quote_identifier( $self->{table} );
    my $key     = $self->{dbh}->quote_identifier('key');
    my $label   = $self->{dbh}->quote_identifier('label');
    my $descr   = $self->{dbh}->quote_identifier('description');
    my $uri     = $self->{dbh}->quote_identifier('uri');
    my $db_name = $self->{dbh}->get_info( $GetInfoType{SQL_DBMS_NAME} );

    my $values = "$label, $descr, $uri";

    my $strings = {
        fetch   => "SELECT $values FROM $table WHERE $key=?",
        store   => "INSERT INTO $table ($key,$values) VALUES (?,?,?,?)",
        # update  => "UPDATE $table SET $value = ? WHERE $key=?",
        # remove   => "DELETE FROM $table WHERE $key = ?",
        # clear    => "DELETE FROM $table",
        # get_keys => "SELECT DISTINCT $key FROM $table",
        create => "CREATE TABLE IF NOT EXISTS $table ("
            . " $key VARCHAR(255), $label TEXT, $descr TEXT, $uri TEXT"
            . ")", 
        # TODO: create index:     
        #  $dbh->do( 'CREATE INDEX '.$table.'_isbn_idx ON '.$table.' (isbn)' );
    };

    # TODO: do not use this duplicate key stmt!
    if ( $db_name eq 'MySQL' ) {
        $strings->{store} =
            "INSERT INTO $table ( $key, $values )"
          . " VALUES (?,?,?,?)"
          . " ON DUPLICATE KEY UPDATE $values = VALUES($values)";
        delete $strings->{update};
    } elsif ( $db_name eq 'SQLite' ) {
        $strings->{store} =
            "INSERT OR REPLACE INTO $table"
        . " ( $key, $values ) VALUES (?,?,?,?)";
        delete $strings->{update};
    } else {
        # ...
    }

    return $strings;
}

1;

=head1 SEE ALSO

This package was partly based on L<CHI::Driver::DBI> by Justin DeVuyst
and Perrin Harkins.

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009 by Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
