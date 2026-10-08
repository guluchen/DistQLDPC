#!/usr/bin/env python3
"""GH-litvals Tier0: baseline vs candidate verbose search-trace identity.

For every case stem in data/matrices and each mode, run both binaries with -v and a
wall limit. Completed runs must have byte-identical stdout+stderr and exit status.
If either run hit the limit, the shorter log (minus its last, possibly partial
line) must be a prefix of the longer one. Any violation is a scientific STOP.
"""
import argparse, concurrent.futures as cf, hashlib, json, os, subprocess, sys, time
from pathlib import Path

MODES = ['default', 'no-card', 'card-mto', 'card-sinz']

def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()

def run(binary, stem, mode, limit, outdir, tag):
    cmd = [binary, '-v', f'-cpu-lim={limit}'] + ([] if mode == 'default' else ['-' + mode]) + [stem]
    t = time.time()
    p = subprocess.run(cmd, capture_output=True, timeout=limit + 30)
    wall = time.time() - t
    base = outdir / f'{stem}.{mode}.{tag}'
    base.with_suffix(base.suffix + '.out').write_bytes(p.stdout)
    base.with_suffix(base.suffix + '.err').write_bytes(p.stderr)
    return {'cmd': cmd, 'rc': p.returncode, 'wall': round(wall, 3), 'out': p.stdout, 'err': p.stderr}

def timed_out(r):
    return b'UNKNOWN' in r['out'] or b'TIMEOUT' in r['out'] or b'timeout' in r['out'].lower()

def strip_last(b):
    i = b.rstrip(b'\n').rfind(b'\n')
    return b[:i + 1] if i >= 0 else b''

def compare(stem, mode, limit, a, outdir):
    rb = run(a.base, stem, mode, limit, outdir, 'base')
    rc = run(a.cand, stem, mode, limit, outdir, 'cand')
    ob, oc = rb['out'] + b'\n#ERR\n' + rb['err'], rc['out'] + b'\n#ERR\n' + rc['err']
    to = timed_out(rb) or timed_out(rc)
    if not to:
        ok = (ob == oc and rb['rc'] == rc['rc'])
        kind = 'identical' if ok else 'MISMATCH'
    else:
        x, y = sorted([rb['out'], rc['out']], key=len)
        ok = y.startswith(strip_last(x))
        kind = 'timeout-prefix-ok' if ok else 'TIMEOUT-PREFIX-MISMATCH'
    last = [l for l in rb['out'].decode(errors='replace').splitlines() if l.startswith('o ') or l.startswith('s ')]
    return {'stem': stem, 'mode': mode, 'kind': kind, 'ok': ok, 'rc': [rb['rc'], rc['rc']],
            'wall': [rb['wall'], rc['wall']], 'result_line': last[-1] if last else None,
            'bytes': [len(rb['out']), len(rc['out'])],
            'sha_out': [hashlib.sha256(rb['out']).hexdigest(), hashlib.sha256(rc['out']).hexdigest()]}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--base', required=True); ap.add_argument('--cand', required=True)
    ap.add_argument('--out', required=True); ap.add_argument('--limit', type=int, default=20)
    ap.add_argument('--jobs', type=int, default=4); ap.add_argument('--stems', nargs='*')
    a = ap.parse_args()
    a.base, a.cand = os.path.abspath(a.base), os.path.abspath(a.cand)
    outdir = Path(a.out); (outdir / 'logs').mkdir(parents=True, exist_ok=True)
    stems = a.stems or sorted({f.name.rsplit('_', 1)[0] for f in Path('data/matrices').glob('*_Hx.txt')})
    meta = {'base': a.base, 'cand': a.cand, 'base_sha256': sha(a.base), 'cand_sha256': sha(a.cand),
            'limit': a.limit, 'jobs': a.jobs, 'modes': MODES, 'stems': stems,
            'started': time.strftime('%Y-%m-%dT%H:%M:%S%z')}
    res = []
    with cf.ThreadPoolExecutor(a.jobs) as ex:
        futs = [ex.submit(compare, s, m, a.limit, a, outdir / 'logs') for s in stems for m in MODES]
        for f in cf.as_completed(futs):
            r = f.result(); res.append(r)
            print(r['kind'], r['stem'], r['mode'], r['result_line'], r['wall'], flush=True)
    res.sort(key=lambda r: (r['stem'], r['mode']))
    meta['finished'] = time.strftime('%Y-%m-%dT%H:%M:%S%z')
    meta['summary'] = {k: sum(1 for r in res if r['kind'] == k) for k in sorted({r['kind'] for r in res})}
    meta['all_ok'] = all(r['ok'] for r in res)
    json.dump({'meta': meta, 'results': res}, open(outdir / 'trace_identity.json', 'w'), indent=1)
    print(json.dumps(meta['summary']), 'ALL_OK' if meta['all_ok'] else 'STOP: MISMATCH')
    return 0 if meta['all_ok'] else 2

if __name__ == '__main__':
    sys.exit(main())
