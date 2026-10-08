#!/usr/bin/env python3
"""Tier 1 serial timing runner for experiment GH-fable-triwatch (macOS host).

Preregistered protocol (PROPOSAL.md section 4): four cases, OFF and MTO,
three baseline + three candidate solves per case/mode, strictly serial,
interleaved AB / BA / AB, 180 s parent wall limit (-cpu-lim=180) and a
195 s external watchdog. Every solve records wall time (parent process,
measured here), the child's reported bounds/result, 1-minute load average
before and after, and rusage CPU time. Raw logs are kept per solve; a JSON
summary with medians, ratios, the preregistered decision and a SHA-256
manifest is written at the end. Nothing here changes solver inputs or limits.

usage: run_tier1_macos.py --baseline BIN --candidate BIN --out DIR [--repo DIR]
       [--cases BB_90_8_10,GB_144_12_8,BB_108_8_10,LP_238_44_6] [--repeats 3]
       [--limit 180] [--watchdog 195]
"""
import argparse, hashlib, json, os, platform, resource, statistics, subprocess, sys, time

def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()

def loadavg():
    return os.getloadavg()

def run_one(binary, mode_flag, case, limit, watchdog, repo, log_path):
    cmd = [binary, f"-cpu-lim={limit}", mode_flag, case]
    before = loadavg()
    ru0 = resource.getrusage(resource.RUSAGE_CHILDREN)
    t0 = time.monotonic()
    killed = False
    with open(log_path, 'w') as log:
        log.write("# cmd: " + " ".join(cmd) + "\n")
        log.flush()
        proc = subprocess.Popen(cmd, cwd=repo, stdout=log, stderr=subprocess.STDOUT)
        try:
            rc = proc.wait(timeout=watchdog)
        except subprocess.TimeoutExpired:
            proc.kill(); rc = proc.wait(); killed = True
    wall = time.monotonic() - t0
    ru1 = resource.getrusage(resource.RUSAGE_CHILDREN)
    after = loadavg()
    result, lb, ub, status = None, None, None, None
    with open(log_path) as log:
        for line in log:
            line = line.rstrip('\n')
            if line.startswith('o '): result = int(line.split()[1])
            elif line.startswith('c d_lb: ') and line.split()[-1] != '-': lb = int(line.split()[-1])
            elif line.startswith('c d_ub: ') and line.split()[-1] != '-': ub = int(line.split()[-1])
            elif line.startswith('s '): status = line
            elif line.startswith('c status:'): status = line
    return {
        "cmd": cmd, "wall_s": wall, "rc": rc, "watchdog_killed": killed,
        "cpu_user_s": ru1.ru_utime - ru0.ru_utime, "cpu_sys_s": ru1.ru_stime - ru0.ru_stime,
        "loadavg_before": before, "loadavg_after": after,
        "o": result, "d_lb": lb, "d_ub": ub, "status": status, "log": os.path.basename(log_path),
    }

