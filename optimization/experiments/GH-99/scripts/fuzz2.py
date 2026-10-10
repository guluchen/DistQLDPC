#!/usr/bin/env python3
"""GH-60 corrected exhaustive oracle (post-hoc fix of fuzz.py, disclosed in ATTEMPTS.md).
Supported fragment only: unit-weight partial MaxSAT with UNIT soft clauses (the only
soft-clause form DistQLDPC produces). Oracle contract follows GH-22 check_pms.py:
truth SAT -> rc in {10,20} and every `optimal:` value == brute-force optimum, status
SATISFIABLE iff rc 10; truth hard-UNSAT -> `s UNSATISFIABLE` and no optimal value.
Crashes/timeouts are recorded per binary; a candidate wrong optimum is a STOP."""
import argparse, json, os, random, re, subprocess, sys, time
from pathlib import Path

def gen(seed):
    r = random.Random(seed); n = r.randint(8, 20); hard = []; soft = []
    for _ in range(r.randint(n, 3 * n)):
        k = r.randint(2, 4); vs = r.sample(range(1, n + 1), k); hard.append([v if r.random() < .5 else -v for v in vs])
    for v in r.sample(range(1, n + 1), r.randint(min(6, n), n)):
        soft.append([v if r.random() < .5 else -v])
    top = len(soft) + 1
    txt = f'p wcnf {n} {len(hard) + len(soft)} {top}\n' + ''.join(f'{top} ' + ' '.join(map(str, c)) + ' 0\n' for c in hard) + ''.join('1 ' + ' '.join(map(str, c)) + ' 0\n' for c in soft)
    return txt

def judge(binary, path, truth, lim):
    try: p = subprocess.run([binary, path], capture_output=True, text=True, timeout=lim)
    except subprocess.TimeoutExpired: return {'status': 'timeout', 'ok': None}
    text = p.stdout; rc = p.returncode
    if rc not in (10, 20): return {'status': 'crash', 'rc': rc, 'ok': None}
    vals = re.findall(r'optimal:\s*([^\r\n,]*)', text); st = re.findall(r'^s\s+(.*?)\s*$', text, re.M)
    if truth is None:
        ok = st == ['UNSATISFIABLE'] and not vals
    else:
        ok = bool(vals) and all(re.fullmatch(r'\d+', v) and int(v) == truth for v in vals) and st == (['SATISFIABLE'] if rc == 10 else ['UNSATISFIABLE'])
    return {'status': 'done', 'rc': rc, 'vals': vals, 'ok': ok}

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--base'); ap.add_argument('--cand'); ap.add_argument('--extra')
    ap.add_argument('--brute'); ap.add_argument('--out'); ap.add_argument('--n', type=int, default=3000); ap.add_argument('--seed0', type=int, default=700000)
    ap.add_argument('--lim', type=int, default=20)
    a = ap.parse_args(); out = Path(a.out); work = out / 'work'; work.mkdir(parents=True, exist_ok=True)
    bins = {'base': os.path.abspath(a.base), 'cand': os.path.abspath(a.cand)}
    if a.extra: bins['check'] = os.path.abspath(a.extra)
    res = []
    for i in range(a.n):
        seed = a.seed0 + i; txt = gen(seed); path = work / 'inst.wcnf'; path.write_text(txt)
        b = subprocess.run([a.brute, str(path)], capture_output=True, text=True).stdout.split()
        truth = None if b[0] == 'unsat' else int(b[1])
        row = {'seed': seed, 'truth': truth}
        for k, bp in bins.items(): row[k] = judge(bp, str(path), truth, a.lim)
        res.append(row)
        if any(row[k]['ok'] is False for k in bins):
            (out / f'wrong-{seed}.wcnf').write_text(txt); print('WRONG', json.dumps(row), flush=True)
        if i % 500 == 0: print(i, flush=True)
    summ = {k: {} for k in bins}
    for row in res:
        for k in bins:
            key = row[k]['status'] + ('' if row[k]['ok'] is None else (':ok' if row[k]['ok'] else ':WRONG')); summ[k][key] = summ[k].get(key, 0) + 1
    cand_wrong = [r['seed'] for r in res if r['cand']['ok'] is False or r.get('check', {'ok': True})['ok'] is False]
    cand_crash_base_ok = [r['seed'] for r in res if r['cand']['status'] == 'crash' and r['base']['ok']]
    hist = {}
    for r in res: hist[str(r['truth'])] = hist.get(str(r['truth']), 0) + 1
    meta = {'n': a.n, 'seed0': a.seed0, 'lim': a.lim, 'bins': bins, 'summary': summ, 'cand_or_check_wrong': cand_wrong,
            'cand_crash_where_base_ok': cand_crash_base_ok, 'truth_histogram': hist, 'finished': time.strftime('%Y-%m-%dT%H:%M:%S%z')}
    json.dump({'meta': meta, 'results': res}, open(out / 'fuzz2.json', 'w'), indent=0)
    print(json.dumps(meta['summary']), 'wrong:', cand_wrong[:20], 'cand crash where base ok:', cand_crash_base_ok[:20])
    return 0 if not cand_wrong else 2
if __name__ == '__main__': sys.exit(main())
