#!/usr/bin/env python3
"""Run both verified CC halves and the extracted CSS distance report."""
import os
import sys


def arguments(bindir, width, hx, hz, budget, rules):
    return [os.path.join(bindir, "pcm-prepare"), "--distance", str(width),
            os.fspath(hx), os.fspath(hz), str(budget), str(rules)]


def calculate(bindir, width, hx, hz, budget, rules):
    import json
    import subprocess
    result = subprocess.run(arguments(bindir, width, hx, hz, budget, rules),
                            stdout=subprocess.PIPE, text=True)
    if result.returncode not in (0, 3):
        raise RuntimeError(f"PCM distance failed with exit {result.returncode}")
    return json.loads(result.stdout)


def main():
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("width", type=int)
    parser.add_argument("hx")
    parser.add_argument("hz")
    parser.add_argument("--budget", type=int, default=100000000, help="iteration budget per half")
    parser.add_argument("--rules", type=int, default=63)
    args = parser.parse_args()
    if not (1 <= args.width <= 107374182 and 0 <= args.budget <= 4294967295 and 0 <= args.rules <= 63):
        parser.error("unsupported width, budget or rule mask")
    bindir = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
    argv = arguments(bindir, args.width, args.hx, args.hz, args.budget, args.rules)
    try:
        os.execv(argv[0], argv)
    except OSError as exc:
        parser.exit(2, f"PCM distance failed: {exc}\n")


if __name__ == "__main__":
    main()
