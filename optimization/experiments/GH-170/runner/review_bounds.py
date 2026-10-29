#!/usr/bin/env python3
"""Retain provisional stronger lower bounds separately from shared engine evidence."""
import argparse
import hashlib
import json
from pathlib import Path


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--audit',type=Path,required=True);ap.add_argument('--out',type=Path,required=True)
    args=ap.parse_args();records=[]
    for row in json.loads(args.audit.read_text()):
        if set(row['engines'])!={'maxsat','cc'}:raise ValueError('both engines required for a bound cross-check')
        bounds=[r['lb'] for r in row['engines'].values()]
        common=min(bounds) if bounds and all(x is not None for x in bounds) else None
        strongest=max([x for x in bounds if x is not None],default=None)
        higher=strongest is not None and (common is None or strongest>common)
        status=('NO_NUMERIC_LOWER_BOUND' if strongest is None else
                'PLAUSIBLE_PENDING_INDEPENDENT_LOWER_BOUND_COMPLETION' if higher else 'CROSS_CHECKED_TWO_ENGINES')
        records.append(dict(stem=row['stem'],published_claim=row['published_claim'],published_d=row['published_d'],
            strongest_observed_lb=strongest,two_engine_common_lb=common,
            verified_witness_ub=min([w['weight'] for w in row['witnesses']],default=None),
            lower_bound_status=status,
            provisional_open_code_lower_bound=strongest if higher and row['published_claim']=='upper' else None,
            exact_result_status=row['scientific_status']))
    report=dict(audit_sha256=hashlib.sha256(args.audit.read_bytes()).hexdigest(),records=records)
    content=json.dumps(report,indent=2)+'\n';args.out.write_text(content);print(content,end='')


if __name__=='__main__':main()
