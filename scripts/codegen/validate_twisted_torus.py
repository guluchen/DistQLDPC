#!/usr/bin/env python3
"""Independent lattice-membership and logical checks for GH-159.

Builds incidence by enumerating congruent source/target pairs, without
importing the generator or calling its coordinate-reduction algorithm.
"""
import argparse
import csv
import json
from pathlib import Path
from validate_css import basis, contains, dot, read_code, validate


def equivalent(dx,dy,h,w,s):
    return dx%w == 0 and (dy-s*(dx//w))%h == 0


def reconstruct(case):
    h,w,s = (case[k] for k in ('h','w','s'))
    if h <= 0 or w <= 0:
        raise ValueError('invalid lattice area')
    points = [(x,y) for x in range(w) for y in range(h)]
    f = [(0,0),(1,0),(case['a'],case['b'])]
    g = [(0,0),(0,1),(case['c'],case['e'])]
    def incidence(polys):
        result = []
        for x,y in points:
            support = 0
            for block,poly in enumerate(polys):
                for j,(xx,yy) in enumerate(points):
                    if sum(equivalent(xx-x-dx,yy-y-dy,h,w,s) for dx,dy in poly)%2:
                        support |= 1 << (block*len(points)+j)
            result.append(support)
        return result
    return incidence([f,g]),incidence([[(-x,-y) for x,y in g],[(-x,-y) for x,y in f]])


def certify(case,n,matrices):
    hx,hz,gx,gz = matrices
    expected = reconstruct(case)
    if hx != expected[0] or hz != expected[1]:
        raise ValueError('matrix differs from independent lattice congruences')
    result = validate(n,matrices)
    if (n,result['k']) != (case['n'],case['k']) or n != 2*case['h']*case['w']:
        raise ValueError('published n,k or lattice area mismatch')
    if any(bin(row).count('1') != 6 for row in hx+hz):
        raise ValueError('expected all checks of weight six')
    witnesses = []
    for label,parity,stab,logical,detectors in (('Gx',hx,hz,gx,gz),('Gz',hz,hx,gz,gx)):
        word = min(logical,key=lambda r:(bin(r).count('1'),r))
        support = [i for i in range(n) if (word >> i)&1]
        if any(dot(word,row) for row in parity) or contains(basis(stab),word):
            raise ValueError('basis witness invalid')
        if not any(dot(word,row) for row in detectors):
            raise ValueError('basis witness has no logical detector')
        if len(support) < case['d']:
            raise ValueError('verified word below published exact distance; scientific review required')
        witnesses.append({'basis':label,'support':support,'weight':len(support),
                          'checks':'PASS zero syndrome, non-stabilizer and logical detector'})
    result.update(stem=f'BB_{n}_{case["k"]}_unknown',parameters=case,
                  verified_basis_witnesses=witnesses,
                  verified_basis_ub=min(w['weight'] for w in witnesses),
                  checks='PASS independent quotient lattice, published dimensions, CSS/logicals and basis witnesses')
    return result


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--output',type=Path,required=True)
    args = ap.parse_args()
    results = []
    for row in csv.DictReader((args.dir/'MANIFEST.csv').open()):
        if row['family']!='BB' or 'scripts/codegen/twisted_torus.py' not in row['generator']:continue
        case=json.loads(row['construction'])
        if row['claimed_d'].split()[:2] != ['exact',str(case['d'])]:
            raise ValueError('manifest distance and parameter provenance disagree')
        n,matrices = read_code(args.dir,row['stem'])
        result=certify(case,n,matrices)
        if result['stem'] != row['stem']:raise ValueError('manifest stem mismatch')
        results.append(result)
    if not results:raise ValueError('no untiered BB cases')
    text=json.dumps(results,indent=2)+'\n'
    args.output.write_text(text)
    print(text,end='')


if __name__ == '__main__':
    main()
