#!/usr/bin/env python3
"""GH-98 XOR detection report from -v traces (<code>.<mode>.out). Per code (mode 'default'), the distinct
'c GH-98 XOR detection' lines in order of appearance (one per CSS half instance; repeated oracle calls repeat them)."""
import sys, os, re, collections
d, listfile = sys.argv[1], sys.argv[2]
pat = re.compile(r'c GH-98 XOR detection: (\d+) XORs \(k3 (\d+), k4 (\d+), k5 (\d+), k6 (\d+)\); (\d+) of (\d+) original clauses \(([\d.]+)%\), (\d+) of (\d+) literals \(([\d.]+)%\); candidates k3 (\d+), k4 (\d+), k5 (\d+), k6 (\d+)')
codes = []
for line in open(listfile):
    c, m = line.split()
    if m == 'default': codes.append(c)
print('| code | half | XORs | k3 | k4 | k5 | k6 | XOR clauses / original | % clauses | % literals | size-3 cand. covered | size-4 cand. covered |')
print('|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|')
tot = collections.Counter()
for c in codes:
    t = open(os.path.join(d, c + '.default.out'), errors='replace').read()
    seen = []
    for m in pat.finditer(t):
        if m.group(0) not in seen: seen.append(m.group(0))
    for h, s in enumerate(seen):
        g = list(map(float, pat.match(s).groups()))
        n, k3, k4, k5, k6, cov, orig, pc, lc, lo, pl, c3, c4, c5, c6 = g
        print(f'| {c} | {h} | {int(n)} | {int(k3)} | {int(k4)} | {int(k5)} | {int(k6)} | {int(cov)} / {int(orig)} | {pc:.1f} | {pl:.1f} | {100*4*k3/c3 if c3 else 0:.1f}% | {100*8*k4/c4 if c4 else 0:.1f}% |')
        tot['inst'] += 1; tot['xors'] += n; tot['k3'] += k3; tot['k4'] += k4; tot['k5'] += k5; tot['k6'] += k6; tot['cov'] += cov; tot['orig'] += orig; tot['lc'] += lc; tot['lo'] += lo
    if not seen: print(f'| {c} | - | no detection line | | | | | | | | | |')
print(f"\nTOTAL half-instances {tot['inst']}: XORs {int(tot['xors'])} (k3 {int(tot['k3'])}, k4 {int(tot['k4'])}, k5 {int(tot['k5'])}, k6 {int(tot['k6'])}); "
      f"clauses covered {int(tot['cov'])}/{int(tot['orig'])} = {100*tot['cov']/max(1,tot['orig']):.1f}%; literals {100*tot['lc']/max(1,tot['lo']):.1f}%")
