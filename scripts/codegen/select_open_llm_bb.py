#!/usr/bin/env python3
"""Select open CSS targets from a pinned public numeric catalogue, no solvers.

GPL-3.0-or-later. Numeric/provenance facts attributed to Cruz-Benito2610.06623.
"""
import argparse
import hashlib
import json
from pathlib import Path

SHA='a5f398de84652b49c11300c69e99af81fedff22361b8af2e52f431dba9772934'
COMMIT='da9178fd65ffc2eec3dab46089f9879eb02d4b23'


def select(data):
    if hashlib.sha256(data).hexdigest()!=SHA:raise ValueError('numeric catalogue SHA256 mismatch')
    rows=[json.loads(line) for line in data.splitlines()]
    eligible=[r for r in rows if r['family']=='CSS' and r['connectivity']['is_connected']
              and not r['distance_class']['is_exact'] and r['provenance']['origin']['model_attributed_observations_present']
              and not r['provenance']['origin']['fixed_safety_net']]
    cases=[];selected=[]
    for n in sorted({r['parameters']['n'] for r in eligible}):
        r=max((r for r in eligible if r['parameters']['n']==n),key=lambda r:(r['distance_class']['upper']-r['distance_class']['lower'],r['distance_class']['upper'],-r['parameters']['k']))
        p=r['parameters'];d=r['distance_class'];g=r['generators']
        if g['C_terms'] or g['D_terms']:raise ValueError('nonCSS generator terms selected')
        cases.append(dict(n=n,k=p['k'],l=p['ell'],m=p['m'],A=g['A_terms'],B=g['B_terms'],
                          published_lower=d['lower'],endpoint=d['upper'],endpoint_supported=d['upper_is_supported'],
                          claim='upper' if d['upper_is_supported'] else 'estimate',presentation_id=r['presentation_id'],
                          class_id=r['equivalence']['class_id'],class_digest=r['equivalence']['canonical_digest_sha256'],
                          source_connected=True,source_class_exact=False,campaign=r['campaign'],
                          model_aliases=r['provenance']['model_aliases'],program_source_hashes=r['provenance']['program_source_hashes']))
        selected.append(r)
    return dict(source_repository='qiskit-community/qcode-discovery',source_commit=COMMIT,catalogue_sha256=SHA,
                selection='per distinct source size, largest class endpoint gap, then larger endpoint/smallerk; stable catalogue order for ties; connected class-nonexact CSS, model attributed, no fixed safety net',
                eligible_presentations=len(eligible),cases=cases),selected


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--catalogue',type=Path,required=True)
    ap.add_argument('--out',type=Path,required=True);ap.add_argument('--selected-source',type=Path,required=True)
    args=ap.parse_args();spec,rows=select(args.catalogue.read_bytes())
    args.out.write_text(json.dumps(spec,indent=2)+'\n');args.selected_source.write_text(json.dumps(rows,indent=2)+'\n')
    print(f'Selected{len(rows)} source-nonexact CSS targets from{spec["eligible_presentations"]} eligible records')


if __name__=='__main__':main()
