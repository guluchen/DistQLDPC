#!/usr/bin/env python3
"""Linux-only, serial 60s untiered smoke package (HGP by default).

Server mode needs a PI-assigned free core; CI mode uses its ephemeral Actions VM.
Preserves logs, argv, binary/input hashes and raw bounds.
Writes a separate results CSV, leaving manifest edits for evidence review.
"""
import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import platform
import time

ROOT = Path(__file__).resolve().parents[2]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def parse(text, expected, exact=True):
    lbs = re.findall(r'^c d_lb:\s*(\d+)\s*$', text, re.M)
    ubs = re.findall(r'^c d_ub:\s*(\d+)\s*$', text, re.M)
    answers = re.findall(r'^o (\d+)\s*$', text, re.M)
    timed_out = 'c status: TIMEOUT (child killed after -cpu-lim)' in text and 's UNKNOWN' in text
    for kind in ('lb','ub'):
        events = re.findall(rf'^c d_{kind}:\s*(\d+|-)\s*$',text,re.M)
        if events and events[-1] == '-' and any(x != '-' for x in events):
            raise ValueError('previous numeric bound withdrawn; review required')
    if any(int(x)>expected for x in lbs) or (exact and any(int(x)<expected for x in ubs)):
        raise ValueError('bound contradicts reference distance claim')
    if any((int(x)!=expected if exact else int(x)>expected) for x in answers):
        raise ValueError('answer contradicts reference distance claim')
    # Zero is a weak but valid lower bound. A nonpositive upper bound or
    # exact answer is impossible for a nontrivial logical of these CSS codes.
    if any(int(x)<1 for x in ubs+answers):
        raise ValueError('nonpositive upper bound or exact distance')
    if lbs and ubs and max(map(int,lbs))>min(map(int,ubs)):
        raise ValueError('lower bound exceeds upper bound')
    if answers and (len(set(answers))!=1 or any(int(x)>int(answers[0]) for x in lbs)
                    or any(int(x)<int(answers[0]) for x in ubs)):
        raise ValueError('answer contradicts observed bounds')
    if (not lbs or not ubs) and (not timed_out or answers):
        raise ValueError('missing bounds; inspect load/run failure')
    if not lbs or not ubs:
        status = 'TIMEOUT_NO_BOUNDS' if not lbs and not ubs else 'TIMEOUT_PARTIAL_BOUNDS'
    else:
        status = 'SOLVED' if answers else 'BOUNDED'
    return dict(lb=max(map(int,lbs)) if lbs else None,
                ub=min(map(int,ubs)) if ubs else None, status=status)


