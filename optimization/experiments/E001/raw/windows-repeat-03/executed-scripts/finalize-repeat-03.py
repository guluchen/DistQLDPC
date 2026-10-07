import hashlib, json, math, re, shutil, statistics
from pathlib import Path

taskdir=Path(__file__).resolve().parent.parent
repo=taskdir/'DistQLDPC';record=repo/'optimization/experiments/E001'
raw=record/'raw/windows-repeat-03'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
tables={}
for label,dirname in [('round_1','windows-validation'),('round_2','windows-repeat-02'),('round_3','windows-repeat-03')]:
    folder=record/'raw'/dirname
    samples=json.loads((folder/'samples.json').read_text(encoding='utf8'))
    assert len(samples)==48
    assert json.loads((folder/'tier0/summary.json').read_text(encoding='utf8'))['status']=='PASS'
    comparisons=[]
    for case in ['BB_90_8_10','GB_144_12_8','BB_108_8_10','LP_238_44_6']:
        for mode in ['no-card','card-mto']:
            groups={}
            for version in ['baseline','candidate']:
                rows=[r for r in samples if r['case']==case and r['mode']==mode and r['version']==version]
                assert len(rows)==3
                expected=int(case.rsplit('_',1)[1])
                assert all(r['returncode']==0 and not r['watchdog'] and not r['semantic']['timeout'] and not r['semantic']['unknown'] and all(r['semantic'][k]==expected for k in ['d','objective','lb','ub']) for r in rows)
                groups[version]=[r['elapsed_sec'] for r in rows]
            b,c=groups['baseline'],groups['candidate']
            comparisons.append(dict(case=case,mode=mode,baseline_raw=b,candidate_raw=c,
                baseline_median=statistics.median(b),candidate_median=statistics.median(c),
                ratio=statistics.median(c)/statistics.median(b),baseline_min=min(b),baseline_max=max(b),
                candidate_min=min(c),candidate_max=max(c),disjoint_regression=min(c)>max(b)))
    tables[label]=comparisons
first=record/'raw/windows-validation'
for dirname in ['windows-repeat-02','windows-repeat-03']:
    assert json.loads((first/'environment.json').read_text(encoding='utf8'))['binary_sha256']==json.loads((record/'raw'/dirname/'environment.json').read_text(encoding='utf8'))['binary_sha256']
geomeans={m:math.prod(r['ratio'] for r in tables['round_3'] if r['mode']==m)**0.25 for m in ['no-card','card-mto']}
local=json.loads((raw/'result.json').read_text(encoding='utf8'))
numeric=local['tier1']['numeric_filter'].upper()
metrics=[]
for row in samples:
    name=f"tier1-{row['case']}-{row['mode']}-{row['repeat']}-{row['version']}.stdout"
    text=(raw/name).read_text(encoding='utf8')
    failed=re.findall(r'^c UB=(\d+) fails, cnfls=(\d+), hcnfls=(\d+)',text,re.M)
    hard=re.findall(r'hardConflicts: (\d+)',text)
    lk=re.findall(r'^c nbLK: (\d+),.*?nbLKup: (\d+)',text,re.M)
    metrics.append(dict(case=row['case'],mode=row['mode'],repeat=row['repeat'],version=row['version'],
        source=name,last_failed_UB_counters=list(map(int,failed[-1])) if failed else None,
        final_hardConflicts=int(hard[-1]) if hard else None,
        final_nbLK_nbLKup=list(map(int,lk[-1])) if lk else None))
(raw/'solver-counters.json').write_text(json.dumps(metrics,indent=2)+'\n',encoding='utf8')
tables.update(platform='Windows/Cygwin',round_3_mode_geomeans=geomeans,
    all_144_results_correct=True,same_binaries=True,windows_numeric_filter=numeric,
    original_controlled_decision='INCONCLUSIVE',tier2='not reached',tier3='not run')
(raw/'all-medians-and-comparison.json').write_text(json.dumps(tables,indent=2)+'\n',encoding='utf8')
shutil.copy2(taskdir/'windows-validation/repeat-03-driver.log',raw/'driver.log')
scripts=raw/'executed-scripts';scripts.mkdir(exist_ok=True)
for name in ['windows_repeat.py','windows_diagnostic.py']:
    shutil.copy2(repo/'optimization/server'/name,scripts/name)
