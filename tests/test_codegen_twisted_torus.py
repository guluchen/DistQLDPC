#!/usr/bin/env python3
"""Independent quotient, seam, antipode, tiny-distance and mutation tests."""
from itertools import combinations
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
import twisted_torus as gen
import validate_twisted_torus as independent
import validate_css as css


def exact_small(n,parity,stabilizers):
    """Enumerate increasing supports, check syndrome and quotient directly."""
    columns=[sum(((row >> i)&1) << j for j,row in enumerate(parity)) for i in range(n)]
    span=css.basis(stabilizers)
    for weight in range(1,7):
        for support in combinations(range(n),weight):
            syndrome=0
            for i in support:syndrome ^= columns[i]
            if syndrome:continue
            word=sum(1 << i for i in support)
            if not css.contains(span,word):return weight,word
    raise AssertionError('no logical support of weight <=6')


class TwistedTests(unittest.TestCase):
    def test_independent_incidence_all_cases(self):
        for c in gen.CASES:
            n,hx,hz=gen.checks(c)
            self.assertEqual((hx,hz),independent.reconstruct(c))
            self.assertEqual(n-len(css.basis(hx))-len(css.basis(hz)),c['k'])
            self.assertFalse(any(css.dot(x,z) for x in hx for z in hz))
            self.assertEqual({bin(x).count('1') for x in hx+hz},{6})

    def test_negative_coordinates_and_lattice_relations(self):
        rng=random.Random(159)
        for c in gen.CASES:
            h,w,s=(c[k] for k in ('h','w','s'))
            for _ in range(30):
                x,y=rng.randrange(-100,100),rng.randrange(-100,100)
                a,b=rng.randrange(-5,6),rng.randrange(-5,6)
                p=gen.reduce_site(x,y,h,w,s)
                self.assertEqual(p,gen.reduce_site(x+a*w,y+a*s+b*h,h,w,s))
                self.assertTrue(independent.equivalent(x-p[0],y-p[1],h,w,s))
            self.assertEqual(gen.reduce_site(w,0,h,w,s),(0,(-s)%h))

    def test_tiny_exact_distance_both_halves(self):
        n,hx,hz=gen.checks(gen.CASES[0])
        for parity,stab in ((hx,hz),(hz,hx)):
            d,word=exact_small(n,parity,stab)
            self.assertEqual(d,6)
            self.assertFalse(any(css.dot(word,r) for r in parity))

    def test_relabelled_tiny_distance(self):
        n,hx,hz=gen.checks(gen.CASES[0])
        order=list(range(n));random.Random(159).shuffle(order)
        move=lambda r:sum(((r >> i)&1) << order[i] for i in range(n))
        self.assertEqual(exact_small(n,list(map(move,hx)),list(map(move,hz)))[0],6)

    def test_omitted_antipode_mutant(self):
        c=gen.CASES[1];n,hx,_=gen.checks(c);v=n//2
        mask=(1 << v)-1
        wrong=[((r & mask) << v)|(r >> v) for r in hx]
        self.assertTrue(any(css.dot(x,z) for x in hx for z in wrong))

    def test_wrong_seam_mutant(self):
        c=gen.CASES[0];bad=dict(c,s=-c['s'])
        n,x,z=gen.checks(bad)
        self.assertNotEqual((x,z),independent.reconstruct(c))
        with self.assertRaisesRegex(ValueError,'congruences'):
            independent.certify(c,n,[x,z,[],[]])

    def test_quotient_cancels_coincident_monomials(self):
        c=dict(n=2,k=0,d=0,h=1,w=1,s=0,a=0,b=0,c=0,e=0)
        n,x,z=gen.checks(c)
        self.assertEqual(n,2)
        self.assertEqual(x,[3])  # Three identical GF(2) monomials leave one.
        self.assertEqual((x,z),independent.reconstruct(c))
        for h,w in ((0,1),(1,0),(-1,2)):
            with self.assertRaises(ValueError):gen.reduce_site(0,0,h,w,0)

    def test_reproduction_and_overwrite(self):
        with tempfile.TemporaryDirectory() as a,tempfile.TemporaryDirectory() as b:
            c=gen.CASES[0];stem=gen.generate(c,Path(a));gen.generate(c,Path(b))
            n,m=css.read_code(Path(a),stem)
            independent.certify(c,n,m)
            before={p.name:p.read_bytes() for p in Path(a).glob('*.txt')}
            self.assertEqual(before,{p.name:p.read_bytes() for p in Path(b).glob('*.txt')})
            with self.assertRaises(FileExistsError):gen.generate(c,Path(a))
            self.assertEqual(before,{p.name:p.read_bytes() for p in Path(a).glob('*.txt')})

    def test_smoke_family_isolation(self):
        argv=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),
              '--cpu','0','--dry-run','--out','/tmp/unused-twisted-smoke','--family','BB']
        jobs=json.loads(subprocess.check_output(argv,cwd=ROOT,text=True))
        self.assertEqual(len(jobs),6)
        self.assertEqual({a[-1].split('/')[-1] for a in jobs},
                         {f'BB_{c["n"]}_{c["k"]}_unknown' for c in gen.CASES})
        bad=subprocess.run(argv+['--stems','COLOR_7_1_unknown'],cwd=ROOT,capture_output=True)
        self.assertNotEqual(bad.returncode,0)


if __name__=='__main__':unittest.main()
