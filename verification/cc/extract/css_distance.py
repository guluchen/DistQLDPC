#!/usr/bin/env python3
"""Run the extracted PCM preparation, both CC halves, and the extracted join."""
import argparse
import json
import subprocess
import sys
from pathlib import Path


def calculate(bindir, width, hx, hz, budget, rules):
    prep = str(bindir / "pcm-prepare")
    solver = str(bindir / "ccv")
    replies = []
    for opposite, same in [(hz, hx), (hx, hz)]:
        data = subprocess.run(
            [prep, str(width), opposite, same], stdout=subprocess.PIPE, check=True
        ).stdout
        run = subprocess.run([solver, str(budget), str(rules)], input=data, stdout=subprocess.PIPE)
        if run.returncode not in (0, 3) or not run.stdout:
            raise RuntimeError(f"CC half returned exit {run.returncode} without a usable result")
        result = json.loads(run.stdout)
        status, bits = result["status"], result["witness"]
        if (status not in (-1, 0, 1) or len(bits) != width or
                any(bit not in (0, 1) for bit in bits) or
                (status == -1) != (run.returncode == 3)):
            raise ValueError("inconsistent half result")
        replies.extend([str(status), "".join(map(str, bits))])
    report = subprocess.run(
        [prep, "--finish", str(width)], input="\n".join(replies) + "\n",
        text=True, capture_output=True, check=True
    )
    return json.loads(report.stdout)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("width", type=int)
    parser.add_argument("hx", type=Path)
    parser.add_argument("hz", type=Path)
    parser.add_argument("--budget", type=int, default=100000000, help="iteration budget per half")
    parser.add_argument("--rules", type=int, default=63)
    args = parser.parse_args()
    if not (1 <= args.width <= 107374182 and 0 <= args.budget <= 4294967295 and 0 <= args.rules <= 63):
        parser.error("unsupported width, budget or rule mask")
    try:
        report = calculate(Path(__file__).resolve().parents[1], args.width, args.hx, args.hz,
                           args.budget, args.rules)
    except (OSError, subprocess.CalledProcessError, ValueError, RuntimeError, KeyError) as exc:
        parser.exit(2, f"PCM distance failed: {exc}\n")
    print(json.dumps(report))
    return 3 if report["status"] == "UNKNOWN" else 0


if __name__ == "__main__":
    sys.exit(main())
