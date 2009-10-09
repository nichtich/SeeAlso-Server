package SeeAlso::DBI;

use strict;
use warnings;

=head1 NAME

SeeAlso::DBI - Store L<SeeAlso::Response> objects in database.

=cut

use DBI;
use DBI::Const::GetInfoType;
use Config::IniFiles;
use Carp qw(croak);

use base qw( SeeAlso::Source );
our $VERSION = '0.47';

=head1 SYNOPSIS

   # use database as SeeAlso::Source

   my $dbh = DBI->connect( ... );
   my $dbi = SeeAlso::DBI->new( dbh => $dbh );

   print SeeAlso::Server->new->query( $dbi );   

=head1 DESCRIPTION

A C<SeeAlso::DBI> object manages a store of L<SeeAlso::Response>
objects that are stored in a database. By default that database
must contain a table named C<seealso> with rows named C<hash>, 
C<label>, C<database>, and C<uri>. A query for identifier C<$id>
of type L<SeeAlso::Identifier> will result in an SQL query such as

  SELECT label, description, uri FROM seealso WHERE hash=?

With the hashed identifier (C<$id<gt>hash>) used as query parameter.
By default a database table accessed with this class stores the four
values hash, label, description, and uri in each row - but you can also
use other schemas.

=head1 METHODS

=head2 new ( %parameters )

Create a new database store. You must specify either a database handle in 
form or a L<DBI> object with parameter C<dbh> parameter, or a C<dbi>
parameter that is passed to C<DBI-E<gt>connect>, or a C<config> parameter
to read setting from the C<[DBI]> section of a configuration file.

  my $dbh = DBI->new( "dbi:mysql:database=$d;host=$host", $user, $password );
  my $db = SeeAlso::DBI->new( dbh => $dbh );

  my $db = SeeAlso::DBI->new( 
      dbi => "dbi:mysql:database=$database;host=$host", 
      user => $user, passwort => $password
  );

  my $db = SeeAlso::DBI->new( config => "dbiconnect.ini" );

The configuration file must be an INI file that contains a section named
C<[DBI]>. All values specified in this section are added to the constructor's
parameter list. Alternatively you directly can pass hash reference instead
of a file name. A configuration file could look like this (replace uppercase 
values with real values):

  [DBI]
  dbi = mysql:database=DBNAME;host=HOST
  user = USER
  password = PWD

The following parameters are recognized:

=over

=item config

Configuration file (as filename, GLOB, GLOB reference, IO::File, scalar reference)
or reference to a hash with parameters that will override the other parameters.

=item dbh

Database Handle of type L<DBI>.

=item dbh_ro

Database Handle of type L<DBI> that will be used for all read access.
Usefull for master-slave database settings.

=item dbi

Source parameter to create a C<DBI> object. C<"dbi:"> is prepended if
the parameter does not start with this prefix.

=item user

Username if parameter C<dbi> is given.

=item password

Password if parameter C<dbi> is given.

=item table

SQL table name for default SQL statements (default: C<seealso>).

=item select

SQL statement to select rows.

=item delete

SQL statement to delete rows.

=item insert

SQL statement to insert rows.

=item clear

SQL statement to clear the database table.

=item build

Newly create the SQL table with the create statement.

=back

=cut

sub new {
    my ($class, %attr) = @_;

    if ( $attr{config} ) {
        my $cfg = $attr{config};
        if ( ref($cfg) eq 'HASH' ) {
            foreach my $hash ( keys %{ $cfg } ) {
                $attr{$hash} = $cfg->{$hash};
            }
        } else {
            my $ini = Config::IniFiles->new( -file => $attr{config} );
            foreach my $hash ( $ini->Parameters('DBI') ) {
                $attr{$hash} = $ini->val('DBI',$hash);
            }
        }
    }

    if ( $attr{dbi} ) {
        $attr{dbi} = 'dbi:' . $attr{dbi} unless $attr{dbi} =~ /^dbi:/i; 
        $attr{user} = "" unless defined $attr{user};
        $attr{password} = "" unless defined $attr{password};
        $attr{dbh} = DBI->connect( $attr{dbi}, $attr{user}, $attr{password} );
    }

    croak('Parameter dbh required') 
        unless UNIVERSAL::isa( $attr{dbh}, 'DBI::db' );
    croak('Parameter dbh_ro must be a DBI object') 
        if defined $attr{dbh_ro} and not UNIVERSAL::isa( $attr{dbh_ro}, 'DBI::db' );

    my $self = bless { }, $class;

    $self->{dbh} = $attr{dbh};
    $self->{dbh_ro} = $attr{dbh_ro};
    $self->{table} = defined $attr{table} ? $attr{table} : 'seealso';

    # build SQL strings
    my $table   = $self->{dbh}->quote_identifier( $self->{table} );
    my $hash    = $self->{dbh}->quote_identifier('hash');
    my $label   = $self->{dbh}->quote_identifier('label');
    my $descr   = $self->{dbh}->quote_identifier('description');
    my $uri     = $self->{dbh}->quote_identifier('uri');
    my $db_name = $self->{dbh}->get_info( $GetInfoType{SQL_DBMS_NAME} );
    my $values = "$label, $descr, $uri";

    my %sql = (
        'select' => "SELECT $values FROM $table WHERE $hash=?",
        insert   => "INSERT INTO $table ($hash,$values) VALUES (?,?,?,?)",
        # update  => "UPDATE $table SET $value = ? WHERE $hash=?",
        'delete' => "DELETE FROM $table WHERE $hash = ?",
        clear    => "DELETE FROM $table",
        # get_keys => "SELECT DISTINCT $hash FROM $table",
        create => "CREATE TABLE IF NOT EXISTS $table ("
            . " $hash VARCHAR(255), $label TEXT, $descr TEXT, $uri TEXT"
            . ")", 
        # TODO: create index:     
        #  $dbh->do( 'CREATE INDEX '.$table.'_isbn_idx ON '.$table.' (isbn)' );
    );

    foreach my $c ( qw(select insert delete clear create) ) {
        $self->{$c} = $attr{$c} ? $attr{$c} : $sql{$c};
    }

    $self->create if $attr{build};

    return $self;
}

