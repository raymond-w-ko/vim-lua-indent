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

do_tests()
{
  DIRECTORY=$1
  REMOVE_INDENT=$2
  INDENT_AMOUNT=''
  if [[ ! -z $3 ]]; then
    INDENT_AMOUNT="-c 'set sw=$3 sts=$3 ts=$3 noet'"
  fi

  for f in $DIRECTORY/*.ok.lua; do
    basename="${f%.ok.lua}"
    INPUT="$basename.in.lua"
    OUTPUT="$basename.OUT.lua"
    COMP="$basename.ok.lua"

    if [[ $REMOVE_INDENT -eq 0 ]]; then
      $VIM -c "write! $INPUT" -c "qa!" "$COMP"
    else
      $VIM -c "normal ggVG420<<" -c "write! $INPUT" -c "qa!" "$COMP"
    fi
    $VIM \
      -c "set nocompatible" \
      -c "edit $INPUT" \
      -c "syntax on" \
      $INDENT_AMOUNT \
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
}

# do_tests "basic" 1
# do_tests "basic_passthrough" 0
# do_tests "tsukuyomi" 0
do_tests "nmap" 0 2
