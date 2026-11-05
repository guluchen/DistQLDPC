#!/usr/bin/env python3
"""GH-227 job files (copied from GH-225; run from a worktree root on yfclab2). Arms (all -engine=cc -cc-stats):
  M  = frozen main 1239e9a2 with its defaults (excl,pack,orbf,parity,leaf,overlap,charge,tiebreak,sparse,sparseov,sparsemrv,
       -cc-roworder=auto) = the baseline of this round;
  C  = the GH-227 candidate binary with its defaults (main + erasure with the cost gate);
  Mx = the candidate binary with the explicit main rules (erasure off; identity / drift control);
  N  = the candidate binary with erasure ungated (-cc-erasure-gate=none, = GH-225's E; information only).
Codes are found under data/matrices/*/; the tier recorded is the directory at job creation.
  panel OUT M_BIN C_BIN ARMS SEEDS LIMIT STEM...: seeds 0..SEEDS-1, the arms of each (code, seed) adjacent (they start together).
  tier5 OUT M_BIN C_BIN ARMS LIMIT STEM...: default seed.
  answers OUT M_BIN C_BIN STEM...: Tier 0 answer + witness check (600 s, -cc-trace TRACEDIR/<id>.trace), candidate variants.
"""
import glob, json, os, sys
kind, out, MBIN, CBIN = sys.argv[1:5]
MR = 'excl,pack,orbf,parity,leaf,overlap,charge,tiebreak,sparse,sparseov,sparsemrv'


def arm(name):
    if name == 'M': return MBIN, []
    if name == 'C': return CBIN, []
    if name == 'Mx': return CBIN, [f'-cc-rules={MR}']
    if name == 'N': return CBIN, ['-cc-erasure-gate=none']
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
    VARS = [('C', []), ('C-seed1', ['-seed=1']), ('C-seed2-dualoff', ['-seed=2', '-cc-dual=off']), ('C-switch', ['-cc-probe=switch']),
            ('C-p0-seed3', ['-cc-probe=0', '-seed=3']), ('C-autoff-seed4', ['-cc-aut=off', '-seed=4']), ('C-nosym', ['-no-symbreak', '-cc-probe=0']),
            ('C-noub', ['-ub-search=off', '-ub-basis=off', '-cc-probe=0']), ('C-start0', ['-cc-erasure-start=0']),
            ('C-start0-k1', ['-cc-erasure-start=0', '-cc-erasure-sample=1']),
            ('C-start0-k2-on', ['-cc-erasure-start=0', '-cc-erasure-sample=2', '-cc-erasure-margin=-1', '-seed=5']),
            ('C-start0-k4-off', ['-cc-erasure-start=0', '-cc-erasure-sample=4', '-cc-erasure-margin=1e9', '-cc-roworder=index', '-seed=6']),
            ('C-start0-bfsmrv-seed7', ['-cc-erasure-start=0', f'-cc-rules={MR},mrv,erasure', '-cc-roworder=bfs', '-seed=7']),
            ('N-start0', ['-cc-erasure-start=0', '-cc-erasure-gate=none'])]
    for stem in sys.argv[5:]:
        code, tier = code_of(stem)
        for name, extra in VARS:
            jid = f'ans.{stem}.{name}'
            jobs.append(dict(id=jid, bin=CBIN, args=['-engine=cc', '-cc-stats'] + extra + [f'-cc-trace=TRACEDIR/{jid}.trace'],
                             code=code, stem=stem, tier=tier, arm=name, seed=0, limit=600))
with open(out, 'w') as fh:
    for j in jobs: fh.write(json.dumps(j) + '\n')
print(len(jobs), 'jobs ->', out)
