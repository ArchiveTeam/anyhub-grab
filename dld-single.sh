#!/bin/bash
#
# Downloads a single prefix and tells the tracker it's done.
# This can be handy if dld-client.sh failed and you'd like
# to retry the prefix.
#
# Usage:   dld-single.sh ${YOURALIAS} ${PREFIX}
#

youralias="$1"
prefix="$2"

if [[ ! $youralias =~ ^[-A-Za-z0-9_]+$ ]]
then
  echo "Usage:  $0 {yournick} {prefix}"
  echo "Run with a nickname with only A-Z, a-z, 0-9, - and _"
  exit 4
fi

if [ -z $prefix ] || [[ ! $prefix =~ ^[0-9A-Za-z]+$ ]]
then
  echo "Usage:  $0 {yournick} {prefix}"
  echo "Provide a prefix."
  exit 5
fi

VERSION=$( grep 'VERSION=' dld-prefix.sh | grep -oE "[-0-9.]+" )

if ./dld-prefix.sh "$prefix"
then
  # complete

  # statistics!
  prefixdir="data/$prefix"
  bytes_str="{"
  bytes_str="${bytes_str}\"warc\":$( ./du-helper.sh -bs "${prefixdir}/" )"
  bytes_str="${bytes_str}}"

  success_str="{\"downloader\":\"${youralias}\",\"user\":\"${prefix}\",\"bytes\":${bytes_str},\"version\":\"${VERSION}\",\"id\":\"\"}"
  echo "Telling tracker that '${prefix}' is done."
  resp=$( curl -s -f -d "$success_str" http://anyhub.heroku.com/done )
  if [[ "$resp" != "OK" ]]
  then
    echo "ERROR contacting tracker. Could not mark '$prefix' done."
    exit 5
  fi
  echo
else
  echo "Error downloading '$prefix'."
  exit 6
fi

