"""Independently inspect completed Windows evidence without invoking a solver."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import statistics


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    root = args.run.resolve()
    evidence, package = root / 'evidence', root / 'E004-server-package'
    read = lambda p: json.loads(p.read_text(encoding='utf8'))
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    manifest = read(package / 'manifest.json')
    for relative, expected in manifest['files'].items():
        assert sha(package / relative) == expected, relative
    for folder in ['src', 'data']:
        for baseline in (package / 'baseline' / folder).rglob('*'):
            if baseline.is_file():
                assert baseline.read_bytes() == (package / 'candidate' / baseline.relative_to(package / 'baseline')).read_bytes()
    for version in ['baseline', 'candidate']:
        commands = [line for line in (evidence / ('build-' + version + '.stdout')).read_text(encoding='utf8').splitlines()
                    if line.startswith('g++ ')]
        assert len(commands) == 5
        assert all(('-flto=1' in command) == (version == 'candidate') for command in commands)
    for version, expected in read(evidence / 'binary-hashes.json').items():
        assert sha(package / version / 'bin/distqldpc.exe') == expected, version
    assert read(evidence / 'tier0/summary.json')['status'] == 'PASS'
    exports = read(evidence / 'tier0/exports.json')
    assert len(exports) == 6
    for export in exports:
        for version in ['baseline', 'candidate']:
            path = evidence / 'tier0' / (export['case'] + '-' + version + '.wcnf')
            assert sha(path) == export['sha256'] and path.stat().st_size == export['bytes']
    for row in read(evidence / 'tier0/cross-repo.json'):
        expected = int(row['stem'].rsplit('_', 1)[1])
        assert len(row['runs']) == 2
        for run in row['runs']:
            assert run['returncode'] == 0 and not run['timed_out']
            assert all(run[k] == expected for k in ['d', 'objective', 'd_lb', 'd_ub'])
    samples = read(evidence / 'samples.json')
    assert len(samples) == 12, 'Incomplete diagnostic; do not infer medians'
    for mode in ['no-card', 'card-mto']:
        rows = [s for s in samples if s['mode'] == mode]
        assert [(s['repeat'], s['version']) for s in rows] == [
            (1, 'baseline'), (1, 'candidate'), (2, 'candidate'),
            (2, 'baseline'), (3, 'baseline'), (3, 'candidate')]
    for sample in samples:
        assert sample['returncode'] == 0 and not sample['resource_abort'] and not sample['external_timeout']
        label = f"LP_340_56_8-{sample['mode']}-{sample['repeat']}-{sample['version']}"
        output = (evidence / (label + '.stdout')).read_text(encoding='utf8')
        for pattern, key in [(r'^c\s+d\s*:\s*(\d+)\s*$', 'd'),
                             (r'^o\s+(-?\d+)\s*$', 'objective'),
                             (r'^c\s+d_lb:\s*(\d+)\s*$', 'lb'),
                             (r'^c\s+d_ub:\s*(\d+)\s*$', 'ub')]:
            values = list(map(int, re.findall(pattern, output, re.M)))
            assert values and values[-1] == 8 and sample['semantic'][key] == 8, label
            if key == 'lb':
                assert all(value <= 8 for value in values), label
            else:
                assert all(value >= 8 for value in values), label
        assert 's UNKNOWN' not in output and 'c status: TIMEOUT' not in output, label
    resources = read(evidence / 'resources.json')
    assert resources and all(r['idle_percent'] > 50 and r['half_spare_logical_cpus'] >= 1 for r in resources)
    medians = {}
    for mode in ['no-card', 'card-mto']:
        timings = {v: [s['elapsed_sec'] for s in samples if s['mode'] == mode and s['version'] == v]
                   for v in ['baseline', 'candidate']}
        b, c = (statistics.median(timings[v]) for v in ['baseline', 'candidate'])
        medians[mode] = dict(raw=timings, baseline_sec=b, candidate_sec=c, ratio=c/b,
                            range_envelope=max(timings['candidate'])/min(timings['baseline']),
                            nonoverlapping_regression=min(timings['candidate']) > max(timings['baseline']))
        recorded = read(evidence / 'result.json')['medians'][mode]
        assert recorded['baseline_sec'] == b and recorded['candidate_sec'] == c and recorded['ratio'] == c/b
    result = dict(audit='PASS', tier0='PASS', correct_solves=12, medians=medians,
                  min_observed_idle=min(r['idle_percent'] for r in resources), resource_checks=len(resources),
                  decision='INCONCLUSIVE', reason='Interactive desktop; controlled Tier 1 gates remain unmet',
                  tier3='not run', scientific_semantics_changed=False)
    (evidence / 'independent-audit.json').write_text(json.dumps(result, indent=2), encoding='utf8', newline='\n')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
