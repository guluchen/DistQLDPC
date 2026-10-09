#!/usr/bin/env python3
"""GH-85 Tier3 worker (Linux server): one case/mode, AB/BA/AB pinned to one logical CPU.
Telemetry: global idle, pinned-CPU idle and SMT-sibling idle sampled every 5 s during each run.
Science: rc 0 and o == named distance, or TIMEOUT with sound emitted bounds; any other outcome stops."""
import argparse, hashlib, json, os, re, subprocess, sys, threading, time
from pathlib import Path

def snap():
    d = {}
    for l in open('/proc/stat'):
        if l.startswith('cpu') and l[3].isdigit():
            p = l.split(); v = list(map(int, p[1:])); d[int(p[0][3:])] = (v[3] + v[4], sum(v))
    return d

def idles(a, b):
    return {c: (b[c][0] - a[c][0]) / max(1, b[c][1] - a[c][1]) for c in a}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--base'); ap.add_argument('--cand'); ap.add_argument('--case'); ap.add_argument('--mode')
    ap.add_argument('--d', type=int); ap.add_argument('--cpu', type=int); ap.add_argument('--limit', type=int, default=1800)
    ap.add_argument('--watchdog', type=int, default=1830); ap.add_argument('--out')
    a = ap.parse_args(); out = Path(a.out); out.mkdir(parents=True, exist_ok=True)
    sib = (a.cpu + 128) % 256
    sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
    bins = {'baseline': os.path.abspath(a.base), 'candidate': os.path.abspath(a.cand)}
    hashes = {k: sha(v) for k, v in bins.items()}
    inputs = {str(f): sha(f) for f in sorted(Path('data/matrices').glob(a.case + '_*.txt'))}
    samples = []; stop = None
    for rep, order in enumerate(['AB', 'BA', 'AB']):
        for v in order:
            ver = 'baseline' if v == 'A' else 'candidate'
            for _ in range(120):                     # wait (<= 10 min) for an idle pinned CPU and >50% global idle
                s0 = snap(); time.sleep(2); i0 = idles(s0, snap())
                g = sum(i0.values()) / len(i0)
                if g > 0.5 and i0[a.cpu] > 0.8: break
                time.sleep(3)
            else:
                stop = 'resource guard not met for 10 min'; break
            tel = []; done = threading.Event()
            def sampler():
                prev = snap()
                while not done.wait(5):
                    cur = snap(); ii = idles(prev, cur); prev = cur
                    tel.append((round(time.time(), 1), round(sum(ii.values()) / len(ii), 3), round(ii[a.cpu], 3), round(ii[sib], 3)))
            th = threading.Thread(target=sampler, daemon=True); th.start()
            cmd = ['taskset', '-c', str(a.cpu), bins[ver], f'-cpu-lim={a.limit}', '-' + a.mode, a.case]
            t = time.perf_counter()
            try:
                p = subprocess.run(cmd, capture_output=True, text=True, timeout=a.watchdog); rc, so, se = p.returncode, p.stdout, p.stderr
            except subprocess.TimeoutExpired:
                rc, so, se = 'WATCHDOG', '', ''
            wall = time.perf_counter() - t; done.set(); th.join()
            name = f'{rep}.{ver}'
            (out / f'{name}.out').write_text(so); (out / f'{name}.err').write_text(se)
            lbs = [int(x) for x in re.findall(r'^c d_lb: (\d+)$', so, re.M)]; ubs = [int(x) for x in re.findall(r'^c d_ub: (\d+)$', so, re.M)]
            o = re.findall(r'^o (\d+)$', so, re.M); status = 'done' if (rc == 0 and o) else ('TIMEOUT' if 'TIMEOUT' in so else 'OTHER')
            rec = {'rep': rep, 'version': ver, 'wall_s': wall, 'rc': rc, 'status': status, 'o': int(o[-1]) if o else None,
                   'lbs': lbs, 'ubs': ubs, 'cmd': cmd, 'pre_global_idle': round(g, 3), 'pre_cpu_idle': round(i0[a.cpu], 3),
                   'pre_sibling_idle': round(i0[sib], 3), 'telemetry': tel}
            samples.append(rec); (out / 'samples.json').write_text(json.dumps(samples, indent=1))
            if status == 'OTHER' or (status == 'done' and rec['o'] != a.d) or any(x > a.d for x in lbs) or any(y < a.d for y in ubs):
                stop = f'SCIENCE problem in {name}: status {status} o {rec["o"]}'; break
        if stop: break
    res = {'case': a.case, 'mode': a.mode, 'cpu': a.cpu, 'sibling': sib, 'limit': a.limit, 'binary_sha256': hashes,
           'binary_sha256_after': {k: sha(v) for k, v in bins.items()}, 'inputs_ok': all(sha(f) == h for f, h in inputs.items()),
           'input_sha256': inputs, 'stopped': stop, 'n': len(samples)}
    (out / 'result.json').write_text(json.dumps(res, indent=1)); print(json.dumps(res))
if __name__ == '__main__': main()
