#!/usr/bin/env bash

pass()
{
  echo -ne "\e[0;32mPASS\e[0m "
  echo "$@"
}

fail()
{
  echo -ne "\e[0;31mFAIL\e[0m "
  echo "$@"
}

for f in *.ok.lua; do
  basename="${f%.ok.lua}"
  INPUT="$basename.in.lua"
  OUTPUT="$basename.OUT.lua"
  COMP="$basename.ok.lua"

  vim -c "normal 1000<<" -c "write $INPUT" -c "qa!" "$COMP"
  vim -c "normal ggVG=" -c "write $OUTPUT" -c "qa!" "$INPUT"
  if diff "$COMP" "$OUTPUT" >/dev/null; then
    pass $basename
  else
    fail $basename
    echo expected:
    cat $COMP
    echo got:
    cat $OUTPUT
  fi
done
