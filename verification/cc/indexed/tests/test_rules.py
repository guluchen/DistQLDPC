"""Exercise the real C filter with known repairs and verify admitted permutations."""
import ctypes
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tests"))
from test_ccv import Harness, Problem, arr


def row_basis(rows):
    pivots = {}
    for row in rows:
        while row and row.bit_length() in pivots:
            row ^= pivots[row.bit_length()]
        if row:
            pivots[row.bit_length()] = row
    return pivots


def member(word, basis):
    while word and word.bit_length() in basis:
        word ^= basis[word.bit_length()]
    return word == 0


def shift(row, width, period, stride):
    image = 0
    for q in range(width):
        if row & (1 << q):
            dest = q - q % period + (q + stride) % period
            image |= 1 << dest
    return image


def reference_period(n, checks, logicals):
    h, l = row_basis(checks), row_basis(logicals)
    size = 1
    for _ in range(n):
        for block in range(n, size, -1):
            if n % block or block % size:
                continue
            if (all(member(shift(r, n, block, size), h) for r in checks)
                    and all(member(shift(r, n, block, size), l) for r in logicals)):
                size = block
                break
        else:
            return size
    raise AssertionError("orbit size failed to stabilize")


def main(path):
    harness = Harness(path)
    probe = harness.lib.verify_combinations
    probe.argtypes = [ctypes.POINTER(Problem), ctypes.c_uint, ctypes.POINTER(ctypes.c_uint)]
    period = harness.lib.period_of
    period.argtypes = [ctypes.POINTER(Problem)]
    period.restype = ctypes.c_uint
    rng = random.Random(195566)
    repairs = ctypes.c_uint()
    for n in [32, 33, 63, 64, 65, 96, 144]:
        for density in [2, 5, 8]:
            rows = [sum(1 << q for q in rng.sample(range(n), density)) for _ in range(17)]
            p = Problem(n, len(rows), 1, 0, arr(rows, n), arr([1], n), None)
            for mask in [0, 1]:
                assert probe(ctypes.byref(p), mask, ctypes.byref(repairs)) == 1
    assert repairs.value == 438374, repairs.value
    for n in [33, 65, 96]:
        for first, distance, witness in [([3, 6], 3, 7), ([3], 2, 3)]:
            h = first + [1 << i for i in range(distance, n)]
            assert harness.run(n, h, [1], [], 63) == (1, distance, witness)
    admitted = 0
    for case in range(100):
        n = rng.choice([32, 63, 64, 65, 96, 144])
        k = rng.choice([d for d in range(2, n + 1) if n % d == 0])
        matrices = []
        for density in [3, 4]:
            seed = sum(1 << i for i in rng.sample(range(n), density))
            matrices.append([shift(seed, n, k, j) for j in range(k)])
        checks, logicals = matrices
        if case % 2:
            logicals.append(1 << rng.randrange(n))
        p = Problem(n, len(checks), len(logicals), 0, arr(checks, n), arr(logicals, n), None)
        expected = reference_period(n, checks, logicals)
        assert period(ctypes.byref(p)) == expected
        admitted += expected > 1
    assert 0 < admitted < 100
    print(f"{repairs.value} known repairs, 6 exact parity controls, 100 orbit comparisons passed")


if __name__ == "__main__":
    main(sys.argv[1])
