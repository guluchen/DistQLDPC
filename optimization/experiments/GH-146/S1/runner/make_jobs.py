#!/usr/bin/env python3
"""GH-146 S1 jobs (yfclab2). One frozen binary BIN (4f16e0d) for both arms: 'old' = the GH-140 finder (no -ub-isd; the
default path is identical to GH-144's 6d2b7a1, S0/ident.py), 'new' = -ub-isd=stern (P 2, L automatic, W 32).
Panel (tier1-4, seeds 0-4, limits tier1-3 1800 s, tier4 5000 s), the two arms of a (code, engine/mode, seed) adjacent:
  CC:     -engine=cc -cc-stats -ub-search=on -seed=S [-ub-isd=stern]
  MaxSAT: -no-card|-card-mto -seed=S -ub-pre=on [-ub-isd=stern]
Tier 5 (6 h, default seed, new arm only; compared with GH-140's CC Tier 5 and GH-144's MaxSAT Tier 5):
  CC:     -engine=cc -cc-stats -ub-search=on -ub-isd=stern -cc-trace=res/tier5_traces/STEM.trace
  MaxSAT: -no-card|-card-mto -ub-pre=on -ub-isd=stern
usage: make_jobs.py BIN OUTDIR   (from a worktree root; writes jobs_panel.jsonl and jobs_tier5.jsonl)"""
import glob, json, os, sys
BIN, OUT = sys.argv[1], sys.argv[2]
def codes(tiers):
    r = []
    for t in tiers:
        for f in sorted(glob.glob(f'data/matrices/tier{t}/*_Hx.txt')):
            r.append((t, os.path.basename(f)[:-7], f[:-7]))
    return r
ISD = ['-ub-isd=stern']
panel = []
for t, stem, code in sorted(codes([1, 2, 3, 4]), key=lambda x: -x[0]):   # tier 4 first
    lim = 5000 if t == 4 else 1800
    for s in range(5):
        for arm in ('old', 'new'):
            panel.append(dict(id=f'{stem}.cc.{arm}.s{s}', bin=BIN, args=['-engine=cc', '-cc-stats', '-ub-search=on', f'-seed={s}'] + (ISD if arm == 'new' else []),
                              code=code, stem=stem, tier=t, arm=arm, seed=s, mode='cc', limit=lim))
        for mode in ('no-card', 'card-mto'):
            for arm in ('old', 'new'):
                panel.append(dict(id=f'{stem}.{mode}.{arm}.s{s}', bin=BIN, args=[f'-{mode}', f'-seed={s}', '-ub-pre=on'] + (ISD if arm == 'new' else []),
                                  code=code, stem=stem, tier=t, arm=arm, seed=s, mode=mode, limit=lim))
t5 = []
for t, stem, code in codes([5]):
    t5.append(dict(id=f't5.{stem}.cc.new', bin=BIN, args=['-engine=cc', '-cc-stats', '-ub-search=on'] + ISD + [f'-cc-trace=res/tier5_traces/{stem}.trace'],
                   code=code, stem=stem, tier=5, arm='new', seed=0, mode='cc', limit=21600))
    for mode in ('no-card', 'card-mto'):
        t5.append(dict(id=f't5.{stem}.{mode}.new', bin=BIN, args=[f'-{mode}', '-ub-pre=on'] + ISD, code=code, stem=stem, tier=5, arm='new',
                       seed=0, mode=mode, limit=21600))
for name, js in (('jobs_panel.jsonl', panel), ('jobs_tier5.jsonl', t5)):
    with open(os.path.join(OUT, name), 'w') as fh:
        for j in js: fh.write(json.dumps(j) + '\n')
    print(name, len(js))
