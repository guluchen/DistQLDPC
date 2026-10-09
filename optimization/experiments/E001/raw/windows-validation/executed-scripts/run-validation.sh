#!/usr/bin/env bash
set -euo pipefail
export PATH=/usr/bin:/bin
export LC_ALL=C
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
taskdir=/cygdrive/c/Users/User/Documents/Codex/2026-10-07/you-are-the-execution-agent-for
package="$taskdir/E001-linux-package"
evidence="$taskdir/DistQLDPC/optimization/experiments/E001/raw/windows-validation"
mkdir -p "$evidence"
uname -a > "$evidence/platform.txt"
g++ --version > "$evidence/compiler.txt"
python3 --version > "$evidence/python.txt"
# Same commands/flags as Makefile, invoked explicitly because make's Cygwin
# Guile dependency failed to start on this host. No solver edits or flag changes.
flags=(-Isrc/solver -Wall -Wno-parentheses -O3 -g -D __STDC_LIMIT_MACROS -D __STDC_FORMAT_MACROS -DNDEBUG)
for version in baseline candidate; do
    cd "$package/$version"
    mkdir -p build bin
    {
        set -x
        g++ "${flags[@]}" -c -o build/SimpSolver.o src/solver/SimpSolver.cc
        g++ "${flags[@]}" -c -o build/Solver.o src/solver/Solver.cc
        g++ "${flags[@]}" -c -o build/Options.o src/solver/utils/Options.cc
        g++ "${flags[@]}" -c -o build/System.o src/solver/utils/System.cc
        g++ "${flags[@]}" -o bin/distqldpc src/core/distqldpc.cc build/SimpSolver.o build/Solver.o build/Options.o build/System.o -lz
        set +x
    } > "$evidence/$version-build.log" 2>&1
done
cd "$package/candidate"
g++ -Isrc/solver -O2 -std=gnu++11 optimization/tests/logical_probe.cc build/SimpSolver.o build/Solver.o build/Options.o build/System.o -lz -o "$evidence/probe" > "$evidence/probe-build.log" 2>&1
python3 optimization/tests/tier0.py --baseline "$package/baseline/bin/distqldpc" --candidate "$package/candidate/bin/distqldpc" --probe "$evidence/probe" --qdistsat "$package/qdistsat" --out "$evidence/tier0" > "$evidence/tier0-driver.log" 2>&1
python3 "$taskdir/DistQLDPC/optimization/server/windows_diagnostic.py" --package "$package" --output "$evidence" > "$evidence/tier1-driver.log" 2>&1
