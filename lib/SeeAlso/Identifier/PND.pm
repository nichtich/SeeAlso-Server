package SeeAlso::Identifier::PND;

use strict;
use warnings;

=head1 NAME

SeeAlso::Identifier::PND - identifier in the German Personennamendatei (PND)

=head1 DESCRIPTION

This class handles an identifier in the German Personennamendatei (PND).
The PND is a name authority file used in libraries and museums to
unambiguously identify authors and other people. Because names cannot
be used to identify authors (homonyms, synonyms), each person record
in the PND has a unique identifier, the PND number, which is modeled
with C<SeeAlso::Identifier::PND>. A PND number consists of eight digits
and a checkdigit which may also be 'X'.

This subclass of L<SeeAlso::Identifier> overrides the constructor C<new>
and the method C<valid>.

=cut

use SeeAlso::Identifier;
use Carp;

use vars qw( $VERSION @ISA );
@ISA = qw( SeeAlso::Identifier );
$VERSION = "0.51";

=head1 METHODS

=head2 new ( [ $value ] )

Create a new PND identifier.

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

    return $self->{value};
}

=head2 valid

Check for validness.

=cut

sub valid() {
    my $self = shift;
    my $value = $self->{value};

    # The current PND-numbers all start with '10' to '14'
    # You can surely optimize this test

    return unless
        $value =~ /^(1)([0-4])([0-9])([0-9])([0-9])([0-9])([0-9])([0-9])([0-9X])$/;
    my $sum = $1*2 + $2*3 + $3*4 + $4*5 + $5*6 + $6*7 + $7*8 + $8*9;
    $sum %= 11;
    $sum = 'X' if $sum == 10;
    return $sum eq $9;
}

1;

__END__

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2007 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
