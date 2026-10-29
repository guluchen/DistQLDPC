#!/usr/bin/env python3
"""Explicitly allocated yfclab2 reproduction, serial 4GiB jobs; default dry-run.

Job fields follow baseline queue conventions, but reference claims are separate
from unknown stems and may be exact or upper estimates. No tier assignment.
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
from smoke_untiered import parse
from verify_css_witness import verify_witness
from validate_css import read_code


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def core_free(cpu):
    if cpu not in os.sched_getaffinity(0):raise ValueError('CPU outside affinity')
    for status in Path('/proc').glob('[0-9]*/status'):
        try:
            if status.parent.name==str(os.getpid()) or not (status.parent/'cmdline').read_bytes():continue
            text=status.read_text()
        except (OSError,ProcessLookupError):continue
        if re.search(rf'^Cpus_allowed_list:\s*{cpu}\s*$',text,re.M):
            raise ValueError(f'core has a pinned userspace process {status.parent.name}')


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--cpu',type=int,required=True);ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--bin',type=Path,default=ROOT/'bin/distqldpc')
    ap.add_argument('--jobs',type=Path,default=Path(__file__).with_name('jobs.jsonl'))
    ap.add_argument('--execute',action='store_true');ap.add_argument('--allocation-ref')
    ap.add_argument('--core-confirmed-free',action='store_true');args=ap.parse_args()
    cases_path=ROOT/'scripts/codegen/covering_bb_cases.json'
    if sha(cases_path)!='438242742832d1635e2dc65c7cbf839f3771734b3b700b9aca7ae21da2ea2d29':ap.error('frozen case definitions changed')
    cases={f'BB_{c["n"]}_{c["k"]}_unknown':c for c in json.loads(cases_path.read_text())['cases']}
    proof_path=Path(__file__).parents[1]/'raw/actions/default/audit.json'
    proofs={r['stem']:r for r in json.loads(proof_path.read_text())}
    jobs=[json.loads(line) for line in args.jobs.read_text().splitlines() if line.strip()]
    if not jobs or len({j['id'] for j in jobs})!=len(jobs):ap.error('nonempty distinct jobs required')
    commands=[]
    for j in jobs:
        c=cases.get(j['stem']);engine=j['engine']
        flags=(['-engine=cc'] if engine=='cc' else [])+['-seed=0','-v']
        if (c is None or engine not in ('maxsat','cc') or j['code']!='data/matrices/untiered/'+j['stem']
                or j['reference_claim']!=c['claim'] or j['expected_d']!=c['d'] or j['limit']!=21600
                or j['args']!=flags or not re.fullmatch(r'[A-Za-z0-9_.-]+',j['id'])):
            ap.error('job does not match the frozen covering-graph BB reference package')
        meta_path=proof_path.parent/('covering_bb-'+engine)/(j['stem']+'.json')
        meta=json.loads(meta_path.read_text())
        if meta['source_head']!=proofs[j['stem']]['source_head']:ap.error('retained input source mismatch')
        if set(meta['input_sha256'])!={'Hx','Hz','Gx','Gz'}:ap.error('incomplete frozen matrix identity')
        if any(sha(ROOT/f'{j["code"]}_{kind}.txt')!=digest for kind,digest in meta['input_sha256'].items()):ap.error('matrix differs from retained smoke input')
        commands.append(['taskset','-c',str(args.cpu),'prlimit','--as=4294967296','--',str(args.bin.resolve())]+
                        j['args']+[f'-cpu-lim={j["limit"]}',j['code']])
    if not args.execute:print(json.dumps(commands,indent=2));return
    if not sys.platform.startswith('linux') or platform.node().split('.')[0]!='yfclab2':ap.error('yfclab2 execution only')
    if not args.allocation_ref or not args.core_confirmed_free:ap.error('explicit PI allocation/free-core confirmation required')
    if subprocess.check_output(['git','status','--porcelain'],cwd=ROOT,text=True).strip():ap.error('clean frozen checkout required')
    core_free(args.cpu);args.out.mkdir(parents=True,exist_ok=False)
    source=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip();binary=sha(args.bin)
    frozen={j['stem']:{kind:sha(ROOT/f'{j["code"]}_{kind}.txt') for kind in ('Hx','Hz','Gx','Gz')} for j in jobs}
    (args.out/'config.json').write_text(json.dumps(dict(source_head=source,binary_sha256=binary,input_sha256=frozen,
        jobs_sha256=sha(args.jobs),cases_sha256=sha(cases_path),cpu=args.cpu,allocation_ref=args.allocation_ref,
        address_space_limit=4294967296,serial=True,jobs=jobs,commands=commands,hostname=platform.node()),indent=2)+'\n')
    results=[]
    for j,cmd in zip(jobs,commands):
        core_free(args.cpu);n,m=read_code(ROOT/'data/matrices/untiered',j['stem'])
        inputs={kind:sha(ROOT/f'{j["code"]}_{kind}.txt') for kind in ('Hx','Hz','Gx','Gz')}
        if inputs!=frozen[j['stem']] or sha(args.bin)!=binary:raise ValueError('frozen inputs/binary changed')
        start=time.monotonic();log_path=args.out/(j['id']+'.log');killed=False
        with log_path.open('w') as log:
            proc=subprocess.Popen(cmd,cwd=ROOT,stdin=subprocess.DEVNULL,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
            try:rc=proc.wait(timeout=j['limit']+600)
            except subprocess.TimeoutExpired:killed=True;os.killpg(proc.pid,signal.SIGKILL);rc=proc.wait()
        identity=dict(id=j['id'],stem=j['stem'],engine=j['engine'],reference_claim=j['reference_claim'],
            expected_d=j['expected_d'],cmd=cmd,source_head=source,binary_sha256=binary,input_sha256=inputs,
            rc=rc,wall_seconds=time.monotonic()-start,runner_backstop=killed)
        (args.out/(j['id']+'.json')).write_text(json.dumps(identity,indent=2)+'\n')
        if any(sha(ROOT/f'{j["code"]}_{kind}.txt')!=digest for kind,digest in inputs.items()) or sha(args.bin)!=binary:
            raise ValueError('input/binary changed during run; evidence saved')
        if killed:raise RuntimeError('wall backstop; evidence saved; stop and review')
        raw=log_path.read_text();result=parse(raw,j['expected_d'],exact=j['reference_claim']=='exact')
        if rc not in (0,1) or (rc==0)!=(result['status']=='SOLVED'):raise RuntimeError('exit status mismatch')
        old=proofs[j['stem']]['engines'].values()
        prior_lb=max([r['lb'] for r in old if r['lb'] is not None]+[0])
        prior_ub=min([r['ub'] for r in old if r['ub'] is not None]+[n])
        if ((result['lb'] is not None and result['lb']>prior_ub)
                or (result['ub'] is not None and result['ub']<prior_lb)):
            raise ValueError('scientific contradiction with retained other-engine evidence; stop and review')
        witnesses=[]
        for match in re.finditer(r'^c witness ([XZ])(?: \([^)]*\))?:\s*([0-9 ]+)\s*$',raw,re.M):
            support=list(map(int,match.group(2).split()));verify_witness(n,m,match.group(1),support)
            if j['reference_claim']=='exact' and len(support)<j['expected_d']:raise ValueError('witness contradicts exact claim')
            if len(support)<prior_lb:raise ValueError('word contradicts retained other-engine lower bound')
            witnesses.append(dict(half=match.group(1),support=support))
        status='PLAUSIBLE_ONE_ENGINE_EXACT' if result['status']=='SOLVED' else 'NO_EXACT_RESULT'
        results.append(dict(**identity,**result,actual_witnesses=witnesses,scientific_status=status))
        (args.out/'results.json').write_text(json.dumps(results,indent=2)+'\n');print(j['id'],result,flush=True)
    (args.out/'DONE').write_text('Recorded engine jobs completed; independent scientific review still required; no tier assignment.\n')


if __name__=='__main__':main()
