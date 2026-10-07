import hashlib, json, math, shutil, statistics
from pathlib import Path

taskdir = Path(__file__).resolve().parent.parent
repo = taskdir / 'DistQLDPC'
record = repo / 'optimization/experiments/E001'
tables = {}
for label, dirname in [('round_1', 'windows-validation'), ('round_2', 'windows-repeat-02')]:
    folder = record / 'raw' / dirname
    samples = json.loads((folder / 'samples.json').read_text(encoding='utf8'))
    assert len(samples) == 48
    assert json.loads((folder / 'tier0/summary.json').read_text())['status'] == 'PASS'
    comparisons = []
    for case in ['BB_90_8_10','GB_144_12_8','BB_108_8_10','LP_238_44_6']:
        for mode in ['no-card','card-mto']:
            groups = {}
            for version in ['baseline','candidate']:
                rows = [r for r in samples if r['case']==case and r['mode']==mode and r['version']==version]
                assert len(rows)==3
                expected = int(case.rsplit('_',1)[1])
                assert all(r['returncode']==0 and not r['watchdog'] and not r['semantic']['timeout'] and not r['semantic']['unknown'] and all(r['semantic'][k]==expected for k in ['d','objective','lb','ub']) for r in rows)
                groups[version] = [r['elapsed_sec'] for r in rows]
            b,c = groups['baseline'],groups['candidate']
            comparisons.append(dict(case=case,mode=mode,baseline_raw=b,candidate_raw=c,
                baseline_median=statistics.median(b),candidate_median=statistics.median(c),
                ratio=statistics.median(c)/statistics.median(b),baseline_min=min(b),baseline_max=max(b),
                candidate_min=min(c),candidate_max=max(c),disjoint_regression=min(c)>max(b)))
    tables[label]=comparisons
first,second = [record/'raw'/x for x in ['windows-validation','windows-repeat-02']]
assert json.loads((first/'environment.json').read_text())['binary_sha256']==json.loads((second/'environment.json').read_text())['binary_sha256']
geomeans={m:math.prod(r['ratio'] for r in tables['round_2'] if r['mode']==m)**0.25 for m in ['no-card','card-mto']}
tables.update(round_2_mode_geomeans=geomeans,all_96_results_correct=True,same_binaries=True,
    windows_numeric_filter='REJECT: GB regression reproduced',controlled_decision='INCONCLUSIVE',tier2='not reached',tier3='not run')
(second/'all-medians-and-comparison.json').write_text(json.dumps(tables,indent=2)+'\n',encoding='utf8')
shutil.copy2(taskdir/'windows-validation/repeat-02-driver.log',second/'driver.log')
scripts=second/'executed-scripts';scripts.mkdir(exist_ok=True)
for name in ['windows_repeat.py','windows_diagnostic.py']:
    shutil.copy2(repo/'optimization/server'/name,scripts/name)
shutil.copy2(Path(__file__),scripts/Path(__file__).name)
report='''# E001 Windows repeat 02 result

User-authorized repeat of unchanged H-001. Same baseline/candidate/probe binary
hashes; all 914 pinned package files verified. No rebuild, production-code,
compiler-flag, input, scientific or timeout/result-semantics change.
DistQLDPC with its embedded downstream MaxCDCL engine is compiled by Cygwin GCC
14.4.0 with original Makefile application flags; Cygwin provides Unix process
APIs. Native Windows Python with UTF-8 drives the unchanged Tier 0 harness,
adapting only native CLI paths for Unix executables. No solver porting patch.

Fresh Tier 0 PASS: 676 algebra inputs, exhaustive small CSS fixtures, smoke,
QDistSAT OFF/MTO pilot and timeout checks. All 48 new measured solves return
correct certified distance/objective/bounds. Combined local samples: 96.
No timing timeout/crash. Serial AB/BA/AB, three runs/version/case/mode;
180-second internal limit and 195-second watchdog; same full-wall-time metric.

| Case | Mode | Round 2 baseline median (s) | Candidate median (s) | Round 1 ratio | Round 2 ratio |
|---|---|---:|---:|---:|---:|
'''
for r1,r2 in zip(tables['round_1'],tables['round_2']):
    report+=f"| {r2['case']} | {r2['mode']} | {r2['baseline_median']:.4f} | {r2['candidate_median']:.4f} | {r1['ratio']:.4f} | {r2['ratio']:.4f} |\n"
report+='\nWindows numerical filter: **REJECT again**, because GB regresses in OFF/MTO.\n'
for r in tables['round_2']:
    if r['case']=='GB_144_12_8':
        report+=f"{r['mode']}: baseline range {r['baseline_min']:.4f}–{r['baseline_max']:.4f} s versus candidate {r['candidate_min']:.4f}–{r['candidate_max']:.4f} s.\n"
report+=f'\nEqual-weight median-ratio geomeans: OFF {geomeans["no-card"]:.5f}; MTO {geomeans["card-mto"]:.5f}. Do not mix modes or hide per-case regressions.\n'
report+='''
GB's observed regression persists in two separately invoked rounds; baseline
and candidate ranges are disjoint in both modes in both rounds. Fewer XOR gates
are insufficient to predict whole-solve speed; causal search mechanism unmeasured.
This desktop has no exclusive reservation, pinned core or fixed power policy.
No hardware-independence claim follows. Original controlled experiment remains
**INCONCLUSIVE**, no acceptance/merge, Tier 2 or Tier 3. Candidate stays isolated.
Another identical desktop repeat is lower priority than controlled reproduction
or analysis of existing GB search logs; no replacement hypothesis selected.

Raw second-round data: raw/windows-repeat-02/, including all outputs, samples,
environment, identity checks, Tier 0, medians/comparison and executed scripts.
Round 1 is untouched. A launcher attempt initially resolved a relative probe
path after changing working directory and failed before any solver test; that
attempt is separately retained under raw/windows-repeat-02-launcher-failure/.
After resolving the path earlier, all tests passed. No scientific mismatch.
'''
(record/'WINDOWS_REPEAT_02_RESULT.md').write_text(report,encoding='utf8')
overall=json.loads((record/'result.json').read_text())
overall['windows_repeat_02']=dict(tier0='PASS',raw_samples=48,combined_local_samples=96,same_binaries=True,
    numeric_filter='REJECT: GB regression reproduced',report='WINDOWS_REPEAT_02_RESULT.md',controlled_environment=False)
assert overall['decision']=='inconclusive'
(record/'result.json').write_text(json.dumps(overall,indent=2)+'\n',encoding='utf8')
for folder in [second,record/'raw/windows-repeat-02-launcher-failure']:
    (folder/'.gitattributes').write_text('* -text\n',encoding='utf8')
    manifest={str(p.relative_to(folder)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest()
        for p in sorted(folder.rglob('*')) if p.is_file() and p.name!='evidence-manifest.json'}
    (folder/'evidence-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
print(json.dumps(dict(new_runs=48,combined_runs=96,all_correct=True,same_binaries=True,
    local_numeric_filter='REJECT',geomeans=geomeans),indent=2))
