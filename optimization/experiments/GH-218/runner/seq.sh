#!/bin/bash
# seq.sh JOBFILE : each line "CORE OUT BIN ENV ARGS..." with ENV quoted as one token using | for spaces
while read -r core out bin envs rest; do
  [ -z "$core" ] && continue
  ./run1.sh $core $out $bin "${envs//|/ }" $rest
done < $1
