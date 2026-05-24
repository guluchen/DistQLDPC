#!/usr/bin/env python3
"""
Build Gx/Gz logical basis files from Hx/Hz parity checks (CSS / QLDPC).

Writes the same format as data/matrices/*_{Gx,Gz}.txt:

  Gx — Z-type logical rows in F_2^n  (ker(Hx) / row(Hz))
  Gz — X-type logical rows in F_2^n  (ker(Hz) / row(Hx))

Requires only {STEM}_Hx.txt and {STEM}_Hz.txt. Uses the same
GF(2) quotient-basis construction as the solver pipeline.

Usage:
  python3 scripts/compute_logicals.py MY_CODE
  python3 scripts/compute_logicals.py --dir path/to/matrices MY_CODE
  python3 scripts/compute_logicals.py --all
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import List, Sequence, Tuple


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


def save_logical(path: Path, header: str, rows: Sequence[Sequence[int]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w") as f:
        f.write(header + "\n")
        for row in rows:
            f.write(" ".join(str(int(x) % 2) for x in row) + "\n")


def _matrix_shape(M: Sequence[Sequence[int]]) -> Tuple[int, int]:
    if not M:
        return 0, 0
    return len(M), len(M[0])


def _kernel_gf2(M: List[List[int]]) -> List[List[int]]:
    m, cols = _matrix_shape(M)
    if m == 0:
        return [[1 if j == i else 0 for j in range(cols)] for i in range(cols)]
    mat = [[int(M[i][j]) % 2 for j in range(cols)] for i in range(m)]
    pivot_row_for_col = [-1] * cols
    pivot_cols: List[int] = []
    row = 0
    for col in range(cols):
        if row >= m:
            break
        pivot = next((r for r in range(row, m) if mat[r][col] == 1), None)
        if pivot is None:
            continue
        mat[row], mat[pivot] = mat[pivot], mat[row]
        pivot_cols.append(col)
        pivot_row_for_col[col] = row
        for r2 in range(m):
            if r2 != row and mat[r2][col] == 1:
                for c in range(cols):
                    mat[r2][c] = (mat[r2][c] + mat[row][c]) % 2
        row += 1
    free_cols = [c for c in range(cols) if pivot_row_for_col[c] < 0]
    if not free_cols:
        return []
    basis: List[List[int]] = []
    for c in free_cols:
        w = [0] * cols
        w[c] = 1
        for col in reversed(pivot_cols):
            r = pivot_row_for_col[col]
            w[col] = sum(mat[r][j] * w[j] for j in range(col + 1, cols)) % 2
        basis.append(w)
    return basis


def _kernel_gf2_with_n(M: List[List[int]], n: int) -> List[List[int]]:
    if not M:
        return [[1 if j == i else 0 for j in range(n)] for i in range(n)]
    return _kernel_gf2(M)


def _vector_in_rref_span(
    rref: List[List[int]], pivot_cols: List[int], v: List[int], n: int
) -> bool:
    work = [int(v[j]) % 2 for j in range(n)]
    for row_idx, pcol in enumerate(pivot_cols):
        if work[pcol]:
            pr = rref[row_idx]
            work = [(work[c] + pr[c]) % 2 for c in range(n)]
    return all(x == 0 for x in work)


def _rref_add_to_span(
    rref: List[List[int]], pivot_cols: List[int], v: List[int], n: int
) -> bool:
    work = [int(v[j]) % 2 for j in range(n)]
    for row_idx, pcol in enumerate(pivot_cols):
        if work[pcol]:
            pr = rref[row_idx]
            work = [(work[c] + pr[c]) % 2 for c in range(n)]
    pivot = next((c for c in range(n) if work[c]), None)
    if pivot is None:
        return True
    new_row = work
    rref.append(new_row)
    pivot_cols.append(pivot)
    idx = len(rref) - 1
    for r in range(idx):
        if rref[r][pivot]:
            rref[r] = [(rref[r][c] + new_row[c]) % 2 for c in range(n)]
    return False


def css_logical_nbit_rows(
    Hx: List[List[int]], Hz: List[List[int]]
) -> Tuple[List[List[int]], List[List[int]]]:
    n = len(Hx[0]) if Hx else len(Hz[0]) if Hz else 0
    if n == 0:
        return [], []

    def quotient(parity: List[List[int]], mod_rows: List[List[int]]) -> List[List[int]]:
        ker = _kernel_gf2_with_n(parity, n)
        rref: List[List[int]] = []
        pivot_cols: List[int] = []
        for row in mod_rows:
            _rref_add_to_span(rref, pivot_cols, [int(x) % 2 for x in row], n)
        out: List[List[int]] = []
        for v in ker:
            vv = [int(x) % 2 for x in v]
            if _vector_in_rref_span(rref, pivot_cols, vv, n):
                continue
            out.append(vv)
            _rref_add_to_span(rref, pivot_cols, vv, n)
        return out

    bz = quotient(Hx if Hx else [], Hz if Hz else [])
    bx = quotient(Hz if Hz else [], Hx if Hx else [])
    return bz, bx


def discover_codes(mat_dir: Path) -> List[str]:
    stems = sorted(p.name[: -len("_Hx.txt")] for p in mat_dir.glob("*_Hx.txt"))
    return stems


def compute_one(
    mat_dir: Path, stem: str, *, overwrite: bool, dry_run: bool
) -> bool:
    hx_path = mat_dir / f"{stem}_Hx.txt"
    hz_path = mat_dir / f"{stem}_Hz.txt"
    gx_path = mat_dir / f"{stem}_Gx.txt"
    gz_path = mat_dir / f"{stem}_Gz.txt"

    if not hx_path.is_file():
        print(f"error: missing {hx_path}", file=sys.stderr)
        return False
    if not hz_path.is_file():
        print(f"error: missing {hz_path}", file=sys.stderr)
        return False

    for p in (gx_path, gz_path):
        if p.exists() and not overwrite:
            print(f"skip (exists): {p}", file=sys.stderr)
            return False

    Hx = load_matrix(hx_path)
    Hz = load_matrix(hz_path)
    if len(Hx[0]) != len(Hz[0]):
        print(f"error: column mismatch for {stem}", file=sys.stderr)
        return False

    n = len(Hx[0])
    bz, bx = css_logical_nbit_rows(Hx, Hz)
    if not bz and not bx:
        print(f"warning: no logical rows for {stem}", file=sys.stderr)
        return False

    if dry_run:
        print(f"would write {gx_path} ({len(bz)} rows), {gz_path} ({len(bx)} rows)")
        return True

    save_logical(
        gx_path,
        f"# n={n}  Z-type logical rows  ker(Hx)/row(Hz)  parity {hx_path.name}",
        bz,
    )
    save_logical(
        gz_path,
        f"# n={n}  X-type logical rows  ker(Hz)/row(Hx)  parity {hz_path.name}",
        bx,
    )
    print(f"wrote {gx_path} ({len(bz)} rows), {gz_path} ({len(bx)} rows)")
    return True


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "stem",
        nargs="?",
        help="code name (e.g. AJ_01); omit with --all",
    )
    ap.add_argument(
        "--dir",
        type=Path,
        default=Path("data/matrices"),
        help="directory with {STEM}_Hx.txt / {STEM}_Hz.txt (default: data/matrices)",
    )
    ap.add_argument(
        "--all",
        action="store_true",
        help="process every *_Hx.txt in --dir that has matching Hz",
    )
    ap.add_argument(
        "--overwrite",
        action="store_true",
        help="replace existing Gx/Gz files",
    )
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    mat_dir = args.dir.resolve()
    if not mat_dir.is_dir():
        print(f"error: not a directory: {mat_dir}", file=sys.stderr)
        return 1

    if args.all:
        ok = 0
        for stem in discover_codes(mat_dir):
            hz = mat_dir / f"{stem}_Hz.txt"
            if not hz.is_file():
                print(f"skip (no Hz): {stem}", file=sys.stderr)
                continue
            if compute_one(mat_dir, stem, overwrite=args.overwrite, dry_run=args.dry_run):
                ok += 1
        print(f"done: {ok} code(s)")
        return 0 if ok else 1

    if not args.stem:
        ap.error("provide STEM or use --all")

    return 0 if compute_one(mat_dir, args.stem, overwrite=args.overwrite, dry_run=args.dry_run) else 1


if __name__ == "__main__":
    raise SystemExit(main())
