import csv
import hashlib
import json
import math
from pathlib import Path
import shutil
import statistics
import sys

taskdir = Path(__file__).resolve().parent.parent
repo = taskdir / 'DistQLDPC'
record = repo / 'optimization/experiments/E001'
out = record / 'raw/windows-validation'
samples = json.loads((out / 'samples.json').read_text())
assert len(samples) == 48
assert json.loads((out / 'tier0/summary.json').read_text())['status'] == 'PASS'
medians = []
for case in ['BB_90_8_10', 'GB_144_12_8', 'BB_108_8_10', 'LP_238_44_6']:
    for mode in ['no-card', 'card-mto']:
        groups = {}
        for version in ['baseline', 'candidate']:
            rows = [s for s in samples if s['case'] == case and s['mode'] == mode and s['version'] == version]
            assert len(rows) == 3
            expected = int(case.rsplit('_', 1)[1])
            assert all(s['returncode'] == 0 and not s['watchdog'] and
                       not s['semantic']['timeout'] and not s['semantic']['unknown'] and
                       all(s['semantic'][k] == expected for k in ['d', 'objective', 'lb', 'ub']) for s in rows)
            groups[version] = [s['elapsed_sec'] for s in rows]
        b, c = groups['baseline'], groups['candidate']
        medians.append({'case': case, 'mode': mode,
            'baseline_raw': b, 'candidate_raw': c,
            'baseline_median': statistics.median(b), 'candidate_median': statistics.median(c),
            'candidate_over_baseline': statistics.median(c)/statistics.median(b),
            'baseline_min': min(b), 'baseline_max': max(b),
            'candidate_min': min(c), 'candidate_max': max(c),
            'disjoint_regression': min(c) > max(b)})
aggregate = {m: math.prod(r['candidate_over_baseline'] for r in medians if r['mode'] == m)**0.25
             for m in ['no-card', 'card-mto']}
(out / 'all-medians.json').write_text(json.dumps({'comparisons': medians,
    'mode_geomean_ratios': aggregate}, indent=2), encoding='utf8')
with (out / 'all-medians.csv').open('w', newline='', encoding='utf8') as f:
    writer = csv.DictWriter(f, fieldnames=list(medians[0]))
    writer.writeheader()
    writer.writerows(medians)
scripts = out / 'executed-scripts'
scripts.mkdir(exist_ok=True)
for name in ['run-validation.sh', 'run-checks.sh', 'run-native-checks.py', 'finalize-evidence.py']:
    shutil.copy2(taskdir / 'windows-validation' / name, scripts / name)
shutil.copy2(repo / 'optimization/server/windows_diagnostic.py', scripts / 'windows_diagnostic.py')
shutil.copy2(taskdir / 'windows-validation/cygwin/var/log/setup.log', out / 'cygwin-setup.log')
shutil.copy2(taskdir / 'windows-validation/sha512.sum', out / 'official-installer-sha512.sum')
native = {'executable': sys.executable, 'version': sys.version,
          'sha256': hashlib.sha256(Path(sys.executable).read_bytes()).hexdigest(),
          'probe_sha256': hashlib.sha256((out / 'probe.exe').read_bytes()).hexdigest()}
(out / 'native-python.json').write_text(json.dumps(native, indent=2), encoding='utf8')
result = json.loads((record / 'result.json').read_text())
result['windows_continuation'] = {'tier0': 'PASS', 'diagnostic_samples': 48,
    'numeric_tier1_filter': 'REJECT: GB_144_12_8 regression in both modes',
    'medians': 'raw/windows-validation/all-medians.json',
    'raw_samples': 'raw/windows-validation/samples.json', 'report': 'WINDOWS_RESULT.md',
    'tier2': 'not reached', 'tier3': 'not run',
    'scientific_semantics_match': True, 'controlled_environment': False}
assert result['decision'] == 'inconclusive'
(record / 'result.json').write_text(json.dumps(result, indent=2)+'\n', encoding='utf8')
(out / '.gitattributes').write_text('* -text\n', encoding='utf8')
(out / '.gitignore').write_text('/probe.exe\n', encoding='utf8')
files = {str(p.relative_to(out)).replace('\\', '/'): hashlib.sha256(p.read_bytes()).hexdigest()
         for p in sorted(out.rglob('*')) if p.is_file() and p.name not in ['evidence-manifest.json', 'probe.exe']}
(out / 'evidence-manifest.json').write_text(json.dumps(files, indent=2), encoding='utf8')
print(json.dumps({'raw_runs': len(samples), 'all_correct': True,
    'evidence_files': len(files), 'local_geomeans': aggregate,
    'diagnostic_gate': 'REJECT', 'controlled_decision': 'INCONCLUSIVE'}, indent=2))
