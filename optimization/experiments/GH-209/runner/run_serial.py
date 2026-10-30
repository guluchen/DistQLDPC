#!/usr/bin/env python3
"""Frozen remaining minor-CSS gates and optional research; dry by default."""
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
from audit_polynomial_minors_smoke import assess,claim
from smoke_untiered import parse_claim
from validate_css import read_code
from verify_css_witness import verify_witness

SOURCE='b859a70a30b0be63a26d2d2df68024a406927d54'
CASES_SHA='a91c244757cc21eea4dbac2c05f90374bf6afd869e6cd9a07fc355088359e7ff'
QUEUES=('jobs.jsonl','optional-maxsat-jobs.jsonl','optional-cc-jobs.jsonl')


def need(ok,message):
    if not ok:raise ValueError(message)


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def make_queues(observations,cases):
    """Known controls must reproduce; unresolved targets need no forced exact."""
    need(len(observations)==len(cases),'missing or extra frozen case records')
    outputs={name:[] for name in QUEUES}
    for c,p in zip(cases,observations):
        stem=f'PM_{3*c["lift"]}_{c["k"]}_unknown'
        need(stem==p['stem'],'frozen case/audit order differs')
        known=p['actual_verified_upper'];word_targets=[]
        for engine in ('maxsat','cc'):
            r=p['engines'][engine];answer=p['explicit_exact_answers'].get(engine)
            missing=r['lb'] is None or r['ub'] is None
            source_incomplete=c['published_exact'] is not None and answer!=c['published_exact']
            if r['ub'] is not None and known>r['ub']:word_targets.append(r['ub'])
            if answer is not None and not any(w['weight']==answer for w in p['witnesses']):word_targets.append(answer)
            required=missing or source_incomplete
            if not required and r['status']=='SOLVED':continue
            purpose='numeric-proof' if missing else 'source-proof' if source_incomplete else 'optional-search'
            job=dict(id=stem+'-'+engine,stem=stem,engine=engine,purpose=purpose,limit=21600,
                code='data/matrices/untiered/'+stem,args=(['-engine=cc'] if engine=='cc' else [])+['-seed=0','-v'],
                reference_claim=claim(c),verified_upper=known,word_target=None)
            outputs['jobs.jsonl' if required else 'optional-'+engine+'-jobs.jsonl'].append(job)
        if word_targets:
            outputs['jobs.jsonl'].append(dict(id=stem+'-word',stem=stem,engine='cc',purpose='word',limit=21600,
                code='data/matrices/untiered/'+stem,args=['-engine=cc','-seed=0','-v','-ub-search=budget:600','-cc-ub-only'],
                reference_claim=claim(c),verified_upper=known,word_target=min(word_targets)))
    return outputs


def verify_solver_sources():
    for target,expected in [('HEAD:src','19cbea916c41b3918de87f86791da9f1c80abbbd'),
                            ('HEAD:Makefile','1951a24d5de920a651ad3919c672331862976365')]:
        need(subprocess.check_output(['git','rev-parse',target],cwd=ROOT,text=True).strip()==expected,'frozen source/build changed')
    need(subprocess.run(['git','diff','--quiet','HEAD','--','src','Makefile'],cwd=ROOT).returncode==0,'dirty solver/build')


