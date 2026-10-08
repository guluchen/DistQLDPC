"""Metadata-only GH41 Linux bundle builder. No compiler/solver/server access."""
import argparse,hashlib,io,json,subprocess,tarfile
from pathlib import Path
BASE='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
CAND='66cf8be5a4881643f2063471325e33cecaa0caf1'
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
TREE=HERE.parents[2]
sha=lambda b:hashlib.sha256(b).hexdigest()
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve();assert out.parent==ROOT and not out.exists(),'Fresh direct workspace package'
    prep=ROOT/'GH36-windows-tier0-01';manifest=json.loads((prep/'SHA256.json').read_text())
    assert sha((prep/'SHA256.json').read_bytes())=='97188a7019ccdb83646d28557496453822b9d1d2ef3873e60947487d71d17198','Frozen fixture provenance manifest changed'
    assert len(manifest)==820
    for name,digest in manifest.items():
        path=(prep/name).resolve();assert path.is_relative_to(prep.resolve()),'Fixture manifest path escape'
        assert sha(path.read_bytes())==digest,name
    files={};archives={}
    for version,commit in [('baseline',BASE),('candidate',CAND)]:
        data=subprocess.check_output(['git','-C',str(TREE),'-c','core.autocrlf=false','archive',commit,'src','Makefile','scripts/smoke_test.sh'],timeout=20)
        archives[version]=sha(data);files['archives/'+version+'.tar']=data
        with tarfile.open(fileobj=io.BytesIO(data)) as archive:
            for member in archive.getmembers():
                if not member.isfile():continue
                assert not Path(member.name).is_absolute() and '..' not in Path(member.name).parts
                files[version+'/'+member.name]=archive.extractfile(member).read()
    package=ROOT/'E004-windows-tier2-02/E004-server-package'
    package_manifest=json.loads((package/'manifest.json').read_text())
    cases=['LP_34_20_2','LP_136_32_4','LP_340_56_8','BB_90_8_10','GB_144_12_8','BB_108_8_10','LP_238_44_6']
    for case in cases:
        for suffix in ['Hx','Hz','Gx','Gz']:
            rel='baseline/data/matrices/'+case+'_'+suffix+'.txt';data=(package/rel).read_bytes()
            assert sha(data)==package_manifest['files'][rel],rel
            files['inputs/'+Path(rel).name]=data
    for p in sorted(prep.glob('css*_*.txt')):files['fixtures/'+p.name]=p.read_bytes()
    for p in sorted(prep.glob('pms-*.wcnf')):files['fixtures/'+p.name]=p.read_bytes()
    for version in ['baseline','candidate']:
        original=files[version+'/src/solver/Solver.cc'].replace(b'\r\n',b'\n')
        for phase in ['pre-search','post-model']:
            if phase=='pre-search':
                assert original.count(b'emitTryUpdate(UB);')==1
                expected=original.replace(b'emitTryUpdate(UB);',b'emitTryUpdate(UB); ::sleep(3);')
            else:
                start=original.index(b'void Solver::noteBestSolution(');end=original.index(b'void Solver::printBestSolution()',start)
                section=original[start:end];assert section.count(b'emitBoundsUpdate();')==1
                expected=original[:start]+section.replace(b'emitBoundsUpdate();',b'emitBoundsUpdate(); ::sleep(3);')+original[end:]
            name=version+'-'+phase+'-test-only-Solver.cc'
            retained=(prep/name).read_bytes()
            assert retained.replace(b'\r\n',b'\n')==b'#include <unistd.h>\n'+expected,'Prior hook not exact GH41 original source '+name
            files['fixtures/'+name]=retained
    for name in ['pms-oracle.json','science.json','tight-positive-residual-coverage.json','preexecution.json','summary.json','SHA256.json']:
        files['windows-provenance/'+name]=(prep/name).read_bytes()
    for p in sorted(prep.glob('pms-*-witness.json')):files['windows-provenance/'+p.name]=p.read_bytes()
    for p in sorted(prep.glob('*-offset-coverage.json')):files['windows-provenance/'+p.name]=p.read_bytes()
    assert not any(p.name=='__pycache__' or p.suffix=='.pyc' for p in HERE.rglob('*')),'Fresh prepared support must contain no bytecode caches'
    support_names=['test_witness.cc','GH41SERVER_PLAN.md']+[p.name for p in sorted(HERE.glob('server_*.py'))]
    support_head=subprocess.check_output(['git','-C',str(TREE),'rev-parse','HEAD'],text=True,timeout=10).strip()
    for name in support_names:
        blob=subprocess.check_output(['git','-C',str(TREE),'show',support_head+':optimization/experiments/GH-41/'+name],timeout=10)
        assert blob.replace(b'\r\n',b'\n')==(HERE/name).read_bytes().replace(b'\r\n',b'\n'),'Uncommitted package support '+name
        files['support/'+name]=(HERE/name).read_bytes()
    info=dict(baseline=BASE,candidate=CAND,archives=archives,windows_raw_manifest_sha256=sha((prep/'SHA256.json').read_bytes()),
        fixture_origin='GH36-windows-tier0-01; rejected optimization; fixtures only, no reused science verdict or binary',
        original_fixture_support='247bc11d4191e36466f2203f0236da102d27ff0d',hypothesis='GH41 explicit-MTO verified original logical-row scalar cap',
        support_head=support_head,files={name:sha(data) for name,data in files.items()},Tier0='NOT_RUN',Tier1='NOT_RUN',server_assignment='NOT_ASSIGNED')
    files['manifest.json']=(json.dumps(info,indent=2)+'\n').encode()
    out.mkdir()
    for name,data in files.items():p=out/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
    print(json.dumps(dict(package=str(out),files=len(files),execution='NOT_RUN',assignment='NOT_ASSIGNED')))
if __name__=='__main__':main()
