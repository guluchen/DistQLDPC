#!/usr/bin/env python3
"""GH-152 adoption Tier 0 identity check (adapted from GH-152 S0/ident.py). -v logs on tier0+tier1, time fields masked,
stdout+stderr compared line by line; each process pinned and capped (taskset -c CORE prlimit --as=4294967296).
Groups:
  maxsat: frozen main e52d15b vs the adoption binary, default MaxSAT path, {-no-card, -card-mto}, with the default
          -ub-pre=on (finder alternates halves by TIME: a difference is attributed to timing only if base-vs-base differs
          or the first differing line is an ub-pre progress line) and with -ub-pre=off (deterministic).
  cc:     (a) e52d15b -engine=cc vs adoption -engine=cc -cc-aut=off (the old CC path), -ub-search=off with/without
          -cc-stats; (b) GH-152 binary dfd0717 -engine=cc -cc-aut=on vs adoption -engine=cc (new default), same flags.
usage: ident_adopt.py GROUP BASE CAND GH152 OUTDIR CORE   (run from a worktree root)"""
import glob, os, re, subprocess, sys
GROUP, BASE, CAND, GH152, OUT, CORE = sys.argv[1:7]
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
tot = {}
for c in codes:
    L = ['-cpu-lim=300', c]
    if GROUP == 'maxsat':
        cfgs = [('maxsat' + m, BASE, ['-v', m] + L, CAND, ['-v', m] + L) for m in ('-no-card', '-card-mto')]
        cfgs += [('maxsat-nopre' + m, BASE, ['-v', '-ub-pre=off', m] + L, CAND, ['-v', '-ub-pre=off', m] + L) for m in ('-no-card', '-card-mto')]
    else:
        cfgs = []
        for nm, ex in (('noub', ['-ub-search=off']), ('noub-stats', ['-ub-search=off', '-cc-stats'])):
            cfgs.append((f'cc-off-{nm}', BASE, ['-engine=cc', '-v'] + ex + L, CAND, ['-engine=cc', '-v', '-cc-aut=off'] + ex + L))
            cfgs.append((f'cc-on-{nm}', GH152, ['-engine=cc', '-v', '-cc-aut=on'] + ex + L, CAND, ['-engine=cc', '-v'] + ex + L))
    for name, bb, ba, cb, ca in cfgs:
        pb = run(bb, ba, f'{c}.{name}.base')
        pc = run(cb, ca, f'{c}.{name}.cand')
        a = (norm(pb.stdout), norm(pb.stderr), pb.returncode); b = (norm(pc.stdout), norm(pc.stderr), pc.returncode)
        same = a == b
        verdict = 'IDENTICAL'
        if not same:
            p2 = run(bb, ba, f'{c}.{name}.base2')
            a2 = (norm(p2.stdout), norm(p2.stderr), p2.returncode)
            x, y = a[0] + a[1], b[0] + b[1]
            first = next((i for i, (p, q) in enumerate(zip(x, y)) if p != q), min(len(x), len(y)))
            line = (x + [''])[first] + ' ' + (y + [''])[first]
            timing = a2 != a or 'ub-pre' in line or 'ub-search' in line
            verdict = 'DIFFERENT-TIMING' if timing else 'DIFFERENT'
        tot.setdefault(name, {}).setdefault(verdict, 0)
        tot[name][verdict] += 1
        print(f'{c:16s} {name:24s} {verdict} ({len(a[0])} stdout lines, rc {pb.returncode}/{pc.returncode})', flush=True)
        if not same:
            print(f'   first diff line {first}:\n   base: {(x + [""])[first]}\n   cand: {(y + [""])[first]}\n   base-vs-base differs: {a2 != a}')
for k, v in tot.items(): print(f'{k}: ' + ', '.join(f'{x} {y}' for x, y in sorted(v.items())))
print('DONE')
