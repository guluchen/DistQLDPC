#!/usr/bin/env python3
"""Independent integer-bitset GF(2) library checks; no solver or logical-builder imports."""
import argparse
import csv
import hashlib
import json
from pathlib import Path


def load(path):
    rows, width = [], None
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        tokens = line.split()
        if any(x not in ('0', '1') for x in tokens):
            raise ValueError(f'{path}: non-binary entry')
        if width is None:
            width = len(tokens)
        if len(tokens) != width:
            raise ValueError(f'{path}: inconsistent width')
        rows.append(sum(int(x) << i for i, x in enumerate(tokens)))
    if not rows:
        raise ValueError(f'{path}: empty matrix')
    return width, rows


def basis(rows):
    pivots = {}
    for row in rows:
        while row:
            p = row.bit_length()-1
            if p in pivots:
                row ^= pivots[p]
            else:
                pivots[p] = row
                break
    return pivots


def contains(pivots, row):
    while row:
        p = row.bit_length()-1
        if p not in pivots:
            return False
        row ^= pivots[p]
    return True


def equal_space(a, b):
    aa, bb = basis(a), basis(b)
    return len(aa) == len(bb) and all(contains(bb, r) for r in aa.values())


def dot(a, b):
    return bin(a & b).count('1') % 2


def read_code(directory, stem):
    matrices = [load(directory/f'{stem}_{kind}.txt') for kind in ('Hx','Hz','Gx','Gz')]
    if len({n for n, _ in matrices}) != 1:
        raise ValueError(f'{stem}: column mismatch')
    return matrices[0][0], [rows for _, rows in matrices]


def validate(n, matrices):
    hx, hz, gx, gz = matrices
    rx, rz = len(basis(hx)), len(basis(hz))
    k = n-rx-rz
    if k <= 0 or len(gx) != k or len(gz) != k:
        raise ValueError('dimension / logical row counts disagree')
    if any(dot(a,b) for a in hx for b in hz):
        raise ValueError('Hx Hz^T != 0')
    for parity, stabilizer, logical in ((hx,hz,gx), (hz,hx,gz)):
        if any(dot(a,b) for a in parity for b in logical):
            raise ValueError('logical outside parity kernel')
        if len(basis(stabilizer+logical)) != len(basis(stabilizer))+k:
            raise ValueError('logical quotient is not a basis')
    pairing = [sum(dot(a,b) << j for j,b in enumerate(gz)) for a in gx]
    if len(basis(pairing)) != k:
        raise ValueError('logical pairing is singular')
    return {'n': n, 'k': k, 'rank_Hx': rx, 'rank_Hz': rz,
            'rank_pairing': k, 'checks': 'PASS'}


def duplicates(n, k, hx, hz, entries, own_path):
    compared, matches = [], []
    for path in entries:
        if path.resolve() == own_path.resolve():
            continue
        stem = path.name[:-7]
        # Bundled filenames carry n,k; verify actual dimensions of every peer.
        if stem.split('_')[1:3] != [str(n), str(k)]:
            continue
        nn, xx = load(path)
        if nn != n:
            continue
        _, zz = load(path.with_name(stem+'_Hz.txt'))
        if nn-len(basis(xx))-len(basis(zz)) != k:
            continue
        compared.append(str(path))
        if equal_space(hx,xx) and equal_space(hz,zz):
            matches.append({'path': str(path), 'swap': False})
        elif equal_space(hx,zz) and equal_space(hz,xx):
            matches.append({'path': str(path), 'swap': True})
    return compared, matches


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--root', type=Path, default=Path('data/matrices'))
    ap.add_argument('--dir', type=Path, default=Path('data/matrices/untiered'))
    ap.add_argument('--output', type=Path)
    args = ap.parse_args()
    manifest = list(csv.DictReader((args.dir/'MANIFEST.csv').open()))
    stems = [row['stem'] for row in manifest]
    actual = {p.name[:-7] for p in args.dir.glob('*_Hx.txt')}
    if len(stems) != len(set(stems)) or set(stems) != actual:
        raise ValueError('manifest/code inventory mismatch')
    entries = sorted(args.root.glob('tier[0-5]/*_Hx.txt')) + sorted(args.root.glob('untiered/*_Hx.txt'))
    results = []
    for row in manifest:
        stem = row['stem']
        n, matrices = read_code(args.dir, stem)
        result = validate(n, matrices)
        if (n,result['k']) != (int(row['n']),int(row['k'])):
            raise ValueError(f'{stem}: manifest dimensions disagree')
        if stem.split('_')[:3] != [row['family'],row['n'],row['k']]:
            raise ValueError(f'{stem}: stem dimensions disagree')
        compared, matches = duplicates(n, result['k'], *matrices[:2], entries, args.dir/f'{stem}_Hx.txt')
        if matches:
            raise ValueError(f'{stem}: duplicate row spaces: {matches}')
        result.update(stem=stem, same_n_k_compared=compared, duplicates=matches,
                      column_permutation_equivalence='not tested; no same-(n,k) peers' if not compared else 'not tested; manual review required',
                      sha256={kind: hashlib.sha256((args.dir/f'{stem}_{kind}.txt').read_bytes()).hexdigest()
                              for kind in ('Hx','Hz','Gx','Gz')})
        results.append(result)
    report = {'codes_checked': len(results), 'inventory_codes': len(entries), 'results': results}
    content = json.dumps(report, indent=2)+'\n'
    if args.output:
        args.output.write_text(content)
    print(content, end='')


if __name__ == '__main__':
    main()
