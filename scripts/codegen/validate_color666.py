#!/usr/bin/env python3
"""Independent Cartesian geometry and GF(2) color-code checks (GH-156).

Does not import the generator or logical builder. Uses squared Euclidean
distance on a scaled Cartesian embedding, rather than neighbor offsets.
"""
import argparse
from collections import Counter
import csv
import json
from pathlib import Path

from validate_css import basis, contains, dot, read_code, validate


def geometry(distance):
    if distance < 3 or distance % 2 != 1:
        raise ValueError('distance must be odd and >= 3')
    height = 3*(distance-1)//2
    # Cartesian location is (x, sqrt(3)*y). Neighboring points have
    # squared Euclidean separation 4. The triangle is |x| <= y <= height.
    sites, faces = [], []
    for y in range(height+1):
        for x in range(-y,y+1,2):
            (faces if (x+3*y)%6 == 4 else sites).append((x,y))
    rows = [sum(1 << i for i,(x,y) in enumerate(sites)
                if (x-fx)**2+3*(y-fy)**2 == 4) for fx,fy in faces]
    return sites, faces, rows


def certify(distance, n, matrices):
    sites, faces, expected = geometry(distance)
    hx,hz,gx,gz = matrices
    if n != (3*distance*distance+1)//4 or len(sites) != n:
        raise ValueError('unexpected number of data qubits')
    if hx != expected or hz != expected:
        raise ValueError('matrix does not match independently reconstructed geometry')
    result = validate(n,matrices)
    if result['k'] != 1:
        raise ValueError('triangular patch must encode one logical qubit')
    t = (distance-1)//2
    weights = Counter(bin(r).count('1') for r in hx)
    wanted = {4:3*t}
    if t > 1:
        wanted[6] = 3*t*(t-1)//2
    if weights != Counter(wanted):
        raise ValueError('unexpected boundary/bulk face weights')
    incidence = [[] for _ in sites]
    for j,row in enumerate(hx):
        for i in range(n):
            if (row >> i)&1:
                incidence[i].append(j)
    degrees = Counter(map(len,incidence))
    if degrees != Counter({1:3,2:3*distance-6,3:n-3*distance+3}):
        raise ValueError('unexpected qubit incidence degrees')
    if any(len({faces[j][1]%3 for j in js}) != len(js) for js in incidence):
        raise ValueError('incident faces do not have distinct colors')
    height = 3*t
    boundaries = {
        'left':[i for i,(x,y) in enumerate(sites) if x == -y],
        'right':[i for i,(x,y) in enumerate(sites) if x == y],
        'bottom':[i for i,(x,y) in enumerate(sites) if y == height],
    }
    checks = basis(hx)
    witnesses = []
    for name,support in boundaries.items():
        word = sum(1 << i for i in support)
        if len(support) != distance or any(dot(word,row) for row in hx):
            raise ValueError('boundary witness has wrong weight or syndrome')
        if contains(checks,word) or not dot(word,gx[0]) or not dot(word,gz[0]):
            raise ValueError('boundary witness is trivial or not detected by logical bases')
        if not dot(word,word):
            raise ValueError('boundary X/Z pair does not anticommute')
        witnesses.append({'boundary':name,'support':support,'weight':len(support),
                          'valid_X':True,'valid_Z':True})
    result.update(distance_claim=distance,face_weights=dict(sorted(weights.items())),
                  qubit_degrees=dict(sorted(degrees.items())),boundary_witnesses=witnesses,
                  distance_lower_bound_source='Sahay-Brown arXiv:2108.11395v3 Sec.II; not computed here',
                  checks='PASS independent geometry, GF(2), color incidence and three boundary logicals')
    return result


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--output',type=Path,required=True)
    args = ap.parse_args()
    results = []
    for row in csv.DictReader((args.dir/'MANIFEST.csv').open()):
        if row['family'] != 'COLOR':
            continue
        n,matrices = read_code(args.dir,row['stem'])
        result = certify(int(row['claimed_d'].split()[1]),n,matrices)
        result['stem'] = row['stem']
        results.append(result)
    if not results:
        raise ValueError('no COLOR entries in manifest')
    content = json.dumps(results,indent=2)+'\n'
    args.output.write_text(content)
    print(content,end='')


if __name__ == '__main__':
    main()
