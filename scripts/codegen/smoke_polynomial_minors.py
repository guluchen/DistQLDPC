#!/usr/bin/env python3
"""Exactly one serial Linux short attempt per frozen polynomial-minor case and engine."""
import argparse
import json
from pathlib import Path
import subprocess
import sys
from audit_polynomial_minors_smoke import assess
from validate_css import read_code

ROOT=Path(__file__).resolve().parents[2]


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--ci',action='store_true',required=True)
    ap.add_argument('--engine',choices=('maxsat','cc'),required=True)
    ap.add_argument('--out',type=Path,required=True)
    a=ap.parse_args();a.out.mkdir(parents=True,exist_ok=False)
    cases=json.loads((ROOT/'scripts/codegen/polynomial_minors_cases.json').read_text())
    construction={c['id']:c for c in json.loads((ROOT/'optimization/experiments/GH-209/raw/construction.json').read_text())}
    for case in cases:
        c=construction[case['id']];stem=c['stem'];out=a.out/stem
        subprocess.run([sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),
                        '--ci','--family','PM','--stems',stem,'--verbose','--engine',a.engine,
                        '--out',str(out)],check=True,cwd=ROOT)
        n,matrices=read_code(ROOT/'data/matrices/untiered',stem)
        result=assess(case,n,matrices,c,{a.engine:(out/(stem+'.log')).read_text()})
        (out/'immediate-word-audit.json').write_text(json.dumps(result,indent=2)+'\n')
        print(json.dumps({k:v for k,v in result.items() if k!='witnesses'}),flush=True)


if __name__=='__main__':main()
