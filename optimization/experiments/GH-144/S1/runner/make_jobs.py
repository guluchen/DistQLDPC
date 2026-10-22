#!/usr/bin/env python3
"""GH-144 S1 jobs (run from a worktree root on yfclab2).
(1) Tier 1-4 panel, MaxSAT path: main 8eb047b (frozen, no flag) vs candidate with -ub-pre=S, modes -no-card and
    -card-mto, seeds 0-4 (-seed=0 = default search), limits tier1-3 1800 s, tier4 5000 s; the two arms of a
    (code, mode, seed) are adjacent in the queue (largest codes first), so they run concurrently on two pinned cores.
(2) Tier 5: every tier5 code x both modes, candidate with -ub-pre=S, default seed, 21600 s (compared with the
    recorded Tier 5 of main c914ef5, optimization/baselines/SERVER.md on branch baselines/main-c914ef5).
usage: make_jobs.py MAIN_BIN CAND_BIN S"""
import glob, json, os, sys
MAIN, CAND, S = sys.argv[1:4]
here = os.path.dirname(os.path.abspath(__file__))
modes = ('-no-card', '-card-mto')
panel, t5 = [], []
for t in (4, 3, 2, 1):
    for f in sorted(glob.glob(f'data/matrices/tier{t}/*_Hx.txt'), key=lambda p: -int(os.path.basename(p).split('_')[1])):
        stem = os.path.basename(f)[:-7]
        for mode in modes:
            for s in range(5):
                for arm, b, extra in (('main', MAIN, []), ('pre', CAND, [f'-ub-pre={S}'])):
                    panel.append(dict(id=f'{stem}.{mode[1:]}.{arm}.s{s}', bin=b, args=[mode, f'-seed={s}'] + extra,
                                      code=f'data/matrices/tier{t}/{stem}', stem=stem, tier=t, arm=arm, seed=s, mode=mode[1:],
                                      limit=5000 if t == 4 else 1800))
for f in sorted(glob.glob('data/matrices/tier5/*_Hx.txt'), key=lambda p: -int(os.path.basename(p).split('_')[1])):
    stem = os.path.basename(f)[:-7]
    for mode in modes:
        t5.append(dict(id=f't5.{stem}.{mode[1:]}.pre', bin=CAND, args=[mode, f'-ub-pre={S}'], code=f'data/matrices/tier5/{stem}',
                       stem=stem, tier=5, arm='pre', seed=0, mode=mode[1:], limit=21600))
for name, js in (('jobs_panel.jsonl', panel), ('jobs_tier5.jsonl', t5)):
    with open(os.path.join(here, name), 'w') as fh:
        for j in js: fh.write(json.dumps(j) + '\n')
    print(name, len(js))
