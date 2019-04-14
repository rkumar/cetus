#!/usr/bin/env bash
# This zips selected files with a password
FILE=~/tmp/selected_files
TODAY=$(date +"%Y%m%d%H%M")
TARGET=enc_${TODAY}.zip
if [[ -f $FILE ]]; then
  wc -l $FILE
else
  # use $1 file under cursor
  printf "Using $1. "
  TARGET="$1.zip"
  echo "$1" > $FILE
fi
printf "Enter zip file name ($TARGET): "
read ANSWER
ANSWER=${ANSWER:-$TARGET}
cat $FILE | zip -e $ANSWER -@
