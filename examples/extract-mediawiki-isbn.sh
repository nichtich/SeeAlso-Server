#!/bin/bash

if [ ! -n "$1"  ]; then
  echo "Usage: `basename $0` database-dump-file language-code"
  exit 1
fi

DUMP="$1"
WIKI="$2" # TODO: regexp from database-dump!
OUT=isbn2wiki.load

echo "Extract and transform ISBN from $DUMP to $OUT"

./extract-mediawiki-templates.pl $DUMP | \
./transform-mediawiki-isbn.pl -log - -type isbn -wiki $WIKI - $OUT

# TODO: Extract templates and Identifiers in one step!