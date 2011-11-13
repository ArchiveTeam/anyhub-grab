#!/bin/bash
#
# Fix script errors in early downloads.
#
# This script will look in your data/ directory for downloads and
# fix the following (if necessary):
#
#  * Add - and _ to downloads that don't have it.
#
# Note: this script will NOT fix any user that's still being
# downloaded, that is, anything that has an .incomplete file.
# This means that you can run this script while a normal
# client is downloading, but you can't use this script to fix
# interrupted downloads.
#
# Usage:   fix-dld.sh ${YOURALIAS}
#

youralias="$1"

if [[ ! $youralias =~ ^[-A-Za-z0-9_]+$ ]]
then
  echo "Usage:  $0 {nickname}"
  echo "Run with a nickname with only A-Z, a-z, 0-9, - and _"
  exit 4
fi

initial_stop_mtime='0'
if [ -f STOP ]
then
  initial_stop_mtime=$( stat -c '%Y' STOP )
fi

for d in data/*
do
  prefix=$( basename "$d" )
  need_fix=0

  if [ -f "${d}/.incomplete" ]
  then
    echo "${prefix} is still incomplete, not fixing."
    continue
  fi

  # FIX 1: check for download of - and _
  if ! grep -q "${prefix}_" "${d}/wget"*".log"
  then
    if [ ! -f "${d}/urls-${prefix}-d1.txt" ]
    then
      echo "${prefix} is missing - and _, needs to be fixed."
      touch "${d}/.incomplete"
      if ./append-dash-underscore.sh "${prefix}"
      then
        need_fix=1
      fi
    fi
  fi

  # fix, if necessary
  if [[ $need_fix -eq 1 ]]
  then
    if ! ./dld-single.sh "$youralias" "${prefix}"
    then
      exit 6
    fi
  fi

  if [ -f STOP ] && [[ $( stat -c '%Y' STOP ) -gt $initial_stop_mtime ]]
  then
    exit
  fi
done

