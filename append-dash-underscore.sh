#!/bin/bash
# Downloads files ending with _ and - from the given prefix.
#
# Usage:  ./append-dash-underscore.sh {PREFIX}
# where PREFIX is the three-letter prefix for the range.
#

# this script needs wget-warc, which you can find on the ArchiveTeam wiki.

WGET_WARC=./wget-warc
if [ ! -x $WGET_WARC ]
then
  echo "./wget-warc not found."
  exit 3
fi

VERSION="20111113.02"

USER_AGENT="Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/533.20.25 (KHTML, like Gecko) Version/5.0.4 Safari/533.20.27"

prefix=$1

prefixdir="data/$1"

mkdir -p "${prefixdir}"
touch "${prefixdir}/.incomplete"

for c in - _
do
  echo "http://f.anyhub.net/${prefix}${c}"
done > "${prefixdir}/urls-${prefix}-d1.txt"

date=$( date +'%Y%m%d' )

result=8
tries=1
while [ $result -eq 8 ]
do
  echo "  Downloading prefix: ${prefix}  try: ${tries}"
  $WGET_WARC -U "${USER_AGENT}" -e "robots=off" \
    -nv -o "${prefixdir}/wget-${prefix}-d${tries}.log" \
    -O /dev/null \
    --max-redirect=0 \
    --warc-file="${prefixdir}/anyhub.net-${prefix}_-${date}-d${tries}" \
    --warc-max-size=inf \
    --warc-header="operator: Archive Team" \
    --warc-header="anyhub-range-prefix: ${prefix}" \
    --input-file="${prefixdir}/urls-${prefix}-d${tries}.txt"
  result=$?
  if [ $result -eq 8 ]
  then
    next_tries=$(( tries + 1 ))
    grep -B 1 'ERROR 50' "${prefixdir}/urls-${prefix}-d${tries}.txt" \
      | grep -oE "http://[^:]+" \
      > "${prefixdir}/urls-${prefix}-d${next_tries}.txt"
    if [ -s "${prefixdir}/urls-${prefix}-d${next_tries}.txt" ]
    then
      tries=$next_tries
      result=8
    else
      result=0
    fi
  fi
done

echo -n "  Prefix ${prefix} done: "
./du-helper.sh -hs "$prefixdir/"

rm "${prefixdir}/.incomplete"

exit 0

