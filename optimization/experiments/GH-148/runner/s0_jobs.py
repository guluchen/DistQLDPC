#!/usr/bin/env python3
"""GH-148 S0 exploration jobs (run from a worktree root on yfclab2): candidate binary, variants off / on (auto
encoding) / on with the sequential counter, tier1-3 (TN_144 only from tier3), both modes, seeds 0-2, -frontier-stats
(per-probe conflict counts on stderr; search unchanged). Informational only (work counts and rough walls), not a gate.
usage: s0_jobs.py CAND OUT.jsonl"""
import glob, json, os, sys
CAND, OUT = sys.argv[1:3]
codes = []
for t in (1, 2, 3):
    for f in sorted(glob.glob(f'data/matrices/tier{t}/*_Hx.txt'), key=lambda p: -int(os.path.basename(p).split('_')[1])):
        stem = os.path.basename(f)[:-7]
        if t == 3 and not stem.startswith('TN_144'): continue
        codes.append((t, stem))
var = (('off', []), ('bin', ['-stab-overlap=on']), ('seq', ['-stab-overlap=on', '-stab-overlap-enc=seq']))
with open(OUT, 'w') as fh:
    for t, stem in codes:
        for mode in ('-no-card', '-card-mto'):
            for s in range(3):
                for vn, ex in var:
                    fh.write(json.dumps(dict(id=f's0.{stem}.{mode[1:]}.{vn}.s{s}', bin=CAND, args=[mode, f'-seed={s}', '-frontier-stats'] + ex,
                                             code=f'data/matrices/tier{t}/{stem}', stem=stem, tier=t, arm=vn, seed=s, mode=mode[1:], limit=1800)) + '\n')
