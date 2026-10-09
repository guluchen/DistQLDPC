#!/usr/bin/env python3
"""H-007 Windows Tier 1 continuation; reuse prior identical validated binaries."""
import argparse
import ctypes
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import platform
import runpy
import statistics
import subprocess
import sys
import tarfile
import time
from windows_cpu_window import Window, ticks, affinity, descendant_affinities
WINDOW = None
OUTPUT = None

ARCHIVE_SHA = '963c398f3ea87c2fd063bb06a752f1739139c75a5b81e518e44ac28d40844d06'
MODES = ['no-card', 'card-mto']


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def cygpath(value):
    value = str(value).replace('\\', '/')
    if value.startswith('-dump-wcnf='):
        return '-dump-wcnf=' + cygpath(value.split('=', 1)[1])
    if len(value) > 2 and value[1] == ':':
        return '/cygdrive/' + value[0].lower() + value[2:]
    return value


def cpu_ticks():
    idle, kernel, user = (ctypes.c_ulonglong() for _ in range(3))
    if not ctypes.windll.kernel32.GetSystemTimes(
            ctypes.byref(idle), ctypes.byref(kernel), ctypes.byref(user)):
        raise ctypes.WinError()
    return idle.value, kernel.value + user.value


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    for name in ['prior', 'cygwin-root', 'output']:
        ap.add_argument('--' + name, type=Path, required=True)
    ap.add_argument("--allow-core-contention", action="store_true")
    args = ap.parse_args()
    global WINDOW, OUTPUT
    OUTPUT = args.output.resolve()
    window = WINDOW = Window(args.allow_core_contention)
    assert platform.system() == 'Windows'
    runtime, prior, out = (args.cygwin_root.resolve(), args.prior.resolve(), args.output.resolve())
    pkg = prior / 'E004-server-package'
    assert json.loads((prior / 'evidence/tier0/summary.json').read_text(encoding='utf8'))['status'] == 'PASS'
    manifest = json.loads((pkg / 'manifest.json').read_text(encoding='utf8'))
    for relative, expected in manifest['files'].items():
        assert sha(pkg / relative) == expected, relative
    binaries = {v: pkg / v / 'bin/distqldpc.exe' for v in ['baseline', 'candidate']}
    expected_binaries = json.loads((prior / 'evidence/binary-hashes.json').read_text(encoding='utf8'))
    assert expected_binaries == {'baseline':'22e398cc7558c2a04d5f24bd6db3030ce552c752622027fc2657eff7c1bd1815',
                                 'candidate':'b483fe59a90201f53c7ea4a87b95aa39740f738f1f418feec3a7b4b036f5e547'}
    for version, binary in binaries.items():
        assert sha(binary) == expected_binaries[version], version
    recorded_setup = Path(__file__).resolve().parent / 'raw/windows-setup-2026-10-08/installed.db'
    assert (runtime / 'etc/setup/installed.db').read_bytes() == recorded_setup.read_bytes()
    previous_environment = json.loads((prior / 'evidence/environment.json').read_text(encoding='utf8'))
    compiler = subprocess.run([str(runtime / 'bin/g++.exe'), '--version'], capture_output=True, text=True, check=True).stdout
    assert compiler == previous_environment['compiler'], 'Compiler changed'
    out.mkdir(parents=True, exist_ok=False)
    os.environ['PATH'] = str(runtime / 'bin') + os.pathsep + os.environ['PATH']
    os.environ.update(LC_ALL='C', OMP_NUM_THREADS='1', OPENBLAS_NUM_THREADS='1', MKL_NUM_THREADS='1')
    original_run = subprocess.run

    def adapted_run(argv, *rest, **kwargs):
        executable = str(runtime / 'bin/bash.exe') if str(argv[0]) == 'bash' else str(argv[0])
        return original_run([executable] + [cygpath(x) for x in argv[1:]], *rest, **kwargs)

    evidence = out / 'evidence'
    evidence.mkdir()
    result = dict(decision='INCONCLUSIVE', tier0='not run', tier1='not run', tier2='prior diagnostic only', tier3='not run',
                  reason='Pinned desktop diagnostic; resource telemetry cannot establish exclusive reservation')
    samples, resources = [], []

    def save(name, obj):
        (evidence / name).write_text(json.dumps(obj, indent=2), encoding='utf8')

    save('environment.json', dict(platform=platform.uname()._asdict(), python=sys.version,
         invocation=sys.argv, manifest=manifest, payload_hashes_verified=len(manifest['files']),
         driver_sha256=sha(Path(__file__)), cpu_count=os.cpu_count(),
         compiler=original_run([str(runtime / 'bin/g++.exe'), '--version'],
                              capture_output=True, text=True, check=True).stdout,
         power_scheme=original_run(['powercfg', '/GETACTIVESCHEME'],
                                   capture_output=True).stdout.decode(errors='replace'),
         reservation=None, affinity=window.selection, power_policy_changed=False))
    save('result.json', result)
    window.previous = ticks()

    def observe(label):
        row = window.observe(label)
        resources.append(row)
        save('resources.json', resources)
        return row['eligible']

    try:
        process = None
        result.update(tier0='PASS (prior identical binaries, package and runtime checked)', tier1='pending')
        save('result.json', result)
        spec = importlib.util.spec_from_file_location('gates', pkg / 'candidate/optimization/server/run.py')
        gates = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(gates)
        for case in gates.CASES1:
            expected = int(case.rsplit('_', 1)[1])
            for mode in MODES:
                reference = None
                for rep in range(3):
                    for version in (['baseline', 'candidate'] if rep % 2 == 0 else ['candidate', 'baseline']):
                        label = f'{case}-{mode}-{rep+1}-{version}'
                        window.previous = ticks()
                        time.sleep(2)
                        if not observe(label + '-preflight'):
                            raise RuntimeError('CPU capacity guard before ' + label)
                        cmd = [str(binaries[version]), '-v', '-cpu-lim=180', '-' + mode,
                               cygpath(pkg / 'baseline/data/matrices' / case)]
                        start = time.perf_counter()
                        abort, watchdog = False, False
                        with (evidence / (label + '.stdout')).open('w', encoding='utf8') as so, \
                             (evidence / (label + '.stderr')).open('w', encoding='utf8') as se:
                            process = subprocess.Popen(cmd, cwd=pkg / version, stdout=so, stderr=se)
                            assert affinity(process._handle) == window.mask, "Parent affinity mismatch"
                            seen_affinities = []
                            last_resource = time.monotonic()
                            while process.poll() is None:
                                try:
                                    process.wait(timeout=0.25)
                                except subprocess.TimeoutExpired:
                                    seen = descendant_affinities(process.pid)
                                    seen_affinities += seen
                                    assert all(r["mask"] == window.mask for r in seen), "Child affinity mismatch"
                                    if time.monotonic() - last_resource >= 2:
                                        abort = not observe(label)
                                        last_resource = time.monotonic()
                                    watchdog = time.perf_counter() - start >= 195
                                    if abort or watchdog:
                                        killed = original_run(['taskkill', '/PID', str(process.pid), '/T', '/F'],
                                                              capture_output=True, text=True)
                                        save(label + '.kill.json', dict(returncode=killed.returncode,
                                             stdout=killed.stdout, stderr=killed.stderr))
                                        process.wait(timeout=15)
                                        break
                        save(label + ".affinity.json", seen_affinities)
                        semantic = gates.parse((evidence / (label + '.stdout')).read_text(encoding='utf8'))
                        samples.append(dict(case=case, mode=mode, version=version, repeat=rep+1,
                             command=cmd, cwd=str(pkg / version), elapsed_sec=time.perf_counter()-start,
                             returncode=process.returncode, resource_abort=abort,
                             external_timeout=watchdog, semantic=semantic))
                        save('samples.json', samples)
                        print(label, samples[-1]['elapsed_sec'], semantic, flush=True)
                        assert semantic['lb'] is None or semantic['lb'] <= expected, 'Invalid partial lower bound: ' + label
                        assert semantic['ub'] is None or semantic['ub'] >= expected, 'Invalid partial upper bound: ' + label
                        assert semantic['objective'] is None or semantic['objective'] >= expected, 'Invalid partial objective: ' + label
                        if abort or watchdog:
                            raise RuntimeError('Interrupted: ' + label)
                        assert process.returncode in [0, 1], 'Crash: ' + label
                        if semantic['d'] is not None:
                            assert all(semantic[k] == expected for k in ['d', 'objective', 'lb', 'ub']), 'Wrong result/bound: ' + label
                            assert not semantic['timeout'] and not semantic['unknown'], 'Wrong output semantics: ' + label
                        if process.returncode != 0 or semantic['d'] is None or semantic['timeout'] or semantic['unknown']:
                            raise RuntimeError('Timeout/incomplete: ' + label)
                        assert reference is None or semantic == reference, 'Semantic mismatch: ' + label
                        reference = semantic
        details, aggregates = [], {}
        for mode in MODES:
            ratios, envelopes = [], []
            for case in gates.CASES1:
                values = {v: [s['elapsed_sec'] for s in samples if s['case'] == case and s['mode'] == mode and s['version'] == v]
                          for v in ['baseline', 'candidate']}
                b, c = (statistics.median(values[v]) for v in ['baseline', 'candidate'])
                ratio, envelope = c/b, max(values['candidate'])/min(values['baseline'])
                ratios.append(ratio); envelopes.append(envelope)
                details.append(dict(case=case, mode=mode, raw=values, baseline_median=b,
                    candidate_median=c, median_ratio=ratio, range_envelope=envelope,
                    nonoverlapping_regression=min(values['candidate']) > max(values['baseline'])))
            gm = lambda xs: __import__('math').exp(sum(__import__('math').log(x) for x in xs)/len(xs))
            aggregates[mode] = dict(median_geomean=gm(ratios), range_envelope_geomean=gm(envelopes))
        numeric, reason, original_details = gates.judge(samples, gates.CASES1)
        result.update(tier1='48 correct diagnostic solves', medians=details, aggregates=aggregates,
                      numeric_filter=numeric, numeric_reason=reason, correctness='All expected distances/objectives/bounds identical')
    except AssertionError as error:
        result.update(decision='REJECTED', reason=str(error), stopped=True)
    except Exception as error:
        result.update(reason=repr(error), stopped=True)
    finally:
        if 'process' in locals() and process is not None and process.poll() is None:
            killed = original_run(['taskkill', '/PID', str(process.pid), '/T', '/F'], capture_output=True, text=True)
            save('exception-cleanup.json', dict(returncode=killed.returncode, stdout=killed.stdout, stderr=killed.stderr))
            process.wait(timeout=15)
        subprocess.run = original_run
        save('result.json', result)
    print(json.dumps(result, indent=2), flush=True)
    return 0 if 'medians' in result else 1


if __name__ == '__main__':
    try:
        code = main()
    finally:
        if WINDOW is not None:
            cleanup = WINDOW.close()
            if OUTPUT and (OUTPUT/'evidence').is_dir():
                (OUTPUT/'evidence/cleanup.json').write_text(json.dumps(cleanup, indent=2), encoding='utf8')
            print('WINDOW_CLEANUP', json.dumps(cleanup), flush=True)
    sys.exit(code)
