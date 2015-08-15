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
LOG="results.diff"

do_tests()
{
  DIRECTORY=$1
  REMOVE_INDENT=$2

  for f in $DIRECTORY*.ok.lua; do
    basename="${f%.ok.lua}"
    INPUT="$basename.in.lua"
    OUTPUT="$basename.OUT.lua"
    COMP="$basename.ok.lua"

    if [[ $REMOVE_INDENT -eq 0 ]]; then
      $VIM -c "write! $INPUT" -c "qa!" "$COMP"
    else
      $VIM -c "normal ggVG420<<" -c "write! $INPUT" -c "qa!" "$COMP"
    fi
    if [[ -n $3 ]]; then
      $VIM \
        -c "set nocompatible lazyredraw" \
        -c "edit $INPUT" \
        -c "syntax on" \
        -c "source ../after/indent/lua.vim" \
        -c "set sw=$3 sts=$3 ts=$3 expandtab" \
        -c "normal ggVG=" \
        -c "write! $OUTPUT" \
        -c "qa!"
    else
      $VIM \
        -c "set nocompatible lazyredraw" \
        -c "edit $INPUT" \
        -c "syntax on" \
        -c "source ../after/indent/lua.vim" \
        -c "normal ggVG=" \
        -c "write! $OUTPUT" \
        -c "qa!"
    fi
    if diff "$COMP" "$OUTPUT" &>/dev/null ; then
      pass $basename
    else
      fail $basename
      echo "--------------------------------------------------------------------------------" >> $LOG
      echo "$OUTPUT" >> $LOG
      echo "$COMP" >> $LOG
      diff -rupN $COMP $OUTPUT >> $LOG
      if [[ -z $4 ]]; then
        exit 1
      fi
    fi
  done
}

echo "" > $LOG

do_tests "basic/" 1
do_tests "basic_passthrough/" 0
do_tests "tsukuyomi/" 0

# problematics ones which are clearly wrong
# do_tests "nmap/stdnse" 0 2
# do_tests "nmap/anyconnect" 0 2

do_tests "nmap/*" 0 2 1
