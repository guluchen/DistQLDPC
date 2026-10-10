#!/bin/bash
# usage: run_one.sh BIN OUTDIR CPULIM DATAROOT CODE MODE
bin="$1"; out="$2"; lim="$3"; root="$4"; code="$5"; mode="$6"
case "$mode" in
  default) flags="-v";;
  nocard) flags="-v -no-card";;
  sinz) flags="-v -card-sinz";;
  mto) flags="-v -card-mto";;
  joint) flags="-joint -v -no-card";;
esac
cd "$root" || exit 2
"$bin" $flags -cpu-lim="$lim" "$code" > "$out/$code.$mode.out" 2>&1
echo "exit=$?" > "$out/$code.$mode.rc"
