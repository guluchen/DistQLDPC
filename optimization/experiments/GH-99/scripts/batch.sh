#!/bin/bash
# usage: batch.sh BIN OUTDIR CPULIM DATAROOT EXTRAFLAGS LISTFILE [JOBS]
bin="$1"; out="$2"; lim="$3"; root="$4"; extra="$5"; list="$6"; jobs="${7:-4}"
S="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$out"
xargs -P"$jobs" -n2 "$S/run_one.sh" "$bin" "$out" "$lim" "$root" "$extra" < "$list"