shutil.copy2(Path(__file__),scripts/Path(__file__).name)
report=f'''# E001 Windows repeat 03 result

**Results obtained on Windows/Cygwin. Windows Tier 1 numerical decision: {numeric}.**

User explicitly requested this Windows execution. Same baseline/candidate/probe
hashes and all 914 package source payloads verified; no rebuild or implementation
change. Baseline 24572d6, E001 candidate code 50623f9, snapshot 9d68f45,
QDistSAT 7c4774f. DistQLDPC includes its downstream MaxCDCL engine; it is not
standalone upstream MaxCDCL. No E002/E003 changes combined.

Windows 11 / Cygwin 3.6.11, GCC 14.4 original application Makefile flags. Native
Python with UTF-8 drives the existing Tier 0 harness and adapts Unix CLI paths.
Cygwin provides POSIX fork/pipe/signals for unchanged application code. Host CPU,
OS, power plan and process inventory in raw/windows-repeat-03/windows-host.json;
compiler/binary hashes and input manifest in environment.json/identity-check.json.

Fresh Tier 0 PASS: 676 algebra cases, exhaustive CSS d=2/d=1, default/OFF/MTO,
smoke, pinned QDistSAT OFF/MTO pilot, six forced timeouts. All 48 new Tier 1
solves have certified correct distance/objective/lower/upper bounds (144 across
three rounds). No crash/timeout or discarded sample. Serial AB/BA/AB, three per
version/case/mode, 180s internal limit/195s watchdog, verbose output redirected;
same full wall-time metric and unchanged preregistered numerical judge.

| Case | Mode | Baseline median (s) | Candidate median (s) | Round 1 ratio | Round 2 ratio | Round 3 ratio |
|---|---|---:|---:|---:|---:|---:|
'''
for r1,r2,r3 in zip(tables['round_1'],tables['round_2'],tables['round_3']):
    report+=f"| {r3['case']} | {r3['mode']} | {r3['baseline_median']:.4f} | {r3['candidate_median']:.4f} | {r1['ratio']:.4f} | {r2['ratio']:.4f} | {r3['ratio']:.4f} |\n"
report+=f'\nRound 3 median-ratio geomeans: OFF {geomeans["no-card"]:.5f}; MTO {geomeans["card-mto"]:.5f}.\n'
for r in tables['round_3']:
    if r['disjoint_regression']:
        report+=f"Disjoint Windows regression: {r['case']} {r['mode']}, baseline {r['baseline_min']:.4f}–{r['baseline_max']:.4f} s, candidate {r['candidate_min']:.4f}–{r['candidate_max']:.4f} s.\n"
report+='''
## Interpretation

This is Windows-derived local evidence. Interactive host, no exclusive reservation,
fixed power policy or pinned CPU. Record the local numerical outcome as such;
do not turn it into Linux/dedicated or hardware-independent evidence. Preserve
all earlier samples and mode-specific regressions, not just aggregate speed.
Original controlled performance status remains INCONCLUSIVE. No Tier 2/3,
acceptance, merge or fresh Brain round. Scientific semantics unchanged.

Row shortening demonstrably reduces raw logical XOR gates; whole-solve runtime
is family-dependent locally. The causal effect on search versus construction
is not isolated. If GB regresses again, this strengthens local reproducibility
but does not identify the cause. Review existing search diagnostics or the
verified dedicated package before selecting any future hypothesis.

Raw new data: raw/windows-repeat-03/, all outputs, timings, commands, environment,
Tier 0 and hash manifest. Repeat plan: WINDOWS_REPEAT_03_PLAN.md.
'''
(record/'WINDOWS_REPEAT_03_RESULT.md').write_text(report,encoding='utf8')
gb=[r for r in metrics if r['case']=='GB_144_12_8' and r['mode']=='no-card' and r['repeat']==1]
report+='\n## Existing solver-log observations (no new instrumentation)\n\n'
for r in gb:
    report+=f"GB OFF repeat 1 {r['version']}: last failed-UB [UB, cnfls, hcnfls] = {r['last_failed_UB_counters']}; final hardConflicts = {r['final_hardConflicts']}; [nbLK, nbLKup] = {r['final_nbLK_nbLKup']}.\n"
report+='These printed counters show different search work for the smaller encoding; they do not isolate a causal explanation or stage runtime. Full extracted observations for all 48 solves: solver-counters.json; source logs retained, absent counters null.\n'
(record/'WINDOWS_REPEAT_03_RESULT.md').write_text(report,encoding='utf8')
overall=json.loads((record/'result.json').read_text(encoding='utf8'))
overall['windows_repeat_03']=dict(platform='Windows/Cygwin',tier0='PASS',raw_samples=48,
    combined_local_samples=144,same_binaries=True,numeric_filter=numeric,
    report='WINDOWS_REPEAT_03_RESULT.md',controlled_environment=False)
assert overall['decision']=='inconclusive'
(record/'result.json').write_text(json.dumps(overall,indent=2)+'\n',encoding='utf8')
(raw/'.gitattributes').write_text('* -text\n',encoding='utf8')
manifest={str(p.relative_to(raw)).replace('\\','/'):sha(p) for p in sorted(raw.rglob('*')) if p.is_file() and p.name!='evidence-manifest.json'}
(raw/'evidence-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
print(json.dumps(dict(platform='Windows/Cygwin',new_runs=48,combined_runs=144,
    all_correct=True,windows_numeric_filter=numeric,geomeans=geomeans,
    comparisons=tables['round_3'],evidence_files=len(manifest)),indent=2))
