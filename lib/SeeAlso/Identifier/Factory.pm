package SeeAlso::Identifier::Factory;

use strict;
use warnings;

=head1 NAME

SeeAlso::Identifier::Factory - Identify and create identifiers

=cut

use SeeAlso::Identifier;
use Carp;
our $VERSION = '0.20';

=head1 DESCRIPTION

A SeeAlso::Identifier::Factory object is given a string (via its method
C<create>) and returns a well-defined L<SeeAlso::Identifier> object. A
factory is useful to parse a string that may be an identifier of several
identifier kinds. 

The factory knows a list of identifier types (subclasses of 
SeeAlso::Identifier); the first type that successfully parses the provided
string value is used to create the identifier object. If no type works,
an empty identifier of the first type is returned.

=head1 SYNOPSIS

  $identifier = $factory->create( $could_be_an_identifier_string );

=head1 METHODS

=head2 new ( %params )

Create a new Identifier Factory. You can either pass an array reference with
identifier class name or a hash of methods that will be used to create a new
identifier class:

  $factory = new SeeAlso::Identifier::Factory
      type => [qw( class1 class2 ... )]

  $factory = new SeeAlso::Identifier::Factory
      parse => sub { ... },
      canonical => sub { lc($_[0]) },
      hash => sub { md5_hex($_[0]) },
      type => '...';

=cut

sub new {
    my ($class, %params) = @_;

    my $self = bless {
        type => [ 'SeeAlso::Identifier' ]
    }, $class;

    my $type  = $params{'type'};
    my $parse = $params{'parse'};

    if ($parse) {
        croak('parse parameter must be a code reference')
            unless ref($parse) eq 'CODE';
        $self->{parse} = $parse;
    }

    if (ref($type) eq 'ARRAY') {
        $self->{type} = $type;
    } elsif (not ref($type) and $type) {
        $self->{type} = [$type];
    } else {
        croak('type parameter must be scalar or array reference');
        # TODO: also support hash reference
    }

    foreach my $type (@{$self->{type}}) {
        if ( not eval 'require ' . $type ) {
            if ( @{$self->{type}} == 1 ) {
                $params{type} = $type;
                makeclass( %params );
            }
        }
        UNIVERSAL::isa( $type, 'SeeAlso::Identifier' )
            or croak("$type must be a (subclass of) SeeAlso::Identifier");
    }

    return $self;
}

=head2 create ( $value )

Create a new L<SeeAlso::Identifier> object as described above.

=cut

sub create {
    my ($self, $value) = @_;

    # optional pre-parsing
    $value = $self->{parse}->($value) if $self->{parse};

    # use the first type that successfully parses the value
    foreach my $type (@{$self->{type}}) {
        my $id = $type->new( $value );
        return $id if $id;
    }

    # if none of the types creates a non-empty identifier, use the first type
    return $self->{type}->[0]->new( $value );
}

=head1 FUNCTIONS

=head2 makeclass

Dynamically creates a subclass of SeeAlso::Identifier with given name and methods.

=cut

sub makeclass {
    my (%params) = @_;

    my $type      = $params{'type'}; # required
    my $parse     = $params{'parse'};
    my $canonical = $params{'canonical'};
    my $hash      = $params{'hash'};
    my $cmp       = $params{'cmp'};

    my @out = "{\n  package $type;";
    push @out, '  require SeeAlso::Identifier; use Data::Dumper;';
    push @out, '  our @ISA = qw(SeeAlso::Identifier);';
    if ($parse) {
        push @out, '  sub parse {';
        push @out, '    my $value = $parse->( shift );';
        push @out, '    return defined $value ? "$value" : "";';
        push @out, '  }';
    }

    push @out, 'sub canonical { my $s = $canonical->($_[0]->value); defined $s ? "$s" : ""; }'
        if $canonical;

    push @out, 'sub hash { my $s = $hash->($_[0]->value); defined $s ? "$s" : ""; }'
        if $hash;

    # TODO: cmp

    push @out, '1; };';
    my $out = join("\n",@out);

    # print $out;# if $print;
    { no warnings; eval $out; }
    carp $@ if $@;

    return $type;
}

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.