def geomean(xs):
    import math
    return math.exp(sum(math.log(x) for x in xs) / len(xs))

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--baseline', required=True); ap.add_argument('--candidate', required=True)
    ap.add_argument('--out', required=True); ap.add_argument('--repo', default='.')
    ap.add_argument('--cases', default='BB_90_8_10,GB_144_12_8,BB_108_8_10,LP_238_44_6')
    ap.add_argument('--modes', default='-no-card,-card-mto')
    ap.add_argument('--repeats', type=int, default=3)
    ap.add_argument('--limit', type=int, default=180); ap.add_argument('--watchdog', type=int, default=195)
    ap.add_argument('--expected', default='', help='comma list case=d of certified distances for science checks')
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    cases = a.cases.split(','); modes = a.modes.split(',')
    expected = {kv.split('=')[0]: int(kv.split('=')[1]) for kv in a.expected.split(',') if kv}
    manifest = {
        "host": platform.node(), "platform": platform.platform(), "machine": platform.machine(),
        "cpu": subprocess.run(['sysctl', '-n', 'machdep.cpu.brand_string'], capture_output=True, text=True).stdout.strip(),
        "ncpu": os.cpu_count(), "start": time.strftime('%Y-%m-%dT%H:%M:%S%z'),
        "baseline": {"path": a.baseline, "sha256": sha256(a.baseline)},
        "candidate": {"path": a.candidate, "sha256": sha256(a.candidate)},
        "limit_s": a.limit, "watchdog_s": a.watchdog, "repeats": a.repeats, "cases": cases, "modes": modes,
        "inputs": {},
    }
    for c in cases:
        for suf in ("Hx", "Hz", "Gx", "Gz"):
            p = os.path.join(a.repo, 'data', 'matrices', f"{c}_{suf}.txt")
            manifest["inputs"][f"{c}_{suf}.txt"] = sha256(p)
    runs = []
    # Interleave: AB, BA, AB per case/mode, serial.
    orders = [("B", "C"), ("C", "B"), ("B", "C")][:a.repeats] if a.repeats <= 3 else \
             [("B", "C") if i % 2 == 0 else ("C", "B") for i in range(a.repeats)]
    bins = {"B": a.baseline, "C": a.candidate}
    for c in cases:
        for m in modes:
            for rep, order in enumerate(orders):
                for tag in order:
                    log_path = os.path.join(a.out, f"{c}_{m.lstrip('-')}_{tag}_rep{rep+1}.log")
                    r = run_one(bins[tag], m, c, a.limit, a.watchdog, a.repo, log_path)
                    r.update({"case": c, "mode": m, "version": "baseline" if tag == "B" else "candidate", "rep": rep + 1})
                    runs.append(r)
                    print(f"{c:12s} {m:10s} {r['version']:9s} rep{rep+1} wall={r['wall_s']:.3f}s o={r['o']} lb={r['d_lb']} ub={r['d_ub']} load={r['loadavg_before'][0]:.2f}->{r['loadavg_after'][0]:.2f} rc={r['rc']}", flush=True)
                    with open(os.path.join(a.out, 'runs.json'), 'w') as f:
                        json.dump({"manifest": manifest, "runs": runs}, f, indent=1)
    # Summary and preregistered decision
    summary = {"per_case": {}, "per_mode": {}, "science": {}}
    science_ok = True
    for m in modes:
        ratios, spreads, disjoint_regr = [], [], []
        for c in cases:
            b = [r['wall_s'] for r in runs if r['case'] == c and r['mode'] == m and r['version'] == 'baseline']
            k = [r['wall_s'] for r in runs if r['case'] == c and r['mode'] == m and r['version'] == 'candidate']
            res = set((r['o'], r['d_lb'], r['d_ub']) for r in runs if r['case'] == c and r['mode'] == m)
            ok = len(res) == 1 and (c not in expected or next(iter(res))[0] == expected[c])
            science_ok &= ok
            bm, km = statistics.median(b), statistics.median(k)
            ratio = km / bm
            spread = max(b) / min(b)
            disjoint = min(k) > max(b)
            disjoint_regr.append((c, disjoint, ratio))
            ratios.append(ratio); spreads.append(spread)
            summary["per_case"][f"{c} {m}"] = {
                "baseline_raw": b, "candidate_raw": k, "baseline_median": bm, "candidate_median": km,
                "ratio": ratio, "baseline_spread": spread, "candidate_spread": max(k) / min(k),
                "disjoint_regression": disjoint, "disjoint_improvement": max(k) < min(b),
                "results": sorted(res), "science_ok": ok,
            }
        G, V = geomean(ratios), geomean(spreads)
        any_disjoint_regr = any(d for _, d, _ in disjoint_regr)
        big_disjoint = any(d and ratio > 1.02 for _, d, ratio in disjoint_regr)
        if G < 1 and G * V < 1 and not any_disjoint_regr: gate = "PASS"
        elif big_disjoint and G >= 1: gate = "REJECT"
        else: gate = "INCONCLUSIVE"
        summary["per_mode"][m] = {"G_geomean_ratio": G, "V_geomean_baseline_spread": V, "G_times_V": G * V,
                                  "any_disjoint_regression": any_disjoint_regr, "gate": gate}
    summary["science"] = {"all_results_identical_and_expected": science_ok}
    summary["decision_rule"] = ("per mode: PASS iff G<1, G*V<1 and no disjoint per-case regression; REJECT if a disjoint "
                                "regression >2% with G>=1; else INCONCLUSIVE (PROPOSAL.md section 4)")
    manifest["end"] = time.strftime('%Y-%m-%dT%H:%M:%S%z')
    with open(os.path.join(a.out, 'runs.json'), 'w') as f:
        json.dump({"manifest": manifest, "runs": runs, "summary": summary}, f, indent=1)
    # SHA-256 manifest of every raw file
    with open(os.path.join(a.out, 'SHA256SUMS'), 'w') as f:
        for name in sorted(os.listdir(a.out)):
            if name == 'SHA256SUMS': continue
            f.write(f"{sha256(os.path.join(a.out, name))}  {name}\n")
    print(json.dumps(summary["per_mode"], indent=1))
    print("science:", summary["science"])
    return 0

if __name__ == '__main__':
    sys.exit(main())
