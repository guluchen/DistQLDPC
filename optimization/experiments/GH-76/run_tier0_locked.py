#!/usr/bin/env python3
"""GH-76: drive the unchanged GH-60 tier0_science.job() serially (jobs=1), waiting before every job
while the host TIMING_LOCK file exists or the 1-min load average is >= MAXLOAD. Same checks, same
science.json format as tier0_science.main(); only scheduling differs. Usage:
  run_tier0_locked.py --base B --cand C --out DIR --lock LOCKFILE [--limit 60] [--maxload 6]"""
import argparse, hashlib, importlib.util, json, os, subprocess, sys, time
from pathlib import Path
here = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('tier0_science', here / 'tier0_science.py')
t0 = importlib.util.module_from_spec(spec); spec.loader.exec_module(t0)

def load1():
    s = subprocess.run(['sysctl', '-n', 'vm.loadavg'], capture_output=True, text=True).stdout
    return float(s.strip('{} \n').split()[0])

def wait(lock, maxload):
    waited = 0
    while os.path.exists(lock) or load1() >= maxload:
        time.sleep(30); waited += 30
    return waited

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--base'); ap.add_argument('--cand'); ap.add_argument('--out')
    ap.add_argument('--limit', type=int, default=60); ap.add_argument('--lock', required=True)
    ap.add_argument('--maxload', type=float, default=6.0)
    a = ap.parse_args(); a.base, a.cand = os.path.abspath(a.base), os.path.abspath(a.cand); a.jobs = 1
    out = Path(a.out); logs = out / 'logs'; logs.mkdir(parents=True, exist_ok=True)
    stems = sorted({f.name.rsplit('_', 1)[0] for f in Path('data/matrices').glob('*_Hx.txt')})
    sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
    meta = {'base': a.base, 'cand': a.cand, 'base_sha256': sha(a.base), 'cand_sha256': sha(a.cand), 'limit': a.limit,
            'jobs': 1, 'scheduler': 'run_tier0_locked.py (lock/load wait between jobs)', 'started': time.strftime('%Y-%m-%dT%H:%M:%S%z')}
    res = []; waits = 0
    for s in stems:
        for m in t0.MODES:
            waits += wait(a.lock, a.maxload)
            r = t0.job(s, m, a, logs); res.append(r)
            print('OK ' if r['ok'] else 'FAIL', r['stem'], r['mode'], r['base']['status'], r['base']['o'], r['base']['wall'], '|',
                  r['cand']['status'], r['cand']['o'], r['cand']['wall'], r['problems'], flush=True)
    res.sort(key=lambda r: (r['stem'], r['mode']))
    meta['finished'] = time.strftime('%Y-%m-%dT%H:%M:%S%z'); meta['all_ok'] = all(r['ok'] for r in res); meta['lock_load_wait_s'] = waits
    meta['counts'] = {'both_done': sum(r['base']['status'] == 'done' and r['cand']['status'] == 'done' for r in res),
                      'only_cand_done': sum(r['base']['status'] != 'done' and r['cand']['status'] == 'done' for r in res),
                      'only_base_done': sum(r['base']['status'] == 'done' and r['cand']['status'] != 'done' for r in res),
                      'problems': sum(bool(r['problems']) for r in res)}
    json.dump({'meta': meta, 'results': res}, open(out / 'science.json', 'w'), indent=1)
    print(json.dumps(meta['counts']), 'ALL_OK' if meta['all_ok'] else 'STOP')
    return 0 if meta['all_ok'] else 2
if __name__ == '__main__': sys.exit(main())
