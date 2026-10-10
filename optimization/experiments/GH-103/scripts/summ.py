#!/usr/bin/env python3
"""summ.py PREFIX... : per-run user CPU and grouped self-sample shares (leaf attribution)."""
import sys, re, subprocess, collections, os
LEAF = os.path.join(os.path.dirname(__file__), 'leaf.py')
G = [('PLK', ['propagateForLK']), ('ENQ', ['uncheckedEnqueueForLK', 'falsifiedSoftVarForLK']),
     ('LBRT', ['lookbackResetTrail']), ('PICK', ['pickAuxiVar', 'removeMin']), ('LKAH', ['Solver::lookahead()']),
     ('HEAP', ['VarOrderGt>::insert', 'KeyedActivityHeap::insert', 'insertAuxiVarOrder', 'KeyedActivityHeap', 'VarOrderGt>']),
     ('MISC', ['bumpConflVars', 'resetConflicts', 'setConflict', 'seeUnlockLits'])]
def selfcounts(f):
    import importlib.util
    out = subprocess.run([sys.executable, '-B', LEAF, f], capture_output=True, text=True).stdout
    c = collections.Counter(); tot = 0
    # rerun leaf with full listing
    return out
print('%-34s %7s %7s | %s' % ('run', 'user', 'real', ' '.join('%6s' % g for g, _ in G) + '   REST  book/REST  LKall/REST'))
for pre in sys.argv[1:]:
    log = open(pre + '.v.log', errors='replace').read()
    u = re.findall(r'^user ([0-9.]+)', log, re.M); r = re.findall(r'^real ([0-9.]+)', log, re.M)
    # full self counts
    txt = subprocess.run([sys.executable, '-B', LEAF, pre + '.sample.txt', 'ZZZNOPE'], capture_output=True, text=True).stdout
    cnt = collections.Counter()
    exec(open(LEAF).read().split("tot = sum")[0].replace("sys.argv[1]", repr(pre + '.sample.txt')), g := {})
    selff = g['selff']; tot = sum(selff.values())
    gs = collections.Counter(); rest = 0
    for fn, c in selff.items():
        for name, pats in G:
            if any(p in fn for p in pats): gs[name] += c; break
        else: rest += c
    book = sum(gs[n] for n, _ in G if n != 'PLK')
    print('%-34s %7s %7s | %s %6.1f  %8.3f  %9.3f' % (os.path.basename(pre), u[-1] if u else '-', r[-1] if r else '-',
          ' '.join('%6.1f' % (100.0 * gs[n] / tot) for n, _ in G), 100.0 * rest / tot, book / rest, (book + gs['PLK']) / rest))
