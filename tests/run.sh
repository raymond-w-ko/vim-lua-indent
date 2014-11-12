#!/usr/bin/env bash

pass()
{
  echo -ne "\e[0;32mPASS\e[0m "
  echo "$@"
}

fail()
{
  echo -ne "\e[0;31mPASS\e[0m "
  echo "$@"
}

for f in *.in.lua; do
  basename="${f%.in.lua}"
  INPUT="$f"
  OUTPUT="$basename.out.lua"
  COMP="$basename.ok.lua"
  vim -c "normal ggVG=" -c "write $OUTPUT" -c "qa!" "$INPUT"
  if diff "$COMP" "$OUTPUT" >/dev/null; then
    pass $basename
  else
    fail $basename
  fi
done
