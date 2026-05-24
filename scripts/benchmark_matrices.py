#!/usr/bin/env python3
"""
Run bin/distqldpc on a fixed benchmark set in data/matrices/.

Default: 18 curated codes, 3 minute timeout per instance, 5 in parallel.
Use --advanced for 4 long-run instances (~20–75 min reference, 8h timeout default).
Use --full for default 18 + advanced 4 (22 codes).
Use --all to run every code with complete Hx/Hz/Gx/Gz files.
Use --compare-card to benchmark both vs off.
Use --compare-card-enc to benchmark both, sinz, mto, both_force, off (five passes).
Use --compare-card-enc --flat -j 110 to run all code×mode tasks in one pool (e.g. 22×5).
Use --compare-card-sm3 to benchmark sinz vs mto vs both_force (three passes).
"""

from __future__ import annotations

import argparse
import csv
import re
import subprocess
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional


SUFFIXES = ("Hx", "Hz", "Gx", "Gz")

# Default benchmark instances (see README).
DEFAULT_BENCHMARK_CODES: tuple[str, ...] = (
    "AJ_01",
    "AJ_04",
    "AJ_07",
    "AJ_10",
    "AJ_13",
    "QT_200_10_10",
    "QT_36_8_3",
    "QT_54_11_4",
    "QT_72_14_4",
    "TN_108_2_12",
    "TN_36_8_4",
    "TN_72_8_8",
    "BB_108_8_10",
    "BB_144_12_12",
    "BB_72_12_6",
    "BB_90_8_10",
    "GB_144_12_24",
    "GB_144_12_37",
)

# Long-run tier (~8h budget); reference wall times on a prior machine (seconds).
ADVANCED_BENCHMARK_CODES: tuple[str, ...] = (
    "TN_144_2_13",
    "BB_144_14_0",
    "xu_16",
    "QT_250_10_15",
)

ADVANCED_REFERENCE_SEC: dict[str, int] = {
    "TN_144_2_13": 1115,
    "BB_144_14_0": 2869,
    "xu_16": 1628,
    "QT_250_10_15": 4430,
}


@dataclass
class RunResult:
    code: str
    status: str  # ok | timeout | error | skip
    distance: Optional[int]
    elapsed_sec: float
    message: str


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def discover_codes(matrices_dir: Path) -> List[str]:
    stems: set[str] = set()
    for path in matrices_dir.glob("*.txt"):
        m = re.match(r"(.+)_(Hx|Hz|Gx|Gz)\.txt$", path.name)
        if m:
            stems.add(m.group(1))
    complete = [
        s
        for s in sorted(stems)
        if all((matrices_dir / f"{s}_{t}.txt").is_file() for t in SUFFIXES)
    ]
    return complete


def code_has_matrices(code: str, matrices_dir: Path) -> bool:
    return all((matrices_dir / f"{code}_{t}.txt").is_file() for t in SUFFIXES)


def resolve_codes(
    matrices_dir: Path,
    *,
    explicit: Optional[List[str]],
    use_all: bool,
    tier: str = "default",
) -> List[str]:
    if explicit:
        codes = list(explicit)
    elif use_all:
        codes = discover_codes(matrices_dir)
    elif tier == "advanced":
        codes = list(ADVANCED_BENCHMARK_CODES)
    elif tier == "full":
        codes = list(DEFAULT_BENCHMARK_CODES) + list(ADVANCED_BENCHMARK_CODES)
    else:
        codes = list(DEFAULT_BENCHMARK_CODES)

    missing = [c for c in codes if not code_has_matrices(c, matrices_dir)]
    if missing:
        print(
            "error: missing Hx/Hz/Gx/Gz for: " + ", ".join(missing),
            file=sys.stderr,
        )
        return []
    return codes


def parse_distance(stdout: str) -> tuple[Optional[int], str]:
    for line in stdout.splitlines():
        line = line.strip()
        if line.startswith("o "):
            try:
                return int(line.split()[1]), "ok"
            except (IndexError, ValueError):
                return None, "bad_output"
        if line == "s UNKNOWN":
            return None, "unknown"
    return None, "no_result_line"


