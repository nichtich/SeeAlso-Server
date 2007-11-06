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
# TODO
#  /^(1)([0-4])([0-9])([0-9])([0-9])([0-9])([0-9])([0-9])([0-9X])$/
#$sum =0;
#  map?
#  for(i=1; i<9; i++) {
#  $sum += match[$i] * ($i+1);
#  }
#  $sum %= 11;
#  if ($sum == 10) $sum = 'X';
#  return $match[0] eq $sum;
}
