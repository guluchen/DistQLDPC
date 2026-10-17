#!/usr/bin/env python3
"""GH-128: compare the value sequence of the quiet output lines (c trying d / c d_lb / c d_ub / c d / o, times dropped)
of every Tier 5 -p1skip=on run with main 398054e's recorded run (results/server-main398-tier5 on yfclab2; old stems are
matched on family_n_k). Identical sequence = same probe sequence (each probe prints its `c trying d` line; a skipped
probe would remove one). Run in ~/mac-agent-20261009/results on yfclab2."""
import glob, os
def seq(f):
    out = []
    for l in open(f):
        if l.startswith('#'): continue
        p = l.rstrip('\n').split('\t', 1)
        if len(p) < 2: continue
        t = p[1]
        if t.startswith(('c trying', 'c d_', 'c d ', 'o ')): out.append(t.strip())
    return out
main = {}
for f in glob.glob('server-main398-tier5/*.main.log'):
    b = os.path.basename(f).split('.'); main[('_'.join(b[0].split('_')[:3]), b[1])] = f
c = {'identical': 0, 'differ': 0}
for f in sorted(glob.glob('gh128-s1/tier5/*.on.*.log')):
    b = os.path.basename(f).split('.'); key = ('_'.join(b[0].split('_')[:3]), b[2])
    a, m = seq(f), seq(main[key])
    if a == m: c['identical'] += 1; st = 'identical'
    else:
        n = min(len(a), len(m)); i = next((i for i in range(n) if a[i] != m[i]), n)
        c['differ'] += 1
        st = f'same first {i} lines; then on {a[i:i+1]} (timeout summary follows) vs main {m[i:i+3]}'
    print(key[0], key[1], st)
print(c)
