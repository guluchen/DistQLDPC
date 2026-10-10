#!/bin/bash
# usage: run_one.sh BIN OUTDIR CPULIM DATAROOT EXTRAFLAGS CODE MODE
# EXTRAFLAGS is one word ("none" for no extra flag), e.g. -no-lkskip or -lkskip=fast.
bin="$1"; out="$2"; lim="$3"; root="$4"; extra="$5"; code="$6"; mode="$7"
case "$mode" in
  default) flags="-v";;
  nocard) flags="-v -no-card";;
  sinz) flags="-v -card-sinz";;
  mto) flags="-v -card-mto";;
  joint) flags="-joint -v -no-card";;
esac
[ "$extra" = "none" ] || flags="$flags $extra"
cd "$root" || exit 2
"$bin" $flags -cpu-lim="$lim" "$code" > "$out/$code.$mode.out" 2>&1
echo "exit=$?" > "$out/$code.$mode.rc"
