#!/usr/bin/env python3
"""Independent physical incidences, actual graph covers, random tiny mutants."""
from copy import deepcopy
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts/codegen'))
import covering_bb as gen
import validate_covering_bb as independent
import validate_css as css

SPEC=gen.SPEC;CASES=gen.CASES


class CoveringBBTests(unittest.TestCase):
    def test_all_actual_inputs_and_column_construction(self):
        for c in CASES:
            n,hx,hz=gen.checks(c);self.assertEqual((hx,hz),independent.independent_columns(c))
            nn,m=css.read_code(ROOT/'data/matrices/untiered',f'BB_{n}_{c["k"]}_unknown');self.assertEqual(nn,n)
            result=independent.certify(c,SPEC['bases'][c['base']],n,m)
            self.assertEqual(result['cover']['h'],c['h']);self.assertEqual(result['rank_pairing'],14)

    def test_random_tiny_cover_maps(self):
        rng=random.Random(176)
        for _ in range(24):
            l,m=3,3
            base=dict(l=l,m=m,A=rng.sample([(x,y) for x in range(l) for y in range(m)],4),B=rng.sample([(x,y) for x in range(l) for y in range(m)],4))
            u,t=rng.choice([(2,1),(1,2),(3,1),(1,3)])
            c=dict(l=l*u,m=m*t,h=u*t)
            for key in ('A','B'):c[key]=[(a+l*rng.randrange(u),b+m*rng.randrange(t)) for a,b in base[key]]
            n,hx,hz=gen.checks(c)
            self.assertEqual((hx,hz),independent.independent_columns(c))
            result=independent.check_cover(c,base,(hx,hz),independent.independent_columns(base))
            self.assertTrue(result['chain_projection'] and result['chain_transfer']);self.assertEqual(result['projection_transfer_scalar'],c['h']%2)

    def test_monomial_and_degree_mutants(self):
        c=deepcopy(CASES[1]);base=SPEC['bases'][c['base']]
        c['A'][0][0]+=1
        with self.assertRaisesRegex(ValueError,'monomial projection'):independent.check_cover(c,base,gen.checks(c)[1:],independent.independent_columns(base))
        c=deepcopy(CASES[1]);hx,hz=gen.checks(c)[1:];hx[0]^=hx[0]&-hx[0]
        with self.assertRaisesRegex(ValueError,'check neighborhood'):independent.check_cover(c,base,(hx,hz),independent.independent_columns(base))

    def test_locally_rewired_cover_mutant(self):
        c=CASES[1];base=SPEC['bases'][c['base']];hx,hz=gen.checks(c)[1:]
        # Move one edge to another same-fiber physical qubit. It preserves
        # the projected check support but violates qubit neighborhood bijection.
        q=independent.support(hx[0])[0];v=c['l']*c['m'];side,t=divmod(q,v);x,y=divmod(t,c['m'])
        qq=side*v+x*c['m']+(y+base['m'])%c['m'];self.assertNotEqual(q,qq)
        self.assertFalse((hx[0]>>qq)&1);hx[0]^=(1<<q)|(1<<qq)
        with self.assertRaisesRegex(ValueError,'qubit neighborhood'):independent.check_cover(c,base,(hx,hz),independent.independent_columns(base))

    def test_bad_multiplicity_and_collisions(self):
        c=deepcopy(CASES[1]);base=SPEC['bases'][c['base']];c['h']=3
        with self.assertRaisesRegex(ValueError,'multiplicity'):independent.check_cover(c,base,gen.checks(c)[1:],independent.independent_columns(base))
        c=deepcopy(CASES[0]);c['A'][1]=c['A'][0]
        with self.assertRaisesRegex(ValueError,'collide'):independent.independent_columns(c)

    def test_invalid_logical_and_incidence_mutants(self):
        c=CASES[0];n,m=css.read_code(ROOT/'data/matrices/untiered',f'BB_{c["n"]}_{c["k"]}_unknown')
        bad=deepcopy(m);bad[0][0]^=1
        with self.assertRaisesRegex(ValueError,'physical columns'):independent.certify(c,SPEC['bases'][c['base']],n,bad)
        bad=deepcopy(m);bad[2][0]=bad[1][0]
        with self.assertRaises(ValueError):css.validate(n,bad)

    def test_dual_map_and_translation_survive_actual_checks(self):
        for c in CASES:
            n,m=css.read_code(ROOT/'data/matrices/untiered',f'BB_{c["n"]}_{c["k"]}_unknown')
            result=independent.certify(c,SPEC['bases'][c['base']],n,m)
            self.assertTrue(result['dual_map_verified']);self.assertTrue(result['connected_both_halves'])

    def test_regeneration_and_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            gen.generate(CASES[0],Path(d))
            for p in Path(d).glob('*.txt'):self.assertEqual(p.read_bytes(),(ROOT/'data/matrices/untiered'/p.name).read_bytes())
            with self.assertRaises(FileExistsError):gen.generate(CASES[0],Path(d))

    def test_frozen_source_claims(self):
        self.assertEqual([(c['n'],c['d'],c['claim']) for c in CASES],[(64,8,'exact'),(128,12,'exact'),(192,16,'upper'),(216,20,'upper'),(256,22,'upper'),(288,24,'upper')])
        self.assertEqual({len(c['A'])+len(c['B']) for c in CASES},{8})

    def test_explicit_subset_smoke(self):
        stems=[f'BB_{c["n"]}_{c["k"]}_unknown' for c in CASES]
        cmd=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--family','BB','--cpu','0','--dry-run','--out','/tmp/unused-covering-bb','--stems']+stems
        jobs=json.loads(subprocess.check_output(cmd,cwd=ROOT,text=True));self.assertEqual(len(jobs),6)
        self.assertEqual({x[-1].split('/')[-1] for x in jobs},set(stems))


if __name__=='__main__':unittest.main()
