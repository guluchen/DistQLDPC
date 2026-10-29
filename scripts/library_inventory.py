#!/usr/bin/env python3
"""Index pinned Git manifests and file identities, never run a solver or fetch.

Counts describe stored stems/file versions, not inequivalent codes or families.
All scientific metadata is retained verbatim, including empty raw fields.
"""
import argparse
import csv
import hashlib
import io
import json
from pathlib import Path
import re
import subprocess

ROOT=Path(__file__).resolve().parents[1]
KINDS=('Hx','Hz','Gx','Gz')
BASE='data/matrices/untiered/'
MATRIX=re.compile(r'(.+)_(Hx|Hz|Gx|Gz)\.txt$')
QUEUE=re.compile(r'optimization/experiments/GH-[0-9]+/runner/[^/]*jobs\.jsonl$')


class GitReader:
    def __init__(self,root):self.root=root
    def text(self,sha,path):
        return subprocess.check_output(['git','show',sha+':'+path],cwd=self.root,text=True)
    def tree(self,sha):
        text=subprocess.check_output(['git','ls-tree','-r',sha],cwd=self.root,text=True)
        entries={}
        for line in text.splitlines():
            metadata,path=line.split('\t',1);mode,kind,blob=metadata.split()
            if kind=='blob':entries[path]=blob
        return entries


def ref_url(ref,path):
    return 'https://github.com/guluchen/DistQLDPC/blob/'+ref['sha']+'/'+path


def grouped_matrices(tree,prefix,flat=True):
    result={}
    for path,blob in sorted(tree.items()):
        if not path.startswith(prefix):continue
        relative=path[len(prefix):]
        if flat and '/' in relative:continue
        match=MATRIX.fullmatch(relative)
        if match:result.setdefault(match[1],{})[match[2]]=dict(path=path,blob=blob)
    for stem,files in result.items():
        if flat and set(files)!=set(KINDS):raise ValueError('incomplete four-file input: '+prefix+stem)
    return result


def pinned_refs(config):
    if config.get('schema_version')!=1:raise ValueError('unsupported refs schema')
    refs=[config['main']]+config['libraries'];names=set()
    for ref in refs:
        if ref['branch'] in names:raise ValueError('duplicate branch pin')
        names.add(ref['branch'])
        if not re.fullmatch('[0-9a-f]{40}',ref['sha']):raise ValueError('full immutable SHA required')
    return refs


