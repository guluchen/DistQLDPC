#!/usr/bin/env python3
"""
Preprocess CSS parity-check matrices into data/s1 and data/s2.

s1: Remove redundant Hx/Hz rows (GF(2)), keep original row vectors and relative
    order of kept rows. When two rows are identical, keep the earlier one (same
    weight; first in file order wins).

s2: Same rank/row space as s1 for Hx/Hz, but row vectors may change via GF(2)
    row combinations to reduce Hamming weight (greedy sparse reduction).

Gx/Gz are copied unchanged to both output trees.
"""

from __future__ import annotations

import argparse
import csv
import shutil
from pathlib import Path
from typing import List, Sequence, Tuple

SUFFIXES = ("Hx", "Hz", "Gx", "Gz")


def load_matrix(path: Path) -> List[List[int]]:
    rows: List[List[int]] = []
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        rows.append([int(c) for c in line if c in "01"])
    if not rows:
        raise ValueError(f"empty matrix: {path}")
    width = len(rows[0])
    for r in rows:
        if len(r) != width:
            raise ValueError(f"inconsistent width in {path}")
    return rows


def save_matrix(path: Path, rows: Sequence[Sequence[int]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w") as f:
        for r in rows:
            f.write(" ".join(str(int(x)) for x in r) + "\n")


def hamming(row: Sequence[int]) -> int:
    return sum(int(x) for x in row)


class IncrementalBasis:
    """Incremental GF(2) row independence test."""

    def __init__(self, ncols: int) -> None:
        self.ncols = ncols
        self.rows: List[List[int]] = []
        self.pivot_cols: List[int] = []

    def _elim(self, work: List[int]) -> List[int]:
        for row_idx, pcol in enumerate(self.pivot_cols):
            if work[pcol]:
                pr = self.rows[row_idx]
                work = [(work[c] + pr[c]) % 2 for c in range(self.ncols)]
        return work

    def in_span(self, row: Sequence[int]) -> bool:
        return all(x == 0 for x in self._elim(list(row)))

    def add(self, row: Sequence[int]) -> None:
        work = self._elim(list(row))
        pivot = next((c for c in range(self.ncols) if work[c]), None)
        if pivot is None:
            return
        self.rows.append(work)
        self.pivot_cols.append(pivot)
        idx = len(self.rows) - 1
        for r in range(idx):
            if self.rows[r][pivot]:
                self.rows[r] = [
                    (self.rows[r][c] + work[c]) % 2 for c in range(self.ncols)
                ]


def gf2_rank(mat: List[List[int]]) -> int:
    if not mat:
        return 0
    m = [r[:] for r in mat]
    rows, cols = len(m), len(m[0])
    r = c = rank = 0
    while r < rows and c < cols:
        pivot = next((i for i in range(r, rows) if m[i][c]), None)
        if pivot is None:
            c += 1
            continue
        m[r], m[pivot] = m[pivot], m[r]
        for i in range(rows):
            if i != r and m[i][c]:
                m[i] = [(m[i][j] + m[r][j]) % 2 for j in range(cols)]
        rank += 1
        r += 1
        c += 1
    return rank


def s1_select_rows(rows: List[List[int]]) -> List[List[int]]:
    """Forward independent set; preserve file order; skip zero/dependent rows.

    Identical duplicate rows keep the earlier copy (same Hamming weight).
    """
    if not rows:
        return []
    basis = IncrementalBasis(len(rows[0]))
    kept: List[List[int]] = []
    seen: set[tuple[int, ...]] = set()
    for row in rows:
        if hamming(row) == 0:
            continue
        key = tuple(row)
        if key in seen:
            continue
        if basis.in_span(row):
            continue
        basis.add(row)
        kept.append(row)
        seen.add(key)
    return kept


def s2_sparse_basis(rows: List[List[int]], max_rounds: int = 200) -> List[List[int]]:
    """Greedy row XOR reduction on an independent set (same row space).

    Only accepts a combination when it is non-zero and strictly lighter than
    the row being replaced. Zero rows would drop stabilizer constraints and
    change the CSS code; they are never written.
    """
    if not rows:
        return []
    target_rank = gf2_rank(rows)
    basis = [r[:] for r in rows]
    for _ in range(max_rounds):
        improved = False
        for i in range(len(basis)):
            for j in range(i + 1, len(basis)):
                comb = [(basis[i][c] + basis[j][c]) % 2 for c in range(len(basis[i]))]
                wc = hamming(comb)
                if wc == 0:
                    continue
                if wc < hamming(basis[i]):
                    basis[i] = comb
                    improved = True
                if wc < hamming(basis[j]):
                    basis[j] = comb
                    improved = True
        if not improved:
            break

    out = [r for r in basis if hamming(r) > 0]
    if gf2_rank(out) != target_rank:
        # Span was corrupted (should not happen with wc > 0); keep s1 basis.
        return [r[:] for r in rows]
    return out


def discover_codes(matrices_dir: Path) -> List[str]:
    stems = {p.name.rsplit("_", 1)[0] for p in matrices_dir.glob("*_Hx.txt")}
    return sorted(stems)


def process_code(
    code: str,
    src: Path,
    dst: Path,
    *,
    variant: str,
) -> dict:
    stats = {"code": code, "variant": variant}
    for suffix in SUFFIXES:
        src_path = src / f"{code}_{suffix}.txt"
        if not suffix in ("Hx", "Hz"):
            shutil.copy2(src_path, dst / f"{code}_{suffix}.txt")
            continue

        rows = load_matrix(src_path)
        stats[f"{suffix}_rows_in"] = len(rows)
        stats[f"{suffix}_ones_in"] = sum(hamming(r) for r in rows)

        if variant == "s1":
            out = s1_select_rows(rows)
        elif variant == "s2":
            ind = s1_select_rows(rows)
            out = s2_sparse_basis(ind)
        else:
            raise ValueError(variant)

        stats[f"{suffix}_rows_out"] = len(out)
        stats[f"{suffix}_ones_out"] = sum(hamming(r) for r in out)
        save_matrix(dst / f"{code}_{suffix}.txt", out)

    return stats


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--src",
        type=Path,
        default=Path("data/matrices"),
        help="source matrices directory",
    )
    ap.add_argument(
        "--root",
        type=Path,
        default=Path("data"),
        help="parent directory for s1/ and s2/",
    )
    ap.add_argument("--codes", nargs="*", help="optional code subset")
    ap.add_argument(
        "--variant",
        choices=("s1", "s2", "both"),
        default="both",
        help="which output tree to build (default: both)",
    )
    ap.add_argument(
        "--no-clean",
        action="store_true",
        help="do not delete output dir before writing (merge/update codes)",
    )
    args = ap.parse_args()

    root = args.root.resolve()
    src = args.src.resolve()
    codes = args.codes if args.codes else discover_codes(src)

    variants = ("s1", "s2") if args.variant == "both" else (args.variant,)

    all_stats: List[dict] = []
    for variant in variants:
        dst = root / variant
        if not args.no_clean and dst.exists():
            shutil.rmtree(dst)
        dst.mkdir(parents=True, exist_ok=True)
        for code in codes:
            all_stats.append(process_code(code, src, dst, variant=variant))

        summary = dst / "preprocess_summary.csv"
        prev: List[dict] = []
        if args.no_clean and summary.is_file():
            with summary.open() as f:
                prev = [r for r in csv.DictReader(f) if r.get("code") not in codes]
        fields = sorted({k for row in prev + all_stats if row["variant"] == variant for k in row})
        with summary.open("w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=fields)
            w.writeheader()
            for row in prev + all_stats:
                if row["variant"] == variant:
                    w.writerow(row)

    if "s1" in variants:
        print(f"c wrote {root / 's1'} ({len(codes)} codes, Hx/Hz row subset)")
    if "s2" in variants:
        print(f"c wrote {root / 's2'} ({len(codes)} codes, Hx/Hz sparse basis)")
    if "s1" in variants:
        print(f"c summary: {root / 's1' / 'preprocess_summary.csv'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
