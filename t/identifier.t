#!perl -Tw

use strict;

use Test::More tests => 26;

use SeeAlso::Identifier;

my $id = SeeAlso::Identifier->new();
ok( !$id->normalized() && !$id->indexed() && !$id->value() && !$id->valid(), "empty identifier" );

$id = SeeAlso::Identifier->new("0");
ok( $id->normalized() eq "0" && $id->indexed() eq "0" && $id->value() eq "0" && $id->valid(), "identifier = '0'" );

$id = SeeAlso::Identifier->new("xy");
ok( $id->normalized() eq "xy" && $id->indexed() eq "xy" && $id->value() eq "xy" && $id->valid(), "identifier = 'xy'" );

is( $id->canonical, 'xy', 'canonical()' );
is( $id->indexed, 'xy', 'indexed()' );
is( $id->hash, 'xy', 'hash()' );
is( "$id", 'xy', '"" (overload)' );

my $s = \*STDOUT;
$id = SeeAlso::Identifier->new( $s );
ok( $id->normalized eq $s && $id->indexed() eq $s && $id->value() eq $s && $id->valid(), "non-string identifier" );

$id = SeeAlso::Identifier->new( 'valid' => sub { return 1; } );
ok( $id->value eq "" , "undefined value with handler" );

# lowercase alpha only
sub lcalpha {
   my $v = shift;
   $v =~ s/[^a-zA-Z]//g;
   return lc($v);
}
$id = SeeAlso::Identifier->new(
  'valid' => sub {
     my $v = shift;
     return $v =~ /^[a-zA-Z]+$/;
  },
  'normalized' => \&lcalpha
);
$id->value("AbC");

ok( $id->valid , "extension: valid");
ok( $id->normalized eq "abc" && $id->indexed eq "abc", "extension: normalized and indexed" );

ok( SeeAlso::Identifier->new('A') == SeeAlso::Identifier->new('A'), '== (overload)' );
ok( SeeAlso::Identifier->new('A') eq SeeAlso::Identifier->new('A'), 'eq (overload)' );
ok( SeeAlso::Identifier->new('A') != SeeAlso::Identifier->new('B'), '!= (overload)' );
ok( SeeAlso::Identifier->new('A') ne SeeAlso::Identifier->new('B'), 'ne (overload)' );

is( $id->parse('abc'), 'abc', 'parse as method' );
is( SeeAlso::Identifier::parse('xyz'), 'xyz', 'parse as function' );


### Example of a derived class

{
    package GVKPPN;

    use base qw(SeeAlso::Identifier);

    sub parse {
        my ($self, $value) = @_;
        return $value =~ /^(gvk:ppn:)?([0-9]*[0-9x])$/i ? lc($2) : '';
    }

    sub hash {
        my $self = shift;
        return '' unless $self->valid;
        return substr($self->value,0,length($self->value)-1);
    }

    sub canonical {
        my $self = shift;
        return '' unless $self->valid;
        return 'gvk:ppn:' . $self->value;
    }

    1;
}

my %ppns = (
    'gvk:ppn:355634236' => '355634236', 
    'gvk:PPN:593861493' => '593861493',
    'ppnx' => undef,
);
 
foreach my $s (keys %ppns) {
    my $ppn = GVKPPN->new($s);
    if ( defined $ppns{$s} ) {
        is( $ppn->value, $ppns{$s}, 'derived class' );
        my $v = lc($s); $v =~ s/x/X/;
        is( $ppn->canonical, $v, 'derived class - canonical' );
        $v = substr($ppn->value,0,length($ppn->value)-1);
        is( $ppn->hash, $v, 'derived class - hash' );
    } else {
        is( $ppn, '', 'derived class - value (undef)' );
        is( $ppn->canonical, '', 'derived class - canonical (undef)' );
        is( $ppn->hash, '', 'derived class - hash (undef)');
    }
}


__END__
##### ISSN

package Identifier::ISSN;

urn:issn

sub parse 
is_valid_checksum( $string )

sub compact {
    return $$self
}

=item indexed 

The form that is used for indexing. This could be '0002936X'
or '0002936' because hyphen and check digit do not contain
information. You could also store the ISSN in the 32 bit
integer number '2996' instead of a string.

### Example: VIAF-ID
package SeeAlso::Identifier::VIAF;

use base qw(SeeAlso::Identifier);

sub parse {
    my ($self, $value) = @_;
    $value =~ s/^\s+|\s+$//g;                                         
    return $2 if $value =~ /^(http:\/\/viaf.org\/)?([0-9]+)/;        
}

sub canonical {
    return 'http://viaf.org/' . $_[0]->value if $_[0]->value ne '';
    return '';
}
