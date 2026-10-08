"""Independently check the completed four-run H-007 BB144 pilot evidence."""
import argparse
import hashlib
import json
import re
from pathlib import Path


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('evidence', type=Path)
    args = ap.parse_args()
    root = args.evidence
    load = lambda name: json.loads((root/name).read_text(encoding='utf8'))
    rows = load('samples.json')
    env = load('environment.json')
    decision = load('decision.json')
    assert len(rows) == 4, 'Incomplete pilot: retain raw evidence; no paired conclusion'
    assert env['affinity'] == [env['cpu']]
    assert decision['controlled_performance'] is False
    assert decision['decision'] == 'inconclusive'
    prior = load('prior-validation.json')
    identities = prior['binary_identities']
    assert prior['prior_decision']['tiers']['0'] == 'PASS'
    assert identities['binaries']['baseline']['sha256'] == '055e973e88cc0bb47dfeea236799b02c05d8f2d19b7a50a049125f9057223c0f'
    assert identities['binaries']['candidate']['sha256'] == '9923009bb57c1f5ce5c5bfdede9af1b490f944e94f0a1731e0a85da5f0af9cca'
    assert env['driver_sha256'] == hashlib.sha256((root/'idle_tier3_pilot_lto.py').read_bytes()).hexdigest()
    order = [(m, v) for m in ['no-card', 'card-mto'] for v in ['baseline', 'candidate']]
    assert [(r['mode'], r['version']) for r in rows] == order
    complete = 0
    for row in rows:
        label = f"tier3-BB_144_12_12-{row['mode']}-1-{row['version']}"
        command = load(label+'.command.json')
        assert row['command'] == command['argv']
        assert row['command'][1:4] == ['-v', '-cpu-lim=600', '-'+row['mode']]
        assert command['watchdog_sec'] == 615 and not command['external_timeout'] and not command['resource_abort']
        assert command['returncode'] == row['returncode'] and command['elapsed_sec'] == row['elapsed_sec']
        output = (root/(label+'.stdout')).read_text(encoding='utf8')
        patterns = {'d': r'^c\s+d\s*:\s*(\d+)\s*$', 'objective': r'^o\s+(-?\d+)\s*$',
                    'lb': r'^c\s+d_lb:\s*(\d+)\s*$', 'ub': r'^c\s+d_ub:\s*(\d+)\s*$'}
        for key, pattern in patterns.items():
            values = list(map(int, re.findall(pattern, output, re.M)))
            assert row['semantic'][key] == (values[-1] if values else None)
            assert all(v <= 12 if key == 'lb' else v >= 12 for v in values)
        timed_out = 'c status: TIMEOUT' in output
        unknown = 's UNKNOWN' in output
        assert row['semantic']['timeout'] == timed_out and row['semantic']['unknown'] == unknown
        if row['returncode'] == 0:
            assert not timed_out and not unknown
            assert all(row['semantic'][key] == 12 for key in patterns)
            complete += 1
        else:
            assert row['returncode'] == 1 and timed_out and unknown and row['semantic']['d'] is None
    pairs = []
    for mode in ['no-card', 'card-mto']:
        b, c = [r for r in rows if r['mode'] == mode]
        ratio = c['elapsed_sec']/b['elapsed_sec'] if b['returncode'] == c['returncode'] == 0 else None
        saved = next(p for p in decision['tiers']['3-pilot']['pairs'] if p['mode'] == mode)
        assert saved['candidate_over_baseline'] == ratio and saved['medians'] is None
        names = [f'tier3-BB_144_12_12-{mode}-1-{v}.stdout' for v in ['baseline', 'candidate']]
        equal_stdout = (root/names[0]).read_bytes() == (root/names[1]).read_bytes()
        pairs.append(dict(mode=mode, baseline_sec=b['elapsed_sec'], candidate_sec=c['elapsed_sec'], ratio=ratio,
                          stdout_byte_identical=equal_stdout))
    resources = load('capacity.json')
    assert resources and all(r['idle_percent'] > 50 and r['half_idle_cpus'] >= 1 for r in resources)
    resource_detail = []
    for row in rows:
        label = f"tier3-BB_144_12_12-{row['mode']}-1-{row['version']}"
        checks = [r for r in resources if r['label'] == label]
        resource_detail.append(dict(label=label, checks=len(checks),
                                   contention_checks=sum(r['core_contention_detected'] for r in checks),
                                   min_global_idle=min(r['idle_percent'] for r in checks),
                                   min_sibling_idle=min(r['sibling_idle_percent'] for r in checks)))
    result = dict(audit='PASS', complete_solves=complete, internal_timeouts=4-complete,
                  pairs=pairs, min_observed_idle=min(r['idle_percent'] for r in resources),
                  resource_checks=len(resources), contention_checks=sum(r['core_contention_detected'] for r in resources),
                  per_run_resources=resource_detail,
                  decision='INCONCLUSIVE', reason='Singleton occupied-host pilot; no controlled promotion', medians=None)
    (root/'independent-audit.json').write_text(json.dumps(result, indent=2), encoding='utf8', newline='\n')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
