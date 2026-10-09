#!/usr/bin/env python3
"""Check the original partition crash against an independent exhaustive oracle."""

import argparse
import hashlib
from pathlib import Path
import re
import subprocess
import tempfile


def oracle(raw):
    lines = raw.decode("ascii").splitlines()
    header = lines[0].split()
    assert header[:2] == ["p", "wcnf"]
    nvars, nclauses, top = map(int, header[2:])
    clauses = [list(map(int, line.split())) for line in lines[1:]]
    assert nvars == 10 and len(clauses) == nclauses and nclauses in (28, 29)
    assert all(c[-1] == 0 and c[0] > 0 for c in clauses)
    assert all(1 <= abs(lit) <= nvars for c in clauses for lit in c[1:-1])
    feasible, optimum = 0, None
    for assignment in range(1 << nvars):
        cost, valid = 0, True
        for weight, *literals in clauses:
            satisfied = any(bool(assignment & (1 << (abs(lit) - 1))) == (lit > 0)
                            for lit in literals[:-1])
            if not satisfied:
                if weight >= top:
                    valid = False
                    break
                cost += weight
        if valid:
            feasible += 1
            optimum = cost if optimum is None else min(optimum, cost)
    assert feasible == 216 and optimum is not None, (feasible, optimum)
    return optimum


def verify(binary, fixture, root, expected):
    result = subprocess.run([str(binary.resolve()), "-verb=1", str(fixture)],
                            capture_output=True, text=True, timeout=10, cwd=root)
    print(result.stdout, end="")
    print(result.stderr, end="")
    labels = re.findall(r"optimal:([^\r\n]*)", result.stdout)
    values = [tail.strip().split(",", 1)[0] for tail in labels]
    assert labels and len(labels) == result.stdout.count("optimal:")
    assert all(re.fullmatch(r"\d+", value) for value in values), values
    costs = [int(value) for value in values]
    statuses = re.findall(r"^s (.+)$", result.stdout, re.MULTILINE)
    assert costs and all(x == expected for x in costs), (costs, expected)
    assert result.returncode in (10, 20), result.returncode
    expected_status = "SATISFIABLE" if result.returncode == 10 else "UNSATISFIABLE"
    assert statuses == [expected_status], (statuses, result.returncode)


def main():
    root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", type=Path, default=root / "bin/maxcdcl")
    args = parser.parse_args()
    fixture = root / "tests/fixtures/partition-retired-soft.wcnf"
    raw = fixture.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == (
        "ae851ec8bb80b3a638c40184d5203259ecade373e5598df2c79dbd7d12eb52d4"
    ), "The retained original failing input must remain byte-identical"
    expected = oracle(raw)
    assert expected == 5
    # Main reports the final optimal cost in a comment, then its existing status.
    # Do not reinterpret the application's legacy exit/status semantics.
    verify(args.binary, fixture, root, expected)
    print("Partition regression passed: all 1024 assignments checked; optimum 5.")
    rows = [list(map(int, line.split())) for line in raw.decode("ascii").splitlines()[1:]]
    variants = []
    for mask in (1, 3, 85, 1023):
        for reverse in (False, True):
            changed = [[r[0], *[-lit if mask & (1 << (abs(lit) - 1)) else lit
                                for lit in r[1:-1]], 0] for r in rows]
            if reverse:
                changed.reverse()
            variants.append((changed, 14))
    for literal in (1, 4):
        # Keep hard clauses hard and retain the new unit's objective multiplicity.
        changed = [[15 if r[0] == 14 else r[0], *r[1:]] for r in rows]
        variants.append((changed + [[1, literal, 0]], 15))
    with tempfile.TemporaryDirectory(prefix="distqldpc-partition-") as temporary:
        for index, (changed, top) in enumerate(variants):
            variant = Path(temporary) / (str(index) + ".wcnf")
            data = (f"p wcnf 10 {len(changed)} {top}\n" + "\n".join(
                " ".join(map(str, row)) for row in changed) + "\n").encode("ascii")
            variant.write_bytes(data)
            verify(args.binary, variant, root, oracle(data))
    print("Partition adjacent oracles passed: 11 total inputs, 1024 assignments each.")


if __name__ == "__main__":
    main()
