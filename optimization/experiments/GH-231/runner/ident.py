#!/usr/bin/env python3
"""GH-231 identity check (from GH-227's ident.py, MaxSAT configurations only): frozen main (BASE) vs the GH-231 candidate
(CAND), -v logs on tier0+tier1, {-no-card, -card-mto} x {default, -ub-pre=off} with the same flags for both, and the same
four with -native-lb=off given explicitly to CAND (the default). Expected: IDENTICAL (main's default -ub-pre=on alternates
its halves by finder TIME, so a -v log can differ between two runs of the same binary; such a difference is attributed to
timing only if BASE-vs-BASE differs too or the first differing line is an ub-pre progress line). Time fields masked;
stdout+stderr compared line by line. Every process pinned and capped (taskset -c CORE prlimit --as=4294967296).
usage: ident.py BASE CAND OUTDIR CORE (from a worktree root)"""
import glob, os, re, subprocess, sys
BASE, CAND, OUT, CORE = sys.argv[1:5]
os.makedirs(OUT, exist_ok=True)
codes = []
for t in (0, 1):
    codes += [os.path.basename(f)[:-7] for f in sorted(glob.glob(f'data/matrices/tier{t}/*_Hx.txt'))]
OLD = ['-native-lb=off']
MASK = [re.compile(r'cpu[ =]?\d+\.\d+s?'), re.compile(r'\d+\.\d+ ?s\b'), re.compile(r'\d+\.\d+s\)'), re.compile(r'detect_cpu=\d+\.\d+s'),
        re.compile(r'time\s*:?\s*\d+\.\d+'), re.compile(r'(CPU time|Real time|Wall)[^\n]*', re.I), re.compile(r'wall \d+\.\d+s')]
def norm(txt):
    out = []
    for l in txt.splitlines():
        for m in MASK: l = m.sub('<T>', l)
        out.append(l)
    return out
pre = ['taskset', '-c', CORE, 'prlimit', '--as=4294967296', '--']
def run(b, args, tag):
    p = subprocess.run(pre + [b] + args, capture_output=True, text=True, stdin=subprocess.DEVNULL)
    open(f'{OUT}/{tag}.out', 'w').write(p.stdout); open(f'{OUT}/{tag}.err', 'w').write(p.stderr)
    return p
tot = {}
for c in codes:
    cfgs = [('maxsat' + m, ['-v', m, '-cpu-lim=300', c], False) for m in ('-no-card', '-card-mto')]
    cfgs += [('maxsat-nopre' + m, ['-v', '-ub-pre=off', m, '-cpu-lim=300', c], False) for m in ('-no-card', '-card-mto')]
    cfgs += [('maxsat-off' + m, ['-v', m, '-cpu-lim=300', c], True) for m in ('-no-card', '-card-mto')]
    cfgs += [('maxsat-off-nopre' + m, ['-v', '-ub-pre=off', m, '-cpu-lim=300', c], True) for m in ('-no-card', '-card-mto')]
    for name, args, cc in cfgs:
        pb = run(BASE, args, f'{c}.{name}.base')
        cargs = (OLD + args) if cc is True else args
        pc = run(CAND, cargs, f'{c}.{name}.cand')
        a = (norm(pb.stdout), norm(pb.stderr), pb.returncode); b = (norm(pc.stdout), norm(pc.stderr), pc.returncode)
        same = a == b
        verdict = 'IDENTICAL'
        if not same:
            p2 = run(BASE, args, f'{c}.{name}.base2')
            a2 = (norm(p2.stdout), norm(p2.stderr), p2.returncode)
            x, y = a[0] + a[1], b[0] + b[1]
            first = next((i for i, (p, q) in enumerate(zip(x, y)) if p != q), min(len(x), len(y)))
            line = (x + [''])[first] + ' ' + (y + [''])[first]
            timing = a2 != a or 'ub-pre' in line or 'ub-search' in line
            verdict = 'DIFFERENT-TIMING' if timing else 'DIFFERENT'
        tot.setdefault(name, {}).setdefault(verdict, 0)
        tot[name][verdict] += 1
        print(f'{c:16s} {name:26s} {verdict} ({len(a[0])} stdout lines, rc {pb.returncode}/{pc.returncode})', flush=True)
        if not same:
            print(f'   first diff line {first}:\n   base: {(x + [""])[first]}\n   cand: {(y + [""])[first]}\n   base-vs-base differs: {a2 != a}')
for k, v in tot.items(): print(f'{k}: ' + ', '.join(f'{x} {y}' for x, y in sorted(v.items())))
