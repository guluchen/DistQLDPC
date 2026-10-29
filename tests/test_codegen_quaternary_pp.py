#!/usr/bin/env python3
"""Independent field/group/physical-weight/quotient and provenance mutants."""
import copy
import json
import math
from pathlib import Path
import random
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/codegen'));sys.path.insert(0,str(ROOT/'scripts'))
import quaternary_pp as gen
import validate_quaternary_pp as independent
import validate_css as gf
import compute_logicals as logicals

CASES=json.loads(gen.CASES.read_text())


def sample(c):
    n,x,z=gen.checks(c);dense=lambda rows:[[(r>>q)&1 for q in range(n)] for r in rows]
    gx,gz=logicals.css_logical_nbit_rows(dense(x),dense(z));bits=lambda rows:[sum(v<<q for q,v in enumerate(row)) for row in rows]
    return n,[x,z,bits(gx),bits(gz)]


def tiny(moduli=(1,),seed=0):
    rng=random.Random(seed);u=[[int(i==j) for j in range(3)]+[rng.randrange(4)] for i in range(3)]
    e=[[rng.randrange(math.prod(moduli)) for _ in range(4)] for i in range(3)]
    return dict(n=16*math.prod(moduli),k=4*math.prod(moduli),C=[r+r for r in u],E=[r+r for r in e],group_moduli=list(moduli),row_choices=[[0,1]]*3)


class QuaternaryPPTests(unittest.TestCase):
    def test_all_field_products_and_trace_basis(self):
        for a in range(4):
            for b in range(4):
                want=gen.RHO[independent.field_mul(a,b)]
                got=tuple(tuple(sum(gen.RHO[a][i][k]*gen.RHO[b][k][j] for k in range(2))%2 for j in range(2)) for i in range(2))
                self.assertEqual(want,got)
        for i,a in enumerate((2,3)):
            for j,b in enumerate((2,3)):self.assertEqual(independent.trace(independent.field_mul(a,b)),int(i==j))

    def test_physical_weight_differs_from_symbol_weight(self):
        bits=lambda x:[independent.trace(independent.field_mul(beta,x)) for beta in (2,3)]
        self.assertEqual(bits(1),[1,1]);self.assertEqual(bits(2),[1,0]);self.assertEqual(bits(3),[0,1])
        self.assertEqual(sum(bits(1)),2)

    def test_product_group_is_not_mod32_mutant(self):
        c=next(c for c in CASES if c['n']==512)
        self.assertEqual(gen.add(15,1,[16,2]),0);self.assertEqual(gen.add(15,1,[32]),16)
        self.assertEqual(gen.negative(17,[16,2]),31)
        wrong=copy.deepcopy(c);wrong['group_moduli']=[32]
        with self.assertRaises(ValueError):independent.weighted_commutation(wrong)
        with self.assertRaises(ValueError):independent.source_binding(wrong)

    def test_fixed_physical_columns_quotients_and_source_words(self):
        for c in CASES:
            n,m=gf.read_code(ROOT/'data/matrices/untiered',f'PP_{c["n"]}_{c["k"]}_unknown')
            result=independent.certify(c,n,m)
            self.assertEqual(result['k'],c['k']);self.assertEqual(gen.checks(c),(n,*m[:2]))
            self.assertEqual([w['weight'] for w in result['witnesses']],[c['d'],c['d']])

    def test_invertible_row_presentations_same_code(self):
        c=copy.deepcopy(CASES[-1]);n,x,z=gen.checks(c);c['row_choices']=[[0,1]]*3;_,xx,zz=gen.checks(c)
        self.assertTrue(gf.equal_space(x,xx));self.assertTrue(gf.equal_space(z,zz))
        self.assertLessEqual(max(bin(r).count('1') for r in x+z),11)
        c['row_choices'][0]=[0,0]
        with self.assertRaises(ValueError):gen.checks(c)

    def test_random_tiny_group_algebra_and_column_reconstruction(self):
        for moduli in ((2,),(3,),(2,2)):
            for seed in range(8):
                c=tiny(moduli,seed);n,m=sample(c)
                independent.weighted_commutation(c);self.assertEqual(independent.reconstruct(c),m[:2])
                self.assertEqual(gf.validate(n,m)['k'],c['k'])

    def test_exhaustive_unlifted_support_oracle(self):
        c=tiny(seed=2);n,m=sample(c);self.assertEqual(n,16)
        for parity,stab in ((m[0],m[1]),(m[1],m[0])):
            space=gf.basis(stab)
            distance=min(bin(w).count('1') for w in range(1,1<<n) if not any(gf.dot(w,r) for r in parity) and not gf.contains(space,w))
            self.assertEqual(distance,1 if c['C'][0][3]==c['C'][1][3]==c['C'][2][3]==0 else 2)

    def test_field_entry_mutant_caught(self):
        c=CASES[0];original=gen.RHO
        bad=list(original);bad[2]=((1,1),(1,1))
        try:
            gen.RHO=tuple(bad);_,x,z=gen.checks(c)
            self.assertNotEqual([x,z],independent.reconstruct(c))
        finally:gen.RHO=original

    def test_stale_source_digest_and_logical_mutants(self):
        c=copy.deepcopy(CASES[0]);c['C'][0][0]^=1
        with self.assertRaises(ValueError):independent.source_binding(c)
        c=CASES[0];n,m=gf.read_code(ROOT/'data/matrices/untiered',f'PP_{c["n"]}_{c["k"]}_unknown')
        m[2][1]=m[2][0]
        with self.assertRaises(ValueError):independent.certify(c,n,m)

    def test_stabilizer_word_rejected(self):
        c=CASES[0];n,m=gf.read_code(ROOT/'data/matrices/untiered',f'PP_{c["n"]}_{c["k"]}_unknown');w=m[1][0]
        with self.assertRaises(ValueError):independent.witness(n,m,'Z',[q for q in range(n) if (w>>q)&1])

    def test_global_sign_is_coordinate_relabeling(self):
        c=copy.deepcopy(CASES[0]);n,x,z=gen.checks(c);p=math.prod(c['group_moduli'])
        c['E']=[[gen.negative(e,c['group_moduli']) for e in row] for row in c['E']];_,xx,zz=gen.checks(c)
        mapping=[(q//p)*p+gen.negative(q%p,c['group_moduli']) for q in range(n)]
        row_order=[block*p+gen.negative(g,c['group_moduli']) for block in range(6) for g in range(p)]
        self.assertEqual([independent.permute(x[i],mapping) for i in row_order],xx)
        self.assertEqual([independent.permute(z[i],mapping) for i in row_order],zz)

    def test_byte_regeneration_and_no_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d);gen.generate(CASES[0],p)
            for f in p.glob('*.txt'):self.assertEqual(f.read_bytes(),(ROOT/'data/matrices/untiered'/f.name).read_bytes())
            with self.assertRaises(FileExistsError):gen.generate(CASES[0],p)


if __name__=='__main__':unittest.main()
