"""Extend the independent Tier1 scientific audit with per-core setup checks."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import audit_windows_tier1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('run', type=Path)
    ap.add_argument('--prior', type=Path, required=True)
    ap.add_argument('--probe', type=Path, required=True)
    a = ap.parse_args()
    sys.argv = [sys.argv[0], str(a.run), '--prior', str(a.prior)]
    audit_windows_tier1.main()
    e = a.run/'evidence'
    load = lambda name: json.loads((e/name).read_text(encoding='utf8'))
    audited = load('independent-audit.json')
    setup = load('environment.json')['affinity']
    assert setup['mask'] == 1 << setup['selected_cpu']
    assert [setup['selected_cpu'], setup['sibling']] in setup['topology']
    assert not setup['exclusive_reservation'] and not setup['power_policy_changed']
    assert load('cleanup.json') == dict(affinity_restored=True, sleep_requirement_restored=True,
                                        final_mask=setup['original_affinity'], job_limit_released=True)
    assert load('environment.json')['driver_sha256'] == hashlib.sha256((e/'executed-driver.py').read_bytes()).hexdigest()
    probe = json.loads((a.probe/'probe.json').read_text(encoding='utf8'))
    assert probe['cleanup']['affinity_restored'] and probe['cleanup']['sleep_requirement_restored']
    spec = importlib.util.spec_from_file_location('gates', a.prior/'E004-server-package/candidate/optimization/server/run.py')
    gates = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gates)
    for row in probe['records']:
        assert row['returncode'] == 1 and row['child_observed']
        assert row['affinities'] and all(r['mask'] == probe['selection']['mask'] for r in row['affinities'])
        parsed = gates.parse((a.probe/(row['version']+'.stdout')).read_text(encoding='utf8'))
        assert parsed['d'] is None and parsed['timeout'] and parsed['unknown']
        assert parsed['lb'] is None or parsed['lb'] <= 10
        assert parsed['ub'] is None or parsed['ub'] >= 10
        assert parsed['objective'] is None or parsed['objective'] >= 10
    observations = load('resources.json')
    assert all(r['affinity'] == setup['mask'] and r['eligible'] for r in observations)
    per_run = []
    for row in load('samples.json'):
        label = f"{row['case']}-{row['mode']}-{row['repeat']}-{row['version']}"
        masks = load(label+'.affinity.json')
        assert masks and all(r['mask'] == setup['mask'] for r in masks)
        assert len({r['pid'] for r in masks}) >= 2, 'Parent and fork child must both be observed'
        checks = [r for r in observations if r['label'] == label or r['label'].startswith(label+'-')]
        per_run.append(dict(label=label, observations=len(checks),
                            contention_observations=sum(r['core_contention_detected'] for r in checks),
                            min_sibling_idle=min(r['sibling_idle'] for r in checks)))
    audited.update(affinity_audit='PASS', selected_cpu=setup['selected_cpu'], sibling=setup['sibling'],
                   contention_observations=sum(r['core_contention_detected'] for r in observations),
                   per_run_resources=per_run, restoration='PASS',
                   reason='Fixed affinity verified, but interactive desktop has unreserved background interference')
    (e/'independent-audit.json').write_text(json.dumps(audited, indent=2), encoding='utf8', newline='\n')
    print(json.dumps({k: v for k, v in audited.items() if k not in ['medians', 'per_run_resources']}, indent=2))


if __name__ == '__main__':
    main()
