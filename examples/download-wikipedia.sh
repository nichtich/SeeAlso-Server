#!/bin/bash
#
# This bash script downloads a wikipedia dump
# unless the local copy is up to date.
#

if [ ! -n "$1" ]; then
  echo "Usage: `basename $0` language"
  echo "  with language being an ISO-639 code (en, fr, es...)"
  exit 1
fi

WIKI="$1wiki"

BASEDIR="http://download.wikipedia.org/$WIKI/latest"
FILE="$WIKI-latest-pages-articles.xml.bz2"

WGET_PARAMS="--timestamping --progress=dot:mega"

echo Downloading $BASEDIR/$FILE ...
echo "wget $WGET_PARAMS $BASEDIR/$FILE"
WGET_OUTPUT=$(2>&1 wget $WGET_PARAMS $BASEDIR/$FILE)

if [ $? -ne 0 ]; then
    # wget had problems.
    echo 1>&2 $0: "$WGET_OUTPUT"  Exiting.
    exit 1
fi

# MB/s or kB/s in download
if echo "$WGET_OUTPUT" | fgrep 'B/s' &> /dev/null
then
    echo "$FILE updated"
else
    echo "$FILE is up to date"
fi
