#!/usr/bin/env python3
"""Prepare only unresolved default internal-engine proofs from actual short evidence."""
import argparse
import json
from pathlib import Path


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--audit',type=Path,required=True);ap.add_argument('--out',type=Path,required=True)
    args=ap.parse_args();jobs=[]
    for row in json.loads(args.audit.read_text()):
        for engine,result in row['engines'].items():
            if engine not in ('maxsat','cc'):raise ValueError('unrecognized engine')
            if result['status']=='SOLVED':continue
            jobs.append(dict(id=f'tn.{row["stem"]}.{engine}.default.s0',stem=row['stem'],
                code='data/matrices/untiered/'+row['stem'],engine=engine,
                args=(['-engine=cc'] if engine=='cc' else [])+['-seed=0','-v'],limit=21600,
                reference_claim=row['published_claim'],expected_d=row['published_d']))
    if args.out.exists():raise FileExistsError('refusing jobs overwrite')
    args.out.write_text(''.join(json.dumps(j,separators=(',',':'))+'\n' for j in jobs))
    print(f'{len(jobs)} unresolved proof jobs prepared; no process launched')


if __name__=='__main__':main()