def core_free(cpu):
    need(cpu in os.sched_getaffinity(0),'core outside allowed affinity')
    for status in Path('/proc').glob('[0-9]*/status'):
        try:
            if status.parent.name==str(os.getpid()) or not (status.parent/'cmdline').read_bytes():continue
            body=status.read_text()
        except OSError:continue
        need(not re.search(rf'^Cpus_allowed_list:\s*{cpu}\s*$',body,re.M),'core already has pinned userspace process '+status.parent.name)


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--cpu',type=int,required=True);ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--bin',type=Path,default=ROOT/'bin/distqldpc')
    ap.add_argument('--jobs',type=Path,default=Path(__file__).with_name('jobs.jsonl'))
    ap.add_argument('--execute',action='store_true');ap.add_argument('--allocation-ref')
    ap.add_argument('--core-confirmed-free',action='store_true');a=ap.parse_args()
    case_path=ROOT/'scripts/codegen/polynomial_minors_cases.json'
    need(sha(case_path)==CASES_SHA,'frozen case definitions changed')
    cases=json.loads(case_path.read_text());raw=Path(__file__).parents[1]/'raw'
    observations=json.loads((raw/'actions/default/audit.json').read_text())
    recipes=make_queues(observations,cases)
    need(a.jobs.resolve() in {Path(__file__).with_name(k).resolve() for k in QUEUES},'only canonical frozen queues are allowed')
    jobs=[json.loads(line) for line in a.jobs.read_text().splitlines() if line.strip()]
    need(jobs==recipes[a.jobs.name],'queue differs from frozen unfinished gates/optional research')
    construction={r['stem']:r for r in json.loads((raw/'construction.json').read_text())}
    old={r['stem']:r for r in observations};case_map={r['stem']:c for c,r in zip(cases,observations)}
    commands=[];identities={}
    for j in jobs:
        p=old[j['stem']]
        meta=json.loads((raw/'actions/default'/j['engine']/j['stem']/(j['stem']+'.json')).read_text())
        need(meta['source_head']==SOURCE==p['source_head'],'retained native source differs')
        need(set(meta['input_sha256'])=={'Hx','Hz','Gx','Gz'},'missing input identity')
        for kind,digest in meta['input_sha256'].items():need(sha(ROOT/f'{j["code"]}_{kind}.txt')==digest,'physical input changed')
        n,m=read_code(ROOT/'data/matrices/untiered',j['stem'])
        for w in p['witnesses']:
            verify_witness(n,m,w['half'],w['support']);need(w['weight']==len(w['support']),'retained word weight differs')
        need(min(w['weight'] for w in p['witnesses'])==j['verified_upper'],'upper lacks actual GF2 word')
        identities[j['stem']]=meta['input_sha256']
        commands.append(['taskset','-c',str(a.cpu),'prlimit','--as=4294967296','--',str(a.bin.resolve())]
                        +j['args']+['-cpu-lim=21600',j['code']])
    if not a.execute:print(json.dumps(commands,indent=2));return
    need(sys.platform.startswith('linux') and platform.node().split('.')[0]=='yfclab2','yfclab2 execution only')
    need(a.allocation_ref and a.core_confirmed_free,'explicit PI allocation and fresh free-core confirmation required')
    need(jobs,'no unfinished jobs in selected queue')
    need(not subprocess.check_output(['git','status','--porcelain'],cwd=ROOT,text=True).strip(),'clean frozen checkout required')
    verify_solver_sources();core_free(a.cpu);a.out.mkdir(parents=True,exist_ok=False)
    head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip();binary=sha(a.bin)
    (a.out/'config.json').write_text(json.dumps(dict(source_head=head,bounded_source=SOURCE,binary_sha256=binary,
        input_sha256=identities,cases_sha256=CASES_SHA,jobs_sha256=sha(a.jobs),jobs=jobs,commands=commands,
        cpu=a.cpu,address_space_limit=4294967296,allocation_ref=a.allocation_ref,hostname=platform.node()),indent=2)+'\n')
    for j,cmd in zip(jobs,commands):
        core_free(a.cpu);need(sha(a.bin)==binary,'binary changed')
        for kind,digest in identities[j['stem']].items():need(sha(ROOT/f'{j["code"]}_{kind}.txt')==digest,'input changed')
        path=a.out/(j['id']+'.log');started=time.monotonic();killed=False
        with path.open('w') as output:
            proc=subprocess.Popen(cmd,cwd=ROOT,stdin=subprocess.DEVNULL,stdout=output,stderr=subprocess.STDOUT,start_new_session=True)
            try:rc=proc.wait(timeout=j['limit']+600)
            except subprocess.TimeoutExpired:killed=True;os.killpg(proc.pid,signal.SIGKILL);rc=proc.wait()
        record=dict(job=j,source_head=head,binary_sha256=binary,input_sha256=identities[j['stem']],cmd=cmd,
                    rc=rc,wall_seconds=time.monotonic()-started,runner_backstop=killed)
        receipt=a.out/(j['id']+'.json');receipt.write_text(json.dumps(record,indent=2)+'\n')
        need(not killed,'wall backstop; retain evidence and stop for review')
        need(sha(a.bin)==binary,'binary changed during run')
        for kind,digest in identities[j['stem']].items():need(sha(ROOT/f'{j["code"]}_{kind}.txt')==digest,'input changed during run')
        c=case_map[j['stem']];n,m=read_code(ROOT/'data/matrices/untiered',j['stem'])
        parsed=parse_claim(path.read_text(),j['reference_claim'],n)
        need(rc in (0,1) and (rc==0)==(parsed['status']=='SOLVED'),'exit/result mismatch')
        p=old[j['stem']];seeded=dict(construction[j['stem']],actual_words=p['witnesses'])
        result=assess(c,n,m,seeded,{j['engine']:path.read_text()})
        old_lb=max([r['lb'] for r in p['engines'].values() if r['lb'] is not None]+list(p['explicit_exact_answers'].values())+[c.get('published_lower') or 1])
        old_ub=min([r['ub'] for r in p['engines'].values() if r['ub'] is not None]+[p['actual_verified_upper']])
        need(parsed['lb'] is None or parsed['lb']<=old_ub,'new lower contradicts prior upper/word')
        need(parsed['ub'] is None or parsed['ub']>=old_lb,'new upper contradicts prior lower/exact')
        complete=(parsed['lb'] is not None and parsed['ub'] is not None)
        if c['published_exact'] is not None:complete &= result['explicit_exact_answers'].get(j['engine'])==c['published_exact']
        if j['purpose']=='word':complete &= result['actual_verified_upper']<=j['word_target']
        complete &= result['reported_upper_word_gate']=='PASS' and result['exact_minimum_word_gate']=='PASS'
        record.update(result=parsed,audit=result,gate='PASS' if complete else 'INCOMPLETE',
                      scientific_status='PLAUSIBLE until independent retained-result/word review')
        receipt.write_text(json.dumps(record,indent=2)+'\n');print(json.dumps(dict(id=j['id'],gate=record['gate'],**parsed)),flush=True)


if __name__=='__main__':main()