def parse_claim(text,claim,n):
    tokens=claim.split()
    if len(tokens)<2 or tokens[0] not in ('exact','<=','estimate'):
        raise ValueError('unsupported reference claim')
    value=int(tokens[1])
    if not 1<=value<=n:raise ValueError('invalid reference endpoint')
    # An explicitly labelled decoder estimate is NOT a rigorous upper bound.
    # Keep generic result consistency checks and the physical n ceiling only.
    return parse(text,n if tokens[0]=='estimate' else value,exact=tokens[0]=='exact')


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--cpu', type=int, help='PI-assigned server core, check it is free first')
    ap.add_argument('--ci', action='store_true', help='ephemeral GitHub Actions runner only')
    ap.add_argument('--bin', type=Path, default=ROOT/'bin/distqldpc')
    ap.add_argument('--out', type=Path, required=True, help='new evidence directory')
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--family', default='HGP', choices=('HGP','COLOR','BB','BP','LP','HYP','PP','TOR','TN','GB','FBC','HPC','HCC','DHLV'), help='manifest family; default HGP')
    ap.add_argument('--engine', choices=('maxsat','cc'),default='maxsat',help='default MaxSAT or explicit CC cross-check')
    ap.add_argument('--stems', nargs='+', help='explicit subset of selected-family manifest stems')
    pre = ap.add_mutually_exclusive_group()
    pre.add_argument('--ub-pre', type=float, help='explicit supplemental pre-pass seconds; default unchanged')
    pre.add_argument('--ub-pre-off', action='store_true', help='explicit supplemental -ub-pre=off')
    ap.add_argument('--verbose', action='store_true')
    args = ap.parse_args()
    if args.ci:
        if os.environ.get('GITHUB_ACTIONS') != 'true' or not sys.platform.startswith('linux'):
            ap.error('--ci requires a Linux GitHub Actions runner')
        if args.cpu is not None:
            ap.error('--ci selects from its allocated runner affinity; omit --cpu')
        args.cpu = min(os.sched_getaffinity(0))
    elif args.cpu is None:
        ap.error('server mode requires --cpu with a PI-assigned core')
    rows = list(csv.DictReader((ROOT/'data/matrices/untiered/MANIFEST.csv').open()))
    available = {r['stem'] for r in rows if r['family']==args.family}
    if args.stems and not set(args.stems).issubset(available):
        ap.error('unknown stem in selected family')
    if args.ub_pre is not None and not 0 < args.ub_pre <= 60:
        ap.error('--ub-pre must be > 0 and <= 60 seconds')
    jobs = []
    for row in rows:
        if row['family'] != args.family or (args.stems and row['stem'] not in args.stems):
            continue
        cmd = ['taskset','-c',str(args.cpu),'prlimit','--as=4294967296','--',
               str(args.bin.resolve()),'-cpu-lim=60']
        if args.engine=='cc':
            cmd.append('-engine=cc')
        if args.ub_pre is not None:
            cmd.append(f'-ub-pre={args.ub_pre:g}')
        if args.ub_pre_off:
            cmd.append('-ub-pre=off')
        if args.verbose:
            cmd.append('-v')
        cmd.append(f'data/matrices/untiered/{row["stem"]}')
        jobs.append((row,cmd))
    if args.dry_run:
        print(json.dumps([cmd for _,cmd in jobs],indent=2))
        return
    if not sys.platform.startswith('linux'):
        ap.error('execution is Linux-server only; use --dry-run to inspect jobs')
    if args.cpu not in os.sched_getaffinity(0):
        ap.error('core outside allowed affinity')
    # A snapshot supplements, but does not replace, the operator free-core check.
    for proc in [] if args.ci else Path('/proc').glob('[0-9]*/status'):
        try:
            text = proc.read_text()
        except (OSError,ProcessLookupError):
            continue
        if re.search(rf'^Cpus_allowed_list:\s*{args.cpu}\s*$',text,re.M):
            ap.error(f'core already has a pinned process: {proc}')
    args.out.mkdir(parents=True,exist_ok=False)
    (args.out/'environment.json').write_text(json.dumps({
        'platform': platform.platform(), 'python':sys.version,
        'environment':'github-actions' if args.ci else 'dedicated-server',
        'run_id':os.environ.get('GITHUB_RUN_ID'),
        'run_attempt':os.environ.get('GITHUB_RUN_ATTEMPT'),
        'source_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        'cpu':args.cpu, 'cpu_limit':60, 'wall_backstop':90,
        'address_space_limit':4294967296,
        'compiler':subprocess.check_output(['c++','--version'],text=True).splitlines()[0],
    },indent=2)+'\n')
    records = []
    for row,cmd in jobs:
        stem = row['stem']
        identity = {kind:sha(ROOT/f'data/matrices/untiered/{stem}_{kind}.txt')
                    for kind in ('Hx','Hz','Gx','Gz')}
        meta = {'cmd':cmd,'binary_sha256':sha(args.bin),'input_sha256':identity,
                'source_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()}
        (args.out/f'{stem}.json').write_text(json.dumps(meta,indent=2)+'\n')
        with (args.out/f'{stem}.log').open('w') as log:
            started = time.monotonic()
            proc = subprocess.Popen(cmd,cwd=ROOT,stdin=subprocess.DEVNULL,
                                    stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
            try:
                rc = proc.wait(timeout=90)
            except subprocess.TimeoutExpired:
                os.killpg(proc.pid,signal.SIGKILL)
                proc.wait()
                raise RuntimeError(f'{stem}: wall backstop hit; inspect raw log')
        meta.update(rc=rc,wall_seconds=round(time.monotonic()-started,3))
        (args.out/f'{stem}.json').write_text(json.dumps(meta,indent=2)+'\n')
        print(f'--- RAW LOG {stem} ---',flush=True)
        print((args.out/f'{stem}.log').read_text(),end='',flush=True)
        result = parse_claim((args.out/f'{stem}.log').read_text(),row['claimed_d'],int(row['n']))
        if rc not in (0,1) or (rc == 0) != (result['status']=='SOLVED'):
            raise RuntimeError(f'{stem}: unexpected exit status {rc}')
        meta.update(**result)
        (args.out/f'{stem}.json').write_text(json.dumps(meta,indent=2)+'\n')
        records.append(dict(stem=stem,rc=rc,**result))
        with (args.out/'results.csv').open('w',newline='') as f:
            writer = csv.DictWriter(f,fieldnames=['stem','rc','lb','ub','status'])
            writer.writeheader()
            writer.writerows(records)
        print(stem,result,flush=True)
    (args.out/'DONE').write_text(f'{len(records)} smoke runs; review before updating manifest\n')
    print('GH153_EVIDENCE_JSON='+json.dumps({p.name:p.read_text() for p in args.out.iterdir() if p.is_file()},separators=(',',':')),flush=True)


if __name__ == '__main__':
    main()
