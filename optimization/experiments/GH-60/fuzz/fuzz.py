#!/usr/bin/env python3
"""GH-60 exhaustive oracle fuzz: random small unit-weight partial MaxSAT WCNFs.
Each binary's returned model (result file) must satisfy all hard clauses and have
cost == brute-force optimum; UNSAT must agree. Seeded; instances are regenerated
deterministically from the seed list in the output."""
import argparse, json, os, random, subprocess, sys, time
from pathlib import Path

def gen(seed):
    r = random.Random(seed); n = r.randint(8, 20); hard = []; soft = []
    for _ in range(r.randint(n, 3 * n)):
        k = r.randint(2, 4); vs = r.sample(range(1, n + 1), k); hard.append([v if r.random() < .5 else -v for v in vs])
    for _ in range(r.randint(6, 20)):
        k = r.choice([1, 1, 2]); vs = r.sample(range(1, n + 1), k); soft.append([v if r.random() < .5 else -v for v in vs])
    top = len(soft) + 1
    txt = f'p wcnf {n} {len(hard) + len(soft)} {top}\n' + ''.join(f'{top} ' + ' '.join(map(str, c)) + ' 0\n' for c in hard) + ''.join('1 ' + ' '.join(map(str, c)) + ' 0\n' for c in soft)
    return n, hard, soft, txt

def check(binary, path, resf, n, hard, soft, lim):
    try: p = subprocess.run([binary, path, '0', resf], capture_output=True, text=True, timeout=lim)
    except subprocess.TimeoutExpired: return {'status': 'timeout'}
    st = next((l[2:] for l in p.stdout.splitlines() if l.startswith('s ')), None)
    if p.returncode not in (10, 20) or st is None: return {'status': 'crash', 'rc': p.returncode, 'tail': (p.stdout + p.stderr)[-400:]}
    if st == 'UNSATISFIABLE': return {'status': 'unsat'}
    toks = Path(resf).read_text().split()
    if not toks or toks[0] != 'SAT': return {'status': 'badres'}
    val = {}
    for t in toks[1:]:
        x = int(t)
        if x: val[abs(x)] = x > 0
    sat = lambda c: any(val.get(abs(x), False) == (x > 0) for x in c)
    if not all(sat(c) for c in hard): return {'status': 'model_violates_hard'}
    return {'status': 'sat', 'cost': sum(1 for c in soft if not sat(c))}

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--base'); ap.add_argument('--cand'); ap.add_argument('--extra', default=None)
    ap.add_argument('--brute'); ap.add_argument('--out'); ap.add_argument('--n', type=int, default=3000); ap.add_argument('--seed0', type=int, default=600000)
    ap.add_argument('--lim', type=int, default=20)
    a = ap.parse_args(); out = Path(a.out); work = out / 'work'; work.mkdir(parents=True, exist_ok=True)
    bins = {'base': os.path.abspath(a.base), 'cand': os.path.abspath(a.cand)}
    if a.extra: bins['check'] = os.path.abspath(a.extra)
    res = []; bad = []
    for i in range(a.n):
        seed = a.seed0 + i; n, hard, soft, txt = gen(seed); path = work / 'inst.wcnf'; path.write_text(txt)
        b = subprocess.run([a.brute, str(path)], capture_output=True, text=True).stdout.split()
        truth = ('unsat', None) if b[0] == 'unsat' else ('sat', int(b[1]))
        row = {'seed': seed, 'n': n, 'truth': truth}
        for k, binp in bins.items():
            r = check(binp, str(path), str(work / f'res.{k}'), n, hard, soft, a.lim); row[k] = r
            ok = (r['status'] == 'unsat' and truth[0] == 'unsat') or (r['status'] == 'sat' and truth[0] == 'sat' and r['cost'] == truth[1])
            r['ok'] = ok
        res.append(row)
        if not (row['cand']['ok'] and row.get('check', {'ok': True})['ok']) and not (row['base']['status'] == 'crash' and row['cand']['status'] == 'crash'):
            bad.append(row); (out / f'bad-{seed}.wcnf').write_text(txt)
            print('BAD', json.dumps(row), flush=True)
            if row['cand']['status'] not in ('crash', 'timeout') or row['base']['ok']:
                pass
        if i % 250 == 0: print(i, 'done', flush=True)
    summ = {}
    for k in bins:
        for row in res:
            key = f"{k}:{row[k]['status']}:{'ok' if row[k]['ok'] else 'WRONG'}"; summ[key] = summ.get(key, 0) + 1
    cand_wrong = [r['seed'] for r in res if not r['cand']['ok'] and not (r['cand']['status'] == 'crash' and r['base']['status'] == 'crash')]
    meta = {'n': a.n, 'seed0': a.seed0, 'lim': a.lim, 'bins': bins, 'summary': summ, 'cand_failures_not_shared_with_base': cand_wrong,
            'truth_opt_histogram': {}, 'finished': time.strftime('%Y-%m-%dT%H:%M:%S%z')}
    for r in res:
        k = str(r['truth'][1]) if r['truth'][0] == 'sat' else 'unsat'; meta['truth_opt_histogram'][k] = meta['truth_opt_histogram'].get(k, 0) + 1
    json.dump({'meta': meta, 'results': res}, open(out / 'fuzz.json', 'w'), indent=0)
    print(json.dumps(meta['summary']), 'cand failures:', cand_wrong[:20])
    return 0 if not cand_wrong else 2
if __name__ == '__main__': sys.exit(main())
