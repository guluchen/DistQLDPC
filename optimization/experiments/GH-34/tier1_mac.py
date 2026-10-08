#!/usr/bin/env python3
"""GH-litvals Tier1 (and Tier2) runner for the macOS host; one solve at a time.

Order per case/mode: AB, BA, AB (A=baseline, B=candidate) -> 3+3 samples.
Optional --replicate N adds N alternating AB/BA pairs per case/mode, reported
separately (preregistered supplementary evidence; never used by the gate).
Gate (unchanged GH16 judge): per mode, geometric mean of per-case median ratios;
range envelope max(cand)/min(base) geometric mean; numerically positive only if
all per-case medians are non-worse AND envelope mean < 1. A case where every
candidate sample is slower than every baseline sample is flagged.
Science: exit status, every emitted progress/bound line and the final result
line must be identical between versions and the distance must equal the
expected value. Any mismatch stops immediately (REJECT).
"""
import argparse, hashlib, json, math, os, platform, statistics, subprocess, sys, time
from pathlib import Path

def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def loadavg():
    return [float(x) for x in subprocess.run(['sysctl', '-n', 'vm.loadavg'], capture_output=True, text=True).stdout.strip('{} \n').split()]
def other_cpu():
    out = subprocess.run(['ps', '-A', '-o', '%cpu='], capture_output=True, text=True).stdout.split()
    return round(sum(float(x) for x in out), 1)

def guard(max_load, wait, log):
    t0 = time.time()
    while True:
        la = loadavg()
        if la[0] < max_load: return la, round(time.time() - t0, 1)
        if time.time() - t0 > wait: return None, round(time.time() - t0, 1)
        log.write(json.dumps({'guard_wait': la}) + '\n'); time.sleep(10)

def solve(binary, case, mode, limit, watchdog):
    cmd = [binary, f'-cpu-lim={limit}', '-' + mode, case]
    t = time.perf_counter()
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=watchdog)
        rc, out, err = p.returncode, p.stdout, p.stderr
    except subprocess.TimeoutExpired as e:
        rc, out, err = 'WATCHDOG', (e.stdout or b'').decode() if isinstance(e.stdout, bytes) else (e.stdout or ''), ''
    return cmd, time.perf_counter() - t, rc, out, err

