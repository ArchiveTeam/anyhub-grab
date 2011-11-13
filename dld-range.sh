#!/bin/bash
# Download a range of Anyhub files.
#
# Usage:  ./dld-range.sh {PREFIX}
# where PREFIX is the three-letter prefix for the range.
#

# this script needs wget-warc, which you can find on the ArchiveTeam wiki.

WGET_WARC=./wget-warc
if [ ! -x $WGET_WARC ]
then
  echo "./wget-warc not found."
  exit 3
fi

USER_AGENT="Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/533.20.25 (KHTML, like Gecko) Version/5.0.4 Safari/533.20.27"

prefix=$1

for c in {A..Z} {a..z} {0..9}
do
  echo "http://f.anyhub.net/${prefix}${c}"
done > "data/urls-${prefix}-1.txt"

date=$( date +'%Y%m%d' )

result=8
tries=1
while [ $result -eq 8 ]
do
  echo "Prefix: ${prefix}  try: ${tries}"
  $WGET_WARC -U "${USER_AGENT}" -e "robots=off" \
    -nv -o "data/wget-${prefix}-${tries}.log" \
    -O /dev/null \
    --warc-file="data/anyhub.net-${prefix}_-${date}-${tries}" \
    --warc-max-size=inf \
    --warc-header="operator: Archive Team" \
    --warc-header="anyhub-range-prefix: ${prefix}" \
    --input-file="data/urls-${prefix}-${tries}.txt"
  result=$?
  if [ $result -eq 8 ]
  then
    next_tries=$(( tries + 1 ))
    grep -B 1 'ERROR 50' "data/urls-${prefix}-${tries}.txt" \
      | grep -oE "http://[^:]+" \
      > "data/urls-${prefix}-${next_tries}.txt"
    if [ -s "data/urls-${prefix}-${next_tries}.txt" ]
    then
      tries=$next_tries
      result=9
    else
      result=0
    fi
  fi
done

