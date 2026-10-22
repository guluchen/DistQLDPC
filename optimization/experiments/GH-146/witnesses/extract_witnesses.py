#!/usr/bin/env python3
"""GH-146: collect the lightest verified finder witness per open code from run logs (-v: 'c witness X (ub-search): ...'
or 'c witness X (ub-pre): ...' lines) and CC traces ('X W UB-SEARCH iter seconds support'), and write one file per
code: <stem>.<half>.w<W>.txt (comment header with the source, then the support). Only codes whose stem has no numeric
distance are written. usage: extract_witnesses.py OUTDIR SOURCE... where SOURCE = LOGDIR (all *.log) or TRACEDIR (all *.trace)"""
import glob, os, re, sys
out = sys.argv[1]
best = {}   # stem -> (w, src, half, support)
def stem_of_log(path):
    first = open(path).readline()
    m = re.search(r'data/matrices/tier\d/(\S+)$', first.strip())
    return m.group(1) if m else None
def offer(stem, w, half, sup, src):
    if stem is None or stem.split('_')[3].isdigit(): return
    if len(sup) != w: raise SystemExit(f'{src}: weight {w} but {len(sup)} qubits')
    if stem not in best or w < best[stem][0]: best[stem] = (w, src, half, sup)
for srcdir in sys.argv[2:]:
    for f in sorted(glob.glob(os.path.join(srcdir, '*.log'))):
        stem = stem_of_log(f)
        for line in open(f):
            m = re.match(r'\s*([0-9.]+)\tc witness ([XZ]) \((ub-search|ub-pre)\): ([0-9 ]+)$', line)
            if m:
                sup = [int(x) for x in m.group(4).split()]
                offer(stem, len(sup), m.group(2), sup, f'{os.path.basename(f)} at {m.group(1)} s ({m.group(3)})')
    for f in sorted(glob.glob(os.path.join(srcdir, '*.trace'))):
        stem = os.path.basename(f)[:-6]
        for line in open(f):
            t = line.split()
            if len(t) > 5 and t[2] == 'UB-SEARCH':
                sup = [int(x) for x in t[5:]]
                offer(stem, int(t[1]), t[0], sup, f'{os.path.basename(f)} iteration {t[3]} at {float(t[4]):.1f} s')
os.makedirs(out, exist_ok=True)
for stem, (w, src, half, sup) in sorted(best.items()):
    for old in glob.glob(os.path.join(out, f'{stem}.*.w*.txt')): os.remove(old)
    with open(os.path.join(out, f'{stem}.{half}.w{w}.txt'), 'w') as fh:
        fh.write(f'# {stem}: {half}-type logical operator of weight {w} (0-based qubit indices), so d <= {w}\n')
        fh.write(f'# found by the DistQLDPC finder (GH-146 S0/S1, binary 4f16e0d): {src}\n')
        fh.write(' '.join(map(str, sorted(sup))) + '\n')
    print(f'{stem}: {half} weight {w} ({src})')
