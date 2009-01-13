package SeeAlso::Identifier::NBNDE;

use strict;
use warnings;

=head1 NAME

SeeAlso::Identifier::NBNDE - German National Library URN

=head1 DESCRIPTION

TODO!

See http://www.persistent-identifier.de/ and RFC 3188.

=cut

use SeeAlso::Identifier;
use Carp;
use Exporter;

use vars qw( $VERSION @ISA @EXPORT_OK );
@ISA = qw( SeeAlso::Identifier Exporter );
$VERSION = "0.10";
@EXPORT_OK = qw( calc_check_digit );

=head1 METHODS

=head2 new ( [ $value ] )

Create a new urn:nbn:de identifier

=cut

sub new {
    my $class = shift;
    my $self = bless { }, $class;
    $self->value( shift || "" );
    return $self;
}

=head2 value ( [ $value ] )

Get and/or set the value of this identifier.

=cut

sub value {
    my $self = shift;
    my $value = shift;

    if (defined $value) {
        $self->{value} = uc($value);
    }

    return "urn:nbn:de:" . $self->{value} . $self->{checksum};
}

my %check_digit_map = (
  48 => [1], 49 => [2], 50 => [3], 51 => [4], 52 => [5], 53 => [6], # 0-4
  54 => [7], 55 => [8], 56 => [9], 57 => [4,1], # 5-9
  97 => [1,8], # a
98 => [1,4], # b
99 => [1,9], # c
100 => [1,5], # d
101 => [1,6], # e
102 => [2,1], # f
103 => [2,2], # g
104 => [2,3], # h
105 => [2,4], # i
106 => [2,5], # j
107 => [4,2], # k
108 => [2,6], # l
109 => [2,7], # m
110 => [1,3], # n
111 => [2,8], # o
112 => [2,9], # p
113 => [3,1], # q
114 => [1,2], # r
115 => [3,2], # s
116 => [3,3], # t
117 => [1,1], # u
118 => [3,4], # v
119 => [3,5], # w
120 => [3,6], # x
121 => [3,7], # y
122 => [3,8], # z
45 => [3,9], # -
58 => [1,7] # :
);

=head1 ADDITIONAL FUNCTIONS

=head2 calc_check_digit ( $urn-without-check-digit )

Calculate the checkdigit for an URN in the urn:nbn:de namespace.
To validate an URN, strip off the check digit and compare it with
the return value of this function. calc_check_digit returns a digit
between 0 and 9 or undef if the provided urn value does not conform
to the urn:nbn:de syntax.

See http://www.persistent-identifier.de/?link=316 for a description
of the algorithm to calculate the check digit.

This implementation is improved by precalculated parts.

=cut

sub calc_check_digit {
    my $string = lc(shift);

    # urn:nbn:de:[Bibliotheksverbund]:[Bibliothekssigel]-[eindeutige Produktionsnummer][Prüfziffer]
    # urn:nbn:de:[vierstellige Ziffer]-[eindeutige Produktionsnummer][Prüfziffer]

    return unless $string =~ /^urn:nbn:de:(([a-z0-9]+:[a-z0-9]+|[0-9]{4})-[a-z0-9]+)$/;

    my @bytes = unpack 'C*', $1;

    # precalculated part "urn:nbn:de:" => "1112131713141317151617" => 801
    my $ps = 801;
    my $i = 23;
    my $c = ""; # letzte Zahl der URN-Ziffernfolge

    foreach ( @bytes ) {
        foreach ( @{ $check_digit_map{$_} } ) {
            $ps += $i * $_;
            $c = $_;
            $i++;
        }
    }

    # Der Quotient (Q) ergibt sich durch die Division der Produktsumme (PS) mit der letzten 
    # Zahl der URN-Ziffernfolge. Die letzte Ziffer des Quotienten (Q) vor dem Komma ist die 
    # Prüfziffer (PZ)

    return int($ps / $c) % 10;
}

1;

__END__

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2007-2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
