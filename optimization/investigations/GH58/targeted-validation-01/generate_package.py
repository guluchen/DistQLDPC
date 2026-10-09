"""Metadata-only exact Git export and finite oracle package. No native execution."""
from pathlib import Path
import argparse,hashlib,json,shutil,subprocess,tarfile
import science
BASE='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
CAND='f06ac3de230362935a23d0faeff1350708651d7d'
SOLVER_SHA='c1360169ca4066e69e2c5ea64f86fd36deb41e5a1db76697b7874f007c873afc'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,v):p.write_text(json.dumps(v,indent=2)+'\n',encoding='utf-8')
def main():
    ap=argparse.ArgumentParser()
    for n in ['repo','out','donor','fixture']:ap.add_argument('--'+n,type=Path,required=True)
    ap.add_argument('--assignment',default='HOST_SLOT_NOT_ASSIGNED');a=ap.parse_args()
    out=a.out.resolve();assert not out.exists();out.mkdir()
    git=lambda *v:subprocess.check_output(['git','-C',str(a.repo),*v])
    source_names=git('ls-tree','-r','--name-only',BASE,'--','src','Makefile','NOTICE','MODIFICATIONS.md','LICENSE','scripts/smoke_test.sh').decode().splitlines()
    assert source_names and 'Makefile' in source_names
    for version,commit in [('baseline',BASE),('candidate',CAND)]:
        for n in source_names:
            p=out/version/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(git('show',commit+':'+n))
    assert sha(out/'candidate/src/solver/Solver.cc')==SOLVER_SHA
    changed=[n for n in source_names if n.startswith('src/') and (out/'baseline'/n).read_bytes()!=(out/'candidate'/n).read_bytes()]
    assert changed==['src/solver/Solver.cc']
    donor_manifest=json.loads((a.donor/'manifest.json').read_text())
    def donor_copy(name,destination):
        p=a.donor/name;assert donor_manifest['files'][name]==sha(p)
        destination.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,destination)
    fixtures=out/'fixtures';fixtures.mkdir();original=a.fixture.read_bytes()
    assert hashlib.sha256(original).hexdigest()=='ae851ec8bb80b3a638c40184d5203259ecade373e5598df2c79dbd7d12eb52d4'
    (fixtures/'mandatory-original.wcnf').write_bytes(original)
    lines=[s.split() for s in original.decode('ascii').splitlines()];assert lines[0]==['p','wcnf','10','28','14']
    rows=[list(map(int,s)) for s in lines[1:]];names=['mandatory-original.wcnf']
    def encode(rows,top):return ('p wcnf 10 '+str(len(rows))+' '+str(top)+'\n'+'\n'.join(' '.join(map(str,r)) for r in rows)+'\n').encode('ascii')
    for mask in [1,3,85,1023]:
        for reverse in [False,True]:
            transformed=[[r[0],*[-l if mask&(1<<(abs(l)-1)) else l for l in r[1:-1]],0] for r in rows]
            if reverse:transformed.reverse()
            n='flip-'+str(mask)+'-reverse-'+str(int(reverse))+'.wcnf';(fixtures/n).write_bytes(encode(transformed,14));names.append(n)
    for lit in [1,4]:
        duplicate=[[15 if r[0]==14 else r[0],*r[1:]] for r in rows]+[[1,lit,0]]
        n='duplicate-positive-'+str(lit)+'.wcnf';(fixtures/n).write_bytes(encode(duplicate,15));names.append(n)
    targeted=[dict(name=n,sha256=sha(fixtures/n),oracle=science.wcnf((fixtures/n).read_bytes())) for n in names]
    assert len(targeted)==11 and targeted[0]['oracle']['exact']==5
    save(fixtures/'targeted-oracles.json',targeted)
    # Full-gate inputs only; no donor candidate/helper/sleep code is imported.
    for stem in ['css1','css4','css5','css-fallback']:
        for s in ['Hx','Hz','Gx','Gz']:donor_copy('fixtures/'+stem+'_'+s+'.txt',fixtures/(stem+'_'+s+'.txt'))
    original_oracles=json.loads((a.donor/'windows-provenance/pms-oracle.json').read_text());assert len(original_oracles)==40
    pms=[]
    for row in original_oracles:
        n='fixtures/'+row['stem']+'.wcnf';donor_copy(n,fixtures/(row['stem']+'.wcnf'))
        truth=science.wcnf((fixtures/(row['stem']+'.wcnf')).read_bytes());assert truth['exact']==row['oracle']
        pms.append(dict(name=row['stem']+'.wcnf',sha256=sha(fixtures/(row['stem']+'.wcnf')),oracle=truth))
    save(fixtures/'pms-oracles.json',pms)
    for stem in ['LP_34_20_2','LP_340_56_8']:
        for s in ['Hx','Hz','Gx','Gz']:donor_copy('inputs/'+stem+'_'+s+'.txt',out/'inputs'/(stem+'_'+s+'.txt'))
    support=out/'support';support.mkdir()
    for n in ['targeted.py','launcher.py','guard.py','science.py','test_partition.cc','generate_package.py','PRERECORD.md']:
        p=Path(__file__).with_name(n);assert p.is_file();shutil.copyfile(p,support/n)
    manifest=dict(baseline=BASE,candidate=CAND,solver_sha=SOLVER_SHA,assignment=a.assignment,phase='TARGETED_ONLY',full_gate='DISABLED_PENDING_ACTUAL_TARGET_PASS_AND_REVIEW',original_fixture_sha=targeted[0]['sha256'],donor_manifest_sha=sha(a.donor/'manifest.json'),generation='Exact Git bytes; eleven independently enumerated fixtures; no compiler/solver',files={str(p.relative_to(out)).replace('\\','/'):sha(p) for p in sorted(out.rglob('*')) if p.is_file()})
    save(out/'manifest.json',manifest)
    tar=out.with_suffix('.tar');assert not tar.exists()
    with tarfile.open(tar,'w') as archive:
        for p in sorted(out.rglob('*')):
            assert not p.is_symlink()
            if p.is_file():archive.add(p,arcname=str(p.relative_to(out)).replace('\\','/'),recursive=False)
    save(out.with_suffix('.package-proof.json'),dict(manifest_sha=sha(out/'manifest.json'),tar_sha=sha(tar),tar_bytes=tar.stat().st_size,files=len(manifest['files']),source_only=True,assignment=a.assignment,targeted_cases=11,partition_cases=80,full_gate_execution=False))
    print(json.dumps(dict(package=str(out),manifest_sha=sha(out/'manifest.json'),tar_sha=sha(tar),source_only=True)))
if __name__=='__main__':main()
