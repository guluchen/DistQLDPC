#!/usr/bin/env python3
"""Server Tier1 re-test worker: one candidate vs baseline on ONE pinned logical CPU.
For each of the 4 Tier1 cases x {no-card, card-mto}: gate 3+3 (AB/BA/AB) then 10 alternating AB/BA pairs.
Search-identical candidates: every run must produce the same o/progress lines as the baseline (rc 0, named d).
Telemetry: pinned CPU and sibling idle before each run. Judge = unchanged GH16 rule per mode (gate) + replication."""
import argparse, hashlib, json, math, os, re, statistics, subprocess, time
from pathlib import Path
CASES = {'BB_90_8_10': 10, 'GB_144_12_8': 8, 'BB_108_8_10': 10, 'LP_238_44_6': 6}
def snap():
    d = {}
    for l in open('/proc/stat'):
        if l.startswith('cpu') and l[3].isdigit():
            p = l.split(); v = list(map(int, p[1:])); d[int(p[0][3:])] = (v[3] + v[4], sum(v))
    return d
def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--base'); ap.add_argument('--cand'); ap.add_argument('--cpu', type=int)
    ap.add_argument('--out'); ap.add_argument('--pairs', type=int, default=10); a = ap.parse_args()
    out = Path(a.out); out.mkdir(parents=True, exist_ok=True); sib = (a.cpu + 128) % 256
    sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
    bins = {'baseline': os.path.abspath(a.base), 'candidate': os.path.abspath(a.cand)}; h0 = {k: sha(v) for k, v in bins.items()}
    S = []; stop = None; ref = {}
    for case, d in CASES.items():
        for mode in ('no-card', 'card-mto'):
            plan = [('gate', r, v) for r, o in enumerate(['AB', 'BA', 'AB']) for v in o] + \
                   [('repl', r, v) for r in range(a.pairs) for v in ('AB' if r % 2 == 0 else 'BA')]
            for phase, rep, v in plan:
                ver = 'baseline' if v == 'A' else 'candidate'
                s0 = snap(); time.sleep(1); s1 = snap()
                idle = lambda c: (s1[c][0] - s0[c][0]) / max(1, s1[c][1] - s0[c][1])
                t = time.perf_counter()
                p = subprocess.run(['taskset', '-c', str(a.cpu), bins[ver], '-cpu-lim=180', '-' + mode, case], capture_output=True, text=True, timeout=195)
                w = time.perf_counter() - t
                lines = [l for l in p.stdout.splitlines() if l.startswith(('c trying', 'c d_lb', 'c d_ub', 'c d ', 'o ', 's '))]
                S.append({'case': case, 'mode': mode, 'phase': phase, 'rep': rep, 'version': ver, 'wall_s': w, 'rc': p.returncode,
                          'cpu_idle': round(idle(a.cpu), 3), 'sib_idle': round(idle(sib), 3)})
                key = (case, mode)
                if p.returncode != 0 or f'o {d}' not in lines: stop = f'SCIENCE {case} {mode} {ver}'; break
                if key not in ref: ref[key] = lines
                elif ref[key] != lines: stop = f'TRACE MISMATCH {case} {mode} {ver}'; break
            if stop: break
        if stop: break
    res = {'stopped': stop, 'n': len(S), 'binary_sha256': h0, 'binary_sha256_after': {k: sha(v) for k, v in bins.items()}, 'cpu': a.cpu}
    for phase in ('gate', 'repl'):
        res[phase] = {}
        for mode in ('no-card', 'card-mto'):
            rows = []
            for case in CASES:
                b = [x['wall_s'] for x in S if x['phase'] == phase and x['case'] == case and x['mode'] == mode and x['version'] == 'baseline']
                c = [x['wall_s'] for x in S if x['phase'] == phase and x['case'] == case and x['mode'] == mode and x['version'] == 'candidate']
                if not b or len(b) != len(c): continue
                rows.append({'case': case, 'ratio': statistics.median(c) / statistics.median(b), 'env': max(c) / min(b),
                             'reg': min(c) > max(b), 'impr': max(c) < min(b)})
            if len(rows) == len(CASES):
                g = math.exp(statistics.mean(math.log(r['ratio']) for r in rows)); e = math.exp(statistics.mean(math.log(r['env']) for r in rows))
                res[phase][mode] = {'geomean': g, 'envelope': e, 'positive': all(r['ratio'] <= 1 for r in rows) and e < 1,
                                    'regflags': [r['case'] for r in rows if r['reg']], 'rows': rows}
    (out / 'samples.json').write_text(json.dumps(S, indent=0)); (out / 'result.json').write_text(json.dumps(res, indent=1))
    print(json.dumps({k: res[k] for k in ('stopped', 'n')}))
if __name__ == '__main__': main()
