#!/usr/bin/env python3
import json,subprocess
from pathlib import Path
results=[]
for mutant in range(1,6):
 name='mutant-%d.so'%mutant
 subprocess.run(['gcc','-std=c99','-O1','-fPIC','-shared','-DCCV_MUTANT=%d'%mutant,'ccv.c','ccv_primitives.c','-o',name],check=True)
 r=subprocess.run(['python3','-B','tests/test_ccv.py',name,'--quick'],text=True,capture_output=True)
 Path('mutant-%d.log'%mutant).write_text(r.stdout+r.stderr)
 assert r.returncode==1 and 'AssertionError:' in r.stderr,('mutant not caught by semantic oracle',mutant,r.returncode,r.stdout,r.stderr)
 results.append(dict(mutant=mutant,caught=True,diagnostic=r.stderr.splitlines()[-1]))
print(json.dumps(dict(status='PASS',mutants=results,proof_claim=False)))
