#!/usr/bin/env python3
"""Re-judge saved Tier0 trace logs with a corrected timeout comparator (no re-run).

Defect in tier0_trace_identity.py (retained unchanged): for timed-out runs it
required the shorter whole log minus one line to prefix the longer one. But in
-v mode the parent appends a multi-line trailer (header reprint, d_lb/d_ub,
status) after killing the child, so two runs killed at different search points
always failed even with identical search. Corrected rule, applied to the
same raw logs:
  * completed runs (no TIMEOUT): whole stdout byte-identical (unchanged rule);
  * timed-out runs: split at the parent trailer (last occurrence of the header
    line 'c DistQLDPC'); the shorter child part minus its last, possibly
    partial, line must prefix the longer child part; both trailers must
    contain the TIMEOUT status and 's UNKNOWN'; reported d_lb/d_ub must not
    exceed the expected distance (for d_lb) / undercut it (for d_ub) when the
    distance is known from the code name.
"""
import json, re, sys
from pathlib import Path

def split(b):
    i = b.rfind(b'c DistQLDPC')
    return (b, b'') if i <= 0 else (b[:i], b[i:])

def strip_last(b):
    i = b.rstrip(b'\n').rfind(b'\n')
    return b[:i + 1] if i >= 0 else b''

def bounds(trailer):
    t = trailer.decode(errors='replace')
    lb = re.search(r'^c d_lb: (\d+)', t, re.M); ub = re.search(r'^c d_ub: (\d+)', t, re.M)
    return (int(lb.group(1)) if lb else None, int(ub.group(1)) if ub else None)

def main(raw):
    raw = Path(raw); data = json.load(open(raw / 'trace_identity.json')); out = []
    for r in data['results']:
        s, m = r['stem'], r['mode']
        b = (raw / 'logs' / f'{s}.{m}.base.out').read_bytes()
        c = (raw / 'logs' / f'{s}.{m}.cand.out').read_bytes()
        d = s.split('_')[-1]; exp = int(d) if d.isdigit() else None
        if r['kind'] == 'identical':
            ok, kind, info = b == c, 'identical' if b == c else 'MISMATCH', None
        else:
            (cb, tb), (cc, tc) = split(b), split(c)
            x, y = sorted([cb, cc], key=len)
            pref = y.startswith(strip_last(x))
            st = all(b'TIMEOUT' in t and b's UNKNOWN' in t for t in (tb, tc))
            bb, bc = bounds(tb), bounds(tc)
            sound = True
            if exp is not None:
                for lb, ub in (bb, bc):
                    if lb is not None and lb > exp: sound = False
                    if ub is not None and ub < exp: sound = False
            ok = pref and st and sound
            kind = 'timeout-child-prefix-ok' if ok else 'TIMEOUT-CHILD-MISMATCH'
            info = {'child_bytes': [len(cb), len(cc)], 'bounds_base': bb, 'bounds_cand': bc,
                    'prefix': pref, 'status_ok': st, 'bounds_sound_vs_name': sound}
        out.append({'stem': s, 'mode': m, 'original_kind': r['kind'], 'rejudged_kind': kind, 'ok': ok, 'info': info})
    summ = {}
    for o in out: summ[o['rejudged_kind']] = summ.get(o['rejudged_kind'], 0) + 1
    res = {'source': str(raw / 'trace_identity.json'), 'summary': summ, 'all_ok': all(o['ok'] for o in out),
           'original_summary': data['meta']['summary'], 'results': out}
    json.dump(res, open(raw / 'rejudged.json', 'w'), indent=1)
    print(json.dumps({k: res[k] for k in ('summary', 'original_summary', 'all_ok')}))
    for o in out:
        if o['original_kind'] != o['rejudged_kind'] or not o['ok']: print(o)
    return 0 if res['all_ok'] else 2

if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
