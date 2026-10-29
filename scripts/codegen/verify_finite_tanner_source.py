#!/usr/bin/env python3
"""Original numeric-only provenance audit; GPL3+, source data MIT credited in NOTICE."""
import sys,json,hashlib,argparse,urllib.request,urllib.parse
import h5py
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
from finite_tanner import group_data,multiply,inverse,checks
from validate_css import equal_space
ap=argparse.ArgumentParser(description='Verify pinned numeric HDF5 parameters and source matrix equivalence; requires h5py only for this optional audit')
ap.add_argument('--cache',type=Path,required=True);ap.add_argument('--out',type=Path,required=True);ap.add_argument('--fetch',action='store_true');args=ap.parse_args()
args.cache.mkdir(parents=True,exist_ok=True)
records=[]
for c in json.loads((ROOT/'scripts/codegen/finite_tanner_cases.json').read_text()):
 group,a,b=group_data(c);p=len(group);nb=len(b);ha,ga,hb,gb=[c[k] for k in ('H_A','G_A','H_B','G_B')]
 permute=lambda rows,pi:[[row[j-1] for j in pi] for row in rows]
 g1a=permute(ga,c['pi_A']);h1b=permute(hb,c['pi_B'])
 path=args.cache/Path(c['source_path']).name
 if not path.exists():
  if not args.fetch:raise FileNotFoundError(path)
  url='https://raw.githubusercontent.com/QuantumSavory/Quantum-Tanner-Codes-at-Moderate-Blocklength/'+c['source_commit']+'/'+urllib.parse.quote(c['source_path'])
  data=urllib.request.urlopen(url,timeout=60).read(16777217)
  if len(data)>16777216:raise ValueError('source file exceeds cap')
 else:data=path.read_bytes()
 if hashlib.sha256(data).hexdigest()!=c['source_sha256'] or hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()!=c['source_blob']:raise ValueError('source identity mismatch')
 if not path.exists():path.write_bytes(data)
 with h5py.File(path) as f:
  params={k:(v[()].decode() if isinstance(v[()],bytes) else v[()].tolist()) for k,v in f['reconstruction'].items()}
  if params!=c['source_reconstruction']:raise ValueError('source mathematical projection mismatch')
  x=f['parity_matrix_x'][()].T.tolist();z=f['parity_matrix_z'][()].T.tolist()
 def action(i,j,ra,rb,top):
  nrb=len(h1b) if top else len(hb);offset=0 if top else len(ga)*len(h1b)*p
  result=[]
  for g in range(p):
   block=z[offset+(ra*nrb+rb)*p+g][(i*nb+j)*p:(i*nb+j+1)*p]
   assert sum(block)==1,(c['n'],i,j,g,block)
   result.append(block.index(1))
  return result
 left=[]
 for i in range(len(a)):
  ra=next(r for r in range(len(g1a)) if g1a[r][i]);j=0;rb=next(r for r in range(len(hb)) if hb[r][j]);left.append(action(i,j,ra,rb,False))
 right=[]
 for j in range(nb):
  i=0;ra=next(r for r in range(len(ga)) if ga[r][i]);rb=next(r for r in range(len(h1b)) if h1b[r][j]);right.append(action(i,j,ra,rb,True))
 labels=None
 for root in range(p):
  lab={root:tuple(range(len(group[0])))};todo=[root];valid=True
  for g in todo:
   for t,act in zip(a,left):
    h=act[g];val=multiply(t,lab[g])
    if h in lab and lab[h]!=val:valid=False;break
    if h not in lab:lab[h]=val;todo.append(h)
   if not valid:break
  if not valid or len(set(lab.values()))!=p:continue
  if any(lab[act[g]]!=multiply(lab[g],inverse(t)) for t,act in zip(b,right) for g in range(p)):continue
  labels=lab;break
 assert labels is not None,('no common source group enumeration',c['n'])
 index={g:i for i,g in enumerate(group)};mapping=[(q//p)*p+index[labels[q%p]] for q in range(c['n'])]
 bitrows=lambda rows:[sum(v<<mapping[q] for q,v in enumerate(row) if v) for row in rows]
 _,xx,zz=checks(c);assert equal_space(xx,bitrows(x));assert equal_space(zz,bitrows(z))
 records.append(dict(n=c['n'],source_blob=c['source_blob'],source_sha256=c['source_sha256'],parameter_projection_sha256=c['source_parameter_projection_sha256'],source_identity_index=root,source_group_index_to_canonical=[index[labels[g]] for g in range(p)],Hx_equal_space=True,Hz_equal_space=True))
 print('PASS source matrix spaces after proved group enumeration',c['n'])
args.out.write_text(json.dumps(records,indent=2)+'\n')
