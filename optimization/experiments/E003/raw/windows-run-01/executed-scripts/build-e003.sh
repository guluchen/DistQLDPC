#!/usr/bin/env bash
set -euo pipefail
export PATH=/usr/bin:/bin
taskdir=/cygdrive/c/Users/User/Documents/Codex/2026-10-07/you-are-the-execution-agent-for
cd "$taskdir/E003-windows-package/candidate"
flags=(-Isrc/solver -Wall -Wno-parentheses -O3 -g -D __STDC_LIMIT_MACROS -D __STDC_FORMAT_MACROS -DNDEBUG)
set -x
g++ "${flags[@]}" -o bin/distqldpc src/core/distqldpc.cc build/SimpSolver.o build/Solver.o build/Options.o build/System.o -lz
g++ -Isrc/solver -O2 -std=gnu++11 optimization/tests/xor_buffer_probe.cc build/SimpSolver.o build/Solver.o build/Options.o build/System.o -lz -o "$taskdir/windows-validation/e003-probe"
