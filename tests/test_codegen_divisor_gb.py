#!/usr/bin/env python3
"""Independent cyclic arithmetic, random tiny CSS checks and caught mutants."""
from copy import deepcopy
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
import divisor_gb as gen
import validate_divisor_gb as independent
import validate_css as css
from verify_css_witness import verify_witness

CASES=json.loads(gen.CASES.read_text())


def tiny_case(l,a,b):
    aa=sum(1<<x for x in a);bb=sum(1<<x for x in b);g=gen.gcd(gen.gcd(aa,bb),(1<<l)|1)
    return dict(l=l,n=2*l,k=2*(g.bit_length()-1),g=[i for i in range(l) if (g>>i)&1],a=a,b=b)


def exact(n,parity,stab):
    span=css.basis(stab)
    for w in range(1,n+1):
        for support in combinations(range(n),w):
            word=sum(1<<q for q in support)
            if not any(css.dot(word,r) for r in parity) and not css.contains(span,word):return w
    return None


class DivisorGBTests(unittest.TestCase):
    def test_fixed_physical_columns_gcd_and_logicals(self):
        for c in CASES:
            n,hx,hz=gen.checks(c)
            self.assertEqual([hx,hz],independent.reconstruct(c))
            n,m=css.read_code(ROOT/'data/matrices/untiered',f'GB_{c["n"]}_{c["k"]}_unknown')
            result=independent.certify(c,n,m)
            self.assertEqual(result['k'],c['k'])
            for w in result['witnesses']:verify_witness(n,m,w['half'],w['support'])

    def test_random_polynomial_products_and_gcd(self):
        rng=random.Random(171)
        for l in range(2,16):
            for _ in range(15):
                a=[i for i in range(l) if rng.randrange(2)];b=[i for i in range(l) if rng.randrange(2)]
                aa=gen.polynomial(a,l);bb=gen.polynomial(b,l)
                prod=gen.product(aa,bb,l)
                self.assertEqual({i for i in range(l) if (prod>>i)&1},independent.multiply(a,b,l))
                gg=gen.gcd(gen.gcd(aa,bb),(1<<l)|1)
                self.assertEqual({i for i in range(l+1) if (gg>>i)&1},independent.common(independent.common(a,b),{0,l}))

    def test_random_cyclic_css_rank_even_and_odd_lengths(self):
        rng=random.Random(1171)
        for l in range(2,10):
            for _ in range(12):
                a=[i for i in range(l) if rng.randrange(2)];b=[i for i in range(l) if rng.randrange(2)]
                if not a and not b:continue
                c=tiny_case(l,a,b);n,hx,hz=gen.checks(c)
                self.assertEqual([hx,hz],independent.reconstruct(c))
                self.assertFalse(any(css.dot(x,z) for x in hx for z in hz))
                self.assertEqual(n-len(css.basis(hx))-len(css.basis(hz)),c['k'])

    def test_tiny_distance_independent_exhaustive_and_duality(self):
        # Only tiny <=12-qubit unit cases, not a source-code distance experiment.
        for l,d in ((3,2),(4,2),(5,3),(6,3)):
            c=tiny_case(l,[0,1],[0,2]);n,hx,hz=gen.checks(c)
            self.assertEqual(exact(n,hx,hz),d)
            self.assertEqual(exact(n,hz,hx),d)
            order=list(range(n));random.Random(171+l).shuffle(order)
            move=lambda rows:[independent.permute(r,order) for r in rows]
            self.assertEqual(exact(n,move(hx),move(hz)),d)

    def test_transpose_mutant_general_cyclic_pair(self):
        c=tiny_case(7,[0,1],[0,2,3]);n,hx,hz=gen.checks(c);l=c['l'];mask=(1<<l)-1
        wrong=[((r&mask)<<l)|(r>>l) for r in hx]
        self.assertNotEqual(wrong,hz)
        self.assertTrue(any(css.dot(x,z) for x in hx for z in wrong))

    def test_source_subclass_transpose_mutant_needs_physical_check(self):
        # The published stronger involution can make an untransposed mutant
        # commute too. CSS alone must not stand in for source reconstruction.
        c=CASES[0];n,hx,hz=gen.checks(c);l=c['l'];mask=(1<<l)-1
        wrong=[((r&mask)<<l)|(r>>l) for r in hx]
        self.assertFalse(any(css.dot(x,z) for x in hx for z in wrong))
        self.assertNotEqual(wrong,hz)
        with self.assertRaisesRegex(ValueError,'physical columns'):independent.certify(c,n,[hx,wrong,[],[]])

    def test_lift_support_and_gcd_mutants(self):
        c=deepcopy(CASES[0]);c['u'].append(1)
        with self.assertRaises(ValueError):gen.checks(c)
        with self.assertRaises(ValueError):independent.facts(c)
        c=deepcopy(CASES[2]);c['g']=[0,1]
        with self.assertRaises(ValueError):gen.checks(c)
        with self.assertRaises(ValueError):independent.facts(c)
        for support in ([0,0],[-1],[23],[1.5]):
            with self.assertRaises(ValueError):gen.polynomial(support,23)

    def test_logical_and_stabilizer_witness_mutants(self):
        c=CASES[1];stem=f'GB_{c["n"]}_{c["k"]}_unknown';n,m=css.read_code(ROOT/'data/matrices/untiered',stem)
        bad=deepcopy(m);bad[2][0]=m[1][0]
        with self.assertRaises(ValueError):css.validate(n,bad)
        support=[q for q in range(n) if (m[1][0]>>q)&1]
        with self.assertRaises(ValueError):verify_witness(n,m,'Z',support)
        bad=deepcopy(m);bad[3][1]=bad[3][0]
        with self.assertRaises(ValueError):css.validate(n,bad)

    def test_fresh_reproduction_and_overwrite_protection(self):
        with tempfile.TemporaryDirectory() as d:
            c=CASES[0];out=Path(d);stem=gen.generate(c,out)
            for p in out.glob('*.txt'):self.assertEqual(p.read_bytes(),(ROOT/'data/matrices/untiered'/p.name).read_bytes())
            with self.assertRaises(FileExistsError):gen.generate(c,out)

    def test_family_and_engine_dry_run(self):
        argv=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','0','--dry-run','--out','/tmp/unused-gb','--family','GB']
        jobs=json.loads(subprocess.check_output(argv,cwd=ROOT,text=True));self.assertEqual(len(jobs),4)
        self.assertTrue(all('-engine=cc' not in x for x in jobs))
        cc=json.loads(subprocess.check_output(argv+['--engine','cc'],cwd=ROOT,text=True))
        self.assertTrue(all('-engine=cc' in x for x in cc))
        self.assertEqual({x[-1].split('/')[-1] for x in cc},{f'GB_{c["n"]}_{c["k"]}_unknown' for c in CASES})


if __name__=='__main__':unittest.main()