def expected(case):
    d = case.split('_')[-1]
    return int(d) if d.isdigit() else None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--base', required=True); ap.add_argument('--cand', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--cases', nargs='+', default=['BB_90_8_10', 'GB_144_12_8', 'BB_108_8_10', 'LP_238_44_6'])
    ap.add_argument('--modes', nargs='+', default=['no-card', 'card-mto'])
    ap.add_argument('--limit', type=int, default=180); ap.add_argument('--watchdog', type=int, default=195)
    ap.add_argument('--replicate', type=int, default=0)
    ap.add_argument('--max-load', type=float, default=6.0); ap.add_argument('--guard-wait', type=int, default=600)
    a = ap.parse_args()
    out = Path(a.out); (out / 'stdout').mkdir(parents=True, exist_ok=True)
    bins = {'baseline': os.path.abspath(a.base), 'candidate': os.path.abspath(a.cand)}
    hashes = {k: sha(v) for k, v in bins.items()}
    inputs = {str(f): sha(f) for c in a.cases for f in sorted(Path('data/matrices').glob(c + '_*.txt'))}
    manifest = {'argv': sys.argv, 'binaries': bins, 'binary_sha256': hashes, 'input_sha256': inputs,
                'host': platform.platform(), 'machine': platform.machine(),
                'cpu': subprocess.run(['sysctl', '-n', 'machdep.cpu.brand_string'], capture_output=True, text=True).stdout.strip(),
                'ncpu': os.cpu_count(), 'python': sys.version, 'started': time.strftime('%Y-%m-%dT%H:%M:%S%z')}
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=1))
    tel = open(out / 'telemetry.jsonl', 'a'); samples = []; stop = None
    plan = []
    for c in a.cases:
        for m in a.modes:
            for rep, order in enumerate(['AB', 'BA', 'AB']):
                for v in order: plan.append(('gate', c, m, rep, 'baseline' if v == 'A' else 'candidate'))
            for rep in range(a.replicate):
                for v in ('AB' if rep % 2 == 0 else 'BA'): plan.append(('replicate', c, m, rep, 'baseline' if v == 'A' else 'candidate'))
    ref = {}
    for i, (phase, c, m, rep, ver) in enumerate(plan):
        la, waited = guard(a.max_load, a.guard_wait, tel)
        if la is None: stop = f'resource guard: load >= {a.max_load} for {a.guard_wait}s before run {i}'; break
        oc = other_cpu()
        cmd, wall, rc, so, se = solve(bins[ver], c, m, a.limit, a.watchdog)
        la2 = loadavg()
        name = f'{i:04d}.{phase}.{c}.{m}.{rep}.{ver}'
        (out / 'stdout' / (name + '.out')).write_text(so); (out / 'stdout' / (name + '.err')).write_text(se)
        lines = [l for l in so.splitlines() if l.startswith(('c trying', 'c d_lb', 'c d_ub', 'c d ', 'o ', 's ', 'c status'))]
        res = next((l for l in reversed(lines) if l.startswith(('o ', 's '))), None)
        rec = {'i': i, 'phase': phase, 'case': c, 'mode': m, 'rep': rep, 'version': ver, 'wall_s': wall, 'rc': rc,
               'result': res, 'science_lines': lines, 'load_before': la, 'guard_wait_s': waited,
               'ps_cpu_sum_before': oc, 'load_after': la2, 'cmd': cmd}
        samples.append(rec); tel.write(json.dumps({'i': i, 'load_before': la, 'ps_cpu': oc, 'load_after': la2}) + '\n'); tel.flush()
        exp = expected(c); key = (c, m)
        if rc != 0 or res != (f'o {exp}' if exp is not None else res):
            stop = f'SCIENCE: unexpected result/rc in {name}: rc={rc} result={res}'; break
        if key not in ref: ref[key] = (rc, lines)
        elif ref[key] != (rc, lines):
            stop = f'SCIENCE: emitted progress/bound lines differ in {name}'; break
        print(f'{name} {wall:.3f}s {res} load={la[0]:.2f}', flush=True)
        (out / 'samples.json').write_text(json.dumps(samples, indent=1))
    (out / 'samples.json').write_text(json.dumps(samples, indent=1))
    result = {'stopped': stop, 'n_samples': len(samples), 'finished': time.strftime('%Y-%m-%dT%H:%M:%S%z'),
              'binary_sha256_after': {k: sha(v) for k, v in bins.items()},
              'input_sha256_after_ok': all(sha(f) == h for f, h in inputs.items())}
    if result['binary_sha256_after'] != hashes: result['stopped'] = (stop or '') + ' BINARY CHANGED'
    for phase in ['gate'] + (['replicate'] if a.replicate else []):
        per = {}
        for m in a.modes:
            rows = []
            for c in a.cases:
                v = {ver: [s['wall_s'] for s in samples if s['phase'] == phase and s['case'] == c and s['mode'] == m and s['version'] == ver] for ver in ('baseline', 'candidate')}
                if not v['baseline'] or len(v['baseline']) != len(v['candidate']): continue
                b, cc = statistics.median(v['baseline']), statistics.median(v['candidate'])
                rows.append({'case': c, 'baseline': v['baseline'], 'candidate': v['candidate'], 'median_b': b, 'median_c': cc,
                             'ratio': cc / b, 'range_envelope': max(v['candidate']) / min(v['baseline']),
                             'nonoverlapping_regression': min(v['candidate']) > max(v['baseline']),
                             'nonoverlapping_improvement': max(v['candidate']) < min(v['baseline'])})
            if len(rows) == len(a.cases):
                g = math.exp(statistics.mean(math.log(r['ratio']) for r in rows))
                e = math.exp(statistics.mean(math.log(r['range_envelope']) for r in rows))
                positive = all(r['ratio'] <= 1 for r in rows) and e < 1
                per[m] = {'rows': rows, 'median_ratio_geomean': g, 'envelope_geomean': e,
                          'all_medians_nonworse': all(r['ratio'] <= 1 for r in rows), 'numeric_positive': positive,
                          'regression_flags': [r['case'] for r in rows if r['nonoverlapping_regression']]}
        result[phase] = per
    (out / 'result.json').write_text(json.dumps(result, indent=1))
    print(json.dumps({k: v for k, v in result.items() if k not in ('gate', 'replicate')}, indent=1))
    for phase in ('gate', 'replicate'):
        for m, r in result.get(phase, {}).items():
            print(phase, m, 'geomean', round(r['median_ratio_geomean'], 5), 'envelope', round(r['envelope_geomean'], 5),
                  'positive', r['numeric_positive'], 'flags', r['regression_flags'])
    return 0 if not result['stopped'] else 2

if __name__ == '__main__':
    sys.exit(main())
