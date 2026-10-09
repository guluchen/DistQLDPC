#!/usr/bin/env python3
"""User-requested E004 Tier 3 pilot diagnostics on an occupied Linux server; never promote."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import platform
import signal
import statistics
import subprocess
import sys
import time


class CapacityLost(RuntimeError):
    pass


def cpu_times():
    return {line.split()[0]: list(map(int, line.split()[1:9]))
            for line in Path('/proc/stat').read_text().splitlines()
            if line.startswith('cpu')}


def idle_percent(before, after, cpu='cpu'):
    delta = [b-a for a, b in zip(before[cpu], after[cpu])]
    total = sum(delta)
    if total <= 0:
        return None
    return 100 * delta[3] / total  # iowait/steal are conservatively unavailable


def capacity_ok(idle, cpus, allocated=1):
    return idle is not None and idle > 50 and allocated <= cpus * idle / 100 / 2


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--package', type=Path, required=True)
    ap.add_argument('--output', type=Path, required=True)
    ap.add_argument('--prior-results', type=Path, required=True)
    ap.add_argument('--user-requested-tier3', action='store_true', required=True)
    ap.add_argument('--input-root', type=Path, required=True)
    ap.add_argument('--cpu', type=int, required=True)
    ap.add_argument('--sibling', type=int, required=True)
    ap.add_argument('--allow-core-contention', action='store_true',
                    help='Keep core contention as telemetry only for diagnostics; never promote')
    args = ap.parse_args()
    if platform.system() != 'Linux':
        ap.error('Linux /proc CPU accounting is required')
    allowed = sorted(os.sched_getaffinity(0))
    if args.cpu not in allowed or args.sibling not in allowed or args.cpu == args.sibling:
        ap.error('Choose a CPU and distinct SMT sibling from allowed affinity')
    actual_siblings = Path(f'/sys/devices/system/cpu/cpu{args.cpu}/topology/thread_siblings_list').read_text().strip()
    if actual_siblings != ','.join(map(str, sorted([args.cpu, args.sibling]))):
        ap.error('CPU pair does not match kernel SMT topology')
    os.sched_setaffinity(0, {args.cpu})  # children inherit this one-CPU ceiling
    pkg = args.package.resolve()
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    manifest = json.loads((pkg/'manifest.json').read_text())
    for path, expected in manifest['files'].items():
        if hashlib.sha256((pkg/path).read_bytes()).hexdigest() != expected:
            raise SystemExit('Package identity mismatch: '+path)
    spec = importlib.util.spec_from_file_location('e001', pkg/'candidate/optimization/server/run.py')
    runner = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(runner)
    env = dict(os.environ, OMP_NUM_THREADS='1', OPENBLAS_NUM_THREADS='1', MKL_NUM_THREADS='1', LC_ALL='C')
    cpus = os.cpu_count()
    telemetry, samples = [], []
    input_root = args.input_root.resolve()
    input_manifest = json.loads((input_root/'manifest.json').read_text())
    assert input_manifest['case'] == 'BB_144_12_12'
    for rel, expected in input_manifest['files'].items():
        assert hashlib.sha256((input_root/rel).read_bytes()).hexdigest() == expected, rel
    summary = {'decision':'inconclusive', 'reason':'Occupied-host diagnostics; no exclusive reservation',
               'tiers':{}, 'controlled_performance':False, 'samples':0}
    environment = {'uname':platform.uname()._asdict(), 'allowed_cpus':allowed,
                   'cpu':args.cpu, 'sibling':args.sibling, 'thread_siblings':actual_siblings,
                   'affinity':list(os.sched_getaffinity(0)), 'load_start':os.getloadavg(),
                   'resource_rule':'idle > 50%; allocated CPUs <= half idle capacity',
                   'allow_core_contention':args.allow_core_contention,
                   'manifest':manifest, 'input_manifest':input_manifest, 'driver_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    for path in ['/proc/cpuinfo', '/proc/meminfo', f'/sys/devices/system/cpu/cpu{args.cpu}/cpufreq/scaling_governor']:
        try:
            environment[path] = Path(path).read_text()
        except OSError:
            environment[path] = None
    (out/'environment.json').write_text(json.dumps(environment, indent=2))

    def save():
        (out/'decision.json').write_text(json.dumps(summary, indent=2))
        (out/'samples.json').write_text(json.dumps(samples, indent=2))
        (out/'capacity.json').write_text(json.dumps(telemetry, indent=2))

    def check(before, after, label, phase):
        idle = idle_percent(before, after)
        sibling = idle_percent(before, after, f'cpu{args.sibling}')
        selected = idle_percent(before, after, f'cpu{args.cpu}')
        row = {'label':label, 'phase':phase, 'time':time.time(), 'idle_percent':idle,
               'selected_cpu_idle_percent':selected, 'sibling_idle_percent':sibling,
               'half_idle_cpus':cpus * (idle or 0) / 200,
               'load':os.getloadavg()}
        contention = ((sibling is not None and sibling < 95)
                      or (phase == 'before' and selected is not None and selected < 95))
        row['core_contention_detected'] = contention
        telemetry.append(row)
        if not capacity_ok(idle, cpus) or (contention and not args.allow_core_contention):
            raise CapacityLost('Capacity/sibling guard failed: '+json.dumps(row))

    def command(cmd, cwd, label, watchdog):
        before = cpu_times()
        time.sleep(2)
        check(before, cpu_times(), label, 'before')
        command_record = {'argv':list(map(str, cmd)), 'cwd':str(cwd), 'watchdog_sec':watchdog}
        (out/(label+'.command.json')).write_text(json.dumps(command_record, indent=2))
        print('START '+label, flush=True)
        start = time.perf_counter()
        deadline = start + watchdog
        external_timeout = False
        resource_abort = None
        with (out/(label+'.stdout')).open('w') as so, (out/(label+'.stderr')).open('w') as se:
            proc = subprocess.Popen(list(map(str, cmd)), cwd=cwd, env=env,
                                    stdout=so, stderr=se, start_new_session=True)
            before = cpu_times()
            while True:
                remaining = deadline-time.perf_counter()
                if remaining <= 0:
                    external_timeout = True
                    os.killpg(proc.pid, signal.SIGKILL)
                    rc = proc.wait()
                    break
                try:
                    rc = proc.wait(timeout=min(2, remaining))
                    break
                except subprocess.TimeoutExpired:
                    after = cpu_times()
                    try:
                        check(before, after, label, 'during')
                    except CapacityLost as exc:
                        resource_abort = str(exc)
                        os.killpg(proc.pid, signal.SIGKILL)
                        rc = proc.wait()
                        break
                    before = after
        elapsed = time.perf_counter()-start
        command_record.update(returncode=rc, elapsed_sec=elapsed,
                              external_timeout=external_timeout, resource_abort=resource_abort)
        (out/(label+'.command.json')).write_text(json.dumps(command_record, indent=2))
        save()
        if resource_abort:
            raise CapacityLost(resource_abort)
        return rc, elapsed, external_timeout

    save()
    try:
        prior = args.prior_results.resolve()
        prior_decision = json.loads((prior/'decision.json').read_text())
        identities = json.loads((prior/'build-identities.json').read_text())
        if prior_decision['tiers'].get('0') != 'PASS':
            raise RuntimeError('Prior Tier 0 is not PASS')
        if identities['baseline'] != manifest['baseline'] or identities['candidate'] != manifest['candidate']:
            raise RuntimeError('Prior source identities differ from package')
        expected_hashes = {'baseline':'055e973e88cc0bb47dfeea236799b02c05d8f2d19b7a50a049125f9057223c0f',
                           'candidate':'9923009bb57c1f5ce5c5bfdede9af1b490f944e94f0a1731e0a85da5f0af9cca'}
        for version, expected in expected_hashes.items():
            actual = hashlib.sha256((pkg/version/'bin/distqldpc').read_bytes()).hexdigest()
            if actual != expected or identities['binaries'][version]['sha256'] != expected:
                raise RuntimeError('Reused binary mismatch: '+version)
        summary['tiers']['0'] = 'PASS (reused matching source/binary identities)'
        summary['tiers']['1'] = {'numerical_diagnostic':'inconclusive', 'source':str(prior)}
        summary['scope'] = 'User-authorized Tier3 exploratory pilot, one case, four bounded runs; lower tiers not relabeled PASS'
        (out/'prior-validation.json').write_text(json.dumps({'prior_decision':prior_decision,
            'binary_identities':identities,'expected_hashes':expected_hashes},indent=2))
        save()
        for case in ['BB_144_12_12']:
            for mode in runner.MODES:
                reference = None
                for rep in range(1):
                    for version in (('baseline','candidate') if rep%2 == 0 else ('candidate','baseline')):
                        label = f'tier3-{case}-{mode}-{rep+1}-{version}'
                        cmd = [pkg/version/'bin/distqldpc','-v','-cpu-lim=600','-'+mode,input_root/case]
                        rc, elapsed, watchdog = command(cmd, pkg/version, label, 615)
                        semantic = runner.parse((out/(label+'.stdout')).read_text())
                        row = {'tier':3, 'case':case, 'mode':mode, 'repeat':rep+1, 'version':version,
                               'command':list(map(str,cmd)), 'elapsed_sec':elapsed, 'returncode':rc,
                               'watchdog':watchdog, 'semantic':semantic, 'load_after':os.getloadavg()}
                        samples.append(row)
                        print(label, rc, elapsed, semantic, flush=True)
                        summary['samples'] = len(samples)
                        save()
                        if not watchdog and (rc < 0 or rc not in (0,1)):
                            summary.update(decision='reject', reason='Unexpected solver crash: '+label)
                            save()
                            return 2
                        if semantic['d'] is not None and (semantic['objective'] != semantic['d'] or semantic['lb'] != semantic['d'] or semantic['ub'] != semantic['d']):
                            summary.update(decision='reject', reason='Malformed exact result: '+label)
                            save()
                            return 2
                        if (semantic['objective'] is not None and semantic['objective'] < 12) or (semantic['lb'] is not None and semantic['lb'] > 12) or (semantic['ub'] is not None and semantic['ub'] < 12):
                            summary.update(decision='reject', reason='Wrong BB144 bound: '+label)
                            save()
                            return 2
                        if watchdog:
                            raise RuntimeError('External watchdog: '+label)
                        complete = rc == 0 and semantic['d'] is not None and not semantic['timeout'] and not semantic['unknown']
                        internal_timeout = rc == 1 and semantic['d'] is None and semantic['timeout'] and semantic['unknown']
                        if not complete and not internal_timeout:
                            summary.update(decision='reject', reason='Unexpected output/timeout semantics: '+label)
                            save();return 2
                        if internal_timeout:
                            continue  # paired pilot still runs; no completed-time comparison
                        if semantic['d'] is not None and semantic['d'] != 12:
                            summary.update(decision='reject', reason='Wrong BB144 distance: '+label)
                            save()
                            return 2
                        if reference is not None and semantic != reference:
                            summary.update(decision='reject', reason='Scientific result mismatch: '+label)
                            save()
                            return 2
                        reference = semantic
        pairs = []
        for mode in runner.MODES:
            rows = [r for r in samples if r['mode'] == mode]
            complete = all(r['returncode']==0 and r['semantic']['d']==12 and not r['semantic']['timeout'] and not r['semantic']['unknown'] for r in rows)
            timings = {r['version']:r['elapsed_sec'] for r in rows}
            pairs.append({'mode':mode,'both_complete':complete,'timings_sec':timings,
                          'candidate_over_baseline':timings['candidate']/timings['baseline'] if complete else None,
                          'medians':None, 'results':rows})
        summary['tiers']['3-pilot'] = {'pairs':pairs, 'repeat_count':1, 'medians':None}
        summary.update(reason='Four bounded exploratory Tier3 runs finished; partial timeouts kept, no controlled promotion or decisive-suite claim.')
        save()
        return 0
    except Exception as exc:
        summary.update(reason=str(exc))
        save()
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
