package SeeAlso::Identifier::PND;

use strict;
use warnings;

=head1 NAME

SeeAlso::Identifier::PND - identifier in the German Personennamendatei (PND)

=cut

use SeeAlso::Identifier;
use Carp;

use vars qw( $VERSION @ISA );
@ISA = qw( SeeAlso::Identifier );
$VERSION = "0.1";

=head1 METHODS

=head2 new ( [ $value ] )

Create a new PND identifier.

=cut

sub new {
    my $class = shift;
    return bless {
        value => uc(shift || "")
    }, $class;
}

=head2 valid

Check for validness.

=cut

sub valid() {
    my $self = shift;
    my $value = $self->{value};
    # TODO: optimize
    return unless
        $value =~ /^(1)([0-4])([0-9])([0-9])([0-9])([0-9])([0-9])([0-9])([0-9X])$/;
    my $sum = $1*2 + $2*3 + $3*4 + $4*5 + $5*6 + $6*7 + $7*8 + $8*9;
    $sum %= 11;
    $sum = 'X' if $sum == 10;
    return $sum eq $9;
}

1;