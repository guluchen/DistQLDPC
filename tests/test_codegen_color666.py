#!/usr/bin/env python3
"""Geometry, exact tiny distances, mutation and CLI selection checks for GH-156."""
import importlib.util
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
import color666 as gen
import validate_color666 as geometry
import validate_css as css

spec = importlib.util.spec_from_file_location('logicals',ROOT/'scripts/compute_logicals.py')
logicals = importlib.util.module_from_spec(spec)
spec.loader.exec_module(logicals)


def matrices(d):
    sites,_,h = gen.patch(d)
    n = len(sites)
    dense = [[(row >> j)&1 for j in range(n)] for row in h]
    gx_dense,gz_dense = logicals.css_logical_bitset_rows(dense,dense)
    pack = lambda rows:[sum(x << j for j,x in enumerate(row)) for row in rows]
    gx,gz = pack(gx_dense),pack(gz_dense)
    return n,[h,h[:],gx,gz]


def coset_minimum(h,logical):
    """Enumerate every stabilizer translate via Gray code, no distance solver."""
    rows = list(css.basis(h).values())
    word = logical
    minimum = word.bit_count() if hasattr(int,'bit_count') else bin(word).count('1')
    for i in range(1,1 << len(rows)):
        word ^= rows[(i & -i).bit_length()-1]
        minimum = min(minimum,bin(word).count('1'))
    return minimum


class ColorTests(unittest.TestCase):
    def test_independent_cartesian_patch(self):
        for d in (3,5,7,13,21):
            n,m = matrices(d)
            result = geometry.certify(d,n,m)
            self.assertEqual(result['k'],1)
            self.assertEqual(result['rank_Hx'],(n-1)//2)
            self.assertEqual([x['weight'] for x in result['boundary_witnesses']],[d]*3)

    def test_exact_small_logical_cosets(self):
        # d=7 has 2^18 translates: an independent exact oracle, still short.
        for d in (3,5,7):
            _,m = matrices(d)
            self.assertEqual(coset_minimum(m[0],m[2][0]),d)
            self.assertEqual(m[0],m[1])  # Same exact oracle applies to both CSS halves.

    def test_steane_by_all_binary_words(self):
        n,m = matrices(3)
        stabilizers = css.basis(m[0])
        nontrivial = [v for v in range(1,1 << n)
                      if not any(css.dot(v,h) for h in m[0]) and not css.contains(stabilizers,v)]
        self.assertEqual(len(nontrivial),8)
        self.assertEqual(min(bin(v).count('1') for v in nontrivial),3)

    def test_relabelled_small_code_distance(self):
        n,m = matrices(5)
        order = list(range(n)); random.Random(156).shuffle(order)
        permute = lambda row:sum(((row >> i)&1) << order[i] for i in range(n))
        moved = [[permute(row) for row in rows] for rows in m]
        css.validate(n,moved)
        self.assertEqual(coset_minimum(moved[0],moved[2][0]),5)

    def test_boundary_incidence_mutant(self):
        n,m = matrices(5)
        m[0][0] ^= 1 << (n-1)
        with self.assertRaisesRegex(ValueError,'geometry'):
            geometry.certify(5,n,m)
        with self.assertRaises(ValueError):
            css.validate(n,m)

    def test_commuting_missing_face_mutant(self):
        n,m = matrices(5)
        m[0] = m[0][1:]; m[1] = m[1][1:]
        self.assertFalse(any(css.dot(a,b) for a in m[0] for b in m[1]))
        with self.assertRaisesRegex(ValueError,'dimension'):
            css.validate(n,m)
        with self.assertRaisesRegex(ValueError,'geometry'):
            geometry.certify(5,n,m)

    def test_logical_stabilizer_mutant(self):
        n,m = matrices(5)
        m[2] = [m[0][0]]
        with self.assertRaisesRegex(ValueError,'quotient'):
            css.validate(n,m)

    def test_regeneration_and_overwrite_guard(self):
        with tempfile.TemporaryDirectory() as a,tempfile.TemporaryDirectory() as b:
            stem = gen.generate(5,Path(a))
            gen.generate(5,Path(b))
            for p in Path(a).glob('*.txt'):
                self.assertEqual(p.read_bytes(),(Path(b)/p.name).read_bytes())
            before = {p.name:p.read_bytes() for p in Path(a).glob('*.txt')}
            with self.assertRaises(FileExistsError):
                gen.generate(5,Path(a))
            self.assertEqual(before,{p.name:p.read_bytes() for p in Path(a).glob('*.txt')})
            self.assertEqual(stem,'COLOR_19_1_unknown')

    def test_invalid_distance(self):
        for d in (-3,0,1,2,4):
            with self.assertRaises(ValueError):
                gen.patch(d)

    def test_smoke_family_selection(self):
        import json
        runner = [sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),
                  '--cpu','0','--dry-run','--out','/tmp/not-created-color-smoke']
        default = json.loads(subprocess.check_output(runner,cwd=ROOT,text=True))
        selected = json.loads(subprocess.check_output(runner+['--family','COLOR'],cwd=ROOT,text=True))
        import csv
        manifest=list(csv.DictReader((ROOT/'data/matrices/untiered/MANIFEST.csv').open()))
        self.assertEqual({argv[-1].split('/')[-1] for argv in default},{r['stem'] for r in manifest if r['family']=='HGP'})
        self.assertTrue(all('HGP_' in argv[-1] for argv in default))
        self.assertEqual(len(selected),6)
        self.assertTrue(all('COLOR_' in argv[-1] for argv in selected))
        rejected = subprocess.run(runner+['--family','COLOR','--stems','HGP_13_1_unknown'],
                                  cwd=ROOT,capture_output=True)
        self.assertNotEqual(rejected.returncode,0)


if __name__ == '__main__':
    unittest.main()
