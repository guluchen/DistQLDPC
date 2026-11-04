#!/usr/bin/env python3
"""GH-224 judgement of an interleave.py panel. Cell = (tier, mode, stem); per seed the median over the repetitions, then
the median over the seeds; ratio = cell(arm) / cell(ref). Per tier x mode: geomean, worst cell, cells > 1.25
(pass = geomean < 1 and no cell > 1.25). Also: answers vs the stem, stdout identity (ref vs arm, per unit), and the
wait slack (wall - user - sys of the process tree) of fast runs, which shows the 10 ms polling floor.
usage: analyze.py REF ARM results.jsonl [--slack-max 0.2]"""
import collections, json, math, statistics as st, sys
REF, ARM, path = sys.argv[1], sys.argv[2], sys.argv[3]
SLACK_MAX = float(sys.argv[5]) if len(sys.argv) > 5 else 0.2
R = [json.loads(l) for l in open(path)]
g = lambda v: math.exp(sum(map(math.log, v)) / len(v))
U = collections.defaultdict(lambda: collections.defaultdict(list))   # (tier, mode, stem, seed) -> arm -> runs
for r in R: U[(r['tier'], r['mode'], r['stem'], r['seed'])][r['arm']].append(r)


def stem_d(stem):
    f = stem.split('_')[3]
    return int(f) if f.isdigit() else None


bad_ans = [(r['stem'], r['mode'], r['seed'], r['arm'], r['o'], r['rc']) for r in R
           if r['rc'] != 0 or r['o'] is None or (stem_d(r['stem']) is not None and int(r['o'].split()[1]) != stem_d(r['stem']))]
C = collections.defaultdict(dict)
for (tier, mode, stem, seed), d in U.items():
    if REF in d and ARM in d:
        C[(tier, mode, stem)][seed] = {a: (st.median(x['wall'] for x in d[a]), st.median(x['utime'] + x['stime'] for x in d[a]))
                                        for a in (REF, ARM)}
print(f'## Cells ({ARM} vs {REF}; median over reps, then over seeds; wall in s)\n')
print(f'| Tier | Mode | Code | seeds | {REF} wall | {ARM} wall | wall ratio | cpu ratio |')
print('|---|---|---|---:|---:|---:|---:|---:|')
per = collections.defaultdict(list)
for (tier, mode, stem), d in sorted(C.items()):
    w0 = st.median(v[REF][0] for v in d.values()); w1 = st.median(v[ARM][0] for v in d.values())
    c0 = st.median(v[REF][1] for v in d.values()); c1 = st.median(v[ARM][1] for v in d.values())
    per[(tier, mode)].append((w1 / w0, stem))
    print(f'| {tier} | {mode} | {stem} | {len(d)} | {w0:.4f} | {w1:.4f} | {w1 / w0:.3f} | {c1 / max(c0, 1e-9):.3f} |')
print(f'\n## Verdict per tier and mode\n')
print('| Tier | Mode | cells | geomean | worst cell | cells > 1.25 | verdict |')
print('|---|---|---:|---:|---|---:|---|')
for (tier, mode), v in sorted(per.items()):
    rs = [x for x, _ in v]; mx = max(v)
    print(f'| {tier} | {mode} | {len(v)} | {g(rs):.3f} | {mx[0]:.3f} ({mx[1]}) | {sum(x > 1.25 for x in rs)} | '
          f'{"PASS" if g(rs) < 1 and mx[0] <= 1.25 else "FAIL"} |')
for tier in sorted({t for t, _ in per}):
    rs = [x for (t, _), v in per.items() if t == tier for x, _ in v]
    print(f'| {tier} | all | {len(rs)} | {g(rs):.3f} | {max(rs):.3f} | {sum(x > 1.25 for x in rs)} | '
          f'{"PASS" if g(rs) < 1 and max(rs) <= 1.25 else "FAIL"} |')
# stdout identity per unit
same = differ = 0; nondet_ref = 0; diff_units = []
for k, d in U.items():
    if REF not in d or ARM not in d: continue
    s0 = {x['stdout'] for x in d[REF]}; s1 = {x['stdout'] for x in d[ARM]}
    if len(s0) > 1: nondet_ref += 1
    if s0 == s1 and len(s0) == 1: same += 1
    else: differ += 1; diff_units.append((k, len(s0), len(s1), s0 == s1))
ms_same = sum(1 for k, n0, n1, eq in diff_units
              if len({tuple(sorted(x['stdout'].splitlines())) for a in (REF, ARM) for x in U[k][a]}) == 1)
print(f'\n## Logs\n\nunits with byte-identical stdout in every run of both arms: {same}; other units: {differ} '
      f'(of which {REF} itself varies across reps: {nondet_ref}; identical up to line order in every run: {ms_same})')
for k, n0, n1, eq in sorted(diff_units)[:40]:
    print(f'- {k}: distinct stdouts {REF} {n0}, {ARM} {n1}, same set: {eq}')
print(f'\n## Answers\n\nruns: {len(R)}; rc != 0 or answer != stem: {len(bad_ans)} {bad_ans[:10]}')
# slack of fast runs
print(f'\n## Wait slack (wall - user - sys) of runs with wall < {SLACK_MAX} s, in ms\n')
print('| Arm | runs | median | p90 | max |')
print('|---|---:|---:|---:|---:|')
for a in (REF, ARM):
    s = sorted(1000 * (r['wall'] - r['utime'] - r['stime']) for r in R if r['arm'] == a and r['wall'] < SLACK_MAX)
    if s: print(f'| {a} | {len(s)} | {st.median(s):.2f} | {s[int(0.9 * (len(s) - 1))]:.2f} | {s[-1]:.2f} |')
