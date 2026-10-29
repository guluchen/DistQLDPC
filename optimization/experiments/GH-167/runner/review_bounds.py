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
        records.append(dict(stem=row['stem'],published_claim='exact',published_d=row['published_exact_d'],
            strongest_observed_lb=strongest,two_engine_common_lb=common,
            verified_witness_ub=min([w['weight'] for w in row['witnesses']],default=None),
            lower_bound_status=status,
            provisional_open_code_lower_bound=strongest if higher and 'exact'=='upper' else None,
            exact_result_status=('CROSS_CHECKED_TWO_ENGINES_AND_GF2_WITNESS' if all(r['status']=='SOLVED' for r in row['engines'].values()) else 'PLAUSIBLE_ONE_ENGINE_EXACT' if any(r['status']=='SOLVED' for r in row['engines'].values()) else 'NO_EXACT_RESULT'),
            raw_audit_verification=row['verification']))
    report=dict(audit_sha256=hashlib.sha256(args.audit.read_bytes()).hexdigest(),records=records)
    content=json.dumps(report,indent=2)+'\n';args.out.write_text(content);print(content,end='')


if __name__=='__main__':main()
