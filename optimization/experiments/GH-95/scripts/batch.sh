#!/bin/bash
# usage: batch.sh BIN OUTDIR CPULIM [LISTFILE]
bin="$1"; out="$2"; lim="$3"; list="${4:-/dev/stdin}"
S="$(dirname "$0")"
mkdir -p "$out"
xargs -P4 -n2 "$S/run_one.sh" "$bin" "$out" "$lim" "$S/base" < "$list"
