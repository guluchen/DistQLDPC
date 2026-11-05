#!/usr/bin/env python3
"""GH-231 job files (MaxSAT engine; run from a worktree root on yfclab2). Arms:
  M   = frozen main (its defaults) = the baseline of this round;
  O   = the GH-231 candidate binary with its defaults (-native-lb off: must behave as main);
  C   = candidate, -native-lb=charge;            CP = candidate, -native-lb=charge -native-lb-prop=on;
  P   = candidate, -native-lb=pack;              PP = candidate, -native-lb=pack -native-lb-prop=on;
  CPg = candidate, -native-lb=charge -native-lb-prop=on -native-lb-gap=-1;
  CPS / PPS / CS = CP / PP / C with -native-lb-sparse=on (GH-181's redundant pair-sum rows added to the bound's rows).
Every run is -MODE (-no-card | -card-mto) -seed=S.
  panel OUT M_BIN C_BIN ARMS SEEDS MODES LIMIT STEM...: seeds 0..SEEDS-1, the arms of each (code, mode, seed) adjacent.
  tier5 OUT M_BIN C_BIN ARMS MODES LIMIT STEM...: default seed (-seed=0).
  answers OUT M_BIN C_BIN STEM...: Tier 0 answer checks of the candidate with -native-lb in both modes (tier0/1: ten variants,
       tier2/3: four), limit 2400 s; the runner checks every answer and bound against the stem.
"""
import glob, json, os, sys
kind, out, MBIN, CBIN = sys.argv[1:5]
ARMS = {'M': (None, []), 'O': ('C', []), 'C': ('C', ['-native-lb=charge']), 'CP': ('C', ['-native-lb=charge', '-native-lb-prop=on']),
        'P': ('C', ['-native-lb=pack']), 'PP': ('C', ['-native-lb=pack', '-native-lb-prop=on']),
        'CPg': ('C', ['-native-lb=charge', '-native-lb-prop=on', '-native-lb-gap=-1']),
        'CPS': ('C', ['-native-lb=charge', '-native-lb-prop=on', '-native-lb-sparse=on']),
        'PPS': ('C', ['-native-lb=pack', '-native-lb-prop=on', '-native-lb-sparse=on']),
        'CS': ('C', ['-native-lb=charge', '-native-lb-sparse=on'])}


def arm(name):
    b, extra = ARMS[name]
    return (MBIN if b is None else CBIN), list(extra)


def code_of(stem):
    f = glob.glob(f'data/matrices/*/{stem}_Hx.txt')
    assert len(f) == 1, (stem, f)
    return f[0][:-7], os.path.basename(os.path.dirname(f[0]))


jobs = []
if kind == 'panel':
    arms, seeds, modes, limit = sys.argv[5].split(','), int(sys.argv[6]), sys.argv[7].split(','), int(sys.argv[8])
    for stem in sys.argv[9:]:
        code, tier = code_of(stem)
        for mode in modes:
            for seed in range(seeds):
                for a in arms:
                    b, extra = arm(a)
                    jobs.append(dict(id=f'mx.{stem}.{mode}.{a}.s{seed}', bin=b, args=[f'-{mode}', f'-seed={seed}'] + extra,
                                     code=code, stem=stem, tier=tier, arm=a, seed=seed, mode=mode, limit=limit))
elif kind == 'tier5':
    arms, modes, limit = sys.argv[5].split(','), sys.argv[6].split(','), int(sys.argv[7])
    for stem in sys.argv[8:]:
        code, tier = code_of(stem)
        for mode in modes:
            for a in arms:
                b, extra = arm(a)
                jobs.append(dict(id=f't5.{stem}.{mode}.{a}', bin=b, args=[f'-{mode}'] + extra, code=code, stem=stem, tier=tier,
                                 arm=a, seed=0, mode=mode, limit=limit))
elif kind == 'answers':
    NL = ['-native-lb=charge', '-native-lb-prop=on']
    V_ALL = [('CP', NL), ('CPS-seed1', NL + ['-native-lb-sparse=on', '-seed=1']), ('CP-nosym-dualoff-seed2', NL + ['-no-symbreak', '-dualmode=off', '-seed=2']),
             ('PP-nopre-noovl-seed3', ['-native-lb=pack', '-native-lb-prop=on', '-ub-pre=off', '-stab-overlap=off', '-seed=3']),
             ('C-seed4', ['-native-lb=charge', '-seed=4']), ('CPg-oddoff', NL + ['-native-lb-gap=-1', '-oddcap-skip=off']),
             ('CP-dualskip-minr3', NL + ['-dualmode=skip', '-native-lb-minr=3']), ('P-frontier-off', ['-native-lb=pack', '-frontier=off']),
             ('CPS-ovlon-seed5', NL + ['-native-lb-sparse=on', '-stab-overlap=on', '-seed=5']), ('CP-isdoff-check', NL + ['-ub-isd=off', '-native-lb-check'])]
    for stem in sys.argv[5:]:
        code, tier = code_of(stem)
        vs = V_ALL if tier in ('tier0', 'tier1') else V_ALL[:4]
        for mode in ('no-card', 'card-mto'):
            for name, extra in vs:
                jobs.append(dict(id=f'ans.{stem}.{mode}.{name}', bin=CBIN, args=[f'-{mode}'] + extra, code=code, stem=stem, tier=tier,
                                 arm=name, seed=0, mode=mode, limit=2400))
with open(out, 'w') as fh:
    for j in jobs: fh.write(json.dumps(j) + '\n')
print(len(jobs), 'jobs ->', out)
