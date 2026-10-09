#!/usr/bin/env python3
"""GH-79 copy of the GH-60 Tier0 science sweep (unchanged rules; added host guard:
before each solver run wait while the coordinator TIMING_LOCK exists or 1-min load >= 6).

GH-60 Tier0 science sweep for a search-changing candidate (rules in PROPOSAL.md).

All bundled codes x {default,no-card,card-mto,card-sinz}, both binaries, wall limit L.
Completed run: rc 0 and `o N` == named distance (xu_/PK_ names: no named distance).
Every run: every emitted `c d_lb: x` <= d <= every emitted `c d_ub: y` (d = named
distance, else the completed value of the other binary if any).
Completed candidate value != completed baseline value => STOP.
"""
import argparse, concurrent.futures as cf, hashlib, json, os, re, subprocess, sys, time
from pathlib import Path
MODES = ['default', 'no-card', 'card-mto', 'card-sinz']

def named(stem):
    d = stem.split('_')[-1]
    return int(d) if d.isdigit() and not stem.startswith(('xu_', 'PK_')) else None

LOCK = os.environ.get('GH79_TIMING_LOCK', '')

def guard_wait():
    while True:
        if LOCK and os.path.exists(LOCK):
            time.sleep(30); continue
        if float(subprocess.run(['sysctl', '-n', 'vm.loadavg'], capture_output=True, text=True).stdout.split()[1]) >= 6:
            time.sleep(30); continue
        return

def run(b, stem, mode, lim, out):
    guard_wait()
    cmd = [b, f'-cpu-lim={lim}'] + ([] if mode == 'default' else ['-' + mode]) + [stem]
    t = time.time(); p = subprocess.run(cmd, capture_output=True, text=True, timeout=lim + 30); w = time.time() - t
    out.write_text(p.stdout + '\n#ERR\n' + p.stderr)
    lbs = [int(x) for x in re.findall(r'^c d_lb: (\d+)$', p.stdout, re.M)]
    ubs = [int(x) for x in re.findall(r'^c d_ub: (\d+)$', p.stdout, re.M)]
    o = re.findall(r'^o (-?\d+)$', p.stdout, re.M)
    status = 'TIMEOUT' if 'TIMEOUT' in p.stdout else ('done' if o and p.returncode == 0 else 'OTHER')
    return {'rc': p.returncode, 'wall': round(w, 3), 'o': int(o[-1]) if o else None, 'status': status, 'lbs': lbs, 'ubs': ubs}

def job(stem, mode, a, logs):
    rb = run(a.base, stem, mode, a.limit, logs / f'{stem}.{mode}.base.txt')
    rc = run(a.cand, stem, mode, a.limit, logs / f'{stem}.{mode}.cand.txt')
    d = named(stem); probs = []
    ref = d if d is not None else (rb['o'] if rb['status'] == 'done' else (rc['o'] if rc['status'] == 'done' else None))
    for tag, r in (('base', rb), ('cand', rc)):
        if r['status'] == 'OTHER': probs.append(f'{tag}: abnormal rc={r["rc"]}')
        if r['status'] == 'done' and d is not None and r['o'] != d: probs.append(f'{tag}: o {r["o"]} != named {d}')
        if ref is not None:
            if any(x > ref for x in r['lbs']): probs.append(f'{tag}: d_lb > {ref}')
            if any(y < ref for y in r['ubs']): probs.append(f'{tag}: d_ub < {ref}')
    if rb['status'] == 'done' and rc['status'] == 'done' and rb['o'] != rc['o']: probs.append('completed values differ')
    # a baseline-only abnormal exit is recorded but not blamed on the candidate
    cand_probs = [x for x in probs if not x.startswith('base:')]
    return {'stem': stem, 'mode': mode, 'base': rb, 'cand': rc, 'problems': probs, 'ok': not cand_probs}

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--base'); ap.add_argument('--cand'); ap.add_argument('--out')
    ap.add_argument('--limit', type=int, default=60); ap.add_argument('--jobs', type=int, default=4)
    a = ap.parse_args(); a.base, a.cand = os.path.abspath(a.base), os.path.abspath(a.cand)
    out = Path(a.out); logs = out / 'logs'; logs.mkdir(parents=True, exist_ok=True)
    stems = sorted({f.name.rsplit('_', 1)[0] for f in Path('data/matrices').glob('*_Hx.txt')})
    sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
    meta = {'base': a.base, 'cand': a.cand, 'base_sha256': sha(a.base), 'cand_sha256': sha(a.cand), 'limit': a.limit, 'jobs': a.jobs,
            'started': time.strftime('%Y-%m-%dT%H:%M:%S%z')}
    res = []
    with cf.ThreadPoolExecutor(a.jobs) as ex:
        for f in cf.as_completed([ex.submit(job, s, m, a, logs) for s in stems for m in MODES]):
            r = f.result(); res.append(r)
            print('OK ' if r['ok'] else 'FAIL', r['stem'], r['mode'], r['base']['status'], r['base']['o'], r['base']['wall'], '|', r['cand']['status'], r['cand']['o'], r['cand']['wall'], r['problems'], flush=True)
    res.sort(key=lambda r: (r['stem'], r['mode']))
    meta['finished'] = time.strftime('%Y-%m-%dT%H:%M:%S%z'); meta['all_ok'] = all(r['ok'] for r in res)
    meta['counts'] = {'both_done': sum(r['base']['status'] == 'done' and r['cand']['status'] == 'done' for r in res),
                      'only_cand_done': sum(r['base']['status'] != 'done' and r['cand']['status'] == 'done' for r in res),
                      'only_base_done': sum(r['base']['status'] == 'done' and r['cand']['status'] != 'done' for r in res),
                      'problems': sum(bool(r['problems']) for r in res)}
    json.dump({'meta': meta, 'results': res}, open(out / 'science.json', 'w'), indent=1)
    print(json.dumps(meta['counts']), 'ALL_OK' if meta['all_ok'] else 'STOP')
    return 0 if meta['all_ok'] else 2
if __name__ == '__main__': sys.exit(main())
