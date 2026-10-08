from pathlib import Path
import json,hashlib,subprocess,re,itertools,zipfile
root=Path(__file__).resolve().parent;tree=root/'GH48-ISA-V2';record=tree/'optimization/experiments/GH-48';raw=record/'raw';local=raw/'windows-tier0-01'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
catalog=json.loads((record/'raw-sha256.json').read_bytes());assert len(catalog)==793
for name,h in catalog.items():
    p=raw/name;assert sha(p)==h,name
    assert subprocess.check_output(['git','-C',str(tree),'show','HEAD:'+p.relative_to(tree).as_posix()],timeout=15)==p.read_bytes(),name
def span(rows):
    s={0}
    for row in rows:s|={a^row for a in s}
    return s
css={}
for stem in ['css1','css4','css5']:
    mats={suffix:[[int(v) for v in line.split()] for line in (local/(stem+'_'+suffix+'.txt')).read_text().splitlines() if line.strip()] for suffix in ['Hx','Hz','Gx','Gz']}
    n=len(mats['Hx'][0]);bits=lambda row:sum(v<<i for i,v in enumerate(row));hx=list(map(bits,mats['Hx']));hz=list(map(bits,mats['Hz']));sx=span(hx);sz=span(hz)
    css[stem]=min((x|z).bit_count() for x,z in itertools.product(range(1<<n),repeat=2) if all((h&z).bit_count()%2==0 for h in hx) and all((h&x).bit_count()%2==0 for h in hz) and (x not in sx or z not in sz))
assert css==dict(css1=1,css4=2,css5=1)
science=json.loads((local/'science.json').read_bytes());assert len(science)==50;fields=0;timeouts=0
for row in science:
    label=row['label'];expected=next((v for k,v in css.items() if label.startswith(k+'-')),None)
    if expected is None:expected=4 if 'LP_136_32_4' in label else 2 if 'LP_34_20_2' in label or '-pre-search-' in label or '-post-model-' in label else 8
    text=(local/(label+'.stdout')).read_text();result=row['result'];command=json.loads((local/(label+'.command.json')).read_bytes())
    assert command['returncode']==result['returncode'] and not command['owned_descendants_remaining']
    for key,pattern in [('lb',r'^c\s+d_lb:\s*(.*?)\s*$'),('ub',r'^c\s+d_ub:\s*(.*?)\s*$'),('d',r'^c\s+d\s*:\s*(.*?)\s*$'),('objective',r'^o(?:\s+(.*?))?\s*$')]:
        values=re.findall(pattern,text,re.M)
        for value in values:
            if value=='-' and key in ['lb','ub'] or value=='UNKNOWN' and key=='d':continue
            assert re.fullmatch(r'\d+',value),(label,key,value);v=int(value)
            assert v<=expected if key=='lb' else v==expected if key=='d' else v>=expected,(label,key,v,expected)
            fields+=1
        if result['returncode']==0:assert values and int(values[-1])==expected,(label,key)
    if result['returncode']==1:
        timeouts+=1;assert re.findall(r'^s\s+(.*?)\s*$',text,re.M)==['UNKNOWN'] and not re.search(r'^o(?:\s|$)',text,re.M)
        assert 'TIMEOUT' in text and result['timeout']
    else:assert result['returncode']==0 and not re.search(r'^s(?:\s|$)|^c\s+status:',text,re.M)
assert timeouts==12
oracles=json.loads((local/'pms-oracle.json').read_bytes());assert len(oracles)==36
for row in oracles:
    p=local/(row['stem']+'.wcnf');assert sha(p)==row['input_sha256'];clauses=[]
    for line in p.read_text().splitlines():
        if line.startswith('p '):_,_,ns,cs,top=line.split();n=int(ns);top=int(top)
        elif line and not line.startswith('c'):vals=list(map(int,line.split()));assert vals[-1]==0;clauses.append((vals[0],vals[1:-1]))
    sat=lambda c,a:any(bool(a&(1<<(abs(l)-1)))==(l>0) for l in c)
    exact=min(sum(w for w,c in clauses if w<top and not sat(c,a)) for a in range(1<<n) if all(sat(c,a) for w,c in clauses if w>=top));assert exact==row['oracle']
    tuples=[]
    for version in ['baseline','candidate']:
        label=row['stem']+'-'+version;text=(local/(label+'.stdout')).read_text();command=json.loads((local/(label+'.command.json')).read_bytes());rc=command['returncode']
        vals=re.findall(r'optimal:\s*([^\s,]+)',text);assert vals and all(re.fullmatch(r'\d+',v) and int(v)==exact for v in vals)
        statuses=re.findall(r'^s\s+(.*?)\s*$',text,re.M);assert rc in [10,20] and statuses==(['SATISFIABLE'] if rc==10 else ['UNSATISFIABLE']);tuples.append((rc,statuses,exact))
    assert tuples[0]==tuples[1]
summary=json.loads((local/'summary.json').read_bytes());assert summary['valid_run'] and summary['Tier0']=='LOCAL_PASS'
assert all(summary['cleanup'][k] for k in ['job_limit_released','affinity_restored','sleep_requirement_restored','priority_restored'])
assert json.loads((local/'runtime-post-file-set.json').read_bytes())['identical']
host=raw/'hosted-5f9a452';audit=json.loads((host/'audit.json').read_bytes());assert sha(host/'artifact.zip')=='451d63d84f4d55472d6eba77500175eec12035c63f2b1637381b5739afe20c38'
for row in audit['source_files']:
    a=subprocess.check_output(['git','-C',str(tree),'show',audit['merge']+':'+row['path']],timeout=10)
    b=subprocess.check_output(['git','-C',str(tree),'show',audit['production']+':'+row['path']],timeout=10);assert a==b and hashlib.sha256(a).hexdigest()==row['sha256']
assert audit['gate']['compatible'] and audit['gate']['level']=='x86-64-v2' and audit['gate']['leaf1_ecx'] & sum(1<<i for i in [0,9,13,19,20,23]) == sum(1<<i for i in [0,9,13,19,20,23]) and audit['gate']['ext_ecx'] & 1 == 1
proof=dict(status='INDEPENDENT_ROOT_GH48_TIER0_AUDIT_PASS',exact_public_raw_git_blobs=len(catalog),science=50,scientific_fields=fields,CSS=css,PMS=72,genuine_timeouts=12,hosted_source_files=len(audit['source_files']),performance='NOT_MEASURED',Tier1='NOT_RUN',controlled_claim=False)
(root/'GH48-root-tier0-audit.json').write_text(json.dumps(proof,indent=2),encoding='utf8',newline='\n');print(json.dumps(proof))
