#!/usr/bin/env python3
"""Independent check of the implied clauses actually emitted by the candidate.

Usage: verify_dump.py <matrices-dir> <code> <baseline.wcnf> <candidate.wcnf>
Both WCNFs come from `-cpu-lim=1 -dump-wcnf=...` (solve path, dumped after the
solver's own preprocessing, which may reshape Tseitin aux clauses differently once
extra clauses are present). Candidate-only clauses of the GH-79 form
(-a_j v OR v_i), v = x (j < |Gx|) or z (j >= |Gx|), are checked: supp + G_j must lie
in rowspace(Hz) (X side) / rowspace(Hx) (Z side). The count of such clauses is
printed for comparison with the `-v` `c conj-clauses` totals; other differences
(aux-variable reshaping by the preprocessor) are counted, not verified.
Variables (1-based): x 1..n, z n+1..2n, w 2n+1..3n, a 3n+1..3n+k.
"""
import collections, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from conj_offline import load, echelon, reduce

def clauses(p):
    out = collections.Counter()
    for line in open(p):
        if not line.strip() or line[0] in 'cp':
            continue
        t = line.split()
        out[(t[0], tuple(sorted(int(v) for v in t[1:-1])))] += 1
    return out

mdir, code, fb, fc = sys.argv[1:5]
Hx, n = load(os.path.join(mdir, code + '_Hx.txt')); Hz, _ = load(os.path.join(mdir, code + '_Hz.txt'))
Gx, _ = load(os.path.join(mdir, code + '_Gx.txt')); Gz, _ = load(os.path.join(mdir, code + '_Gz.txt'))
bx, bz = echelon(Hz, list(range(n))), echelon(Hx, list(range(n)))
cb, cc = clauses(fb), clauses(fc)
missing = cb - cc
extra = cc - cb
ok = bad = other = 0
for (w, lits), cnt in extra.items():
    neg = [l for l in lits if l < 0]
    pos = [l for l in lits if l > 0]
    if not (len(neg) == 1 and 3 * n < -neg[0] <= 3 * n + len(Gx) + len(Gz) and pos and all(l <= 2 * n for l in pos)):
        other += cnt
        continue
    good = True
    if good:
        j = -neg[0] - 3 * n - 1
        if j < len(Gx):
            g, basis, lo = Gx[j], bx, 1
        else:
            g, basis, lo = Gz[j - len(Gx)], bz, n + 1
        u = 0
        for l in pos:
            i = l - lo
            if not 0 <= i < n:
                good = False; break
            u |= 1 << i
        good = good and reduce(u ^ g, basis) == 0
    if good: ok += cnt
    else: bad += cnt; print('BAD', w, lits)
print('%s: conj-form clauses verified implied %d, bad %d; other preprocessing differences +%d/-%d' % (
    code, ok, bad, other, sum(missing.values())))
sys.exit(1 if bad else 0)
