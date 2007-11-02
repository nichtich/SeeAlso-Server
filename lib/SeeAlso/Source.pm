package SeeAlso::Source;

use strict;
use Carp qw(croak);
use SeeAlso::Response;

=head1 NAME

SeeAlso::Source - An source of OpenSearch Suggestions reponses

=head1 SYNOPSIS

  my $source = SeeAlso::Source->new();

=cut


=head2 new

Create a new source.

=cut

sub new {
    my ($class, $mQuery) = @_;

    my $self = bless {
        mQuery => $mQuery
    }, $class;

    croak("parameter to SeeAlso::Source->new must be a method")
        if defined $self->{mQuery} and ref($self->{mQuery}) ne "CODE";

    return $self;
}

=head2 query ( $identifier )

Gets a L<SeeAlso::Identifier> object and
returns a L<SeeAlso::Response> object or
undef.

TODO: what about failing query functions?
Where to catch errors?

=cut

sub query {
    my $self = shift;
     if (defined $self->{mQuery}) {
        return &{$self->{mQuery}}(@_);
    } else {
        return SeeAlso::Response->new();
    }
}

1;