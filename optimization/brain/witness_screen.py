"""Read-only Brain feasibility screen; not solver or performance evidence."""
import hashlib
import json
from pathlib import Path
import subprocess

BASELINE = '24572d6d09cce9a4a5faa58300a89e0feba9da6a'
ROOT = Path(__file__).resolve().parents[2]


def load(case, tag):
    name = f'data/matrices/{case}_{tag}.txt'
    data = subprocess.check_output(['git','show',BASELINE+':'+name],cwd=ROOT)
    rows = [[int(c) for c in line if c in '01'] for line in data.decode().splitlines()
            if line.strip() and not line.lstrip().startswith('#')]
    assert rows and all(len(r)==len(rows[0]) for r in rows)
    return rows, dict(path=name,sha256=hashlib.sha256(data).hexdigest())


def dot(a,b):
    assert len(a)==len(b)
    return sum(x*y for x,y in zip(a,b)) % 2


def main():
    results=[]
    for case in ('LP_136_32_4','BB_90_8_10','GB_144_12_8','BB_108_8_10','LP_238_44_6','LP_340_56_8'):
        inputs={tag:load(case,tag) for tag in ('Hx','Hz','Gx','Gz')}
        m={tag:value[0] for tag,value in inputs.items()}
        valid=[]
        rejected=0
        for typ,g,h,opposite in (('X','Gz','Hz','Gx'),('Z','Gx','Hx','Gz')):
            for i,row in enumerate(m[g]):
                if any(row) and all(dot(row,r)==0 for r in m[h]) and any(dot(row,r) for r in m[opposite]):
                    valid.append(dict(type=typ,row=i,weight=sum(row),bits=''.join(map(str,row))))
                else:
                    rejected+=1
        results.append(dict(case=case,validated_rows=len(valid),rejected_rows=rejected,
            inputs=[v[1] for v in inputs.values()],
            best=min(valid,key=lambda v:(v['weight'],v['type'],v['row'])) if valid else None))
    receipt=dict(baseline=BASELINE,kind='read-only feasible-witness screen',
        performance_test=False,optimality_claim=False,source='committed original matrices only',cases=results)
    output=ROOT/'optimization/brain/raw/round2-witness-screen.json'
    output.parent.mkdir(exist_ok=True)
    output.write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(json.dumps([dict(case=r['case'],valid=r['validated_rows'],best_weight=r['best']['weight']) for r in results]))


if __name__=='__main__':
    main()
