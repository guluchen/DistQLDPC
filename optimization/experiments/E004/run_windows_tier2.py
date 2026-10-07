#!/usr/bin/env python3
"""Fresh E004 Windows diagnostic; needs an already available Cygwin runtime."""
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
    for name in ['archive', 'cygwin-root', 'output']:
        ap.add_argument('--' + name, type=Path, required=True)
    args = ap.parse_args()
    assert platform.system() == 'Windows', 'Windows-only driver'
    runtime, archive, out = (args.cygwin_root.resolve(), args.archive.resolve(), args.output.resolve())
    for executable in ['bash.exe', 'g++.exe', 'make.exe']:
        if not (runtime / 'bin' / executable).is_file():
            raise SystemExit('Missing Cygwin dependency: ' + executable)
    assert sha(archive) == ARCHIVE_SHA, 'Archive identity mismatch'
    out.mkdir(parents=True, exist_ok=False)
    pkg = out / 'E004-server-package'
    with tarfile.open(archive) as tf:
        tf.extractall(out, filter='data')
    manifest = json.loads((pkg / 'manifest.json').read_text(encoding='utf8'))
    for relative, expected in manifest['files'].items():
        assert sha(pkg / relative) == expected, relative
    os.environ['PATH'] = str(runtime / 'bin') + os.pathsep + os.environ['PATH']
    os.environ.update(LC_ALL='C', OMP_NUM_THREADS='1', OPENBLAS_NUM_THREADS='1', MKL_NUM_THREADS='1')
    original_run = subprocess.run

    def adapted_run(argv, *rest, **kwargs):
        executable = str(runtime / 'bin/bash.exe') if str(argv[0]) == 'bash' else str(argv[0])
        return original_run([executable] + [cygpath(x) for x in argv[1:]], *rest, **kwargs)

    evidence = out / 'evidence'
    evidence.mkdir()
    result = dict(decision='INCONCLUSIVE', tier0='not run', tier2='not run', tier3='not run',
                  reason='Interactive desktop diagnostics cannot satisfy controlled gates')
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
         reservation=None, affinity=None, power_policy_changed=False))
    save('result.json', result)
    previous = cpu_ticks()

    def observe(label):
        nonlocal previous
        current = cpu_ticks()
        delta = current[1] - previous[1]
        idle = 100 * (current[0] - previous[0]) / delta if delta > 0 else 0
        previous = current
        resources.append(dict(label=label, time=time.time(), idle_percent=idle,
                              half_spare_logical_cpus=(os.cpu_count() or 1) * idle / 200))
        save('resources.json', resources)
        return idle > 50 and resources[-1]['half_spare_logical_cpus'] >= 1

    try:
        for version in ['baseline', 'candidate']:
            # No shell, no other build target, no reused objects. Flags come from the immutable Makefile.
            cmd = [str(runtime / 'bin/make.exe'), '-j1', 'LTO=' + str(int(version == 'candidate')),
                   'bin/distqldpc']
            build = original_run(cmd, cwd=pkg / version, capture_output=True, text=True, timeout=300)
            save('build-' + version + '.command.json', dict(argv=cmd, cwd=str(pkg / version),
                                                           returncode=build.returncode))
            for stream in ['stdout', 'stderr']:
                (evidence / ('build-' + version + '.' + stream)).write_text(getattr(build, stream), encoding='utf8')
            if build.returncode != 0:
                raise RuntimeError('Build/toolchain failure: ' + version)
        binaries = {v: pkg / v / 'bin/distqldpc.exe' for v in ['baseline', 'candidate']}
        save('binary-hashes.json', {v: sha(p) for v, p in binaries.items()})
        subprocess.run = adapted_run
        sys.argv = [str(pkg / 'candidate/optimization/tests/tier0_lto.py')]
        for key, value in dict(baseline=binaries['baseline'], candidate=binaries['candidate'],
                               qdistsat=pkg / 'qdistsat', out=evidence / 'tier0').items():
            sys.argv += ['--' + key, str(value)]
        try:
            runpy.run_path(sys.argv[0], run_name='__main__')
        finally:
            subprocess.run = original_run
        assert json.loads((evidence / 'tier0/summary.json').read_text(encoding='utf8'))['status'] == 'PASS'
        result.update(tier0='PASS', tier2='pending')
        save('result.json', result)
        spec = importlib.util.spec_from_file_location('gates', pkg / 'candidate/optimization/server/run.py')
        gates = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(gates)
        for mode in MODES:
            reference = None
            for rep in range(3):
                for version in (['baseline', 'candidate'] if rep % 2 == 0 else ['candidate', 'baseline']):
                    label = f'LP_340_56_8-{mode}-{rep+1}-{version}'
                    previous = cpu_ticks()
                    time.sleep(2)
                    if not observe(label + '-preflight'):
                        raise RuntimeError('CPU capacity guard before ' + label)
                    cmd = [str(binaries[version]), '-v', '-cpu-lim=600', '-' + mode,
                           cygpath(pkg / 'baseline/data/matrices/LP_340_56_8')]
                    start = time.perf_counter()
                    abort, watchdog = False, False
                    with (evidence / (label + '.stdout')).open('w', encoding='utf8') as so, \
                         (evidence / (label + '.stderr')).open('w', encoding='utf8') as se:
                        process = subprocess.Popen(cmd, cwd=pkg / version, stdout=so, stderr=se)
                        while process.poll() is None:
                            try:
                                process.wait(timeout=2)
                            except subprocess.TimeoutExpired:
                                abort = not observe(label)
                                watchdog = time.perf_counter() - start >= 615
                                if abort or watchdog:
                                    killed = original_run(['taskkill', '/PID', str(process.pid), '/T', '/F'],
                                                          capture_output=True, text=True)
                                    save(label + '.kill.json', dict(returncode=killed.returncode,
                                         stdout=killed.stdout, stderr=killed.stderr))
                                    process.wait(timeout=15)
                                    break
                    semantic = gates.parse((evidence / (label + '.stdout')).read_text(encoding='utf8'))
                    samples.append(dict(case='LP_340_56_8', mode=mode, version=version, repeat=rep+1,
                         command=cmd, cwd=str(pkg / version), elapsed_sec=time.perf_counter()-start,
                         returncode=process.returncode, resource_abort=abort,
                         external_timeout=watchdog, semantic=semantic))
                    save('samples.json', samples)
                    print(label, samples[-1]['elapsed_sec'], semantic, flush=True)
                    assert semantic['lb'] is None or semantic['lb'] <= 8, 'Invalid partial lower bound: ' + label
                    assert semantic['ub'] is None or semantic['ub'] >= 8, 'Invalid partial upper bound: ' + label
                    assert semantic['objective'] is None or semantic['objective'] >= 8, 'Invalid partial objective: ' + label
                    if abort or watchdog:
                        raise RuntimeError('Interrupted: ' + label)
                    assert process.returncode in [0, 1], 'Crash: ' + label
                    if semantic['d'] is not None:
                        assert all(semantic[k] == 8 for k in ['d', 'objective', 'lb', 'ub']), 'Wrong result/bound: ' + label
                        assert not semantic['timeout'] and not semantic['unknown'], 'Wrong output semantics: ' + label
                    if process.returncode != 0 or semantic['d'] is None or semantic['timeout'] or semantic['unknown']:
                        raise RuntimeError('Timeout/incomplete: ' + label)
                    assert reference is None or semantic == reference, 'Semantic mismatch: ' + label
                    reference = semantic
        medians = {}
        for mode in MODES:
            values = {v: [s['elapsed_sec'] for s in samples if s['mode'] == mode and s['version'] == v]
                      for v in ['baseline', 'candidate']}
            medians[mode] = dict(raw_timings=values,
                baseline_sec=statistics.median(values['baseline']),
                candidate_sec=statistics.median(values['candidate']),
                ratio=statistics.median(values['candidate'])/statistics.median(values['baseline']),
                range_envelope=max(values['candidate'])/min(values['baseline']))
        result.update(tier2='12 correct diagnostic solves', medians=medians,
                      correctness='d/objective/LB/UB=8 in both versions and modes')
    except AssertionError as error:
        result.update(decision='REJECTED', reason=str(error), stopped=True)
    except Exception as error:
        result.update(reason=repr(error), stopped=True)
    finally:
        subprocess.run = original_run
        save('result.json', result)
    print(json.dumps(result, indent=2), flush=True)
    return 0 if 'medians' in result else 1


if __name__ == '__main__':
    sys.exit(main())
