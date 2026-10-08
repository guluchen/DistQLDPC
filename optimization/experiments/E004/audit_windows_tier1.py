"""Read-only independent audit of one completed H-007 Windows Tier 1 run."""
import argparse,hashlib,json,math,re,statistics
from pathlib import Path

def main():
 ap=argparse.ArgumentParser();ap.add_argument('run',type=Path);ap.add_argument('--prior',type=Path,required=True);a=ap.parse_args()
 e=a.run.resolve()/'evidence';p=a.prior.resolve()/'E004-server-package'
 load=lambda x:json.loads(x.read_text(encoding='utf8'))
 sha=lambda x:hashlib.sha256(x.read_bytes()).hexdigest()
 manifest=load(p/'manifest.json')
 for rel,want in manifest['files'].items():assert sha(p/rel)==want,rel
 identities=load(a.prior.resolve()/'evidence/binary-hashes.json')
 for version,want in identities.items():assert sha(p/version/'bin/distqldpc.exe')==want
 assert load(a.prior.resolve()/'evidence/tier0/summary.json')['status']=='PASS'
 samples=load(e/'samples.json');assert len(samples)==48,'Incomplete: no numeric conclusion'
 cases=['BB_90_8_10','GB_144_12_8','BB_108_8_10','LP_238_44_6'];modes=['no-card','card-mto']
 details=[];aggregates={}
 for mode in modes:
  ratios=[];envelopes=[];nonworse=True
  for case in cases:
   rows=[s for s in samples if s['case']==case and s['mode']==mode]
   assert [(s['repeat'],s['version']) for s in rows]==[(1,'baseline'),(1,'candidate'),(2,'candidate'),(2,'baseline'),(3,'baseline'),(3,'candidate')]
   expected=int(case.rsplit('_',1)[1])
   for row in rows:
    assert row['returncode']==0 and not row['resource_abort'] and not row['external_timeout']
    assert row['command'][1:4]==['-v','-cpu-lim=180','-'+mode]
    label=f"{case}-{mode}-{row['repeat']}-{row['version']}"
    output=(e/(label+'.stdout')).read_text(encoding='utf8')
    patterns={'d':r'^c\s+d\s*:\s*(\d+)\s*$','objective':r'^o\s+(-?\d+)\s*$','lb':r'^c\s+d_lb:\s*(\d+)\s*$','ub':r'^c\s+d_ub:\s*(\d+)\s*$'}
    for key,pattern in patterns.items():
     values=list(map(int,re.findall(pattern,output,re.M)))
     assert values and values[-1]==expected and row['semantic'][key]==expected
     assert all(v<=expected if key=='lb' else v>=expected for v in values)
    assert 's UNKNOWN' not in output and 'c status: TIMEOUT' not in output
   raw={v:[s['elapsed_sec'] for s in rows if s['version']==v] for v in ['baseline','candidate']}
   b,c=(statistics.median(raw[v]) for v in ['baseline','candidate'])
   ratio,envelope=c/b,max(raw['candidate'])/min(raw['baseline']);ratios.append(ratio);envelopes.append(envelope);nonworse &= c<=b
   details.append(dict(case=case,mode=mode,raw=raw,baseline_median=b,candidate_median=c,median_ratio=ratio,range_envelope=envelope,nonoverlapping_regression=min(raw['candidate'])>max(raw['baseline'])))
  gm=lambda xs:math.exp(sum(math.log(x) for x in xs)/len(xs))
  aggregates[mode]=dict(median_geomean=gm(ratios),range_envelope_geomean=gm(envelopes),no_worse_medians=nonworse)
 numeric='reject' if any(d['nonoverlapping_regression'] for d in details) else ('pass' if all(x['range_envelope_geomean']<1 and x['no_worse_medians'] for x in aggregates.values()) else 'inconclusive')
 recorded=load(e/'result.json');assert recorded['numeric_filter']==numeric
 for d in details:
  r=next(r for r in recorded['medians'] if r['case']==d['case'] and r['mode']==d['mode'])
  assert all(r[k]==d[k] for k in ['baseline_median','candidate_median','median_ratio','range_envelope'])
 resources=load(e/'resources.json');assert resources and all(r['idle_percent']>50 and r['half_spare_logical_cpus']>=1 for r in resources)
 result=dict(audit='PASS',correct_solves=48,binary_sha256=identities,medians=details,aggregates=aggregates,numeric_filter=numeric,min_observed_idle=min(r['idle_percent'] for r in resources),resource_checks=len(resources),decision='INCONCLUSIVE',reason='Desktop diagnostics do not establish controlled promotion',tier2='prior diagnostic retained; not rerun',tier3='not run')
 (e/'independent-audit.json').write_text(json.dumps(result,indent=2),encoding='utf8',newline='\n');print(json.dumps(result,indent=2))
if __name__=='__main__':main()
