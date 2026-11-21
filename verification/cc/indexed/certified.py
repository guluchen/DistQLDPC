#!/usr/bin/env python3
"""Find a witness in a separate process, then certify its exact distance."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parent


def pure_witness(data, width):
    if not isinstance(data, dict) or data.get("status") != "FOUND":
        return None
    x, z = data.get("x"), data.get("z")
    if any(not isinstance(s, str) or len(s) != width or set(s) - {"0", "1"} for s in (x, z)):
        return None
    if ("1" in x) == ("1" in z):
        return None
    return ("X", x) if "1" in x else ("Z", z)


def upper_proposal(raw, width, rounds):
    args = [ROOT/"pcm-upper", *raw]
    if rounds is not None:
        args.append(str(rounds))
    result = subprocess.run(args, capture_output=True, text=True)
    lines = result.stdout.splitlines()
    if result.returncode or len(lines) != 2:
        return None
    side, word = lines
    if side not in ("X", "Z") or len(word) != width or set(word) - {"0", "1"} or "1" not in word:
        return None
    return side, word


def packed_check(verifier, proposal):
    side, word = proposal
    payload = side+"\n"+word+"\n"
    if int(verifier[1]) <= 189:
        small = subprocess.run([ROOT/"pcm-small", *verifier[1:]], input=payload,
                               capture_output=True, text=True)
        if small.returncode != 3:
            return small
    return subprocess.run(verifier, input=payload, capture_output=True, text=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("width", type=int)
    parser.add_argument("hx")
    parser.add_argument("hz")
    parser.add_argument("--budget", type=int, default=100000000, help="iteration budget per half per stage")
    parser.add_argument("--rules", type=int, default=39, help="mask for the verified C bounded query")
    parser.add_argument("--row-order", choices=("index","reverse-bfs"), default="index",
                        help="row order for the packed lower-bound searches")
    parser.add_argument("--pair-pack", action="store_true", help="try sums of check rows in saturated packings")
    parser.add_argument("--upper-rounds", type=int, help="fixed number of shuffled information sets (1..4096)")
    parser.add_argument("--sparse-checks", action="store_true", help="add independently checked short pair-XOR rows")
    parser.add_argument("--erasure-pack", action="store_true",
                        help="certify syndrome inconsistency on the occupied packing region")
    args = parser.parse_args()
    if args.upper_rounds is not None and not 1 <= args.upper_rounds <= 4096:
        parser.error("--upper-rounds must be between 1 and 4096")
    if not (0 < args.width <= 107374182 and 0 <= args.rules <= 63 and 0 <= args.budget <= 4294967295):
        parser.error("unsupported width, rule mask or budget")
    raw = [str(args.width), args.hx, args.hz]
    budget = str(args.budget)
    order = [] if args.row_order == "index" else [args.row_order]
    if args.sparse_checks:
        order.append("sparse-checks")
    if args.erasure_pack:
        order.append("erasure-pack")
    if args.pair_pack:
        order.append("pair-pack")
    if args.width <= 64:
        os.execv(ROOT/"pcm-proved", ["pcm-proved","--distance",*raw,budget,"63"])
    verifier = [ROOT/("pcm-large" if args.width > 378 else "pcm-wide"), *raw, *order]
    tried = set()
    if args.width <= 756 and args.budget == 100000000:
        # A failed lower check can also mean that the proposed upper bound is
        # loose. A deeper C pass is worthwhile before launching full C search.
        rounds = [args.upper_rounds] if args.upper_rounds is not None else [None, 512]
        best = args.width + 1
        for effort in rounds:
            suggestion = upper_proposal(raw, args.width, effort)
            if suggestion is None or suggestion[1].count("1") >= best:
                continue
            best = suggestion[1].count("1")
            checked = packed_check(verifier, suggestion)
            if checked.returncode == 0:
                sys.stdout.write(checked.stdout)
                return 0
            if checked.returncode == 3:
                tried.add(suggestion)
    proposed = subprocess.run([ROOT/"pcm-indexed", "--distance", *raw, budget, "63"],
                              capture_output=True, text=True)
    suggestion = None
    if proposed.returncode == 0:
        try:
            suggestion = pure_witness(json.loads(proposed.stdout), args.width)
        except ValueError:
            pass
    if suggestion is None:
        # An untrusted EMPTY, UNKNOWN or failed proposal carries no conclusion.
        os.execv(ROOT/"pcm-proved", ["pcm-proved","--distance",*raw,budget,"63"])
    side, word = suggestion
    if 190 <= args.width <= 756 and args.budget == 100000000 and suggestion not in tried:
        wide = packed_check(verifier, suggestion)
        if wide.returncode == 0:
            sys.stdout.write(wide.stdout)
            return 0
        if wide.returncode != 3:
            sys.stderr.write(wide.stderr)
            return wide.returncode
    result = subprocess.run([ROOT/"pcm-check",*raw,budget,str(args.rules)],
                            input=side+"\n"+word+"\n",text=True)
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
