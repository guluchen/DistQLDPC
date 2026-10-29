#!/usr/bin/env python3
"""Finite chain, first-admissible base, gauge and GF2-word tests/mutants."""
from copy import deepcopy
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts/codegen'))
import fiber_bundle as gen
import validate_fiber_bundle as independent
import validate_css as css
from verify_css_witness import verify_witness
CASES=json.loads(gen.CASES.read_text())


class FiberBundleTests(unittest.TestCase):
    def test_frozen_first_admissible_generation(self):
        self.assertEqual([c['replay']['base']['sample'] for c in CASES],[7,43,45,17,21,7])
        for c in CASES:
            base,edges,replay=gen.parameters(c)
            self.assertEqual([format(r,'x') for r in base],c['base_rows_hex']);self.assertEqual(edges,c['edges'])
            self.assertEqual(replay,c['replay']);self.assertEqual(replay['twist_sample'],0)
        bad=deepcopy(CASES[0]);bad['edges'][0][2]=(bad['edges'][0][2]+3)%9
        with self.assertRaisesRegex(ValueError,'first-admissible'):gen.parameters(bad)

    def test_all_actual_chain_columns_and_upper_words(self):
        for c in CASES:
            n,x,z=gen.checks(c);self.assertEqual((x,z),independent.columns(c))
            nn,m=css.read_code(ROOT/'data/matrices/untiered',f'FBC_{n}_{c["k"]}_unknown')
            result=independent.certify(c,nn,m);w=result['independently_checked_upper']
            self.assertEqual(w['weight'],c['L']);verify_witness(n,m,'X',w['support'])

    def test_tiny_random_chain_squarezero(self):
        rng=random.Random(178)
        for _ in range(16):
            nb,mb,L=4,3,rng.choice([3,5]);base=[rng.randrange(1,1<<nb) for r in range(mb)]
            edges=[[r,b,rng.randrange(L)] for r,row in enumerate(base) for b in gen.support(row)]
            c=dict(base_n=nb,base_m=mb,L=L,edges=edges)
            n,x,z=gen.checks(c,base,edges);self.assertEqual((x,z),independent.columns(c))
            self.assertFalse(any(css.dot(a,b) for a in x for b in z))

    def test_weighted_gauge_matches_bfs_and_trivial_mutant(self):
        rng=random.Random(17802)
        for c in CASES:
            a=independent.gauge(c);b=gen.cycle_residues(c['base_n'],c['base_m'],c['L'],c['edges'])[1]
            self.assertEqual(a['cycle_gcd'],b);self.assertEqual(b,c['ell'])
            shifted=deepcopy(c);p=[rng.randrange(c['L']) for i in range(c['base_n']+c['base_m'])]
            shifted['edges']=[[r,b,(t+p[r]-p[c['base_m']+b])%c['L']] for r,b,t in c['edges']]
            self.assertEqual(independent.gauge(shifted)['cycle_gcd'],b)
        c=deepcopy(CASES[0]);c['edges']=[[r,b,0] for r,b,t in c['edges']]
        self.assertEqual(independent.gauge(c)['cycle_gcd'],c['L'])
        n,m=css.read_code(ROOT/'data/matrices/untiered',f'FBC_{c["n"]}_{c["k"]}_unknown')
        with self.assertRaisesRegex(ValueError,'removable'):independent.certify(c,n,m)

    def test_gauge_transformation_is_actual_physical_permutation(self):
        c=CASES[0];nb,mb,L=c['base_n'],c['base_m'],c['L'];base=[int(s,16) for s in c['base_rows_hex']]
        rng=random.Random(17803);bit=[rng.randrange(L) for _ in range(nb)];check=[rng.randrange(L) for _ in range(mb)]
        changed=[[r,b,(t+check[r]-bit[b])%L] for r,b,t in c['edges']]
        n,x,z=gen.checks(c,base,c['edges']);_,xx,zz=gen.checks(c,base,changed)
        order=[b*L+(j+bit[b])%L for b in range(nb) for j in range(L)]+[nb*L+r*L+(j+check[r])%L for r in range(mb) for j in range(L)]
        move=lambda w:sum(1<<order[q] for q in gen.support(w))
        self.assertEqual({move(w) for w in x},set(xx));self.assertEqual({move(w) for w in z},set(zz))

    def test_incorrect_boundary_twist_mutant(self):
        c=CASES[0];n,m=css.read_code(ROOT/'data/matrices/untiered',f'FBC_{c["n"]}_{c["k"]}_unknown')
        bad=deepcopy(m);vertical=c['base_n']*c['L'];q=next(q for q in gen.support(bad[1][0]) if q>=vertical)
        r,j=divmod(q-vertical,c['L']);qq=vertical+r*c['L']+(j+1)%c['L'];bad[1][0]^=(1<<q)|(1<<qq)
        self.assertTrue(any(css.dot(a,b) for a in bad[0] for b in bad[1]))
        with self.assertRaisesRegex(ValueError,'chain columns'):independent.certify(c,n,bad)

    def test_invalid_base_and_fiber_mutants(self):
        c=deepcopy(CASES[0]);n,m=css.read_code(ROOT/'data/matrices/untiered',f'FBC_{c["n"]}_{c["k"]}_unknown')
        c['base_rows_hex'][0]=c['base_rows_hex'][1]
        with self.assertRaisesRegex(ValueError,'base shape'):independent.certify(c,n,m)
        for L,ell in [(8,3),(4,2)]:
            bad=dict(CASES[0],L=L,ell=ell)
            with self.assertRaisesRegex(ValueError,'square fiber'):gen.derive(bad)

    def test_stabilizer_is_not_an_upper_word(self):
        c=CASES[0];n,m=css.read_code(ROOT/'data/matrices/untiered',f'FBC_{c["n"]}_{c["k"]}_unknown')
        with self.assertRaises(ValueError):verify_witness(n,m,'X',gen.support(m[0][0]))

    def test_byte_regeneration_and_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            gen.generate(CASES[0],Path(d))
            for p in Path(d).glob('*.txt'):self.assertEqual(p.read_bytes(),(ROOT/'data/matrices/untiered'/p.name).read_bytes())
            with self.assertRaises(FileExistsError):gen.generate(CASES[0],Path(d))

    def test_stable_random_stream(self):
        r=gen.Random64(0);self.assertEqual([r.word(),r.word()],[0xe220a8397b1dcdaf,0x6e789e6aa1b965f4])
        with self.assertRaises(ValueError):r.below(0)

    def test_explicit_subset_smoke(self):
        stems=[f'FBC_{c["n"]}_{c["k"]}_unknown' for c in CASES]
        argv=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','0','--dry-run','--family','FBC','--out','/tmp/unused-fiber-bundle','--stems']+stems
        jobs=json.loads(subprocess.check_output(argv,cwd=ROOT,text=True));self.assertEqual(len(jobs),6)
        self.assertEqual({j[-1].split('/')[-1] for j in jobs},set(stems))


if __name__=='__main__':unittest.main()