def build(config,reader):
    refs=pinned_refs(config);codes={};quarantine={};queues={};packages=[];main_tiers=[];unparsed={}
    for ref in refs:
        tree=reader.tree(ref['sha']);flat=grouped_matrices(tree,BASE)
        raw=reader.text(ref['sha'],BASE+'MANIFEST.csv')
        rows=list(csv.DictReader(io.StringIO(raw)))
        stems=[row.get('stem') for row in rows]
        if len(stems)!=len(set(stems)) or set(stems)!=set(flat):raise ValueError('manifest/flat inventory mismatch: '+ref['branch'])
        for row in rows:
            stem=row['stem'];n=int(row['n']);k=int(row['k'])
            if n<1 or not 0<k<=n or stem.split('_')[:3]!=[row['family'],str(n),str(k)]:
                raise ValueError('manifest/stem parameter mismatch: '+stem)
            key=json.dumps({kind:flat[stem][kind]['blob'] for kind in KINDS},sort_keys=True)
            version=hashlib.sha256(key.encode()).hexdigest()
            code=codes.setdefault(stem,dict(stem=stem,family_prefix=row['family'],n=n,k=k,versions={}))
            v=code['versions'].setdefault(version,dict(file_set_id=version,files=flat[stem],observations={}))
            metadata_id=hashlib.sha256(json.dumps(row,sort_keys=True).encode()).hexdigest()
            observation=v['observations'].setdefault(metadata_id,dict(manifest=row,locations=[]))
            observation['locations'].append(dict(ref=ref,manifest_url=ref_url(ref,BASE+'MANIFEST.csv')))
        held=grouped_matrices(tree,BASE+'quarantine/',flat=False)
        for name,files in held.items():
            key=json.dumps(files,sort_keys=True)
            record=quarantine.setdefault(key,dict(source_claimed_path_stem=name,files=files,
                missing_kinds=sorted(set(KINDS)-set(files)),locations=[]))
            record['locations'].append(dict(ref=ref,readme_url=ref_url(ref,BASE+'quarantine/'+str(Path(name).parent)+'/README.md')))
        queue_paths=[]
        for path,blob in sorted(tree.items()):
            if '/runner/' not in path or not re.search(r'job.*\.(?:jsonl|csv|tsv)$',Path(path).name):continue
            if not QUEUE.fullmatch(path):
                item=unparsed.setdefault((path,blob),dict(path=path,blob=blob,locations=[]))
                item['locations'].append(dict(ref=ref,url=ref_url(ref,path)));continue
            job_rows=[json.loads(line) for line in reader.text(ref['sha'],path).splitlines() if line.strip()]
            if any(not isinstance(row,dict) for row in job_rows):raise ValueError('non-object queue entry: '+path)
            runner_path=str(Path(path).with_name('run_serial.py'));runner_blob=tree.get(runner_path)
            key=(path,blob,runner_blob)
            record=queues.setdefault(key,dict(path=path,blob=blob,runner_path=runner_path if runner_blob else None,
                runner_blob=runner_blob,jobs=job_rows,locations=[]))
            record['locations'].append(dict(ref=ref,url=ref_url(ref,path)))
            queue_paths.append(path)
        packages.append(dict(ref=ref,flat_manifest_rows=len(rows),quarantined_candidates=len(held),queue_paths=queue_paths))
        if ref['branch']==config['main']['branch']:
            for tier in range(6):
                matrix_sets=grouped_matrices(tree,'data/matrices/tier%d/'%tier)
                main_tiers.append(dict(tier=tier,count=len(matrix_sets),inputs=matrix_sets))
    out_codes=[]
    for stem,code in sorted(codes.items()):
        code['versions']=[v for _,v in sorted(code['versions'].items())]
        for v in code['versions']:v['observations']=[obs for _,obs in sorted(v['observations'].items())]
        out_codes.append(code)
    same_n_k={}
    for code in out_codes:same_n_k.setdefault((code['n'],code['k']),[]).append('untiered:'+code['stem'])
    for tier in main_tiers:
        for stem in tier['inputs']:
            fields=stem.split('_')
            if len(fields)<3 or not all(s.isdigit() for s in fields[1:3]):raise ValueError('main tier stem lacks n,k: '+stem)
            same_n_k.setdefault((int(fields[1]),int(fields[2])),[]).append('tier%d:%s'%(tier['tier'],stem))
    peer_groups=[dict(n=n,k=k,stems=stems,status='REVIEW_GROUP_ONLY_NOT_EQUIVALENCE_PROOF')
                 for (n,k),stems in sorted(same_n_k.items()) if len(stems)>1]
    identities={}
    for code in out_codes:
        for version in code['versions']:identities.setdefault(version['file_set_id'],[]).append(code['stem'])
    aliases=[dict(file_set_id=key,stems=sorted(set(stems))) for key,stems in sorted(identities.items()) if len(set(stems))>1]
    queue_list=[]
    for _,record in sorted(queues.items(),key=lambda item:str(item[0])):
        limits=[row.get('limit') for row in record['jobs']]
        known=all(isinstance(x,(int,float)) and not isinstance(x,bool) and x>0 for x in limits)
        record['declared_cpu_limit_sum_seconds']=sum(limits) if known else None
        record['limit_semantics']='declared limit fields only; unknown stays null; not ETA or authorization'
        queue_list.append(record)
    memberships=sum(p['flat_manifest_rows'] for p in packages)
    return dict(schema_version=1,scope=config['scope'],pins=config,
        semantics=dict(parameters='manifest/filename only; no GF2 rerun',
            identity='Git blob sets including headers; different identity is not proof of inequivalence',
            metadata='verbatim per-ref manifest records; not re-certified or promoted',
            queue_status='declared retained plans, not proof of pending/unexecuted/required jobs; consult package report',
            quarantine='excluded from flat manifest/stem/family and main-tier counts'),
        summary=dict(pinned_refs=len(refs),manifest_memberships=memberships,distinct_stems=len(codes),
            stored_four_file_versions=len(identities),
            identical_file_set_alias_groups=len(aliases),
            repeated_stem_memberships=memberships-len(codes),
            main_untiered_rows=packages[0]['flat_manifest_rows'],main_tiered_inputs=sum(t['count'] for t in main_tiers),
            quarantined_candidate_versions=len(quarantine),retained_queue_versions=len(queue_list),
            distinct_manifest_records=sum(len(v['observations']) for c in out_codes for v in c['versions']),
            unparsed_job_files=len(unparsed)),
        packages=packages,codes=out_codes,main_tiers=main_tiers,
        same_n_k_review_groups=peer_groups,
        identical_file_set_aliases=aliases,
        quarantined=[record for _,record in sorted(quarantine.items())],
        queue_versions=queue_list,unparsed_job_files=[item for _,item in sorted(unparsed.items())])


