#!/usr/bin/env python3
"""GH-225 job files (run from a worktree root on yfclab2). Arms (all -engine=cc -cc-stats):
  A      = frozen PR #220 head 42d7d1d0 with its defaults (excl,pack,orbf,parity,leaf,overlap,charge,tiebreak,sparse,sparseov,
           sparsemrv, -cc-roworder=auto) = the baseline of this round;
  E      = the GH-225 candidate binary with its defaults (A + erasure);
  Ax     = the candidate binary with the explicit A rules (erasure off; drift / identity control);
  tuning arms on the A binary: Es<N> = -cc-rules=<A rules>,erasure -cc-erasure-start=N.
Codes are found under data/matrices/*/; the tier recorded is the directory at job creation.
  panel OUT A_BIN E_BIN ARMS SEEDS LIMIT STEM...: seeds 0..SEEDS-1, the arms of each (code, seed) adjacent (they start together).
  tier5 OUT A_BIN E_BIN ARMS LIMIT STEM...: default seed.
  answers OUT A_BIN E_BIN STEM...: Tier 0 answer + witness check (600 s, -cc-trace TRACEDIR/<id>.trace), candidate variants.
"""
import glob, json, os, sys
kind, out, ABIN, EBIN = sys.argv[1:5]
AR = 'excl,pack,orbf,parity,leaf,overlap,charge,tiebreak,sparse,sparseov,sparsemrv'


def arm(name):
    if name == 'A': return ABIN, []
    if name == 'E': return EBIN, []
    if name == 'Ax': return EBIN, [f'-cc-rules={AR}']
    if name.startswith('Es'): return ABIN, [f'-cc-rules={AR},erasure', f'-cc-erasure-start={int(name[2:])}']
    raise SystemExit('unknown arm ' + name)


def code_of(stem):
    f = glob.glob(f'data/matrices/*/{stem}_Hx.txt')
    assert len(f) == 1, (stem, f)
    return f[0][:-7], os.path.basename(os.path.dirname(f[0]))


jobs = []
if kind == 'panel':
    arms, seeds, limit = sys.argv[5].split(','), int(sys.argv[6]), int(sys.argv[7])
    for stem in sys.argv[8:]:
        code, tier = code_of(stem)
        for seed in range(seeds):
            for a in arms:
                b, extra = arm(a)
                jobs.append(dict(id=f'cc.{stem}.{a}.s{seed}', bin=b, args=['-engine=cc', '-cc-stats', f'-seed={seed}'] + extra,
                                 code=code, stem=stem, tier=tier, arm=a, seed=seed, limit=limit))
elif kind == 'tier5':
    arms, limit = sys.argv[5].split(','), int(sys.argv[6])
    for stem in sys.argv[7:]:
        code, tier = code_of(stem)
        for a in arms:
            b, extra = arm(a)
            jobs.append(dict(id=f't5.{stem}.{a}', bin=b, args=['-engine=cc', '-cc-stats'] + extra, code=code, stem=stem, tier=tier,
                             arm=a, seed=0, limit=limit))
elif kind == 'answers':
    VARS = [('E', []), ('E-seed1', ['-seed=1']), ('E-seed2-dualoff', ['-seed=2', '-cc-dual=off']), ('E-switch', ['-cc-probe=switch']),
            ('E-p0-seed3', ['-cc-probe=0', '-seed=3']), ('E-autoff-seed4', ['-cc-aut=off', '-seed=4']), ('E-nosym', ['-no-symbreak', '-cc-probe=0']),
            ('E-noub', ['-ub-search=off', '-ub-basis=off', '-cc-probe=0']), ('E-start0', ['-cc-erasure-start=0']),
            ('E-start0-index-seed5', ['-cc-erasure-start=0', '-cc-roworder=index', '-seed=5']),
            ('E-start0-bfsmrv-seed6', ['-cc-erasure-start=0', f'-cc-rules={AR},mrv,erasure', '-cc-roworder=bfs', '-seed=6'])]
    for stem in sys.argv[5:]:
        code, tier = code_of(stem)
        for name, extra in VARS:
            jid = f'ans.{stem}.{name}'
            jobs.append(dict(id=jid, bin=EBIN, args=['-engine=cc', '-cc-stats'] + extra + [f'-cc-trace=TRACEDIR/{jid}.trace'],
                             code=code, stem=stem, tier=tier, arm=name, seed=0, limit=600))
with open(out, 'w') as fh:
    for j in jobs: fh.write(json.dumps(j) + '\n')
print(len(jobs), 'jobs ->', out)
