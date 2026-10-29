#!/usr/bin/env python3
"""Independent cells, both-half certificates, tiny random proof units/mutants."""
from copy import deepcopy
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
import toric4d as gen
import validate_toric4d as independent
import validate_css as css
import verify_toric4d_certificate as standalone
from verify_css_witness import verify_witness

CASES=json.loads(gen.CASES.read_text())


class Toric4DTests(unittest.TestCase):
    def test_all_fixed_column_incidence(self):
        for c in CASES:
            n,x,z=gen.checks(c['shape']);self.assertEqual((x,z),independent.reconstruct(c['shape']))
            self.assertEqual(n,c['n']);self.assertEqual({bin(r).count('1') for r in x+z},{6})

    def test_all_fixed_actual_matrix_certificates(self):
        for c in CASES:
            n,m=css.read_code(ROOT/'data/matrices/untiered',f'TOR_{c["n"]}_6_unknown')
            result=independent.certify(c,n,m)
            self.assertEqual([result['lower_certificates'][h]['lower_bound'] for h in ('X','Z')],[c['d'],c['d']])
            for w in result['witnesses']:verify_witness(n,m,w['half'],w['support'])

    def test_tiny_random_certificate_vs_complete_supports(self):
        rng=random.Random(175)
        for _ in range(16):
            order=list(range(4));rng.shuffle(order)
            move=lambda r:sum(((r>>q)&1)<<order[q] for q in range(4))
            parity=[move(15)];logical=list(map(move,[3,5]));families=[list(map(move,f)) for f in ([3,12],[5,10])]
            css.validate(4,[parity,parity,logical,logical])
            proof=independent.packing_certificate(4,parity,parity,logical,families)
            actual=min(bin(w).count('1') for w in range(1,16) if not any(css.dot(w,r) for r in parity) and not css.contains(css.basis(parity),w))
            self.assertEqual(proof['lower_bound'],actual)

    def test_disjointness_and_homology_mutants(self):
        with self.assertRaisesRegex(ValueError,'not disjoint'):
            independent.packing_certificate(4,[15],[15],[3,5],[[3,3],[5,10]])
        with self.assertRaisesRegex(ValueError,'not homologous'):
            independent.packing_certificate(4,[15],[15],[3,5],[[3,8],[5,10]])
        with self.assertRaisesRegex(ValueError,'syndrome'):
            independent.packing_certificate(4,[15],[15],[3,5],[[1,14],[5,10]])

    def test_missing_logical_class_mutants(self):
        with self.assertRaisesRegex(ValueError,'family count'):
            independent.packing_certificate(4,[15],[15],[3,5],[[3,12]])
        with self.assertRaisesRegex(ValueError,'full logical quotient'):
            independent.packing_certificate(4,[15],[15],[3,5],[[3,12],[3,12]])

    def test_source_proof_survives_random_column_permutation(self):
        c=CASES[0];n,m=css.read_code(ROOT/'data/matrices/untiered','TOR_96_6_unknown')
        fibers,planes=independent.detector_families(c['shape']);order=list(range(n));random.Random(9175).shuffle(order)
        move=lambda w:independent.permute(w,order)
        mm=[[move(w) for w in rows] for rows in m]
        css.validate(n,mm)
        for parity,stab,logical,fs in ((mm[0],mm[1],mm[2],fibers),(mm[1],mm[0],mm[3],planes)):
            proof=independent.packing_certificate(n,parity,stab,logical,[[move(w) for w in f] for f in fs])
            self.assertEqual(proof['lower_bound'],4)

    def test_missing_periodic_incidence_and_logical_mutants(self):
        c=CASES[0];n,m=css.read_code(ROOT/'data/matrices/untiered','TOR_96_6_unknown')
        bad=deepcopy(m);bad[0][0]^=bad[0][0]&-bad[0][0]
        with self.assertRaisesRegex(ValueError,'physical face columns'):independent.certify(c,n,bad)
        bad=deepcopy(m);bad[2][0]=bad[1][0]
        with self.assertRaises(ValueError):css.validate(n,bad)

    def test_dual_square_is_translation_and_invalid_shapes(self):
        shape=CASES[1]['shape'];V=len(independent.grid(shape));order=independent.dual_map(shape)
        for q in range(6*V):
            block,t=divmod(q,V);x=independent.grid(shape)[t]
            expected=block*V+independent.label([a-1 for a in x],shape)
            self.assertEqual(order[order[q]],expected)
        for shape in ([1,2,2,2],[2,2,2],[0,2,2,2],[2,2,2,2.5]):
            with self.assertRaises(ValueError):gen.checks(shape)
            with self.assertRaises(ValueError):independent.grid(shape)

    def test_reproduction_and_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            stem=gen.generate(CASES[0],Path(d))
            for p in Path(d).glob('*.txt'):self.assertEqual(p.read_bytes(),(ROOT/'data/matrices/untiered'/p.name).read_bytes())
            with self.assertRaises(FileExistsError):gen.generate(CASES[0],Path(d))

    def test_explicit_family_subset_smoke(self):
        stems=[f'TOR_{c["n"]}_6_unknown' for c in CASES]
        cmd=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--family','TOR','--cpu','0','--dry-run','--out','/tmp/unused-toric4d','--stems']+stems
        jobs=json.loads(subprocess.check_output(cmd,cwd=ROOT,text=True))
        self.assertEqual({x[-1].split('/')[-1] for x in jobs},set(stems));self.assertEqual(len(jobs),6)

    def test_standalone_actual_receipt_and_mutants(self):
        receipt=json.loads((ROOT/'optimization/experiments/GH-175/raw/construction.json').read_text())[0]
        directory=ROOT/'data/matrices/untiered'
        self.assertEqual(standalone.check_code(receipt,directory)['verified_exact_d'],4)
        bad=deepcopy(receipt)
        bad['lower_certificates']['Z']['families'][0][1]=bad['lower_certificates']['Z']['families'][0][0]
        with self.assertRaisesRegex(ValueError,'overlaps'):standalone.check_code(bad,directory)
        bad=deepcopy(receipt);bad['lower_certificates']['X']['families'].pop()
        with self.assertRaisesRegex(ValueError,'omits'):standalone.check_code(bad,directory)
        bad=deepcopy(receipt);bad['witnesses'][0]['support']=[0];bad['witnesses'][0]['weight']=1
        with self.assertRaisesRegex(ValueError,'not logical'):standalone.check_code(bad,directory)

    def test_standalone_low_pivots_against_complete_random_spans(self):
        rng=random.Random(17502)
        for _ in range(24):
            rows=[rng.randrange(64) for i in range(rng.randrange(7))]
            span={0}
            for row in rows:span|={w^row for w in list(span)}
            pivots=standalone.low_basis(rows)
            for word in range(64):self.assertEqual(standalone.in_space(word,pivots),word in span)


if __name__=='__main__':unittest.main()
