#!/usr/bin/env bash

GREEN="\e[0;32m"
RED="\e[0;31m"
NORM="\e[0m "

pass()
{
  echo -ne "$GREEN"
  echo -ne "PASS$NORM"
  echo "$@"
}

fail()
{
  echo -ne "$RED"
  echo -ne "FAIL$NORM"
  echo "$@"
}

VIM="vim -u NONE -U NONE -i NONE"

for f in *.ok.lua; do
  basename="${f%.ok.lua}"
  INPUT="$basename.in.lua"
  OUTPUT="$basename.OUT.lua"
  COMP="$basename.ok.lua"

  $VIM -c "normal ggVG420<<" -c "write! $INPUT" -c "qa!" "$COMP"
  $VIM \
    -c "set nocompatible" \
    -c "edit $INPUT" \
    -c "source ../after/indent/lua.vim" \
    -c "normal ggVG=" \
    -c "write! $OUTPUT" \
    -c "qa!"
  if diff "$COMP" "$OUTPUT" &>/dev/null ; then
    pass $basename
  else
    fail $basename
    diff -rupN $COMP $OUTPUT
    exit 1
  fi
done
