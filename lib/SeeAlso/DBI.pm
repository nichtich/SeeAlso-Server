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
   OR
   my $source = SeeAlso::DBI->new( dbh => $dbh, dbh_ro => $dbh_ro );

=head1 METHODS

=head2 new

=over

=item table

Optional table name to be used when no sql strings are supplied.
The default table name is C<seealso>.

=back

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

    if ( $attr{create_table} or ($attr{sql} and $attr{sql}->{create}) ) {
        $self->{dbh}->do( $self->{sql}->{create} )
            or croak $self->{dbh}->errstr;
    }

    return $self;
}


# = sub thaw 
=head2 query

Fetch from DB

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

# freeze # TODO: duplicates!!
sub store {
    my ($self, $response) = @_;

    croak('SeeAlso::Response object required') unless
        UNIVERSAL::isa( $response, 'SeeAlso::Response' );

    my $key = $response->identifier->hash;

    # TODO: store all results
    my $sth = $self->{dbh}->prepare_cached( $self->{sql}->{store} );

    $response->add("","","") unless $response->size;
    for(my $i=0; $i<$response->size; $i++) {
        my @values = $response->get($i);
        if ( not $sth->execute( $key, @values ) ) {
            if ( $self->{sql}->{store2} ) {
                my $sth =
                $self->{dbh}->prepare_cached( $self->{sql}->{store2} )
                or croak $self->{dbh}->errstr;
                $sth->execute( @values, $key )
                or croak $sth->errstr;
            } else {
                croak $sth->errstr;
            }
        }
    }
    $sth->finish;

    return;
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
        #store2  => "UPDATE $table SET $value = ? WHERE $key=?",
        # remove   => "DELETE FROM $table WHERE $key = ?",
        # clear    => "DELETE FROM $table",
        # get_keys => "SELECT DISTINCT $key FROM $table",
        create => "CREATE TABLE IF NOT EXISTS $table ("
            . " $key VARCHAR(255), $label TEXT, $descr TEXT, $uri TEXT"
            . ")", # index!
    };

    if ( $db_name eq 'MySQL' ) {
        $strings->{store} =
            "INSERT INTO $table ( $key, $values )"
          . " VALUES (?,?,?,?)"
          . " ON DUPLICATE KEY UPDATE $values = VALUES($values)";
        delete $strings->{store2};
    } elsif ( $db_name eq 'SQLite' ) {
        $strings->{store} =
            "INSERT OR REPLACE INTO $table"
        . " ( $key, $values ) VALUES (?,?,?,?)";
        delete $strings->{store2};
    }

    return $strings;
}

1;

=head1 SEE ALSO

This package is partly based on L<CHI::Driver::DBI> by Justin DeVuyst
and Perrin Harkins.

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009 by Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
