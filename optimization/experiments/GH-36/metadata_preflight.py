# Metadata only. No driver/helper imports, Window, compilation, solver or timing.
import ast,hashlib,json,subprocess,tarfile
from pathlib import Path
here=Path(__file__).resolve().parent;root=here.parents[3] if here.name=='GH-36' else here
record=root/'GH36-WITNESS/optimization/experiments/GH-36'
candidate=root/'GH36-WITNESS'
prep=root/'GH36-windows-tier0-01'
package=root/'E004-windows-tier2-02/E004-server-package'
runtime=root/'E004-windows-runtime/cygwin'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
text=(record/'windows_tier1.py').read_text()
tree=ast.parse(text) # syntax metadata only; never evaluate/import the driver
constants={}
for n in tree.body:
    if isinstance(n,ast.Assign):
        try:value=ast.literal_eval(n.value)
        except (ValueError,TypeError):continue
        for target in n.targets:
            if isinstance(target,ast.Name):constants[target.id]=value
assert constants['ASSIGNED_URL']=='HOST_SLOT_NOT_ASSIGNED'
assert constants['CAND']=='f8f379ddb7d7cc4a0f8dc1d62f670b2e97bd22a1'
assert constants['CASES']==['BB_90_8_10','GB_144_12_8','BB_108_8_10','LP_238_44_6']
assert constants['MODES']==['no-card','card-mto']
assert "record=candidate/'optimization/experiments/GH-36'" in text
assert 'GH-27' not in text and 'ENQUEUE' not in text
original=json.loads((prep/'preexecution.json').read_text())
manifest=json.loads((prep/'SHA256.json').read_text());assert len(manifest)==820
for name,digest in manifest.items():assert sha(prep/name)==digest,name
source_count=0;archive_count=0;archive_export_differences=[]
for version,hashes in original['source_hashes'].items():
    commit=constants['BASE'] if version=='baseline' else constants['CAND']
    raw_archive=subprocess.check_output(['git','-C',str(candidate),'archive',commit,'src','Makefile','scripts/smoke_test.sh'],timeout=20)
    assert raw_archive==(prep/(version+'-source.tar')).read_bytes(),(version,'actual Git archive byte proof')
    with tarfile.open(prep/(version+'-source.tar'),'r') as archive:
        members={m.name:m for m in archive.getmembers() if m.isfile()}
        for name,digest in hashes.items():
            p=prep/(version+'-source')/name;assert sha(p)==digest,name;source_count+=1
            rel=name.replace('\\','/');blob=archive.extractfile(members[rel]).read()
            commit=constants['BASE'] if version=='baseline' else constants['CAND']
            actual=subprocess.check_output(['git','-C',str(candidate),'show',commit+':'+rel],timeout=10)
            if actual!=blob:archive_export_differences.append(version+':'+rel)
            assert actual.replace(b'\r\n',b'\n')==blob.replace(b'\r\n',b'\n'),(version,rel,'normalized blob');archive_count+=1
            build=p.read_bytes()
            assert build==(blob.replace(b'\r\n',b'\n') if rel in ['Makefile','scripts/smoke_test.sh'] else blob),(version,rel,'normalization')
for name,digest in original['support'].items():
    p=root/'DistQLDPC/optimization/experiments/E004/windows_cpu_window.py' if name=='windows_cpu_window.py' else record/name
    assert sha(p)==digest,name
for name,digest in original['runtime_hashes'].items():assert sha(runtime/'bin'/name)==digest,name
for name,digest in original['input_hashes'].items():assert sha(package/name)==digest,name
for version,digest in constants['HASHES'].items():assert sha(prep/(version+'-source')/'bin/distqldpc.exe')==digest,version
inputs=json.loads((record/'tier1-input-sha256.json').read_text())
package_manifest=json.loads((package/'manifest.json').read_text())
for case in constants['CASES']:
    for suffix in ['Hx','Hz','Gx','Gz']:
        p=package/'baseline/data/matrices'/(case+'_'+suffix+'.txt')
        assert sha(p)==inputs[p.name]==package_manifest['files'][str(p.relative_to(package)).replace('\\','/')]
hosted=record/'raw/hosted-247bc11'
identity=json.loads((hosted/'identity.json').read_text());assert sha(hosted/'artifact.zip')==identity['zip_sha256']
result=json.loads((hosted/'result.json').read_text());assert result['scientific_semantics_match'] and len(result['rows'])==4
for row in result['rows']:
    exact=int(row['stem'].rsplit('_',1)[1]);assert row['same_semantics']
    for version in ['baseline','candidate']:
        r=row[version];assert r['returncode']==0 and not r['timed_out']
        assert all(r[k]==exact for k in ['d_lb','d_ub','d','objective'])
summary=json.loads((prep/'summary.json').read_text());assert summary['Tier0']=='LOCAL_PASS' and summary['diagnostic']=='NOT_REQUESTED'
cleanup=json.loads((prep/'owned-cleanup-223.json').read_text());assert cleanup['confirmed'] and not cleanup['remaining']
assert summary['cleanup']['final_mask']==65535 and summary['cleanup']['final_priority_class']==32
print(json.dumps(dict(metadata_only=True,driver_imported=False,helper_imported=False,Window_created=False,
    engine_executed=False,manifest_files=820,source_hashes=source_count,Git_archive_matches=archive_count,
    inputs=len(inputs),hosted_solves=8,driver_sha256=sha(record/'windows_tier1.py'),
    archive_export_differences=archive_export_differences,future_committed_blob_checks='WAIT_ROOT_COMMIT'),indent=2))
