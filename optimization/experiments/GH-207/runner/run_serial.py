#!/usr/bin/env python3
"""Frozen unfinished BCH numeric/proof gaps; dry-run until PI allocates yfclab2 core."""
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
from smoke_untiered import parse_claim
from validate_css import read_code
from verify_css_witness import verify_witness
from audit_bch_smoke import assess
from bch_certificate import verify as verify_certificate, stem as certificate_stem

SOURCE='25936e3f36aad13fa47ba85708af68b01c274b0a'
CASES_SHA='86665170d79a2109d235ef3be0cb584269f6d575d69ea47f03b82a9773adffca'


def require(ok,message):
    if not ok:raise ValueError(message)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def core_free(cpu):
    require(cpu in os.sched_getaffinity(0),'core outside allowed affinity')
    for status in Path('/proc').glob('[0-9]*/status'):
        try:
            if status.parent.name==str(os.getpid()) or not (status.parent/'cmdline').read_bytes():continue
            text=status.read_text()
        except (OSError,ProcessLookupError):continue
        require(not re.search(rf'^Cpus_allowed_list:\s*{cpu}\s*$',text,re.M),
                'core already has a pinned userspace process '+status.parent.name)


def verify_solver_sources():
    for target,expected in [('HEAD:src','19cbea916c41b3918de87f86791da9f1c80abbbd'),
                            ('HEAD:Makefile','1951a24d5de920a651ad3919c672331862976365')]:
        require(subprocess.check_output(['git','rev-parse',target],cwd=ROOT,text=True).strip()==expected,
                'frozen solver/build identity changed')
    require(subprocess.run(['git','diff','--quiet','HEAD','--','src','Makefile'],cwd=ROOT).returncode==0,
            'uncommitted solver/build changes')


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--cpu',type=int,required=True)
    ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--bin',type=Path,default=ROOT/'bin/distqldpc')
    ap.add_argument('--jobs',type=Path,default=Path(__file__).with_name('jobs.jsonl'))
    ap.add_argument('--execute',action='store_true')
    ap.add_argument('--allocation-ref')
    ap.add_argument('--core-confirmed-free',action='store_true')
    a=ap.parse_args()
    cases_path=ROOT/'scripts/codegen/bch_cases.json'
    require(sha(cases_path)==CASES_SHA,'frozen definitions changed')
    cases={c['id']:c for c in json.loads(cases_path.read_text())}
    raw=Path(__file__).parents[1]/'raw/actions/default'
    proofs={r['stem']:r for r in json.loads((raw/'audit.json').read_text())}
    construction={r['stem']:r for r in json.loads((raw/'construction.json').read_text())}
    certified={}
    for c in cases.values():
        name=certificate_stem(c)
        cert=json.loads((raw.parent.parent/'certificates'/(name+'.json')).read_text())
        certified[name]=verify_certificate(c,ROOT/'data/matrices/untiered',cert)
    allowed={Path(__file__).with_name(name).resolve():engine for name,engine in
             [('jobs.jsonl','maxsat'),('optional-cc-jobs.jsonl','cc')]}
    require(a.jobs.resolve() in allowed,'only the two canonical frozen queues are allowed')
    engine=allowed[a.jobs.resolve()]
    jobs=[json.loads(line) for line in a.jobs.read_text().splitlines() if line.strip()]
    expected={name for name,p in certified.items() if p['certificate_exact'] is None}
    require(len(jobs)==len(expected) and {j['stem'] for j in jobs}==expected,
            'queue must contain exactly the unfinished retained engine cases')
    require(len({j['id'] for j in jobs})==len(jobs),'duplicate job id')
    commands=[]
    frozen={}
    for j in jobs:
        stem=j['stem'];p=proofs[stem];c=cases[construction[stem]['id']]
        lo,hi=certified[stem]['certificate_lower'],certified[stem]['actual_verified_upper']
        flags=(['-engine=cc'] if engine=='cc' else [])+['-seed=0','-v']
        purpose='numeric-proof' if None in (p['engines'][engine]['lb'],p['engines'][engine]['ub']) else 'optional-proof'
        require(j['engine']==engine and j['purpose']==purpose and j['limit']==21600
                and j['code']=='data/matrices/untiered/'+stem and j['args']==flags
                and j['reference_claim']==f'>= {lo}' and j['verified_upper']==p['actual_verified_upper']
                and re.fullmatch(r'[A-Za-z0-9_.-]+',j['id']),'changed frozen job')
        meta=json.loads((raw/engine/stem/(stem+'.json')).read_text())
        require(meta['source_head']==SOURCE==p['source_head'],'retained source mismatch')
        require(set(meta['input_sha256'])=={'Hx','Hz','Gx','Gz'},'missing input identity')
        for kind,digest in meta['input_sha256'].items():
            require(sha(ROOT/f'{j["code"]}_{kind}.txt')==digest,'matrix differs from bounded source')
        n,matrices=read_code(ROOT/'data/matrices/untiered',stem)
        for w in p['witnesses']:
            verify_witness(n,matrices,w['half'],w['support'])
            require(w['weight']==len(w['support']),'retained witness weight mismatch')
        require(min(w['weight'] for w in p['witnesses'])==j['verified_upper'],'upper lacks actual word')
        frozen[stem]=meta['input_sha256']
        commands.append(['taskset','-c',str(a.cpu),'prlimit','--as=4294967296','--',str(a.bin.resolve())]
                        +flags+['-cpu-lim=21600',j['code']])
    if not a.execute:
        print(json.dumps(commands,indent=2));return
    require(sys.platform.startswith('linux') and platform.node().split('.')[0]=='yfclab2','yfclab2 execution only')
    require(a.allocation_ref and a.core_confirmed_free,'explicit PI allocation and fresh free-core confirmation required')
    require(not subprocess.check_output(['git','status','--porcelain'],cwd=ROOT,text=True).strip(),'clean frozen checkout required')
    verify_solver_sources()
    core_free(a.cpu)
    a.out.mkdir(parents=True,exist_ok=False)
    source=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
    binary=sha(a.bin)
    (a.out/'config.json').write_text(json.dumps(dict(source_head=source,bounded_source=SOURCE,
        binary_sha256=binary,input_sha256=frozen,jobs_sha256=sha(a.jobs),cases_sha256=CASES_SHA,
        cpu=a.cpu,allocation_ref=a.allocation_ref,hostname=platform.node(),serial=True,
        address_space_limit=4294967296,jobs=jobs,commands=commands),indent=2)+'\n')
    for j,cmd in zip(jobs,commands):
        core_free(a.cpu);stem=j['stem'];p=proofs[stem]
        require(sha(a.bin)==binary,'binary changed')
        for kind,digest in frozen[stem].items():require(sha(ROOT/f'{j["code"]}_{kind}.txt')==digest,'input changed')
        started=time.monotonic();path=a.out/(j['id']+'.log');killed=False
        with path.open('w') as log:
            proc=subprocess.Popen(cmd,cwd=ROOT,stdin=subprocess.DEVNULL,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
            try:rc=proc.wait(timeout=j['limit']+600)
            except subprocess.TimeoutExpired:
                killed=True;os.killpg(proc.pid,signal.SIGKILL);rc=proc.wait()
        identity=dict(id=j['id'],stem=stem,engine=engine,cmd=cmd,source_head=source,
                      binary_sha256=binary,input_sha256=frozen[stem],rc=rc,
                      wall_seconds=time.monotonic()-started,runner_backstop=killed)
        meta=a.out/(j['id']+'.json');meta.write_text(json.dumps(identity,indent=2)+'\n')
        require(not killed,'wall backstop; raw evidence retained, stop for review')
        require(sha(a.bin)==binary,'binary changed during run')
        for kind,digest in frozen[stem].items():require(sha(ROOT/f'{j["code"]}_{kind}.txt')==digest,'input changed during run')
        result=parse_claim(path.read_text(),j['reference_claim'],int(stem.split('_')[1]))
        require(rc in (0,1) and (rc==0)==(result['status']=='SOLVED'),'exit/result mismatch')
        n,matrices=read_code(ROOT/'data/matrices/untiered',stem)
        assessed=assess(cases[construction[stem]['id']],n,matrices,construction[stem],{engine:path.read_text()})
        old_lb=max([r['lb'] for r in p['engines'].values() if r['lb'] is not None]+[certified[stem]['certificate_lower']])
        old_ub=min([r['ub'] for r in p['engines'].values() if r['ub'] is not None]+[p['actual_verified_upper']])
        require(result['lb'] is None or result['lb']<=min(old_ub,p['actual_verified_upper']),'lower contradicts retained word/other engine')
        require(result['ub'] is None or result['ub']>=old_lb,'upper contradicts retained other engine')
        identity.update(result=result,audit=assessed,scientific_status='PLAUSIBLE until reviewed against independent finite certificate and retained words')
        meta.write_text(json.dumps(identity,indent=2)+'\n')
        print(json.dumps(dict(id=j['id'],**result)),flush=True)


if __name__=='__main__':main()
