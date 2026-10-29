#!/usr/bin/env python3
"""Record unresolved Table I row 5 normal-closure interpretations, not matrices."""
import argparse
import json
from pathlib import Path
from hyperbolic_surface import CASES,Quotient,relators,walk,ALPHABET


def diagnose():
    c=[c for c in CASES if c['n']==1920][0]
    word=tuple(ALPHABET.index(x) for x in c['words'][0]);mirror=tuple(g^1 for g in word)
    evidence=[]
    for reflection in (False,True):
        relations=relators(c,reflection=reflection)
        table,stats=Quotient(relations).run()
        alternate,_=Quotient(list(reversed(relations))).run()
        if alternate!=table:raise ValueError('alternate relation scan disagrees')
        evidence.append(dict(interpretation='full_reflection_normal_closure' if reflection else 'orientation_preserving_normal_closure',
                             **stats,all_defining_relators_verified=True,reverse_scan_canonical_table_equal=True,
                             mirror_moves=sum(walk(table,a,mirror)!=a for a in range(len(table))),
                             original_word=c['words'][0],mirror_word=''.join(ALPHABET[g] for g in mirror),
                             actual_matrix_files_generated=False))
    return evidence


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--output',type=Path,required=True)
    args=ap.parse_args();content=json.dumps(diagnose(),indent=2)+'\n';args.output.write_text(content);print(content,end='')


if __name__=='__main__':main()
