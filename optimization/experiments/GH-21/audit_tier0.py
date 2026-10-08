"""Independent raw Tier0/provenance/capacity audit, no solver execution."""
import hashlib
import json
from pathlib import Path
import re
import sys

sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
def audit(directory):
    d=Path(directory).resolve();summary=read(d/'summary.json');identity=read(d/'identity.json')
    assert summary['Tier0']=='LOCAL_PASS' and summary['valid_run'] and summary['status']=='PREPARATORY_COMPLETE'
    assert summary['performance']=='NOT_MEASURED'
    assert summary['candidate']==identity['candidate']=='c64b0365a81bc62001194b0d49c481a5092b2ac0'
    assert identity['baseline']=='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
    for key in ['job_limit_released','affinity_restored','priority_restored','sleep_requirement_restored']:
        assert summary['cleanup'][key] is True
    assert summary['cleanup']['final_mask']==65535 and summary['cleanup']['final_priority_class']==32
    assert len(read(d/'job-pids-before-release.json'))==1
    for p in d.glob('owned-cleanup-*.json'):
        assert read(p)['confirmed'] and read(p)['remaining']==[]
    mask=identity['selection']['mask'] if 'mask' in identity['selection'] else None
    resources=read(d/'resources.json');assert resources
    assert all(r['eligible'] and r['idle_percent']>50 and r['half_spare_logical_cpus']>=1 for r in resources)
    masks={r['affinity'] for r in resources};assert len(masks)==1
    mask=masks.pop();assert mask and mask & (mask-1)==0
    descendants=read(d/'descendants.json')
    assert all(r['mask']==mask and r['priority_class']==32768 for row in descendants for r in row['records'])
    manifest=read(d/'SHA256.json')
    missing_private=[]
    for path,digest in manifest.items():
        p=d/Path(path.replace('\\','/'))
        if not p.exists() and p.suffix=='.exe':missing_private.append(path);continue
        assert sha(p)==digest,path
    tier=d/'tier0';assert read(tier/'summary.json')['Tier0']=='LOCAL_PASS'
    def science(label,expected,timeout=False):
        command=read(tier/(label+'.command.json'));text=(tier/(label+'.stdout')).read_text(encoding='utf-8')
        assert command['returncode']==(1 if timeout else 0)
        assert not command['owned_descendants_remaining']
        assert (tier/(label+'.stderr')).read_bytes()==b''
        specs={'lb':r'^c\s+d_lb:\s*(.*?)\s*$', 'ub':r'^c\s+d_ub:\s*(.*?)\s*$',
               'd':r'^c\s+d\s*:\s*(.*?)\s*$', 'objective':r'^o\s+(.*?)\s*$'}
        values={}
        for key,pattern in specs.items():
            raw=re.findall(pattern,text,re.M);nums=[]
            for value in raw:
                if value=='-' and key in ['lb','ub']:continue
                if value=='UNKNOWN' and key=='d':continue
                assert re.fullmatch(r'\d+',value),(label,key,value)
                v=int(value);nums.append(v)
                assert v<=expected if key=='lb' else v==expected if key=='d' else v>=expected,(label,key,v)
            values[key]=nums
        if timeout:
            assert 's UNKNOWN' in text and 'c status: TIMEOUT' in text
            assert not values['d'] and not values['objective']
        else:
            assert 's UNKNOWN' not in text and 'c status: TIMEOUT' not in text
            assert all(values[k] and values[k][-1]==expected for k in values)
    for stem,expected in [('css1',1),('css4',2),('css5',1)]:
        for mode in ['no-card','card-mto']:
            for version in ['baseline','candidate']:science(f'{stem}-{mode}-{version}',expected)
            baseline=tier/f'{stem}-{mode}-baseline.wcnf';candidate=tier/f'{stem}-{mode}-candidate.wcnf'
            assert baseline.read_bytes()==candidate.read_bytes()
            for version in ['baseline','candidate']:
                cmd=read(tier/f'{stem}-{mode}-{version}-dump.command.json')
                assert '-'+mode in cmd['argv'] and cmd['returncode']==0
    for version in ['baseline','candidate']:
        for mode in ['no-card','card-mto']:
            science(f'smoke-{version}-{mode}',2)
            science(f'timeout-{version}-{mode}',8,True)
    for stem,expected in [('pms-zero',0),('pms-conflict',1),('pms-triangle',2),('pms-cycle',2)]:
        statuses=[]
        for version in ['baseline','candidate']:
            text=(tier/f'{stem}-{version}.stdout').read_text(encoding='utf-8')
            command=read(tier/f'{stem}-{version}.command.json')
            assert command['returncode']==10 and not command['owned_descendants_remaining']
            assert int(re.findall(r'optimal:\s*(\d+)',text)[-1])==expected
            statuses.append(re.findall(r'^s\s+(.+)$',text,re.M))
        assert statuses[0]==statuses[1]
    for version in ['baseline','candidate']:
        cmd=read(d/'build-logs'/f'{version}-original-smoke-script.command.json')
        assert cmd['returncode']==0 and not cmd['owned_descendants_remaining']
    source_hashes=identity['source_hashes']
    # Exact executed support is copied into durable raw after completion.
    if (d/'executed-support').exists():
        for name,digest in identity['support_hashes'].items():assert sha(d/'executed-support'/name)==digest,name
        assert sha(d/'executed-support/window-helper.py')==identity['helper_sha256']
    report=dict(audit='PASS',production_candidate='e1aa9175c511b72dbb7305f5769b1e11f41bc05f',
       executed_support=summary['candidate'],css_solves=12,wcnf_pairs=6,pms_solves=8,smoke_solves=4,
       actual_solver_timeout_checks=4,original_smoke_scripts=2,resource_checks=len(resources),
       contention_alerts=sum(r['core_contention_detected'] for r in resources),
       minimum_global_idle=min(r['idle_percent'] for r in resources),
       private_exe_hash_only=missing_private,cleanup='PASS',performance='NOT_MEASURED')
    print(json.dumps(report,indent=2));return report

if __name__=='__main__':audit(sys.argv[1])
