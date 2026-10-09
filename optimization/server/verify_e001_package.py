#!/usr/bin/env python3
"""Read-only audit of the unchanged E001 Linux archive; no solver/timing run."""
import argparse, hashlib, io, json, subprocess, sys, tarfile, zipfile
from pathlib import Path

EXPECTED='3df26a2e60dd23216c37c3cd2f3dfe07b5173059a383c9ba565e28078973b84e'
BASE='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
CODE='50623f9710969288d3a9d1c6325f3a72c35ff6d5'
CAND='9d68f459019e9c5a20c5c513cf89aaf4a2cd2854'
QD='7c4774fffc49856f48a22ae5f9063d00b2661aaa'
sha=lambda b:hashlib.sha256(b).hexdigest()

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--archive',type=Path,required=True)
    ap.add_argument('--report',type=Path,required=True,help='New file; never overwrite prior evidence')
    a=ap.parse_args();repo=Path(__file__).resolve().parents[2]
    assert not a.report.exists(),'Report already exists'
    assert sha(a.archive.read_bytes())==EXPECTED,'Archive hash mismatch'
    with tarfile.open(a.archive) as tf:
        blobs={m.name:tf.extractfile(m).read() for m in tf.getmembers() if m.isfile()}
    prefix='E001-linux-package/'
    manifest=json.loads(blobs[prefix+'manifest.json'])
    assert manifest['revisions']==dict(baseline=BASE,candidate=CAND,qdistsat=QD)
    assert len(manifest['files'])==914
    assert set(blobs)=={prefix+x for x in manifest['files']}|{prefix+'manifest.json'}
    for rel,expected in manifest['files'].items():assert sha(blobs[prefix+rel])==expected,rel
    git=lambda *args:subprocess.check_output(['git',*args],cwd=repo)
    assert blobs[prefix+'candidate/src/core/distqldpc.cc']==git('show',CODE+':src/core/distqldpc.cc')
    patch=blobs[prefix+'candidate/optimization/experiments/E001/implementation.patch']
    assert patch==git('diff',BASE,CAND,'--','src')
    assert git('diff',BASE,CAND,'--','src/solver','MODIFICATIONS.md','NOTICE')==b''
    assert git('show',CAND+':optimization/server/run.py')==blobs[prefix+'candidate/optimization/server/run.py']
    identities=json.loads((repo/'optimization/experiments/E001/input-identities.json').read_text())
    for rel,expected in identities.items():
        for version in ['baseline','candidate']:assert sha(blobs[prefix+version+'/'+rel])==expected
    hosted=blobs[prefix+'candidate/optimization/experiments/E001/raw/hosted-cross-repo.zip']
    assert sha(hosted)=='3f15057e113be03cebf5b967719d23c388adad4722128662615de37447a131cb'
    with zipfile.ZipFile(io.BytesIO(hosted)) as z:report=json.loads(z.read('result.json'))
    assert report['scientific_semantics_match'] and len(report['rows'])==4
    for row in report['rows']:
        expected={'LP_136_32_4':4,'BB_108_8_10':10}[row['stem']]
        assert row['same_semantics']
        for version in ['baseline','candidate']:
            r=row[version]
            assert r['returncode']==0 and not r['timed_out']
            assert all(r[k]==expected for k in ['d','objective','d_lb','d_ub'])
    test=subprocess.run([sys.executable,str(repo/'optimization/tests/test_server.py')],cwd=repo,capture_output=True,text=True)
    assert test.returncode==0,test.stdout+test.stderr
    result=dict(audit='PASS',archive=a.archive.name,sha256=EXPECTED,payloads_verified=914,
        input_identities_verified=len(identities),revisions=manifest['revisions'],candidate_code=CODE,
        retained_hosted_correctness='PASS; timing excluded',fresh_gate_tests=test.stdout+test.stderr,
        fresh_solver_runs=0,fresh_controlled_samples=0,decision='INCONCLUSIVE',
        blocker='No dedicated-server endpoint/access or exclusive reservation supplied',
        scientific_semantics_changed=False)
    a.report.write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
    print(json.dumps(result,indent=2))

if __name__=='__main__':main()
