#!/usr/bin/env python3
"""One serial Linux short attempt per fixed case, with immediate word audit."""
import argparse
import json
from pathlib import Path
import subprocess
import sys
from audit_hyperbicycle_smoke import assess
from validate_css import read_code

ROOT=Path(__file__).resolve().parents[2]


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--ci',action='store_true',required=True)
    ap.add_argument('--engine',choices=('maxsat','cc'),required=True)
    ap.add_argument('--out',type=Path,required=True)
    a=ap.parse_args()
    a.out.mkdir(parents=True,exist_ok=False)
    cases=json.loads((ROOT/'scripts/codegen/hyperbicycle_cases.json').read_text())
    constructions={c['id']:c for c in json.loads((ROOT/'optimization/experiments/GH-205/raw/construction.json').read_text())['cases']}
    for case in cases:
        construction=constructions[case['id']];stem=construction['stem']
        out=a.out/stem
        subprocess.run([sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),
                        '--ci','--family','LP','--stems',stem,'--verbose',
                        '--engine',a.engine,'--out',str(out)],check=True,cwd=ROOT)
        n,matrices=read_code(ROOT/'data/matrices/untiered',stem)
        raw=(out/(stem+'.log')).read_text()
        result=assess(case,n,matrices,construction,{a.engine:raw})
        (out/'immediate-word-audit.json').write_text(json.dumps(result,indent=2)+'\n')
        print(json.dumps({k:v for k,v in result.items() if k!='witnesses'}),flush=True)


if __name__=='__main__':
    main()
