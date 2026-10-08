from pathlib import Path
import json,hashlib,subprocess,re,statistics,math
root=Path(__file__).resolve().parent;tree=root/'GH38-CLANG';folder=tree/'optimization/experiments/GH-38/raw/windows-tier1-01'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
catalog=json.loads((folder/'PUBLIC-SHA256.json').read_bytes())
for name,v in catalog['files'].items():
    p=folder/name;assert sha(p)==v['sha256']
    blob=subprocess.check_output(['git','-C',str(tree),'show','HEAD:'+p.relative_to(tree).as_posix()],timeout=10)
    assert blob==p.read_bytes(),name
samples=json.loads((folder/'samples.json').read_bytes());assert len(samples)==48
groups=[];fields=0
for case in ['BB_90_8_10','GB_144_12_8','BB_108_8_10','LP_238_44_6']:
    exact=int(case.rsplit('_',1)[1])
    for mode in ['no-card','card-mto']:
        rows=[r for r in samples if r['case']==case and r['mode']==mode]
        assert [(r['repeat'],r['version']) for r in rows]==[(1,'baseline'),(1,'candidate'),(2,'candidate'),(2,'baseline'),(3,'baseline'),(3,'candidate')]
        for row in rows:
            assert row['returncode']==0 and not row['resource_abort'] and not row['external_timeout']
            assert row['semantic']==dict(d=exact,objective=exact,lb=exact,ub=exact,timeout=False,unknown=False)
            label=f"{case}-{mode}-{row['repeat']}-{row['version']}"
            text=(folder/(label+'.stdout')).read_text();command=json.loads((folder/(label+'.command.json')).read_bytes())
            assert command['elapsed_sec']==row['elapsed_sec'] and command['returncode']==0 and not command['owned_descendants_remaining']
            for key,pattern in [('lb',r'^c\s+d_lb:\s*(.*?)\s*$'),('ub',r'^c\s+d_ub:\s*(.*?)\s*$'),('d',r'^c\s+d\s*:\s*(.*?)\s*$'),('objective',r'^o(?:\s+(.*?))?\s*$')]:
                vals=re.findall(pattern,text,re.M);assert vals
                for value in vals:
                    if value=='-' and key in ['lb','ub']:continue
                    assert re.fullmatch(r'\d+',value);n=int(value)
                    assert n<=exact if key=='lb' else n==exact if key=='d' else n>=exact
                    fields+=1
                assert int(vals[-1])==exact
            assert not re.search(r'^s(?:\s|$)|^c\s+status:',text,re.M)
        b=[r['elapsed_sec'] for r in rows if r['version']=='baseline'];c=[r['elapsed_sec'] for r in rows if r['version']=='candidate']
        groups.append(dict(case=case,mode=mode,ratio=statistics.median(c)/statistics.median(b),disjoint_regression=min(c)>max(b)))
result=json.loads((folder/'result.json').read_bytes());assert result['valid_run'] and result['decision']=='REJECT'
assert sum(g['ratio']>1 for g in groups)==7 and sum(g['disjoint_regression'] for g in groups)==6
assert all(json.loads((folder/'cleanup.json').read_bytes())[k] for k in ['job_limit_released','affinity_restored','sleep_requirement_restored','priority_restored'])
assert json.loads((folder/'remaining-owned.json').read_bytes())==[]
proof=dict(status='INDEPENDENT_ROOT_TIER1_AUDIT_PASS',raw_git_blobs=len(catalog['files']),science_solves=48,scientific_fields=fields,groups=groups,decision='LOCAL_REJECT_NOT_ADOPTED',controlled_claim=False,Tier2='NOT_RUN',Tier3='NOT_RUN')
(root/'GH38-root-tier1-audit.json').write_text(json.dumps(proof,indent=2),encoding='utf8',newline='\n');print(json.dumps(proof))
