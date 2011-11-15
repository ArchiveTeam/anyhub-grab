#!/bin/bash
#
# Upload complete files to batcave.
#
# This script will look in your data/ directory to find
# users that are finished. It will upload the data for
# these users to the $DEST folder using rsync.
#
# Suggested $DEST format:
#   ${SERVER}::${MODULENAME}/anyhub/
#
# You can run this while you're still downloading,
# since it will only upload data that is done.
#
# Usage:
#   ./upload-finished.sh $DEST
# (ask SketchCow for a module name)
#
# You can set a bwlimit for rsync, e.g.:
#   ./upload-finished.sh $DEST 300
#

dest=$1
if [ -z "$dest" ]
then
  echo "Usage:  $0 [dest] [bwlimit]"
  exit
fi
if [[ ! $dest =~ ^[.a-zA-Z0-9]+::[a-zA-Z0-9]+/anyhub/$ ]]
then
  echo "$dest does not look like a proper rsync destination."
  echo "Usage:  $0 [dest] [bwlimit]"
  exit
fi

bwlimit=$2
if [ -n "$bwlimit" ]
then
  bwlimit="--bwlimit=${bwlimit}"
fi

cd data/
find -mindepth 1 -maxdepth 1 -type d -name "???" | while read d
do
  if [ ! -f "${d}/.incomplete" ]
  then
    echo "${d}/"
  fi
done | rsync \
      -avz --partial \
      --compress-level=9 \
      --progress \
      ${bwlimit} \
      --exclude=".incomplete" \
      --files-from="-" \
      --recursive \
      ./ ${dest}