CARD_MODES = ("both", "sinz", "mto", "both_force", "off")
CARD_COMPARE_SM3 = ("sinz", "mto", "both_force")
CARD_FLAG = {
    "both": None,
    "sinz": "-card-sinz",
    "mto": "-card-mto",
    "both_force": "-card-both-force",
    "off": "-no-card",
}


def run_one(
    binary: Path,
    code: str,
    *,
    timeout_sec: int,
    matrices_dir: Path,
    quiet: bool,
    card_mode: str = "both",
) -> RunResult:
    cmd = [str(binary)]
    if quiet:
        cmd.append("-q")
    flag = CARD_FLAG.get(card_mode)
    if flag:
        cmd.append(flag)
    root = repo_root()
    try:
        mat_arg = str(matrices_dir.relative_to(root) / code)
    except ValueError:
        mat_arg = str(matrices_dir / code)
    cmd.extend([f"-cpu-lim={timeout_sec}", mat_arg])

    t0 = time.monotonic()
    try:
        proc = subprocess.run(
            cmd,
            cwd=repo_root(),
            capture_output=True,
            text=True,
            timeout=timeout_sec + 15,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return RunResult(
            code=code,
            status="timeout",
            distance=None,
            elapsed_sec=time.monotonic() - t0,
            message=f"subprocess timeout > {timeout_sec}s",
        )
    except OSError as e:
        return RunResult(
            code=code,
            status="error",
            distance=None,
            elapsed_sec=time.monotonic() - t0,
            message=str(e),
        )

    elapsed = time.monotonic() - t0
    out = (proc.stdout or "") + (proc.stderr or "")

    if proc.returncode != 0 and not out.strip():
        return RunResult(
            code=code,
            status="error",
            distance=None,
            elapsed_sec=elapsed,
            message=f"exit {proc.returncode}",
        )

    dist, hint = parse_distance(out)
    if dist is not None:
        return RunResult(
            code=code,
            status="ok",
            distance=dist,
            elapsed_sec=elapsed,
            message="",
        )
    if hint == "unknown":
        return RunResult(
            code=code,
            status="unknown",
            distance=None,
            elapsed_sec=elapsed,
            message="s UNKNOWN",
        )
    tail = "\n".join(out.strip().splitlines()[-3:])
    return RunResult(
        code=code,
        status="error",
        distance=None,
        elapsed_sec=elapsed,
        message=tail or f"exit {proc.returncode}",
    )


def write_csv(
    path: Path, rows: List[RunResult], *, include_ref: bool = False
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as f:
        w = csv.writer(f)
        header = ["code", "status", "distance", "elapsed_sec", "message"]
        if include_ref:
            header.insert(4, "ref_sec")
        w.writerow(header)
        for r in rows:
            row = [r.code, r.status, r.distance, f"{r.elapsed_sec:.2f}", r.message]
            if include_ref:
                ref = ADVANCED_REFERENCE_SEC.get(r.code, "")
                row.insert(4, ref if ref != "" else "")
            w.writerow(row)


def run_benchmark_pass(
    *,
    binary: Path,
    codes: List[str],
    timeout_sec: int,
    matrices_dir: Path,
    quiet: bool,
    card_mode: str,
    jobs: int,
    label: str,
) -> List[RunResult]:
    results: List[RunResult] = []
    done = 0
    print_lock = threading.Lock()

    def report(r: RunResult) -> None:
        nonlocal done
        with print_lock:
            done += 1
            prefix = f"c [{label} {done}/{len(codes)}] {r.code}"
            if r.status == "ok":
                print(f"{prefix} -> d={r.distance} ({r.elapsed_sec:.1f}s)", flush=True)
            elif r.status == "timeout":
                print(f"{prefix} -> TIMEOUT ({r.elapsed_sec:.1f}s)", flush=True)
            elif r.status == "unknown":
                print(f"{prefix} -> UNKNOWN ({r.elapsed_sec:.1f}s)", flush=True)
            else:
                msg = r.message.replace("\n", " | ")
                print(f"{prefix} -> ERROR ({r.elapsed_sec:.1f}s) {msg[:120]}", flush=True)

    with ThreadPoolExecutor(max_workers=jobs) as pool:
        futures = {
            pool.submit(
                run_one,
                binary,
                code,
                timeout_sec=timeout_sec,
                matrices_dir=matrices_dir,
                quiet=quiet,
                card_mode=card_mode,
            ): code
            for code in codes
        }
        for fut in as_completed(futures):
            results.append(fut.result())
            report(results[-1])

    results.sort(key=lambda r: r.code)
    return results


def run_benchmark_grid(
    *,
    binary: Path,
    codes: List[str],
    modes: List[str],
    timeout_sec: int,
    matrices_dir: Path,
    quiet: bool,
    jobs: int,
) -> dict[str, List[RunResult]]:
    """Run every (code, card_mode) pair in one thread pool."""
    tasks = [(code, mode) for mode in modes for code in codes]
    n = len(tasks)
    results_by_mode: dict[str, List[RunResult]] = {m: [] for m in modes}
    done = 0
    print_lock = threading.Lock()

    def report(code: str, mode: str, r: RunResult) -> None:
        nonlocal done
        with print_lock:
            done += 1
            prefix = f"c [{mode} {done}/{n}] {code}"
            if r.status == "ok":
                print(f"{prefix} -> d={r.distance} ({r.elapsed_sec:.1f}s)", flush=True)
            elif r.status == "timeout":
                print(f"{prefix} -> TIMEOUT ({r.elapsed_sec:.1f}s)", flush=True)
            elif r.status == "unknown":
                print(f"{prefix} -> UNKNOWN ({r.elapsed_sec:.1f}s)", flush=True)
            else:
                msg = r.message.replace("\n", " | ")
                print(f"{prefix} -> ERROR ({r.elapsed_sec:.1f}s) {msg[:120]}", flush=True)

    with ThreadPoolExecutor(max_workers=jobs) as pool:
        futures = {
            pool.submit(
                run_one,
                binary,
                code,
                timeout_sec=timeout_sec,
                matrices_dir=matrices_dir,
                quiet=quiet,
                card_mode=mode,
            ): (code, mode)
            for code, mode in tasks
        }
        for fut in as_completed(futures):
            code, mode = futures[fut]
            r = fut.result()
            results_by_mode[mode].append(r)
            report(code, mode, r)

    for mode in modes:
        results_by_mode[mode].sort(key=lambda r: r.code)
    return results_by_mode


def summarize_pass(rows: List[RunResult]) -> dict[str, float | int]:
    return {
        "ok": sum(1 for r in rows if r.status == "ok"),
        "timeout": sum(1 for r in rows if r.status == "timeout"),
        "unknown": sum(1 for r in rows if r.status == "unknown"),
        "error": sum(1 for r in rows if r.status == "error"),
        "ok_time": sum(r.elapsed_sec for r in rows if r.status == "ok"),
        "wall_time": sum(r.elapsed_sec for r in rows),
    }


def write_compare_csv(
    path: Path,
    card: List[RunResult],
    nocard: List[RunResult],
) -> None:
    by_card = {r.code: r for r in card}
    by_nocard = {r.code: r for r in nocard}
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(
            [
                "code",
                "status_card",
                "distance_card",
                "elapsed_card",
                "status_nocard",
                "distance_nocard",
                "elapsed_nocard",
                "distance_match",
                "elapsed_ratio_nocard_over_card",
            ]
        )
        for code in sorted(by_card):
            a, b = by_card[code], by_nocard[code]
            match = a.distance == b.distance and a.status == b.status
            ratio = ""
            if a.elapsed_sec > 0:
                ratio = f"{b.elapsed_sec / a.elapsed_sec:.3f}"
            w.writerow(
                [
                    code,
                    a.status,
                    a.distance if a.distance is not None else "",
                    f"{a.elapsed_sec:.2f}",
                    b.status,
                    b.distance if b.distance is not None else "",
                    f"{b.elapsed_sec:.2f}",
                    "yes" if match else "no",
                    ratio,
                ]
            )


def print_compare_summary(card: List[RunResult], nocard: List[RunResult]) -> None:
    sc = summarize_pass(card)
    sn = summarize_pass(nocard)
    mismatches = []
    for a, b in zip(card, nocard):
        if a.code != b.code:
            continue
        if a.status != b.status or a.distance != b.distance:
            mismatches.append(
                f"{a.code}: card={a.status}/d={a.distance} vs "
                f"nocard={b.status}/d={b.distance}"
            )

    print("c --- compare: cardinality on vs -no-card ---", flush=True)
    print(
        f"c card:    ok={sc['ok']} unknown={sc['unknown']} timeout={sc['timeout']} "
        f"error={sc['error']} ok_time={sc['ok_time']:.1f}s sum_elapsed={sc['wall_time']:.1f}s",
        flush=True,
    )
    print(
        f"c nocard:  ok={sn['ok']} unknown={sn['unknown']} timeout={sn['timeout']} "
        f"error={sn['error']} ok_time={sn['ok_time']:.1f}s sum_elapsed={sn['wall_time']:.1f}s",
        flush=True,
    )
    if sc["ok_time"] > 0:
        delta = (sn["ok_time"] - sc["ok_time"]) / sc["ok_time"] * 100.0
        faster = "nocard" if sn["ok_time"] < sc["ok_time"] else "card"
        print(
            f"c ok-case time: card {sc['ok_time']:.1f}s vs nocard {sn['ok_time']:.1f}s "
            f"({delta:+.1f}% nocard vs card; {faster} faster on ok cases)",
            flush=True,
        )
    print(f"c distance/status mismatches: {len(mismatches)}", flush=True)
    for m in mismatches:
        print(f"c   MISMATCH {m}", flush=True)


def write_compare_multi_csv(
    path: Path,
    passes: dict[str, List[RunResult]],
) -> None:
    modes = list(passes.keys())
    by_mode = {m: {r.code: r for r in passes[m]} for m in modes}
    codes = sorted(by_mode[modes[0]])
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as f:
        w = csv.writer(f)
        header = ["code"]
        for m in modes:
            header.extend([f"status_{m}", f"distance_{m}", f"elapsed_{m}"])
        header.append("all_match")
        w.writerow(header)
        for code in codes:
            row: list = [code]
            refs = [by_mode[m][code] for m in modes]
            for r in refs:
                row.extend([r.status, r.distance if r.distance is not None else "", f"{r.elapsed_sec:.2f}"])
            match = all(
                refs[0].status == r.status and refs[0].distance == r.distance for r in refs
            )
            row.append("yes" if match else "no")
            w.writerow(row)


def print_compare_multi_summary(passes: dict[str, List[RunResult]]) -> None:
    print("c --- compare cardinality encodings ---", flush=True)
    base = None
    mismatches = []
    for mode, rows in passes.items():
        sc = summarize_pass(rows)
        print(
            f"c {mode:5s}: ok={sc['ok']} unknown={sc['unknown']} timeout={sc['timeout']} "
            f"error={sc['error']} ok_time={sc['ok_time']:.1f}s sum_elapsed={sc['wall_time']:.1f}s",
            flush=True,
        )
        if base is None:
            base = {r.code: r for r in rows}
        else:
            for r in rows:
                b = base.get(r.code)
                if b and (b.status != r.status or b.distance != r.distance):
                    mismatches.append(
                        f"{r.code}: {b.status}/d={b.distance} vs {mode}={r.status}/d={r.distance}"
                    )
    print(f"c distance/status mismatches vs first mode: {len(mismatches)}", flush=True)
    for m in mismatches:
        print(f"c   MISMATCH {m}", flush=True)


def main() -> int:
    root = repo_root()
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--matrices-dir",
        type=Path,
        default=root / "data" / "matrices",
        help="directory with <code>_{Hx,Hz,Gx,Gz}.txt",
    )
    ap.add_argument(
        "--binary",
        type=Path,
        default=root / "bin" / "distqldpc",
        help="path to distqldpc binary",
    )
    ap.add_argument(
        "--timeout",
        type=int,
        default=None,
        metavar="SEC",
        help="per-instance wall timeout (default: 180 curated, 28800=8h with --advanced)",
    )
    ap.add_argument(
        "-j",
        "--jobs",
        type=int,
        default=None,
        metavar="N",
        help="parallel processes (default: 5 curated, 1 with --advanced)",
    )
    ap.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="CSV output path (tier-specific default if omitted)",
    )
    ap.add_argument("-v", action="store_true", help="verbose solver output (no -q)")
    ap.add_argument(
        "--advanced",
        action="store_true",
        help="advanced tier: TN_144_2_13, BB_144_14_0, xu_16, QT_250_10_15 (8h timeout, -j 1)",
    )
    ap.add_argument(
        "--full",
        action="store_true",
        help="curated 18 + advanced 4 (22 codes); use --timeout for long instances",
    )
    ap.add_argument(
        "--all",
        action="store_true",
        help="run all codes with Hx/Hz/Gx/Gz in matrices dir (not the default set)",
    )
    ap.add_argument(
        "--codes",
        nargs="*",
        metavar="CODE",
        help="override code list (default: curated 18-instance benchmark set)",
    )
    ap.add_argument(
        "--card-mode",
        choices=CARD_MODES,
        default="both",
        help="cardinality: both (default), sinz, mto, both_force, off",
    )
    ap.add_argument(
        "--no-card",
        action="store_true",
        help="alias for --card-mode off",
    )
    ap.add_argument(
        "--compare-card",
        action="store_true",
        help="run each code twice (both vs off) and write comparison CSV",
    )
    ap.add_argument(
        "--compare-card-enc",
        action="store_true",
        help="run each code in all modes (both, sinz, mto, both_force, off)",
    )
    ap.add_argument(
        "--flat",
        action="store_true",
        help="with --compare-card-enc*: one pool for all code×mode tasks (e.g. -j 110 for 22×5)",
    )
    ap.add_argument(
        "--compare-card-sm3",
        action="store_true",
        help="run sinz vs mto vs both_force (forced Sinz+MTO) per code",
    )
    ap.add_argument(
        "--compare-output",
        type=Path,
        default=root / "data" / "benchmark_compare_card.csv",
        help="comparison CSV path",
    )
    args = ap.parse_args()

    if args.no_card:
        args.card_mode = "off"
    compare_flags = [args.compare_card, args.compare_card_enc, args.compare_card_sm3]
    if sum(compare_flags) > 1:
        print(
            "error: use only one of --compare-card, --compare-card-enc, --compare-card-sm3",
            file=sys.stderr,
        )
        return 1
    if compare_flags.count(True) and args.card_mode != "both":
        print("error: compare modes use built-in card settings; do not set --card-mode", file=sys.stderr)
        return 1
    if args.flat and not (args.compare_card_enc or args.compare_card_sm3):
        print("error: --flat requires --compare-card-enc or --compare-card-sm3", file=sys.stderr)
        return 1

    if not args.binary.is_file():
        print(f"error: binary not found: {args.binary}", file=sys.stderr)
        print("run: make", file=sys.stderr)
        return 1
    if not args.matrices_dir.is_dir():
        print(f"error: matrices dir not found: {args.matrices_dir}", file=sys.stderr)
        return 1

    tier_flags = sum([args.advanced, args.full, args.all])
    if tier_flags > 1:
        print("error: use only one of --advanced, --full, --all", file=sys.stderr)
        return 1
    if args.codes and tier_flags:
        print("error: --codes cannot combine with --advanced, --full, or --all", file=sys.stderr)
        return 1

    tier = "advanced" if args.advanced else "full" if args.full else "default"

    codes = resolve_codes(
        args.matrices_dir,
        explicit=args.codes if args.codes else None,
        use_all=args.all,
        tier=tier,
    )
    if not codes:
        return 1

    if args.timeout is not None:
        timeout = args.timeout
    elif tier in ("advanced", "full"):
        timeout = 28800
    else:
        timeout = 180
    if args.jobs is not None:
        jobs = max(1, args.jobs)
    elif args.flat and args.compare_card_enc:
        jobs = len(codes) * len(CARD_MODES)
    elif args.flat and args.compare_card_sm3:
        jobs = len(codes) * len(CARD_COMPARE_SM3)
    elif tier == "advanced":
        jobs = 1
    elif tier == "full":
        jobs = 5
    else:
        jobs = 5
    if args.output is not None:
        output_path = args.output
    elif tier == "advanced":
        output_path = root / "data" / "benchmark_results_advanced.csv"
    elif tier == "full":
        output_path = root / "data" / "benchmark_results_full.csv"
    else:
        output_path = root / "data" / "benchmark_results.csv"

    if tier == "advanced":
        print("c advanced tier (reference solve times on prior runs):", flush=True)
        for code in codes:
            ref = ADVANCED_REFERENCE_SEC.get(code)
            if ref is not None:
                print(f"c   {code}: ref ~{ref}s ({ref / 60:.1f} min)", flush=True)

    if args.compare_card_sm3:
        n_tasks = len(codes) * len(CARD_COMPARE_SM3)
        print(
            f"c compare-card-sm3: {len(codes)} codes x 3 = {n_tasks} tasks, "
            f"timeout={timeout}s, jobs={jobs}, flat={args.flat}, binary={args.binary}",
            flush=True,
        )
        t0 = time.monotonic()
        if args.flat:
            passes = run_benchmark_grid(
                binary=args.binary,
                codes=codes,
                modes=list(CARD_COMPARE_SM3),
                timeout_sec=timeout,
                matrices_dir=args.matrices_dir,
                quiet=not args.v,
                jobs=jobs,
            )
        else:
            passes = {}
            for i, mode in enumerate(CARD_COMPARE_SM3, 1):
                print(f"c pass {i}/{len(CARD_COMPARE_SM3)}: card-mode={mode}", flush=True)
                rows = run_benchmark_pass(
                    binary=args.binary,
                    codes=codes,
                    timeout_sec=timeout,
                    matrices_dir=args.matrices_dir,
                    quiet=not args.v,
                    card_mode=mode,
                    jobs=jobs,
                    label=mode,
                )
                passes[mode] = rows
        for mode, rows in passes.items():
            write_csv(root / "data" / f"benchmark_results_card_{mode}.csv", rows)
        write_compare_multi_csv(args.compare_output, passes)
        print_compare_multi_summary(passes)
        wall = time.monotonic() - t0
        print(f"c compare wall={wall:.1f}s", flush=True)
        print(f"c wrote {args.compare_output}", flush=True)
        err = sum(1 for rows in passes.values() for r in rows if r.status == "error")
        return 0 if err == 0 else 2

    if args.compare_card_enc:
        n_tasks = len(codes) * len(CARD_MODES)
        print(
            f"c compare-card-enc: {len(codes)} codes x {len(CARD_MODES)} modes = {n_tasks} tasks, "
            f"timeout={timeout}s, jobs={jobs}, flat={args.flat}, binary={args.binary}",
            flush=True,
        )
        t0 = time.monotonic()
        if args.flat:
            passes = run_benchmark_grid(
                binary=args.binary,
                codes=codes,
                modes=list(CARD_MODES),
                timeout_sec=timeout,
                matrices_dir=args.matrices_dir,
                quiet=not args.v,
                jobs=jobs,
            )
        else:
            passes = {}
            for i, mode in enumerate(CARD_MODES, 1):
                print(f"c pass {i}/{len(CARD_MODES)}: card-mode={mode}", flush=True)
                rows = run_benchmark_pass(
                    binary=args.binary,
                    codes=codes,
                    timeout_sec=timeout,
                    matrices_dir=args.matrices_dir,
                    quiet=not args.v,
                    card_mode=mode,
                    jobs=jobs,
                    label=mode,
                )
                passes[mode] = rows
        for mode, rows in passes.items():
            write_csv(root / "data" / f"benchmark_results_card_{mode}.csv", rows)
        write_compare_multi_csv(args.compare_output, passes)
        print_compare_multi_summary(passes)
        wall = time.monotonic() - t0
        print(f"c compare wall={wall:.1f}s", flush=True)
        print(f"c wrote {args.compare_output}", flush=True)
        err = sum(1 for rows in passes.values() for r in rows if r.status == "error")
        return 0 if err == 0 else 2

    if args.compare_card:
        print(
            f"c compare-card: {len(codes)} codes, timeout={timeout}s, jobs={jobs}, "
            f"binary={args.binary}",
            flush=True,
        )
        t0 = time.monotonic()
        card_path = root / "data" / "benchmark_results_card.csv"
        nocard_path = root / "data" / "benchmark_results_nocard.csv"

        print("c pass 1/2: cardinality both (default)", flush=True)
        card = run_benchmark_pass(
            binary=args.binary,
            codes=codes,
            timeout_sec=timeout,
            matrices_dir=args.matrices_dir,
            quiet=not args.v,
            card_mode="both",
            jobs=jobs,
            label="both",
        )
        write_csv(card_path, card)

        print("c pass 2/2: -no-card (soft-conflict only)", flush=True)
        nocard = run_benchmark_pass(
            binary=args.binary,
            codes=codes,
            timeout_sec=timeout,
            matrices_dir=args.matrices_dir,
            quiet=not args.v,
            card_mode="off",
            jobs=jobs,
            label="off",
        )
        write_csv(nocard_path, nocard)
        write_compare_csv(args.compare_output, card, nocard)
        print_compare_summary(card, nocard)

        wall = time.monotonic() - t0
        print(f"c compare wall={wall:.1f}s", flush=True)
        print(f"c wrote {card_path}", flush=True)
        print(f"c wrote {nocard_path}", flush=True)
        print(f"c wrote {args.compare_output}", flush=True)
        err = sum(1 for r in card + nocard if r.status == "error")
        return 0 if err == 0 else 2

    print(
        f"c benchmark ({tier}): {len(codes)} codes, timeout={timeout}s, jobs={jobs}, "
        f"binary={args.binary}, card-mode={args.card_mode}",
        flush=True,
    )

    t0 = time.monotonic()
    results = run_benchmark_pass(
        binary=args.binary,
        codes=codes,
        timeout_sec=timeout,
        matrices_dir=args.matrices_dir,
        quiet=not args.v,
        card_mode=args.card_mode,
        jobs=jobs,
        label=args.card_mode,
    )
    write_csv(output_path, results, include_ref=(tier == "advanced"))

    sc = summarize_pass(results)
    wall = time.monotonic() - t0
    print(
        f"c done: ok={sc['ok']} timeout={sc['timeout']} unknown={sc['unknown']} "
        f"error={sc['error']} total={len(codes)} wall={wall:.1f}s",
        flush=True,
    )
    if tier == "advanced":
        for r in results:
            ref = ADVANCED_REFERENCE_SEC.get(r.code)
            if ref is not None and r.status == "ok":
                ratio = r.elapsed_sec / ref
                print(
                    f"c   {r.code}: {r.elapsed_sec:.0f}s vs ref {ref}s ({ratio:.2f}x)",
                    flush=True,
                )
    print(f"c wrote {output_path}", flush=True)
    return 0 if sc["error"] == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
