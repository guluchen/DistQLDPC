#!/usr/bin/env python3
"""Per run: are all levels below the final lb EMPTY? Reports the halves searched, levels with no record (parity-skipped candidates) and any non-EMPTY status.
usage: verify_lb.py RESULTS.jsonl..."""
import json, re, sys
for p in sys.argv[1:]:
    for l in open(p):
        if not l.strip(): continue
        r = json.loads(l); lb = r.get('final_lb')
        if lb is None: print(r['id'], 'no final lb'); continue
        st = {}
        for x in r['levels']:
            m = re.match(r'([XZ]) level (\d+) ([A-Z]+) nodes (\d+)', x)
            if m: st[(m.group(1), int(m.group(2)))] = (m.group(3), int(m.group(4)))
        halves = sorted({h for h, _ in st})
        bad = {k: v[0] for k, v in st.items() if v[0] != 'EMPTY'}
        miss = {h: [L for L in range(1, lb) if (h, L) not in st] for h in halves}
        last = {h: st.get((h, lb - 1)) or st.get((h, lb - 2)) for h in halves}
        print(f"{r['id']:44s} lb {lb} o {r['result'][1] if r['result'] else '-'} halves {''.join(halves)} non-EMPTY {bad or '-'} missing<lb {miss} last {last}")