=head2 query ( $identifier )

Fetch from DB, uses the hash value!

=cut

sub query_callback {
    my ($self, $identifier) = @_;

    my $hash = $identifier->hash;

    my $dbh = $self->{dbh_ro} ? $self->{dbh_ro} : $self->{dbh};
    my $sth = $dbh->prepare_cached( $self->{'select'} )
        or croak $dbh->errstr;
    $sth->execute($hash) or croak $sth->errstr;
    my $result = $sth->fetchall_arrayref;

    my $response = SeeAlso::Response->new( $identifier );

    foreach my $row ( @{$result} ) {
        $response->add( @{$row} );
    }

    return $response;
}


=head2 create

Create the database table.

=cut

sub create {
    my ($self) = @_;
    $self->{dbh}->do( $self->{'create'} ) or croak $self->{dbh}->errstr;
    return;
}

=head2 clear

Delete all content in the database.

=cut

sub clear {
    my ($self) = @_;
    $self->{dbh}->do( $self->{'clear'} ) or croak $self->{dbh}->errstr;
    return;
}

=head2 delete ( $identifier )

Removes all rows associated with a given identifier.

=cut

sub delete {
    my ($self, $identifier) = @_;
    $self->{dbh}->do( $self->{'delete'}, undef, $identifier->hash ) 
        or croak $self->{dbh}->errstr;
}

=head2 update ( $response )

Replace all rows associated with the the identifier of a given response
with the new response.

=cut

sub update {
    my ($self, $response) = @_;
    $self->delete( $response->identifier );
    $self->insert( $response );
}

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

    my $hash = $response->identifier->hash;
    my @rows;

    for(my $i=0; $i<$response->size; $i++) {
        my ($label, $description, $uri) = $response->get($i);
        push @rows, [$hash, $label, $description, $uri];
    }

    return $self->bulk_insert( sub { shift @rows } );
}

=head2 bulk_insert ( $fetch_quadruple_sub )

Add a set of quadrupels to the database. The subroutine $fetch_quadruple_sub
is called unless without any parameters, until it returns a false value. It
is expected to return a reference to an array with four values (hash, label,
description, uri) which will be added to the database. Returns the number
of affected rows or -1 if the database driver cannot determine this number.

=cut

sub bulk_insert {
    my ($self, $sub) = @_;

    croak('bulk_insert expects a code reference') unless ref($sub) eq 'CODE';

    my $sth = $self->{dbh}->prepare_cached( $self->{insert} );
    my $tuples = $sth->execute_for_fetch( $sub );
    $sth->finish;

    return $tuples;
}

=head2 bulk_import ( [ file => $file ... ] )

=cut

sub bulk_import {
    my ($self, %param) = @_;
    my $file = $param{file};
    croak 'No file specified' unless defined $file;

    my $label       = defined $param{label} ? $param{label} : '#2';
    my $description = defined $param{description} ? $param{description} : '#3';
    my $uri         = defined $param{uri} ? $param{uri} : '#4';

    open FILE, $file or croak "Failed to open file $file";
    binmode FILE, ":utf8";

    $self->bulk_insert( sub {
        my $line = readline(*FILE);
        return unless $line;
        chomp($line);
        my @v = split /\t/, $line;
        my ($l,$d,$u) = ($label,$description,$uri);

        no warnings;
        $l =~ s/#([0-9])/${v[$1-1]}/g;
        $d =~ s/#([0-9])/${v[$1-1]}/g;
        $u =~ s/#([0-9])/${v[$1-1]}/g;

        return [ $v[0], $l, $d, $u ];
    } );

    close FILE;
}

1;

=head1 SEE ALSO

This package was partly inspired by on L<CHI::Driver::DBI> by Justin DeVuyst
and Perrin Harkins.

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009 by Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
