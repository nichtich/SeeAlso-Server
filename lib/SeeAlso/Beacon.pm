package SeeAlso::Beacon;

use strict;
use warnings;

=head1 NAME

SeeAlso::Beacon - BEACON format parser and serializer

=cut

use Data::Validate::URI qw(is_uri);
use Time::Piece;
use Carp;

our $VERSION = '0.10';

=head1 SYNOPSIS

  use SeeAlso::Beacon;

  my $beacon = new SeeAlso::Beacon( $beaconfile );

  $beacon->meta(); # returns all meta fields as hash
  $beacon->meta( 'DESCRIPTION' => 'my best links' ); # set meta fields
  my $descr = $beacon->meta( 'DESCRIPTION' );        # get meta field
  $beacon->meta( 'DESCRIPTION' => '' );              # unset meta field

# Not implemented yet:
#  $beacon->size(); # number of lines, parsed so far
#  $beacon->parse( [$file], \&handler ); # parse all lines
#  $beacon->query( $id );

=head1 DESCRIPTION

=cut

=head1 METHODS

=head2 new ( [ $file ] )

Create a new Beacon object, optionally from a given file.

=cut

sub new {
    my $class = shift;
    my $self = bless { }, $class;
    $self->_startparsing( @_ );
    return $self;
}

=head2 meta ( [ $key [ => $value [ ... ] ] ] )

Get and/or set one or more meta fields. Returns a hash (no arguments),
or string or undef (one argument), or croaks on invalid arguments. A
meta field can be unset by setting its value to the empty string.
The FORMAT field cannot be unset. This method may also croak if supplied
invalid field for known fields such as FORMAT, PREFIX, FEED, EXAMPLES,
REVISIT, TIMESTAMP.

=cut

sub meta {
    my $self = shift;
    return %{$self->{meta}} unless @_;

    if (@_ == 1) {
        my $key = uc(shift @_);
        $key =~ s/^\s+|\s+$//g;
        return $self->{meta}->{$key};
    }

    croak('Wrong number of arguments in SeeAlso::Beacon->meta') if @_ % 2;

    my %list = (@_);
    foreach my $key (keys %list) {
        croak('invalid meta name: "'.$key.'"') 
            unless $key =~ /^\s*([a-zA-Z_-]+)\s*$/; 
        my $value = $list{$key};
        $key = uc($1);
        $value =~ s/\s+|\s+$|\n//g;
        if ($value eq '') { # empty field: unset
            croak 'You cannot unset meta field #FORMAT' if $key eq 'FORMAT';
            delete $self->{meta}->{$key};
        } else { # check format of known meta fields
            if ($key eq 'TARGET') {

                # TODO

            } elsif ($key eq 'FEED') {
                croak 'FEED meta value must be a HTTP/HTTPS URL' 
                    unless is_url($value);
            } elsif ($key eq 'PREFIX') {
                croak 'PREFIX meta value must be a URI' 
                    unless is_uri($value);
            } elsif ( $key =~ /^(REVISIT|TIMESTAMP)$/) {
                if ($value =~ /^[0-9]+$/) { # seconds since epoch
                    $value = gmtime($value)->datetime(); 
                    # TODO: add warning about this conversion
                } else {
                    croak $key . ' meta value must be of form YYYY-MM-DDTHH:MM:SS'
                        unless $value = Time::Piece->strptime( $value, '%Y-%m-%dT%T' );
                    $value = $value->datetime();
                }
            } elsif ( $key eq 'FORMAT' ) {
                croak 'Invalid FORMAT, must be BEACON or end with -BEACON'
                    unless $value =~ /^([A-Z]+-)?BEACON$/;
            } elsif ( $key eq 'EXAMPLES' ) {
                my @examples = map { s/^\s+|\s+$//g; $_ } split '\|', $value;
                $self->{examples} = [ grep { $_ ne '' } @examples ];
                $value = join '|', @{$self->{examples}};
                if ($value eq '') { # yet another edge case: "EXAMPLES: |" etc.
                    delete $self->{meta}->{EXAMPLES};
                    next;
                }
                # NOTE: examples are not checked for validity, we may need PREFIX first
            }
            $self->{meta}->{$key} = $value;
        }
    }
}

=head2 metastring 

Return all meta fields, serialized and sorted as string.

=cut

sub metastring {
    my $self = shift;
    my %meta = $self->meta();
    my @lines = '#FORMAT: ' . $meta{'FORMAT'};
    delete $meta{'FORMAT'};
    foreach my $key (keys %meta) {
        push @lines, "#$key: " . $meta{$key}; 
    }

    return @lines ? join ("\n", @lines) . "\n" : "";
}

=head2 warning( $string )

Adds a warning.

=cut

sub warning {
    my ($self, $warning) = @_;
    push @{$self->{warnings}}, $warning; # TODO: check this
}

=head2 parse ( [ $filename ] )

Parse all remaining links. If provided a file name, this starts a new Beacon.
That means the following is equivalent:

  $b = new SeeAlso::Beacon( $filename );

  $b = new SeeAlso::Beacon;
  $b->parse( $filename );

=cut

sub parse {
    my $self = shift;
    $self->_startparsing( @_ );
    
    # TODO: parse all lines (IDs) via parselink
}

=head2 parselink ( $line )

Parses a line, interpreted as link in BEACON format. Returns an array reference
with four values on success, an empty array reference for empty linkes, or an 
error string on failure. This method does not check whether the query identifier
is a valid URI, because it may be expanded by a prefix.

=cut

sub parselink {
    my ($self, $line) = @_;

    my @parts = map { s/^\s+|\s$//g; $_ } split('\|',$line);
    my $n = @parts;
    return [] if ($n < 1 || $parts[0] eq '');
    return "found too many parts (>4), divided by '|' characters" if $n > 4;
    my $link = [shift @parts,"","",""];

    $link->[3] = pop @parts
        if ($n > 1 && is_uri($parts[$n-2]));

    $link->[1] = shift @parts if @parts;
    $link->[2] = shift @parts if @parts;

    return "URI part has not valid URI form" if @parts; 

    return $link;
}

=head1 INTERNAL METHODS

=head2 _startparsing ( [ $filename ] )

Open a BEACON file and start parsing by parsing all meta fields,
and possibly the first link.

=cut

sub _startparsing {
    my $self = shift;

    $self->{meta} = { 'FORMAT' => 'BEACON' };
    $self->{lineno} = 0;
    $self->{examples} = [];
    $self->{warnings} = [];

    return unless @_;

    # TODO: open file and parse all meta fields
    my $filename = shift @_;

    open $self->{fh}, $filename;
    # TODO: check error on opening stream

    # TODO: remove BOM (allowed in UTF-8)
    # /^\xEF\xBB\xBF/
    while (my $line = readline $self->{fh}) {
        $line =~ s/^\s+|\s*\n?$//g;
        next if $line eq '';
        if ($line =~ /^#([^:=\s]+)(\s*[:=]?\s*|\s+)(.*)$/) {
            $self->meta($1,$3);
        } else {
            my $link = $self->parselink( $line );
            # TODO: handle $link
            last;
        }
    }
}

=head2 is_url ( $string )

Check whether a given String looks like a HTTP/HTTPS URL.

=cut

sub is_url {
    return $_[0] =~ /^http(s)?:\/\/[a-z0-9-]+(.[a-z0-9-]+)*(:[0-9]+)?(\/[^#|]*)?(\?[^#|]*)?$/i;
}

1;

__END__

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2007-2010 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
