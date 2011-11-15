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

VERSION="20111115.02"

USER_AGENT="Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/533.20.25 (KHTML, like Gecko) Version/5.0.4 Safari/533.20.27"

prefix=$1

prefixdir="data/$1"

if [[ -f "${prefixdir}/.incomplete" ]]
then
  echo "  Deleting incomplete result for ${prefix}"
  rm -rf "${prefixdir}"
fi

if [[ -d "${prefixdir}" ]]
then
  echo "  Already downloaded ${prefix}"
  exit 0
fi

mkdir -p "${prefixdir}"
touch "${prefixdir}/.incomplete"


for c in {A..Z} {a..z} {0..9} - _
do
  echo "http://f.anyhub.net/${prefix}${c}"
done > "${prefixdir}/urls-${prefix}-1.txt"

date=$( date +'%Y%m%d' )

result=8
tries=1
while [ $result -eq 8 ]
do
  echo "  Downloading prefix: ${prefix}  try: ${tries}"
  $WGET_WARC -U "${USER_AGENT}" -e "robots=off" \
    -nv -o "${prefixdir}/wget-${prefix}-${tries}.log" \
    -O /dev/null \
    --max-redirect=0 \
    --warc-file="${prefixdir}/anyhub.net-${prefix}_-${date}-${tries}" \
    --warc-max-size=inf \
    --warc-header="operator: Archive Team" \
    --warc-header="anyhub-range-prefix: ${prefix}" \
    --input-file="${prefixdir}/urls-${prefix}-${tries}.txt"
  result=$?
  if [ $result -eq 8 ]
  then
    next_tries=$(( tries + 1 ))
    grep -B 1 'ERROR 50' "${prefixdir}/wget-${prefix}-${tries}.log" \
      | grep -oE "http://[^:]+" \
      > "${prefixdir}/urls-${prefix}-${next_tries}.txt"
    if [ -s "${prefixdir}/urls-${prefix}-${next_tries}.txt" ]
    then
      tries=$next_tries
      result=8
    else
      result=0
    fi
  elif [ $result -ne 0 ]
  then
    echo "  wget returned an error (ERROR ${result})."
    echo "  Check the wget log ${prefixdir}/wget-${prefix}-${tries}.log to see what it was."
    echo
    tail -n 10 "${prefixdir}/wget-${prefix}-${tries}.log"
    echo
    exit 4
  fi
done

echo -n "  Prefix ${prefix} done: "
./du-helper.sh -hs "$prefixdir/"

rm "${prefixdir}/.incomplete"

exit 0

