#!/usr/bin/env python3
"""Actual products, tiny inverse/nilpotence checks and metric-invariance mutant."""
from copy import deepcopy
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts/codegen'))
import homological_product as gen
import validate_homological_product as independent
import validate_css as css
from verify_css_witness import verify_witness
CASES=json.loads(gen.CASES.read_text())


def tiny_distance(rows):
    n=len(rows);trans=gen.transpose(rows,n);spans=[css.basis(rows),css.basis(trans)];best=n+1
    for parity,stab in ((rows,spans[1]),(trans,spans[0])):
        for w in range(1,1<<n):
            if not any(css.dot(w,r) for r in parity) and not css.contains(stab,w):best=min(best,bin(w).count('1'))
    return best


class HomologicalProductTests(unittest.TestCase):
    def test_all_actual_products_canonical_logicals_and_upper_words(self):
        for c in CASES:
            n,x,z=gen.checks(c);xx,zz,_,_=independent.reconstruct(c);self.assertEqual((x,z),(xx,zz))
            nn,m=css.read_code(ROOT/'data/matrices/untiered',f'HPC_{n}_{c["k"]}_unknown');r=independent.certify(c,nn,m)
            self.assertTrue(r['canonical_pairing_identity']);self.assertEqual(r['canonical_logical_count'],c['H']**2)
            for w in r['independently_checked_uppers']:verify_witness(n,m,w['half'],w['support'])

    def test_frozen_first_invertible_pairs_without_distance_screening(self):
        self.assertEqual([c['replay']['pair_sample'] for c in CASES],[0]*6)
        for c in CASES:
            factors,replay=gen.parameters(c);self.assertEqual(factors,c['factors']);self.assertEqual(replay,c['replay']);self.assertEqual(replay['rejected'],[])
        bad=deepcopy(CASES[0]);bad['factors'][0]['delta'][0]='0'
        with self.assertRaisesRegex(ValueError,'first-admissible'):gen.parameters(bad)

    def test_random_tiny_inverse_against_complete_vector_actions(self):
        rng=random.Random(179)
        for n in range(2,7):
            for _ in range(8):
                rows=[rng.randrange(1<<n) for i in range(n)];inv=gen.inverse(rows)
                self.assertEqual(inv is None,len(css.basis(rows))<n)
                if inv is not None:
                    for v in range(1<<n):self.assertEqual(independent.act(inv,independent.act(rows,v)),v)

    def test_tiny_random_nilpotent_products(self):
        for seed in range(16):
            c=dict(M=5,H=1);f=[gen.factor(gen.Random64(seed),5,1),gen.factor(gen.Random64(seed+100),5,1)];c['factors']=f
            xx,zz,_,_=independent.reconstruct(c);x=gen.product_rows(*[[int(s,16) for s in g['delta']] for g in f])
            self.assertEqual(x,xx);self.assertEqual(gen.transpose(x,25),zz)
            self.assertFalse(any(css.dot(a,b) for a in x for b in zz));self.assertEqual(25-2*len(css.basis(x)),1)

    def test_wrong_canonical_orientation_mutant(self):
        c=CASES[0];f=deepcopy(c['factors'][0]);f['delta']=[format(w,'x') for w in gen.transpose([int(s,16) for s in f['delta']],c['M'])]
        with self.assertRaisesRegex(ValueError,'conjugacy'):independent.factor(c,f)

    def test_diagonal_or_instead_of_xor_mutant(self):
        c=CASES[0];n,m=css.read_code(ROOT/'data/matrices/untiered',f'HPC_{c["n"]}_{c["k"]}_unknown');M=c['M']
        a,b=[[int(s,16) for s in f['delta']] for f in c['factors']]
        q=next(i*M+j for i in range(M) for j in range(M) if ((a[i]>>i)&1) and ((b[j]>>j)&1))
        bad=deepcopy(m);self.assertFalse((bad[0][q]>>q)&1);bad[0][q]^=1<<q
        with self.assertRaisesRegex(ValueError,'physical columns'):independent.certify(c,n,bad)

    def test_similarity_is_not_a_weight_isometry(self):
        # Canonical[[4,2,1]] and similar all-ones differential[[4,2,2]].
        # Exhaust all15 nonzero words; this is a tiny proof-unit fixture only.
        u=[7,5,6,12];inv=gen.inverse(u);d=gen.canonical(4,2);delta=gen.multiply(gen.multiply(u,d),inv)
        self.assertEqual(delta,[15]*4);self.assertEqual(tiny_distance(d),1);self.assertEqual(tiny_distance(delta),2)
        self.assertNotEqual(bin(independent.column(u,0)).count('1'),1)

    def test_invalid_inverse_width_and_logical_mutants(self):
        c=CASES[0];bad=deepcopy(c['factors'][0]);bad['inverse'][0]=format(1<<c['M'],'x')
        with self.assertRaisesRegex(ValueError,'width'):independent.factor(c,bad)
        n,m=css.read_code(ROOT/'data/matrices/untiered',f'HPC_{c["n"]}_{c["k"]}_unknown')
        with self.assertRaises(ValueError):verify_witness(n,m,'X',gen.support(next(w for w in m[0] if w)))
        for M,H in [(5,0),(5,5),(4,1)]:
            with self.assertRaises(ValueError):gen.canonical(M,H)

    def test_regeneration_and_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            gen.generate(CASES[0],Path(d))
            for p in Path(d).glob('*.txt'):self.assertEqual(p.read_bytes(),(ROOT/'data/matrices/untiered'/p.name).read_bytes())
            with self.assertRaises(FileExistsError):gen.generate(CASES[0],Path(d))

    def test_stable_random_stream(self):
        rng=gen.Random64(0);self.assertEqual([rng.word(),rng.word()],[0xe220a8397b1dcdaf,0x6e789e6aa1b965f4])

    def test_explicit_subset_smoke(self):
        stems=[f'HPC_{c["n"]}_{c["k"]}_unknown' for c in CASES]
        argv=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','0','--dry-run','--family','HPC','--out','/tmp/unused-homological-product','--stems']+stems
        jobs=json.loads(subprocess.check_output(argv,cwd=ROOT,text=True));self.assertEqual(len(jobs),6)
        self.assertEqual({j[-1].split('/')[-1] for j in jobs},set(stems))


if __name__=='__main__':unittest.main()
