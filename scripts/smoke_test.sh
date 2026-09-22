#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

binary="${1:-./bin/distqldpc}"

if [[ ! -x "$binary" ]]; then
    echo "error: expected executable at $binary" >&2
    exit 1
fi

help_output="$($binary --help)"
grep -Fq "Usage:" <<<"$help_output"
grep -Fq "Options: -cpu-lim=N" <<<"$help_output"

# Exercise the documented small artifact with a strict wall limit. The smoke
# test checks only integration and output structure, never a distance value.
set +e
run_output="$($binary -v -cpu-lim=1 AJ_01 2>&1)"
run_status=$?
set -e

if [[ $run_status -ne 0 && $run_status -ne 1 ]]; then
    echo "error: DistQLDPC exited unexpectedly with status $run_status" >&2
    printf '%s\n' "$run_output" >&2
    exit 1
fi

grep -Fq "c Hx: data/matrices/AJ_01_Hx.txt" <<<"$run_output"
grep -Eq '^c Hx: [0-9]+ x [0-9]+, Hz: [0-9]+ x [0-9]+, Gx: [0-9]+ x [0-9]+, Gz: [0-9]+ x [0-9]+, logicals: [0-9]+$' <<<"$run_output"
grep -Eq '^(o [0-9]+|s UNKNOWN)$' <<<"$run_output"

echo "DistQLDPC smoke validation passed"
