package SeeAlso::Identifier::GND;

use strict;
use warnings;

=head1 NAME

SeeAlso::Identifier::GND - Identifier of the GND Authority File

=head1 DESCRIPTION

This class handles an identifier of the "Gemeinsame Normdatei" (GND), 
a common authority file of names, subjects, and organizations that is 
coordinated by the German National Library. GND is beeing build by
combining the Names Authority File "Personennamendatei" (PND), the 
Subject Headings Authority File "Schlagwortnormdatei" (SWD), and the 
Corporate Body Authority File "Gemeinsame Körperschaftsdatei" (GKD).
Furthermore it is planned to include the Uniform Title Authority file
"Einheitssachtitel" (EST).

Each authority file record has an unique number which is modeled by 
this class. A GND number consists of up to eight digits and a check digit 
which may also be an 'X'.  Heading zero digits are removed. There is an
URI representation of a GND number that can be created by prepending
'http://d-nb.info/gnd/'.

This subclass of L<SeeAlso::Identifier> overrides the constructor
C<new> and the methods C<valid> and C<normalized>.

=cut

use SeeAlso::Identifier;
use Carp;

use base qw( SeeAlso::Identifier );
our $VERSION = "0.54";

=head1 METHODS

=head2 new ( [ $value ] )

Create a new GND identifier.

=cut

sub new {
    my $class = shift;
    my $self = bless { }, $class;
    $self->value( shift || "" );
    return $self;
}

=head2 value ( [ $value ] )

Get and/or set the value of this identifier. Whitespaces at the ends of 
the value string, the character '-', and one of the prefixes 'GND', 'PND',
'GKD', 'EST', 'http://d-nb.info/gnd/' are removed as well as zeros at the
beginning.

=cut

sub value {
    my $self = shift;
    my $value = shift;

    if (defined $value) {
        $value =~  s/^\s+|\s+$//;
        $value =~ s/^http:\/\/d-nb.info\/gnd\/|(GND|pnd|SWD|GKD|EST)\s*//i;
        $value =~  s/^0+//; # zeros
        $value =~ s/-//g;
        $self->{value} = uc($value);
    }

    return $self->{value};
}

=head2 valid ( )

Test whether the GND consists of 8 digits plus the right check digit. Because
there are two methods for check digit computation, not all errors can be detected.

=cut

sub valid {
    my $self = shift;
    my $value = $self->{value};

    # TODO: fix bad syntax
    if ($value) { # not on empty value
        for (my $i = 9-length($value);$i>0;$i--) {
            $value =  "0$value";
        }
    }

    $value =~ /^([0-9])([0-9])([0-9])([0-9])([0-9])([0-9])([0-9])([0-9])([0-9X])$/ 
    || return;
    my $sum = $1*9 + $2*8 + $3*7 + $4*6 + $5*5 + $6*4 + $7*3 + $8*2;
    my $c = $9 eq 'X' ? 10 : $9;
    $sum %= 11;

    return ((((11 - $sum) % 11) eq $c) or ((11 - (11 - $sum) % 11) eq $c));
}

=head2 normalized ( )

Return a normalized version of the GND identifier as Uniform
Resource Identifier (URI) by adding the prefix 'http://d-nb.info/gnd/'.
If the identifier is not valid, this methods returns an empty string.

=cut

sub normalized {
    my $self = shift;
    return $self->valid() ? ("http://d-nb.info/gnd/" . $self->{value}) : "";
}

=head2 indexed ( )

Return a shortened version of the GND identifier, that is the valid 
GND without hyphen, prefix, or heading zeroes. You could further 
strip off the check digit.

=cut

sub indexed {
    my $self = shift;
    return $self->valid ? $self->{value} : undef;
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
