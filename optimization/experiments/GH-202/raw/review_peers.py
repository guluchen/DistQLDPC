#!/usr/bin/env python3
"""Read-only pinned inventory and retained own-engine/GF2 peer evidence replay."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
from validate_css import read_code,validate,equal_space
from verify_css_witness import verify_witness
from smoke_untiered import parse_claim


def git(sha,path):return subprocess.check_output(['git','show',sha+':'+path],cwd=ROOT)


def main():
    raw=Path(__file__).parent;refs=json.loads((raw/'peer-refs.json').read_text());made=json.loads((raw/'generation.json').read_text())
    targets={(r['n'],r['k']):r['stem'] for r in made};peers=[]
    for ref in refs:
        paths=subprocess.check_output(['git','ls-tree','-r','--name-only',ref['sha'],'data/matrices'],cwd=ROOT,text=True).splitlines()
        for path in paths:
            if not path.endswith('_Hx.txt') or '/quarantine/' in path:continue
            stem=Path(path).name[:-7];fields=stem.split('_')
            if len(fields)<3 or not all(v.isdigit() for v in fields[1:3]):continue
            key=(int(fields[1]),int(fields[2]))
            if key in targets:peers.append(dict(ref=ref,path=path,stem=stem,candidate=targets[key]))
    if {(r['stem'],r['candidate']) for r in peers}!={('GB_180_26_unknown','TN_180_26_unknown')}:raise ValueError('new same(n,k)peer requires scientific review')
    proof_ref='3fea2322b478a21fb0c987c29829a9169aaf4f75';stem='GB_180_26_unknown';audits=json.loads(git(proof_ref,'optimization/experiments/GH-196/raw/actions/default/audit.json'))
    audit=next(r for r in audits if r['stem']==stem)
    with tempfile.TemporaryDirectory() as temp:
        directory=Path(temp)
        for kind in ['Hx','Hz','Gx','Gz']:(directory/(stem+'_'+kind+'.txt')).write_bytes(git(proof_ref,'data/matrices/untiered/'+stem+'_'+kind+'.txt'))
        n,m=read_code(directory,stem);r=validate(n,m)
        if (n,r['k'])!=(180,26):raise ValueError('peer actual n/k changed')
        for w in audit['witnesses']:verify_witness(n,m,w['half'],w['support'])
        if min(len(w['support']) for w in audit['witnesses'])!=7:raise ValueError('peer exact proof lacks verified minimum7 or has conflicting shorter word')
        engine_results={}
        for engine in ['maxsat','cc']:
            # Resolve the actual retained label instead of inventing a log path.
            all_paths=subprocess.check_output(['git','ls-tree','-r','--name-only',proof_ref,'optimization/experiments/GH-196/raw/actions/default'],cwd=ROOT,text=True).splitlines()
            log_path=next(p for p in all_paths if p.endswith('/'+stem+'.log') and engine in p)
            meta=json.loads(git(proof_ref,log_path[:-4]+'.json'));text=git(proof_ref,log_path).decode()
            if set(meta['input_sha256'])!={'Hx','Hz','Gx','Gz'}:raise ValueError('incomplete peer identity')
            if any(hashlib.sha256((directory/(stem+'_'+k+'.txt')).read_bytes()).hexdigest()!=v for k,v in meta['input_sha256'].items()):raise ValueError('peer log/input identity mismatch')
            result=parse_claim(text,'exact 7',180)
            if result!=dict(lb=7,ub=7,status='SOLVED') or audit['engines'][engine]!=result:raise ValueError('retained peer exact proof changed')
            engine_results[engine]=dict(result=result,path=log_path,sha256=hashlib.sha256(text.encode()).hexdigest(),source_head=meta['source_head'],binary_sha256=meta['binary_sha256'])
        if len({(r['source_head'],r['binary_sha256']) for r in engine_results.values()})!=1:raise ValueError('retained peer engines used different sources/binaries')
        nn,mm=read_code(ROOT/'data/matrices/untiered/quarantine/GH-202','TN_180_26_unknown');validate(nn,mm)
        if (equal_space(m[0],mm[0]) and equal_space(m[1],mm[1])) or (equal_space(m[0],mm[1]) and equal_space(m[1],mm[0])):raise ValueError('duplicate peer rowspaces')
        construction=json.loads((raw/'construction.json').read_text());own=next(r for r in construction if r['stem']=='TN_180_26_unknown')
        word=min(own['independently_checked_uppers'],key=lambda w:w['weight']);verify_witness(nn,mm,word['half'],word['support'])
        if word['weight']!=6:raise ValueError('physical-inequivalence upper word absent')
    out=dict(ref_count=len(refs),same_n_k_peers=peers,
        rowspace_and_XZ_swap='distinct actual stabilizer pairs',peer_proof_ref=proof_ref,
        peer_exact=engine_results,candidate_actual_GF2_word=word,
        physical_inequivalence='candidate distance<=6 by actual GF2 word; peer exact7 independently cross-checked in retained own engines; qubit permutations/global XZ swap preserve distance',
        scope='no new distance search or external solver; not a claim that candidate exact6 has been reproduced yet')
    (raw/'cross-branch-review.json').write_text(json.dumps(out,indent=2)+'\n');print('PASS',len(refs),'refs; sole peer GB180k26 exact7 vs TN verifiedword6')


if __name__=='__main__':main()
