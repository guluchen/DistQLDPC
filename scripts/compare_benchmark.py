#!/usr/bin/env python3
"""Compare two benchmark CSVs against a reference (distances + timing)."""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path


def load(path: Path) -> dict[str, dict]:
    with path.open() as f:
        return {r["code"]: r for r in csv.DictReader(f)}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("reference", type=Path, help="reference CSV (correct distances)")
    ap.add_argument("candidate", type=Path, help="new benchmark CSV")
    ap.add_argument(
        "--min-speedup",
        type=float,
        default=0.15,
        help="required wall-time speedup vs reference sum (default 0.15 = 15%%)",
    )
    args = ap.parse_args()

    ref = load(args.reference)
    cand = load(args.candidate)

    wrong = []
    new_errors = []
    ok_times_ref = 0.0
    ok_times_cand = 0.0
    n_ok = 0

    for code in sorted(ref):
        r, c = ref[code], cand.get(code)
        if not c:
            wrong.append((code, "missing in candidate"))
            continue
        if r["status"] == "ok":
            rd = r.get("distance")
            if c["status"] != "ok":
                new_errors.append((code, f"was ok d={rd}, now {c['status']}"))
            elif c.get("distance") != rd:
                wrong.append((code, f"d {rd} -> {c.get('distance')}"))
            else:
                ok_times_ref += float(r["elapsed_sec"])
                ok_times_cand += float(c["elapsed_sec"])
                n_ok += 1

    wall_ref = sum(float(ref[c]["elapsed_sec"]) for c in ref)
    wall_cand = sum(float(cand[c]["elapsed_sec"]) for c in cand if c in ref)

    print(f"ok compared: {n_ok}")
    print(f"distance mismatches: {len(wrong)}")
    for w in wrong:
        print(f"  WRONG {w[0]}: {w[1]}")
    print(f"regressions (ok->fail): {len(new_errors)}")
    for e in new_errors:
        print(f"  REGRESS {e[0]}: {e[1]}")

    if ok_times_ref > 0:
        speedup = 1.0 - ok_times_cand / ok_times_ref
        print(f"ok-case time: {ok_times_ref:.1f}s -> {ok_times_cand:.1f}s ({speedup*100:.1f}% faster)")
    print(f"wall time (all): {wall_ref:.1f}s -> {wall_cand:.1f}s")

    ok_correct = len(wrong) == 0 and len(new_errors) == 0
    fast_enough = ok_times_ref > 0 and (1.0 - ok_times_cand / ok_times_ref) >= args.min_speedup
    if ok_correct and fast_enough:
        print("VERDICT: KEEP")
        return 0
    if ok_correct:
        print("VERDICT: REVERT (correct but not significantly faster)")
        return 1
    print("VERDICT: REVERT (incorrect or regressed)")
    return 2


if __name__ == "__main__":
    sys.exit(main())
