#!/usr/bin/env python3
"""Retest Tier0 trace identity: frozen 72d1fe1 baseline vs each candidate, -v traces.

Cases: 5 stems x {no-card, card-mto}. Baseline runs twice (determinism check).
Completed runs (no TIMEOUT): stdout, stderr and exit status byte-identical to baseline rep 1.
Timed-out runs: corrected GH-34 rule (child part before last 'c DistQLDPC' header,
minus last line, is a prefix). All runs pinned to NUMA node 0 by the caller's taskset.
"""
import concurrent.futures as cf, hashlib, json, subprocess, sys, time
from pathlib import Path
HOME = Path.home() / 'mac-agent-20261009'
BASE = HOME / 'frozen/tier3/base/distqldpc'
CWD = HOME / 'base72'
STEMS = ['BB_90_8_10', 'GB_144_12_8', 'BB_108_8_10', 'LP_238_44_6', 'LP_34_20_2']
MODES = ['no-card', 'card-mto']
LIMIT = int(sys.argv[2]) if len(sys.argv) > 2 else 120
CANDS = ['gh34-litvals', 'gh21-o2', 'gh48-isa-v2', 'gh20-watch-tail', 'gh64-prefetch', 'h007-lto', 'gh16-pgo']
OUT = Path(sys.argv[1])
sha = lambda b: hashlib.sha256(b).hexdigest()

def run(tag, binary, stem, mode):
    cmd = [str(binary), '-v', f'-cpu-lim={LIMIT}', '-' + mode, stem]
    t = time.time(); p = subprocess.run(cmd, capture_output=True, cwd=CWD, timeout=LIMIT + 60); w = time.time() - t
    d = OUT / 'logs' / tag; d.mkdir(parents=True, exist_ok=True)
    (d / f'{stem}.{mode}.out').write_bytes(p.stdout); (d / f'{stem}.{mode}.err').write_bytes(p.stderr)
    return {'tag': tag, 'stem': stem, 'mode': mode, 'rc': p.returncode, 'wall': round(w, 2), 'out': p.stdout, 'err': p.stderr,
            'timeout': b'TIMEOUT' in p.stdout}

def split(b):
    i = b.rfind(b'c DistQLDPC'); return (b, b'') if i <= 0 else (b[:i], b[i:])
def strip_last(b):
    i = b.rstrip(b'\n').rfind(b'\n'); return b[:i + 1] if i >= 0 else b''

def judge(b, c):
    if not b['timeout'] and not c['timeout']:
        ok = b['out'] == c['out'] and b['err'] == c['err'] and b['rc'] == c['rc']
        return 'identical' if ok else 'MISMATCH'
    (cb, tb), (cc, tc) = split(b['out']), split(c['out'])
    x, y = sorted([cb, cc], key=len)
    return 'timeout-child-prefix-ok' if y.startswith(strip_last(x)) else 'TIMEOUT-CHILD-MISMATCH'

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    bins = {'base1': BASE, 'base2': BASE}
    bins.update({n: HOME / 'retest' / n / 'bin/distqldpc' for n in CANDS})
    meta = {'host': 'yfclab2 (Linux, GCC 13.3), taskset -c 0-63,128-191, 4 concurrent runs', 'limit': LIMIT, 'cwd': str(CWD),
            'sha256': {k: sha(v.read_bytes()) for k, v in bins.items()}, 'started': time.strftime('%Y-%m-%dT%H:%M:%S%z')}
    res = {}
    with cf.ThreadPoolExecutor(4) as ex:
        futs = [ex.submit(run, tag, b, s, m) for tag, b in bins.items() for s in STEMS for m in MODES]
        for f in cf.as_completed(futs):
            r = f.result(); res[(r['tag'], r['stem'], r['mode'])] = r
            print(r['tag'], r['stem'], r['mode'], r['rc'], r['wall'], 'TIMEOUT' if r['timeout'] else 'done', flush=True)
    rows = []
    for tag in ['base2'] + CANDS:
        for s in STEMS:
            for m in MODES:
                b, c = res[('base1', s, m)], res[(tag, s, m)]
                last = [l for l in c['out'].decode(errors='replace').splitlines() if l.startswith(('o ', 's '))]
                rows.append({'cand': tag, 'stem': s, 'mode': m, 'kind': judge(b, c), 'rc': [b['rc'], c['rc']],
                             'wall': [b['wall'], c['wall']], 'result': last[-1] if last else None,
                             'sha_out': [sha(b['out']), sha(c['out'])], 'bytes': [len(b['out']), len(c['out'])]})
    summ = {}
    for r in rows: summ.setdefault(r['cand'], {}).setdefault(r['kind'], 0); summ[r['cand']][r['kind']] += 1
    meta['finished'] = time.strftime('%Y-%m-%dT%H:%M:%S%z'); meta['summary'] = summ
    json.dump({'meta': meta, 'results': rows}, open(OUT / 'trace_identity.json', 'w'), indent=1)
    print(json.dumps(summ, indent=1))

if __name__ == '__main__':
    main()
