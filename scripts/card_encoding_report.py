#!/usr/bin/env python3
"""Report n, k, and CARD_ENC_BOTH encoding choice per benchmark code."""
from __future__ import annotations

import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CODES = [
    line.split(",")[0]
    for line in (ROOT / "data/benchmark_compare_card.csv").read_text().strip().splitlines()[1:]
]


def matrix_n(code: str) -> int:
    row0 = (ROOT / f"data/matrices/{code}_Hx.txt").read_text().splitlines()[0].split()
    return len(row0)


def classify_both(n: int, k: int) -> str:
    if n < 2 or k < 1 or n <= k:
        return "off (skip)"
    if n * k > 10000:
        return "off (skip n·k>10000)"
    if n <= 100:
        return "Sinz+MTO"
    return "MTO only"


def max_k_before_skip(n: int) -> int:
    if n < 2:
        return 0
    return min(n - 1, 10000 // n)


def probe(code: str, timeout_sec: int = 8) -> tuple[int | None, int | None, str]:
    proc = subprocess.Popen(
        [str(ROOT / "bin/distqldpc"), "-v", f"-cpu-lim={timeout_sec}", code],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        cwd=ROOT,
    )
    try:
        text, _ = proc.communicate(timeout=timeout_sec + 5)
    except subprocess.TimeoutExpired:
        proc.kill()
        text, _ = proc.communicate()

    mobj = re.search(r"objForSearch:\s*(\d+)", text)
    n_active = int(mobj.group(1)) if mobj else None
    card_lines = re.findall(r"c Cardinality: \d+ \(([^)]+)\) for UB (\d+)", text)
    if card_lines:
        _, ub = card_lines[0]
        k1 = int(ub) - 1
    elif n_active is not None:
        k1 = 1
    else:
        k1 = None
    method = classify_both(n_active, k1) if n_active is not None and k1 is not None else "?"
    return n_active, k1, method


def main() -> int:
    print(f"{'code':<16} {'n_phys':>6} {'n_soft':>6} {'k@1st':>5} {'k_max':>5}  both(default)")
    print("-" * 68)
    rows: list[tuple] = []
    with ThreadPoolExecutor(max_workers=8) as pool:
        futs = {pool.submit(probe, code): code for code in CODES}
        for fut in as_completed(futs):
            code = futs[fut]
            n_phys = matrix_n(code)
            n_active, k1, method = fut.result()
            kmax = max_k_before_skip(n_active) if n_active is not None else "?"
            rows.append((code, n_phys, n_active, k1, kmax, method))
    rows.sort(key=lambda r: r[0])
    for r in rows:
        print(
            f"{r[0]:<16} {r[1]:>6} {str(r[2]):>6} {str(r[3]):>5} {str(r[4]):>5}  {r[5]}"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
