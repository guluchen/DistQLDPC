#!/usr/bin/env python3
"""Prepare only missing default internal-engine numeric gates from actual short evidence."""
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
            if result['lb'] is not None and result['ub'] is not None:continue
            jobs.append(dict(id=f'tor.{row["stem"]}.{engine}.default.s0',stem=row['stem'],
                code='data/matrices/untiered/'+row['stem'],engine=engine,
                args=(['-engine=cc'] if engine=='cc' else [])+['-seed=0','-v'],limit=21600,
                reference_claim='exact',expected_d=row['published_exact_d']))
    if args.out.exists():raise FileExistsError('refusing jobs overwrite')
    args.out.write_text(''.join(json.dumps(j,separators=(',',':'))+'\n' for j in jobs))
    print(f'{len(jobs)} missing-numeric jobs prepared; no process launched')


if __name__=='__main__':main()
