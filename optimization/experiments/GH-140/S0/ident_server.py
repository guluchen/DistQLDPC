#!/usr/bin/env python3
"""GH-140 identity check (server: each process pinned, 4 GB cap): frozen main c914ef5 vs candidate, default MaxSAT path, -v logs on tier0+tier1 x {-no-card, -card-mto}.
Lines are compared after masking time fields (cpu/wall seconds). usage: ident_server.py MAIN CAND OUTDIR CORE"""
import glob, os, re, subprocess, sys
MAIN, CAND, OUT, CORE = sys.argv[1:5]
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
ident = diff = 0
for c in codes:
    for mode in ('-no-card', '-card-mto'):
        logs = {}
        for name, b in (('main', MAIN), ('cand', CAND)):
            p = subprocess.run(['taskset', '-c', CORE, 'prlimit', '--as=4294967296', '--', b, '-v', mode, '-cpu-lim=300', c], capture_output=True, text=True, stdin=subprocess.DEVNULL)
            open(f'{OUT}/{c}{mode}.{name}.out', 'w').write(p.stdout); open(f'{OUT}/{c}{mode}.{name}.err', 'w').write(p.stderr)
            logs[name] = (norm(p.stdout), norm(p.stderr), p.returncode)
        same = logs['main'] == logs['cand']
        ident += same; diff += not same
        n_lines = len(logs['main'][0])
        print(f'{c:16s} {mode:10s} {"IDENTICAL" if same else "DIFFERENT"} ({n_lines} stdout lines, rc {logs["main"][2]}/{logs["cand"][2]})', flush=True)
        if not same:
            a, b = logs['main'][0] + logs['main'][1], logs['cand'][0] + logs['cand'][1]
            for i, (x, y) in enumerate(zip(a, b)):
                if x != y: print(f'   first diff line {i}:\n   main: {x}\n   cand: {y}'); break
            if len(a) != len(b): print(f'   line counts {len(a)} vs {len(b)}')
print(f'identical {ident}, different {diff}')
