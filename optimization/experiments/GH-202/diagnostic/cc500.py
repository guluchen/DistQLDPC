#!/usr/bin/env python3
"""PI-authorized single-case CC diagnosis, not source-distance adoption.

Approval: human chat reply2026-10-30, issue202 comment6510319434. Fixed
quarantined500 input only; never rerun MaxSAT or select another case.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import signal
import subprocess
import sys
import time

ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
from validate_css import read_code,validate
from verify_css_witness import verify_witness
from smoke_untiered import parse_claim

STEM='TN_500_42_unknown'
MATRICES=ROOT/'data/matrices/untiered/quarantine/GH-202'
RAW=ROOT/'optimization/experiments/GH-202/raw'
OLD=RAW/'actions/failed-source-smoke/schreier-maxsat'
ORIGINAL_SOURCE='e41bff4c327fa60a3467be5552509ea9ec9e496c'
EXPECTED={
    'Hx':'a350fdef721ff6accf99369d0cb36e141edeb7445168fe17baa8be03f06f9041',
    'Hz':'f6c1c9afff5b15f7ca0de889390b0e1cf989162a9e1959ddc6b7f6523c191b7c',
    'Gx':'d83b9967c4acfa18d95ffddf0e90f7c28a2136621e10abf4b9b24b8865e03507',
    'Gz':'57e7c8941ee472f65953af26802abedc40633b40d3689cc32e9e371558e0c61f',
}


def require(ok,message):
    if not ok:raise ValueError(message)


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def preflight():
    meta=json.loads((OLD/(STEM+'.json')).read_text())
    require(meta['source_head']==ORIGINAL_SOURCE and meta['input_sha256']==EXPECTED,'original identity changed')
    require({kind:sha(MATRICES/(STEM+'_'+kind+'.txt')) for kind in EXPECTED}==EXPECTED,'quarantined matrix changed')
    n,matrices=read_code(MATRICES,STEM);checked=validate(n,matrices)
    require(n==500 and checked['k']==42 and (checked['rank_Hx'],checked['rank_Hz'])==(230,228),'actual dimensions changed')
    old_raw=(OLD/(STEM+'.log')).read_text()
    old_result=parse_claim(old_raw,'unknown',500)
    require(old_result==dict(lb=8,ub=8,status='SOLVED') and meta['rc']==0,'original MaxSAT observation changed')
    words=extract_words(old_raw,n,matrices,'original MaxSAT')
    require(any(w['weight']==8 for w in words),'original exact8 lacks actual word')
    return n,matrices,meta,old_result,words


def extract_words(raw,n,matrices,origin):
    words=[]
    for match in re.finditer(r'^c witness ([XZ])(?: \([^)]*\))?:\s*([0-9 ]+)\s*$',raw,re.M):
        support=list(map(int,match.group(2).split()))
        verify_witness(n,matrices,match.group(1),support)
        words.append(dict(half=match.group(1),weight=len(support),support=support,origin=origin))
    return words


def assess(raw,rc):
    n,matrices,old,previous,words=preflight()
    result=parse_claim(raw,'unknown',n) # observed protocol only; source exact6 is NEVER changed.
    require(rc in (0,1) and (rc==0)==(result['status']=='SOLVED'),'CC exit/protocol mismatch')
    words+=extract_words(raw,n,matrices,'authorized CC')
    exacts=list(map(int,re.findall(r'^o (\d+)\s*$',raw,re.M)))
    exact=exacts[-1] if exacts else None
    if exact is not None:require(any(w['weight']==exact for w in words),'CC exact result lacks materialized minimum word')
    actual=min(w['weight'] for w in words)
    conflict=(actual<8 or (result['ub'] is not None and result['ub']<8)
              or (result['lb'] is not None and result['lb']>8)
              or (exact is not None and exact!=8))
    agrees=exact==8 and result['lb']==8 and result['ub']==8
    source_guard_failed=False
    try:parse_claim(raw,'exact 6',n)
    except ValueError:source_guard_failed=True
    return dict(stem=STEM,source_reference_exact=6,original_maxsat=previous,authorized_cc=result,
                cc_explicit_exact=exact,actual_verified_upper=actual,witnesses=words,
                solver_conflict=conflict,source_exact_guard_raised=source_guard_failed,
                interpretation='SOLVER_DISAGREEMENT_REQUIRES_PI' if conflict else
                'BOTH_ENGINES_AGREE_RECONSTRUCTED_INPUT8; SOURCE6_NOT_REPRODUCED' if agrees else
                'INDEPENDENT_CC_PROOF_INCOMPLETE; SOURCE_HOLD_UNRESOLVED',
                reconstructed_input_exact_crosschecked=8 if agrees else None,
                intended_published_code_identified=False,paper_erratum_claim=False,
                library_adoption=False,quarantine_preserved=True)


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--ci',action='store_true',required=True)
    ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--bin',type=Path,default=ROOT/'bin/distqldpc')
    a=ap.parse_args()
    require(sys.platform.startswith('linux') and os.environ.get('GITHUB_ACTIONS')=='true','ephemeral Linux Actions only; no Mac/server execution')
    require(not (RAW/'authorized-cc500').exists(),'a retained CC diagnosis already exists; new PI approval required')
    preflight()
    require(subprocess.run(['git','diff','--quiet',ORIGINAL_SOURCE,'--','src','Makefile'],cwd=ROOT).returncode==0,'original solver/build sources changed')
    a.out.mkdir(parents=True,exist_ok=False)
    cpu=min(os.sched_getaffinity(0))
    cmd=['taskset','-c',str(cpu),'prlimit','--as=4294967296','--',str(a.bin.resolve()),
         '-engine=cc','-seed=0','-v','-cpu-lim=60','data/matrices/untiered/quarantine/GH-202/'+STEM]
    identity=dict(cmd=cmd,source_head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
                  binary_sha256=sha(a.bin),input_sha256=EXPECTED,engine='cc',original_source=ORIGINAL_SOURCE,
                  original_binary_sha256=json.loads((OLD/(STEM+'.json')).read_text())['binary_sha256'],
                  platform=platform.platform(),cpu=cpu,source_reference_exact=6,
                  authorization='human chat2026-10-30; issue202 comment6510319434',address_space_limit=4294967296)
    (a.out/'identity.json').write_text(json.dumps(identity,indent=2)+'\n')
    start=time.monotonic();killed=False
    with (a.out/'cc500.log').open('w') as log:
        proc=subprocess.Popen(cmd,cwd=ROOT,stdin=subprocess.DEVNULL,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
        try:rc=proc.wait(timeout=90)
        except subprocess.TimeoutExpired:
            killed=True;os.killpg(proc.pid,signal.SIGKILL);rc=proc.wait()
    identity.update(rc=rc,wall_seconds=time.monotonic()-start,runner_backstop=killed)
    (a.out/'identity.json').write_text(json.dumps(identity,indent=2)+'\n')
    require(not killed,'wall backstop; evidence retained, do not retry')
    preflight();require(sha(a.bin)==identity['binary_sha256'],'binary changed during diagnosis')
    result=assess((a.out/'cc500.log').read_text(),rc)
    (a.out/'audit.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({k:v for k,v in result.items() if k!='witnesses'},indent=2))
    require(not result['solver_conflict'],'engine disagreement; evidence retained, stop for PI review')


if __name__=='__main__':main()
