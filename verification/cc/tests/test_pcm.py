"""Check the extracted preparation, C search and extracted full CSS report."""
import argparse
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def rows_as_text(rows, n):
    return "".join(" ".join(str((x >> i) & 1) for i in range(n)) + "\n" for x in rows)


def row_span(rows):
    span = {0}
    for row in rows:
        span |= {s ^ row for s in span}
    return span


def annihilates(word, rows):
    return all((word & r).bit_count() % 2 == 0 for r in rows)


def run(n, hx, hz, *args):
    return subprocess.run(
        [sys.executable, "-B", ROOT / "extract/css_distance.py", str(n), hx, hz, *args],
        capture_output=True, text=True, timeout=60
    )


def check_result(report, n, hx, hz, distance):
    if distance is None:
        assert report == {"status": "EMPTY"}, report
        return
    assert report["status"] == "FOUND" and report["distance"] == distance, report
    bx, bz = report["x"], report["z"]
    assert len(bx) == len(bz) == n and set(bx + bz) <= {"0", "1"}
    x, z = int(bx[::-1], 2), int(bz[::-1], 2)
    assert (x | z).bit_count() == distance
    assert annihilates(x, hz) and annihilates(z, hx)
    assert x not in row_span(hx) or z not in row_span(hz)


def compare_native_to_file_driver(n, hx, hz):
    # The process-based oracle uses the original separately linked C executable.
    prepared = [subprocess.check_output([ROOT / "pcm-prepare", str(n), a, b])
                for a, b in [(hz, hx), (hx, hz)]]
    for rules in range(64):
        for budget in (0, 31, 4294967295) if rules in (0, 63) else (100000,):
            replies = []
            for data in prepared:
                half = subprocess.run([ROOT / "ccv", str(budget), str(rules)],
                                      input=data, capture_output=True, timeout=10)
                assert half.returncode in (0, 3)
                result = json.loads(half.stdout)
                replies.extend([str(result["status"]), "".join(map(str, result["witness"]))])
            raw = subprocess.check_output([ROOT / "pcm-prepare", "--finish", str(n)],
                                          input="\n".join(replies) + "\n", text=True)
            expected = json.loads(raw)
            native = subprocess.run([ROOT / "pcm-prepare", "--distance", str(n), hx, hz,
                                     str(budget), str(rules)], capture_output=True, timeout=10)
            assert native.returncode == (3 if expected["status"] == "UNKNOWN" else 0)
            assert json.loads(native.stdout) == expected, (rules, budget, expected, native.stdout)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--matrices", type=Path, required=True, help="repository tier0 directory")
    opts = parser.parse_args()
    rng = random.Random(57)
    cases = [(3, [], [3, 6]), (3, [3, 6], []), (3, [], []), (2, [3, 3, 0], [3])]
    for n in range(1, 6):
        for _ in range(5):
            hx = [rng.randrange(1 << n) for _ in range(rng.randrange(4))]
            valid = [e for e in range(1 << n) if annihilates(e, hx)]
            hz = [rng.choice(valid) for _ in range(rng.randrange(4))]
            cases.append((n, hx, hz))
    with tempfile.TemporaryDirectory() as folder:
        h, z = [Path(folder) / f for f in ("x", "z")]
        for n, hx, hz in cases:
            h.write_text(rows_as_text(hx, n))
            z.write_text(rows_as_text(hz, n))
            sx, sz = row_span(hx), row_span(hz)
            exact = min(((u | v).bit_count() for u in range(1 << n) if annihilates(u, hz)
                         for v in range(1 << n) if annihilates(v, hx) and (u not in sx or v not in sz)),
                        default=None)
            result = run(n, h, z)
            assert result.returncode == 0, result.stderr
            check_result(json.loads(result.stdout), n, hx, hz, exact)
        # Exercise sparse products beyond two machine words. One shared high
        # column anticommutes; sharing both high columns commutes.
        n_wide = 129
        pair = (1 << 64) | (1 << 128)
        wide_x = [0, pair, pair]
        h.write_text(rows_as_text(wide_x, n_wide))
        z.write_text(rows_as_text([1 << 128], n_wide))
        rejected = run(n_wide, h, z)
        assert rejected.returncode == 2 and not rejected.stdout, rejected
        z.write_text(rows_as_text([pair], n_wide))
        accepted = run(n_wide, h, z)
        assert accepted.returncode == 0, accepted.stderr
        check_result(json.loads(accepted.stdout), n_wide, wide_x, [pair], 1)
        h.write_text("")
        z.write_text("110\n011\n")
        limited = run(3, h, z, "--budget", "0")
        assert limited.returncode == 3 and json.loads(limited.stdout) == {"status": "UNKNOWN"}
        for xdata, zdata in [("100\n", "100\n"), ("20\n", ""), ("11\n1\n", "")]:
            h.write_text(xdata)
            z.write_text(zdata)
            bad = run(3, h, z)
            assert bad.returncode == 2 and not bad.stdout, bad
    for stem, n, d in [("COLOR_7_1_3", 7, 3), ("HGP_13_1_3", 13, 3)]:
        files = [opts.matrices / (stem + "_" + label + ".txt") for label in ("Hx", "Hz")]
        rows = []
        for file in files:
            bits = ["".join(line.split("#", 1)[0].split()) for line in file.read_text().splitlines()]
            rows.append([int(line[::-1], 2) for line in bits if line])
        result = run(n, *files)
        assert result.returncode == 0, result.stderr
        check_result(json.loads(result.stdout), n, *rows, d)
    compare_native_to_file_driver(30, opts.matrices / "BB_30_4_6_Hx.txt",
                                  opts.matrices / "BB_30_4_6_Hz.txt")
    print("PASS native/file-driver agreement on all 64 rule masks and boundary budgets")
    print(f"PASS {len(cases)} exhaustive comparisons, 2 repository PCMs, 1 budget, 3 rejection cases and 2 wide-column cases")


if __name__ == "__main__":
    main()
