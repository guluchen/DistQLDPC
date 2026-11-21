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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("width", type=int)
    parser.add_argument("hx")
    parser.add_argument("hz")
    parser.add_argument("--budget", type=int, default=100000000, help="iteration budget per half per stage")
    parser.add_argument("--rules", type=int, default=39, help="mask for the verified C bounded query")
    parser.add_argument("--row-order", choices=("index","reverse-bfs"), default="index",
                        help="row order for the packed lower-bound searches")
    args = parser.parse_args()
    if not (0 < args.width <= 107374182 and 0 <= args.rules <= 63 and 0 <= args.budget <= 4294967295):
        parser.error("unsupported width, rule mask or budget")
    raw = [str(args.width), args.hx, args.hz]
    budget = str(args.budget)
    order = [] if args.row_order == "index" else [args.row_order]
    if args.width <= 64:
        os.execv(ROOT/"pcm-proved", ["pcm-proved","--distance",*raw,budget,"63"])
    if args.width <= 756 and args.budget == 100000000:
        upper = subprocess.run([ROOT/"pcm-upper", *raw],capture_output=True,text=True)
        if upper.returncode == 0:
            verifier = [ROOT/"pcm-large" if args.width > 378 else ROOT/"pcm-wide", *raw, *order]
            checked = subprocess.run(verifier, input=upper.stdout,capture_output=True,text=True)
            if checked.returncode == 0:
                sys.stdout.write(checked.stdout)
                return 0
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
    if 190 <= args.width <= 756 and args.budget == 100000000:
        wide = subprocess.run([ROOT/"pcm-large" if args.width > 378 else ROOT/"pcm-wide", *raw, *order], input=side+"\n"+word+"\n", capture_output=True,text=True)
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
