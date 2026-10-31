#!/usr/bin/env python3
"""Open-target provenance, independent columns, exact component algebra and mutants."""
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts/codegen'))
import open_llm_bb as gen
import validate_open_llm_bb as independent
import validate_css as css
from smoke_untiered import parse,parse_claim
from select_open_llm_bb import select

CASES=gen.CASES


class OpenLLMTests(unittest.TestCase):
    def test_all_actual_inputs_and_source_claims(self):
        self.assertEqual([(c['n'],c['endpoint'],c['claim']) for c in CASES],[(120,10,'estimate'),(162,9,'upper'),(180,14,'estimate'),(384,16,'estimate'),(420,22,'upper'),(432,23,'upper')])
        for c in CASES:
            n,x,z=gen.checks(c);self.assertEqual((x,z),independent.columns(c))
            nn,m=css.read_code(ROOT/'data/matrices/untiered',f'BB_{n}_{c["k"]}_unknown')
            r=independent.certify(c,nn,m);self.assertEqual(r['stabilizer_rowspace_components'],[n]);self.assertTrue(r['dual_map_verified'])

    def test_retained_source_and_corrupt_hash(self):
        with self.assertRaisesRegex(ValueError,'SHA256'):select(b'{"family":"CSS"}\n')
        # Fixed retained output has no class-exact, unsupported-generator or
        # fixed-safety-net row; CI need not download the5MB source catalogue.
        rows=json.loads((ROOT/'optimization/experiments/GH-177/raw/selected-source-records.json').read_text())
        self.assertEqual(len(rows),6)
        for r in rows:
            self.assertFalse(r['distance_class']['is_exact']);self.assertTrue(r['connectivity']['is_connected'])
            self.assertFalse(r['generators']['C_terms'] or r['generators']['D_terms'])
            self.assertFalse(r['provenance']['origin']['fixed_safety_net'])

    def test_reduced_basis_invariant_under_row_mixing(self):
        rng=random.Random(177)
        for _ in range(24):
            rows=[rng.randrange(64) for i in range(5)];mixed=rows[:]
            for i in range(16):
                a,b=rng.sample(range(len(mixed)),2);mixed[a]^=mixed[b]
            rng.shuffle(mixed)
            self.assertEqual(independent.rref(rows),independent.rref(mixed))

    def test_components_against_every_small_coordinate_partition(self):
        rng=random.Random(17702);n=6;all_bits=(1<<n)-1
        for _ in range(20):
            x=[rng.randrange(1<<n) for i in range(4)];z=[rng.randrange(1<<n) for i in range(4)]
            factors=independent.stabilizer_components(n,x,z)
            for mask in range(1,all_bits):
                invariant=all(css.contains(css.basis(rows),row&mask) for rows in (x,z) for row in rows)
                union_of_components=all(not (any((mask>>q)&1 for q in c) and any(not ((mask>>q)&1) for q in c)) for c in factors)
                self.assertEqual(invariant,union_of_components)

    def test_mixed_disconnected_generator_mutant(self):
        original=[3,12,48,192];mixed=[3,3^12,12^48,48^192]
        self.assertEqual(len(independent.components(8,mixed)),1)
        self.assertEqual(independent.stabilizer_components(8,mixed,mixed),[[0,1],[2,3],[4,5],[6,7]])
        self.assertEqual(independent.stabilizer_components(8,original,original),independent.stabilizer_components(8,mixed,mixed))

    def test_tiny_random_polynomial_columns_and_commutation(self):
        rng=random.Random(17703)
        for _ in range(20):
            points=[(x,y) for x in range(3) for y in range(4)]
            c=dict(l=3,m=4,A=rng.sample(points,2),B=rng.sample(points,3))
            n,x,z=gen.checks(c);self.assertEqual((x,z),independent.columns(c))
            self.assertFalse(any(css.dot(a,b) for a in x for b in z))

    def test_transpose_and_logical_mutants(self):
        c=CASES[0];n,m=css.read_code(ROOT/'data/matrices/untiered',f'BB_{c["n"]}_{c["k"]}_unknown')
        bad=[rows[:] for rows in m];v=n//2;mask=(1<<v)-1
        bad[1]=[((row&mask)<<v)|(row>>v) for row in m[0]]
        with self.assertRaisesRegex(ValueError,'physical column'):independent.certify(c,n,bad)
        bad=[rows[:] for rows in m];bad[2][0]=bad[1][0]
        with self.assertRaises(ValueError):css.validate(n,bad)

    def test_decoder_estimate_is_not_a_hard_upper_bound(self):
        text='c d_lb: 16\nc d_ub: 16\no 16\n'
        self.assertEqual(parse_claim(text,'estimate 14 (decoder only)',100),dict(lb=16,ub=16,status='SOLVED'))
        with self.assertRaises(ValueError):parse_claim(text,'<= 14',100)
        with self.assertRaises(ValueError):parse_claim('c d_lb: 17\nc d_ub: 16\no 16\n','estimate 14',100)

    def test_existing_exact_and_upper_claims_preserved(self):
        for text,expected,exact in [('c d_lb: 8\nc d_ub: 8\no 8\n',8,True),('c d_lb: 5\nc d_ub: 10\n',12,False)]:
            self.assertEqual(parse_claim(text,('exact ' if exact else '<= ')+str(expected),100),parse(text,expected,exact=exact))
        for claim in ('range 10','estimate 0','estimate 101'):
            with self.assertRaises(ValueError):parse_claim('c d_lb: 5\nc d_ub: 10\n',claim,100)

    def test_regeneration_and_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            gen.generate(CASES[0],Path(d))
            for p in Path(d).glob('*.txt'):self.assertEqual(p.read_bytes(),(ROOT/'data/matrices/untiered'/p.name).read_bytes())
            with self.assertRaises(FileExistsError):gen.generate(CASES[0],Path(d))

    def test_explicit_subset_smoke(self):
        stems=[f'BB_{c["n"]}_{c["k"]}_unknown' for c in CASES]
        argv=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','0','--dry-run','--family','BB','--out','/tmp/unused-open-llm','--stems']+stems
        jobs=json.loads(subprocess.check_output(argv,cwd=ROOT,text=True));self.assertEqual(len(jobs),6)
        self.assertEqual({j[-1].split('/')[-1] for j in jobs},set(stems))


if __name__=='__main__':unittest.main()
