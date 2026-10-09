#!/usr/bin/env bash
set -euo pipefail
export PATH=/usr/bin:/bin
export LC_ALL=C
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
taskdir=/cygdrive/c/Users/User/Documents/Codex/2026-10-07/you-are-the-execution-agent-for
package="$taskdir/E001-linux-package"
evidence="$taskdir/DistQLDPC/optimization/experiments/E001/raw/windows-validation"
cd "$package/candidate"
g++ -Isrc/solver -O2 -std=gnu++11 optimization/tests/logical_probe.cc build/SimpSolver.o build/Solver.o build/Options.o build/System.o -lz -o "$evidence/probe" > "$evidence/probe-build.log" 2>&1
python3 optimization/tests/tier0.py --baseline "$package/baseline/bin/distqldpc" --candidate "$package/candidate/bin/distqldpc" --probe "$evidence/probe" --qdistsat "$package/qdistsat" --out "$evidence/tier0" > "$evidence/tier0-driver.log" 2>&1
python3 "$taskdir/DistQLDPC/optimization/server/windows_diagnostic.py" --package "$package" --output "$evidence" > "$evidence/tier1-driver.log" 2>&1
