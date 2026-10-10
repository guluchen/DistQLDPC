#!/usr/bin/env python3
"""fntab.py RUNPREFIX... : absolute self samples for the lookahead functions (leaf attribution) + user CPU."""
import sys, re, os, collections
F = [('propagateForLK', 'propagateForLK()'), ('uncheckedEnqueueForLK', 'uncheckedEnqueueForLK('), ('falsifiedSoftVarForLK', 'falsifiedSoftVarForLK('),
     ('lookbackResetTrail', 'lookbackResetTrail('), ('pickAuxiVar', 'pickAuxiVar()'), ('lookahead', 'Solver::lookahead()'),
     ('heap insert', 'VarOrderGt>::insert'), ('bumpConflVars', 'bumpConflVars()'), ('resetConflicts', 'resetConflicts(int)')]
LEAF = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'leaf.py')
src = open(LEAF).read().split("tot = sum")[0]
print('| run | user s | samples | ' + ' | '.join(n for n, _ in F) + ' |')
print('|---|---:|---:|' + '---:|' * len(F))
for pre in sys.argv[1:]:
    g = {}; exec(src.replace("sys.argv[1]", repr(pre + '.sample.txt')), g); selff = g['selff']
    u = re.findall(r'^user ([0-9.]+)', open(pre + '.v.log', errors='replace').read(), re.M)
    row = []
    for n, pat in F:
        pats = [pat] + (['KeyedActivityHeap::insert'] if n == 'heap insert' else [])
        row.append(sum(c for fn, c in selff.items() if any(p in fn for p in pats)))
    print('| %s | %s | %d | %s |' % (os.path.basename(pre), u[-1] if u else '-', sum(selff.values()), ' | '.join(str(x) for x in row)))
