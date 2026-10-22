#!/usr/bin/env python3
"""GH-144 identity check: frozen main 8eb047b vs candidate (no -ub-pre flag, i.e. the default MaxSAT path), -v logs on
tier0+tier1 x {-no-card, -card-mto}; optional EXTRA flags are given to the candidate only (e.g. -ub-pre=off).
Lines are compared after masking time fields (cpu/wall seconds). Server: every process pinned and capped
(taskset -c CORE prlimit --as=4294967296); CORE = 'mac' runs without them (macOS has neither).
usage: ident.py MAIN CAND OUTDIR CORE [EXTRA...]   (from a worktree root)"""
import glob, os, re, subprocess, sys
MAIN, CAND, OUT, CORE = sys.argv[1:5]
EXTRA = sys.argv[5:]
os.makedirs(OUT, exist_ok=True)
codes = []
for t in (0, 1):
    codes += [os.path.basename(f)[:-7] for f in sorted(glob.glob(f'data/matrices/tier{t}/*_Hx.txt'))]
MASK = [re.compile(r'cpu[ =]?\d+\.\d+s?'), re.compile(r'\d+\.\d+ ?s\b'), re.compile(r'\d+\.\d+s\)'), re.compile(r'detect_cpu=\d+\.\d+s'),
        re.compile(r'time\s*:?\s*\d+\.\d+'), re.compile(r'(CPU time|Real time|Wall)[^\n]*', re.I)]
def norm(txt):
    out = []
    for l in txt.splitlines():
        for m in MASK: l = m.sub('<T>', l)
        out.append(l)
    return out
pre = [] if CORE == 'mac' else ['taskset', '-c', CORE, 'prlimit', '--as=4294967296', '--']
ident = diff = 0
tag = ('_' + '_'.join(e.strip('-') for e in EXTRA)) if EXTRA else ''
for c in codes:
    for mode in ('-no-card', '-card-mto'):
        logs = {}
        for name, b, ex in (('main', MAIN, []), ('cand', CAND, EXTRA)):
            p = subprocess.run(pre + [b, '-v', mode] + ex + ['-cpu-lim=300', c], capture_output=True, text=True, stdin=subprocess.DEVNULL)
            open(f'{OUT}/{c}{mode}{tag}.{name}.out', 'w').write(p.stdout); open(f'{OUT}/{c}{mode}{tag}.{name}.err', 'w').write(p.stderr)
            logs[name] = (norm(p.stdout), norm(p.stderr), p.returncode)
        same = logs['main'] == logs['cand']
        ident += same; diff += not same
        n_lines = len(logs['main'][0])
        print(f'{c:16s} {mode:10s} {" ".join(EXTRA):12s} {"IDENTICAL" if same else "DIFFERENT"} ({n_lines} stdout lines, rc {logs["main"][2]}/{logs["cand"][2]})', flush=True)
        if not same:
            a, b = logs['main'][0] + logs['main'][1], logs['cand'][0] + logs['cand'][1]
            for i, (x, y) in enumerate(zip(a, b)):
                if x != y: print(f'   first diff line {i}:\n   main: {x}\n   cand: {y}'); break
            if len(a) != len(b): print(f'   line counts {len(a)} vs {len(b)}')
print(f'identical {ident}, different {diff}')
