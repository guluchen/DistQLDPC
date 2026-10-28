#!/usr/bin/env python3
"""
Export bundled codes for the web demo (web/codes/*.json) from data/matrices/tierN.

Each code becomes web/codes/<stem>.json with sparse rows (column indices of the 1 entries):
  {"stem", "tier", "n", "k", "d", "Hx": [[...], ...], "Hz", "Gx", "Gz", "bb": {"l", "m"} | null}
and web/codes/index.json lists the codes with their metadata (no matrices). "d" is the distance in the stem when it
is a number (the bundled ground truth), else null. "bb": for bivariate bicycle codes, a factorization n/2 = l*m for
which both blocks of Hx = [A | B] commute with the shifts x = S_l (x) I_m and y = I_l (x) S_m in the qubit order
i*m + j, i.e. the qubits of each block sit on an l x m torus (used only for the drawing of a witness).

Usage: python3 scripts/web_export_codes.py [--out web/codes] [--timings web/timings.json]
Copyright (C) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
SPDX-License-Identifier: GPL-3.0-or-later
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data" / "matrices"

# tiers 0-4 entirely, plus every tier5 code that the CC engine solves within the 6 h Tier 5 limit
# (GH-146 S1 Tier 5 table, yfclab2, one core: 1 s .. 11141 s)
EXTRA_TIER5 = ["LP_1020_136_16", "LP_2610_744_16", "LP_1122_148_20", "LP_1054_140_20", "LP_1768_224_22",
               "TN_180_2_17", "BB_360_12_24", "LP_1428_184_24", "TN_216_4_18", "TN_252_2_21"]
# known BB (l, m) (Bravyi et al. 2024 and the bundled data); used when several factorizations are consistent
KNOWN_BB = {72: (6, 6), 90: (15, 3), 108: (9, 6), 144: (12, 6), 288: (12, 12), 360: (30, 6), 756: (21, 18)}


def load(path: Path) -> list[list[int]]:
    rows = []
    for line in path.read_text().splitlines():
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        bits = [c for c in s if c in "01"]
        if bits:
            rows.append([i for i, c in enumerate(bits) if c == "1"])
    return rows


def ncols(path: Path) -> int:
    for line in path.read_text().splitlines():
        s = line.strip()
        if s and not s.startswith("#"):
            return sum(1 for c in s if c in "01")
    return 0


def bb_shape(hx: list[list[int]], n: int):
    if n % 2:
        return None
    N = n // 2
    blocks = []
    for half in (0, 1):
        A = set()
        for r, row in enumerate(hx):
            for c in row:
                if (c >= N) == bool(half):
                    A.add((r, c - half * N))
        blocks.append(A)
    if len(hx) != N:
        return None
    good = []
    for l in range(2, N):
        if N % l:
            continue
        m = N // l
        if m < 2:
            continue
        x = lambda q: ((q // m + 1) % l) * m + q % m
        y = lambda q: (q // m) * m + (q % m + 1) % m
        if all({(p(r), p(c)) for (r, c) in A} == A for A in blocks for p in (x, y)):
            good.append((l, m))
    if not good:
        return None
    if KNOWN_BB.get(n) in good:
        return KNOWN_BB[n]
    return min(good, key=lambda t: (abs(t[0] - t[1]), -t[0]))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=ROOT / "web" / "codes")
    ap.add_argument("--timings", type=Path, default=ROOT / "web" / "timings.json",
                    help="optional native reference times {stem: {maxsat: s, cc: s}} (yfclab2)")
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    timings = json.loads(args.timings.read_text()) if args.timings.is_file() else {}
    index = []
    picks = []
    for t in range(5):
        for hx in sorted((DATA / f"tier{t}").glob("*_Hx.txt")):
            picks.append((t, hx.name[:-7]))
    for stem in EXTRA_TIER5:
        if (DATA / "tier5" / f"{stem}_Hx.txt").is_file():
            picks.append((5, stem))
    for t, stem in picks:
        d = DATA / f"tier{t}"
        mats = {k: load(d / f"{stem}_{k}.txt") for k in ("Hx", "Hz", "Gx", "Gz")}
        n = ncols(d / f"{stem}_Hx.txt")
        fam, sn, sk, sd = stem.split("_", 3)
        dist = int(sd) if re.fullmatch(r"\d+", sd) else None
        bb = None
        if fam == "BB":
            sh = bb_shape(mats["Hx"], n)
            bb = {"l": sh[0], "m": sh[1]} if sh else None
        rec = {"stem": stem, "tier": t, "family": fam, "n": n, "k": len(mats["Gx"]), "d": dist, "bb": bb}
        (args.out / f"{stem}.json").write_text(json.dumps({**rec, **mats}, separators=(",", ":")))
        rec["timing"] = timings.get(stem)
        rec["bytes"] = (args.out / f"{stem}.json").stat().st_size
        index.append(rec)
        print(f"{stem:18s} tier{t} n={n:5d} k={rec['k']:4d} d={dist} bb={bb} {rec['bytes']} bytes")
    (args.out / "index.json").write_text(json.dumps(index, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
