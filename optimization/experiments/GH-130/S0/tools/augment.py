#!/usr/bin/env python3
"""GH-130 causal check: append redundant parity rows (sums of two rows that share a qubit) to both Hx and Hz of
a code. The row spaces, hence the code, its distance and every half's solution set, are unchanged; the Tanner
graph gains 4-cycles (a sum row shares w-1 qubits with each summand). usage: augment.py SRC_PREFIX OUT_PREFIX FRAC SEED"""
import random, sys, itertools
src, out, frac, seed = sys.argv[1], sys.argv[2], float(sys.argv[3]), int(sys.argv[4])
rng = random.Random(seed)
def load(p):
    rows = [[int(x) for x in l.split()] for l in open(p) if l.strip()]
    return rows
def c4(rows):
    S = [set(i for i, v in enumerate(r) if v) for r in rows]
    tot = 0
    for a, b in itertools.combinations(range(len(S)), 2):
        k = len(S[a] & S[b]); tot += k * (k - 1) // 2
    return tot / len(S)
for M in ('Hx', 'Hz'):
    rows = load(f'{src}_{M}.txt'); m = len(rows); n = len(rows[0])
    add = []
    for i in rng.sample(range(m), int(round(frac * m))):
        nb = [j for j in range(m) if j != i and any(rows[i][q] and rows[j][q] for q in range(n))]
        j = rng.choice(nb); add.append([x ^ y for x, y in zip(rows[i], rows[j])])
    new = rows + add
    open(f'{out}_{M}.txt', 'w').write('\n'.join(' '.join(map(str, r)) for r in new) + '\n')
    print(M, 'rows', m, '->', len(new), 'C4/row', round(c4(rows), 2), '->', round(c4(new), 2))
for M in ('Gx', 'Gz'):
    open(f'{out}_{M}.txt', 'w').write(open(f'{src}_{M}.txt').read())
