#!/usr/bin/env python3
"""GH-227 identity check (from GH-225/GH-217/GH-206/GH-183): frozen main 1239e9a2 (BASE) vs the
candidate (CAND, erasure in the default rules), -v logs on tier0+tier1.
(1) MaxSAT default path, same flags for both: {-no-card, -card-mto}, with and without -ub-pre=off (main's default -ub-pre=on
alternates its halves by finder TIME, so its -v log can differ between two runs of the same binary).
(2) CC engine: BASE with its defaults, CAND with the explicit GH-217 default rules
-cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,tiebreak,sparse,sparseov,sparsemrv ("OLD"; when a configuration names its own
-cc-rules, CAND gets the same flags), with -ub-search=off
(deterministic), -cc-stats, -cc-aut=off, the finder on (default; wall-time share, compared after masking times), -engine=auto.
Control: a differing configuration is re-run with BASE; it is attributed to timing only if BASE-vs-BASE differs too or the first
differing line is an ub-pre / ub-search progress line. Time fields masked; stdout+stderr compared line by line. Every process
pinned and capped (taskset -c CORE prlimit --as=4294967296). usage: ident.py BASE CAND OUTDIR CORE (from a worktree root)"""
import glob, os, re, subprocess, sys
BASE, CAND, OUT, CORE = sys.argv[1:5]
os.makedirs(OUT, exist_ok=True)
codes = []
for t in (0, 1):
    codes += [os.path.basename(f)[:-7] for f in sorted(glob.glob(f'data/matrices/tier{t}/*_Hx.txt'))]
OLD = ['-cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,tiebreak,sparse,sparseov,sparsemrv']
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
    cfgs += [('cc-noub', ['-engine=cc', '-v', '-ub-search=off', '-cpu-lim=300', c], True),
             ('cc-noub-stats', ['-engine=cc', '-v', '-ub-search=off', '-cc-stats', '-cpu-lim=300', c], True),
             ('cc-default', ['-engine=cc', '-v', '-cpu-lim=300', c], True),
             ('cc-autoff-noub-stats', ['-engine=cc', '-v', '-cc-aut=off', '-ub-search=off', '-cc-stats', '-cpu-lim=300', c], True),
             ('cc-seed3-noub-stats', ['-engine=cc', '-v', '-seed=3', '-ub-search=off', '-cc-stats', '-cpu-lim=300', c], True),
             ('engine-auto-noub', ['-engine=auto', '-v', '-ub-search=off', '-cpu-lim=300', c], True),
             ('cc-gh206-rules-noub-stats', ['-engine=cc', '-v', '-ub-search=off', '-cc-stats', '-cc-rules=excl,pack,orbf,parity,leaf,overlap', '-cpu-lim=300', c], 'ro')]
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
