#!/usr/bin/env python3
"""Compare ident_server.py outputs: per pair (main|on vs auto), the -frontier-stats per-probe lines (conflicts,
decisions, frontier picks) and the bound lines on stdout. Completed probes must match exactly; when a run hit its
cpu limit, the interrupted last probe and the final status lines are excluded. usage: ident_compare.py DIR"""
import glob, os, re, sys
D = sys.argv[1]
def probes(p): return [l.strip() for l in open(p) if l.startswith('c FRONTIER')]
def bounds(p): return [l.strip() for l in open(p) if re.match(r'c (trying d|d_lb|d_ub|d  )|o ', l)]
ok = bad = 0
for f in sorted(glob.glob(f'{D}/*.auto.err')):
    base = f[:-9]; ref = base + ('.main' if os.path.exists(base + '.main.err') else '.on')
    pa, pr_ = probes(f), probes(ref + '.err'); ba, br = bounds(base + '.auto.out'), bounds(ref + '.out')
    solved = any(l.startswith('o ') for l in ba) and any(l.startswith('o ') for l in br)
    if solved: same = pa == pr_ and ba == br
    else:
        k = min(len(pa), len(pr_)) - 1; same = k >= 0 and pa[:k] == pr_[:k]
        kb = min(len(ba), len(br)); same = same and ba[:kb - 1] == br[:kb - 1]
    ok += same; bad += not same
    print(f'{os.path.basename(base):45s} vs {ref[-4:].strip(".")}: {"IDENTICAL" if same else "DIFFERENT"} '
          f'({len(pa)} / {len(pr_)} probe lines, {"solved" if solved else "cpu limit: completed probes compared"})')
print(f'identical {ok}, different {bad}')
