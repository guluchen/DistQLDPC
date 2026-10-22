#!/usr/bin/env python3
"""GH-140 S1 jobs: (1) Tier 1-4 panel, -engine=cc with -ub-search=off ("off") vs -ub-search=on ("on"), seeds 0-4,
limits tier1-3 1800 s, tier4 5000 s (GH-138 rules; both arms of a (code, seed) back to back, largest codes first);
(2) Tier 5: every tier5 code, -engine=cc -ub-search=on, default seed, 21600 s. -cc-stats in every run."""
import glob, json, os
here = os.path.dirname(os.path.abspath(__file__))
panel, t5 = [], []
for t in (4, 3, 2, 1):
    for f in sorted(glob.glob(f'data/matrices/tier{t}/*_Hx.txt')):
        stem = os.path.basename(f)[:-7]
        for s in range(5):
            for arm, extra in (('off', []), ('on', ['-ub-search=on'])):
                panel.append(dict(id=f'cc.{stem}.{arm}.s{s}', args=['-engine=cc', '-cc-stats', f'-seed={s}'] + extra,
                                  code=f'data/matrices/tier{t}/{stem}', stem=stem, tier=t, arm=arm, seed=s,
                                  limit=5000 if t == 4 else 1800))
for f in sorted(glob.glob('data/matrices/tier5/*_Hx.txt'), key=lambda p: -int(os.path.basename(p).split('_')[1])):
    stem = os.path.basename(f)[:-7]
    t5.append(dict(id=f't5.{stem}.on', args=['-engine=cc', '-cc-stats', '-ub-search=on'], code=f'data/matrices/tier5/{stem}',
                   stem=stem, tier=5, arm='on', seed=0, limit=21600))
for name, js in (('jobs_panel.jsonl', panel), ('jobs_tier5.jsonl', t5)):
    with open(os.path.join(here, name), 'w') as fh:
        for j in js: fh.write(json.dumps(j) + '\n')
    print(name, len(js))
