#!/usr/bin/env python3
"""E001 local timing evidence after Tier 0; never bypasses controlled-host gates."""
import argparse
import hashlib
import importlib.util
import json
import os
import platform
import signal
import subprocess
import sys
import time
from pathlib import Path


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--package', type=Path, required=True)
    ap.add_argument('--output', type=Path, required=True)
    a = ap.parse_args()
    pkg, out = a.package.resolve(), a.output.resolve()
    assert json.loads((out / 'tier0/summary.json').read_text())['status'] == 'PASS'
    spec = importlib.util.spec_from_file_location('gates', pkg / 'candidate/optimization/server/run.py')
    gates = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gates)
    env = dict(os.environ, OMP_NUM_THREADS='1', OPENBLAS_NUM_THREADS='1',
               MKL_NUM_THREADS='1', LC_ALL='C')
    identity = {v: hashlib.sha256((pkg / v / 'bin/distqldpc.exe').read_bytes()).hexdigest()
                for v in ['baseline', 'candidate']}
    (out / 'environment.json').write_text(json.dumps({'platform': platform.uname()._asdict(),
        'compiler': subprocess.check_output(['g++', '--version'], text=True),
        'binary_sha256': identity, 'reservation': None, 'fixed_power_policy': False,
        'timing_scope': 'local relative evidence; cross-machine portability untested',
        'manifest': json.loads((pkg / 'manifest.json').read_text())}, indent=2))
    samples = []
    result = {'decision': 'INCONCLUSIVE', 'tier0': 'PASS', 'tier1': 'pending',
              'tier2': 'not reached', 'tier3': 'not run',
              'reason': 'Interactive Windows host; original controlled-host gate not satisfied'}

    def save():
        (out / 'samples.json').write_text(json.dumps(samples, indent=2))
        (out / 'result.json').write_text(json.dumps(result, indent=2))

    save()
    for case in gates.CASES1:
        expected = int(case.rsplit('_', 1)[1])
        for mode in gates.MODES:
            reference = None
            for rep in range(3):
                for version in (['baseline', 'candidate'] if rep % 2 == 0 else ['candidate', 'baseline']):
                    label = f'tier1-{case}-{mode}-{rep+1}-{version}'
                    matrix_prefix = str(pkg / 'baseline/data/matrices' / case).replace('\\', '/')
                    cmd = [str(pkg / version / 'bin/distqldpc'), '-v', '-cpu-lim=180',
                           '-' + mode, matrix_prefix]
                    watchdog = False
                    start = time.perf_counter()
                    with (out / (label + '.stdout')).open('w') as so, (out / (label + '.stderr')).open('w') as se:
                        p = subprocess.Popen(cmd, cwd=pkg / version, env=env,
                                             stdout=so, stderr=se, start_new_session=True)
                        try:
                            rc = p.wait(timeout=195)
                        except subprocess.TimeoutExpired:
                            watchdog = True
                            if platform.system() == 'Windows':
                                subprocess.run(['taskkill', '/PID', str(p.pid), '/T', '/F'],
                                               capture_output=True, check=False)
                            else:
                                os.killpg(p.pid, signal.SIGKILL)
                            rc = p.wait()
                    elapsed = time.perf_counter() - start
                    semantic = gates.parse((out / (label + '.stdout')).read_text())
                    samples.append({'case': case, 'mode': mode, 'version': version,
                        'repeat': rep + 1, 'command': cmd, 'cwd': str(pkg / version),
                        'elapsed_sec': elapsed, 'returncode': rc, 'watchdog': watchdog,
                        'semantic': semantic})
                    save()
                    print(label, round(elapsed, 3), semantic, flush=True)
                    exact = semantic['d'] is not None
                    mismatch = exact and any(semantic[k] != expected for k in ['d', 'objective', 'lb', 'ub'])
                    mismatch |= exact and (semantic['timeout'] or semantic['unknown'])
                    mismatch |= exact and reference is not None and semantic != reference
                    crash = rc not in [0, 1] or (rc == 1 and not semantic['timeout'] and not watchdog)
                    if mismatch or crash:
                        result.update(decision='REJECTED', tier1='stopped',
                                      reason=f'Semantic mismatch or crash: {label}')
                        save()
                        return 2
                    if watchdog or rc != 0 or not exact or semantic['timeout'] or semantic['unknown']:
                        result.update(tier1='incomplete', reason=f'Timeout/incomplete: {label}')
                        save()
                        return 1
                    reference = semantic
    numeric, reason, medians = gates.judge(samples, gates.CASES1)
    result.update(tier1={'numeric_filter': numeric, 'reason': reason, 'medians': medians},
                  correctness='identical certified distances and bounds for every completed run')
    save()
    print(json.dumps(result, indent=2), flush=True)
    return 0


if __name__ == '__main__':
    sys.exit(main())