def markdown(result):
    s=result['summary'];lines=['# Pinned cross-branch library index','',
        'This is an inventory of stored inputs and retained metadata, not a count of',
        'independent code families, proven distances, or accepted additions to main.',
        'No source-dependent scientific hold is waived by this index.','',
        '* %d pinned refs; main has %d tiered and %d untiered entries.'%(s['pinned_refs'],s['main_tiered_inputs'],s['main_untiered_rows']),
        '* %d manifest memberships collapse to %d distinct stems (%d repeated memberships).'%(s['manifest_memberships'],s['distinct_stems'],s['repeated_stem_memberships']),
        '* %d stored four-file versions; %d quarantined candidates excluded from those counts.'%(s['stored_four_file_versions'],s['quarantined_candidate_versions']),
        '* %d retained queue versions; %d other job files listed without parsing.'%(s['retained_queue_versions'],s['unparsed_job_files']),'',
        'Different Git file identities can reflect headers or logical-basis changes;',
        'they do not prove physical inequivalence. Same-(n,k) groups require the',
        'original rowspace/permutation reviews. Source claims, empty fields and raw',
        'bounds are preserved verbatim per ref in INDEX.json. No synthetic bound',
        'or scientific completion label is inferred from a green check or filename.','',
        '## Pinned packages','',
        '| Branch | Commit | Manifest rows | Quarantined | Queue files |',
        '|---|---|---:|---:|---:|']
    for p in result['packages']:
        r=p['ref'];url='https://github.com/guluchen/DistQLDPC/tree/'+r['sha']
        lines.append('|'+r['branch']+'|['+r['sha'][:12]+']('+url+')|'+str(p['flat_manifest_rows'])+'|'+str(p['quarantined_candidates'])+'|'+str(len(p['queue_paths']))+'|')
    lines+=['','## Configured scientific holds','',
        'This list tracks explicit snapshot decisions. The [coverage ledger]',
        '(../CSS_LIBRARY_COVERAGE.md) retains other source/proof/integration gaps.','']
    for hold in result['pins'].get('scientific_holds',[]):
        lines.append('* [GH-%d](https://github.com/guluchen/DistQLDPC/issues/%d): %s. %s'%(hold['issue'],hold['issue'],hold['status'],hold['decision']))
    lines+=['','## Retained queues','',
        'These are versioned queue records, including optional/historical plans.',
        'They are not added together as a mandatory workload or execution ETA.',
        'Each linked package report/runner controls source guards, allocation,',
        'selection and whether a job is still needed. No core is allocated here.','',
        '| Source package | Queue | Records | Declared CPU limit sum (seconds) |',
        '|---|---|---:|---:|']
    for q in result['queue_versions']:
        loc=q['locations'][0];r=loc['ref'];limit=q['declared_cpu_limit_sum_seconds']
        lines.append('|'+r['branch']+'@'+r['sha'][:8]+'|['+q['path']+']('+loc['url']+')|'+str(len(q['jobs']))+'|'+('unknown' if limit is None else str(limit))+'|')
    lines+=['','## Reproduction','',
        'Run `python3 scripts/library_inventory.py --check` with the pinned Git',
        'objects present. Missing objects/files and inconsistent inventories fail.',
        'To regenerate, omit `--check`. The script performs no network access,',
        'distance search, matrix generation, merge, or server execution.',
        'REFS.json is an explicit historical snapshot; refresh pins deliberately.','']
    return '\n'.join(lines)


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--repo',type=Path,default=ROOT)
    ap.add_argument('--refs',type=Path,default=ROOT/'docs/library/REFS.json')
    ap.add_argument('--out',type=Path,default=ROOT/'docs/library')
    ap.add_argument('--check',action='store_true');a=ap.parse_args()
    result=build(json.loads(a.refs.read_text()),GitReader(a.repo))
    outputs={'INDEX.json':json.dumps(result,indent=2)+'\n','INDEX.md':markdown(result)}
    if not a.check:a.out.mkdir(parents=True,exist_ok=True)
    for name,text in outputs.items():
        path=a.out/name
        if a.check:
            if not path.exists() or path.read_text()!=text:raise ValueError('inventory snapshot stale: '+str(path))
        else:path.write_text(text)
    print(json.dumps(result['summary'],sort_keys=True))


if __name__=='__main__':main()
