#!/bin/bash
#
# This bash script downloads thingISBN unless the local copy is up to date.
#

URLDIR="http://www.librarything.com/feeds"
FILE=thingISBN.xml.gz

WGET_PARAMS="--timestamping --progress=dot:mega"

echo Downloading $URLDIR/$FILE ...
echo "wget $WGET_PARAMS $URLDIR/$FILE"
WGET_OUTPUT=$(2>&1 wget $WGET_PARAMS $URLDIR/$FILE)

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

