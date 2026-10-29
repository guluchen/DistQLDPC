#!/usr/bin/env python3
"""GH-148 S1 jobs (run from a worktree root on yfclab2).
Panel: tier T (1-4), main = frozen 12b3e05 binary (no flag) vs candidate with CAND_FLAGS, modes -no-card and
-card-mto, seeds 0-4 (-seed=0 = default search), limits tier1-3 1800 s, tier4 5000 s; the two arms of a
(code, mode, seed) are adjacent in the queue (largest codes first) so they run concurrently on two pinned cores.
Tier 5: every tier5 code x both modes, candidate (and, with --main, main) default seed, 21600 s.
usage: make_jobs.py panel T MAIN CAND OUT.jsonl FLAG...   |   make_jobs.py tier5 ARM BIN OUT.jsonl FLAG..."""
import glob, json, os, sys
kind = sys.argv[1]
modes = ('-no-card', '-card-mto')
js = []
if kind == 'panel':
    T, MAIN, CAND, OUT = int(sys.argv[2]), sys.argv[3], sys.argv[4], sys.argv[5]
    flags = sys.argv[6:]
    for f in sorted(glob.glob(f'data/matrices/tier{T}/*_Hx.txt'), key=lambda p: -int(os.path.basename(p).split('_')[1])):
        stem = os.path.basename(f)[:-7]
        for mode in modes:
            for s in range(5):
                for arm, b, extra in (('main', MAIN, []), ('cand', CAND, flags)):
                    js.append(dict(id=f't{T}.{stem}.{mode[1:]}.{arm}.s{s}', bin=b, args=[mode, f'-seed={s}', '-frontier-stats'] + extra,
                                   code=f'data/matrices/tier{T}/{stem}', stem=stem, tier=T, arm=arm, seed=s, mode=mode[1:],
                                   limit=5000 if T == 4 else 1800))
else:
    ARM, BIN, OUT = sys.argv[2], sys.argv[3], sys.argv[4]
    flags = sys.argv[5:]
    for f in sorted(glob.glob('data/matrices/tier5/*_Hx.txt'), key=lambda p: -int(os.path.basename(p).split('_')[1])):
        stem = os.path.basename(f)[:-7]
        for mode in modes:
            js.append(dict(id=f't5.{stem}.{mode[1:]}.{ARM}', bin=BIN, args=[mode, '-frontier-stats'] + flags, code=f'data/matrices/tier5/{stem}',
                           stem=stem, tier=5, arm=ARM, seed=0, mode=mode[1:], limit=21600))
with open(OUT, 'w') as fh:
    for j in js: fh.write(json.dumps(j) + '\n')
print(OUT, len(js))
