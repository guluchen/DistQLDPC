#!/usr/bin/env python3
"""GH-146 identity check: the GH-144 binary (BASE) vs the candidate (CAND) without -ub-isd and with -ub-isd=off, on
tier0+tier1. Configurations: (1) default MaxSAT path, -v, {-no-card, -card-mto}; (2) -ub-pre=on, -v, both modes (the
pre-pass is iteration-based, so its words, iterations and U0 are deterministic); time fields masked, stdout+stderr
compared line by line. (3) CC finder alone (-engine=cc -v -ub-basis=off -ub-search=budget:1 -cc-ub-only): how many iterations fit in
1 s depends on the machine, so the sequences of 'word of weight' / witness lines are compared up to the shorter one
(with the iteration numbers, which are deterministic per seed).
With -ub-isd=off and no finder flag (configuration 1) the candidate refuses the flag by design (exit 1, 'needs the
finder'), so those rows differ by construction. Every process pinned and capped (taskset -c CORE prlimit --as=4294967296). usage: ident.py BASE CAND OUTDIR CORE (from a worktree root)"""
import glob, os, re, subprocess, sys
BASE, CAND, OUT, CORE = sys.argv[1:5]
os.makedirs(OUT, exist_ok=True)
codes = []
for t in (0, 1):
    codes += [os.path.basename(f)[:-7] for f in sorted(glob.glob(f'data/matrices/tier{t}/*_Hx.txt'))]
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
ident = diff = 0
for c in codes:
    cfgs = [('maxsat' + m, ['-v', m, '-cpu-lim=300', c], 'full') for m in ('-no-card', '-card-mto')]
    cfgs += [('ubpre' + m, ['-v', '-ub-pre=on', m, '-cpu-lim=300', c], 'full') for m in ('-no-card', '-card-mto')]
    cfgs += [('ccfinder', ['-engine=cc', '-v', '-ub-basis=off', '-ub-search=budget:1', '-cc-ub-only', '-cpu-lim=300', c], 'words')]
    for name, args, kind in cfgs:
        pb = run(BASE, args, f'{c}.{name}.base')
        for ex in ([], ['-ub-isd=off']):
            pc = run(CAND, ex + args, f'{c}.{name}{"_".join([""] + [e.strip("-") for e in ex])}.cand')
            if kind == 'full':
                same = (norm(pb.stdout), norm(pb.stderr), pb.returncode) == (norm(pc.stdout), norm(pc.stderr), pc.returncode)
            else:
                wa = [norm(l)[0] for l in pb.stdout.splitlines() if 'word of weight' in l or l.startswith('c witness')]
                wb = [norm(l)[0] for l in pc.stdout.splitlines() if 'word of weight' in l or l.startswith('c witness')]
                k = min(len(wa), len(wb))
                same = wa[:k] == wb[:k] and (k > 0 or len(wa) == len(wb))
            ident += same; diff += not same
            print(f'{c:16s} {name:18s} {" ".join(ex):12s} {"IDENTICAL" if same else "DIFFERENT"}', flush=True)
print(f'identical {ident}, different {diff}')
