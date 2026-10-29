#!/usr/bin/env python3
"""Tiny algebra/source/CLI/evidence mutants; no logical-distance solver."""
import copy
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts/codegen'))
import schreier_tanner as gen
import validate_schreier as audit
import audit_schreier_smoke as evidence
from validate_css import read_code,validate,dot
from smoke_untiered import parse_claim


class Schreier(unittest.TestCase):
    def setUp(self):
        self.cases=json.loads(gen.CASES.read_text())
        self.made={r['case_id']:r for r in json.loads((ROOT/'optimization/experiments/GH-202/raw/generation.json').read_text())}
        self.checked={r['case_id']:r for r in json.loads((ROOT/'optimization/experiments/GH-202/raw/construction.json').read_text())}

    def test_frozen_selection_and_claims(self):
        self.assertEqual([(c['id'],c['p'],c['n'],c['k'],c['published_exact']) for c in self.cases],
            [('source180',5,180,26,6),('source500',5,500,42,6),('source686',7,686,28,14),
             ('original1100',11,1100,None,None),('original1900',19,1900,None,None),('original2900',29,2900,None,None)])

    def test_source_inverse_pair_order(self):
        c=self.cases[2];self.assertEqual(c['A'],[[2,-2,3,-3],[0,1,4],[1,-1,3,-3]])
        self.assertEqual(c['B'],[0,1,-1,2,-2,3,-3]);self.assertEqual(c['HA'],['1011100','0111010','0001111'])
        self.assertEqual(self.cases[1]['HB'],['11100','01110','00111'])

    def test_every_actual_code_against_independent_geometry(self):
        for c in self.cases:
            r=audit.audit(c,self.made[c['id']],ROOT/'data/matrices/untiered')
            self.assertEqual(r,self.checked[c['id']]);self.assertEqual(r['stabilizer_support_components'],[c['n']])

    def test_petersen_factor_is_exact_literal_graph(self):
        c=self.cases[0];vertices,A,B,ia,ib=audit.literal_actions(c)
        for u,(a,b,g) in enumerate(vertices):
            neighbors={vertices[v] for v in A[u]}
            step=1 if a==0 else 2
            self.assertEqual(neighbors,{(a,b,(g+step)%5),(a,b,(g-step)%5),(1-a,b,g)})

    def test_thirty_tiny_random_commuting_cases(self):
        rng=random.Random(202)
        for _ in range(30):
            c=copy.deepcopy(self.cases[0]);p=rng.choice([3,5,7]);c.update(p=p,n=36*p,k=None,published_exact=None)
            c['A'][1]=[rng.randrange(p)];c['B'][1]=[rng.randrange(p)]
            result,hx,hz,stars=gen.construction(c)
            self.assertEqual(result['n'],36*p);self.assertFalse(any(dot(a,b) for a in hx for b in hz))
            vertices,A,B,ia,ib=audit.literal_actions(c)
            self.assertEqual(len(vertices),4*p)

    def test_source_k_mismatch_refused(self):
        c=dict(self.cases[0],k=27)
        with tempfile.TemporaryDirectory() as temp:
            with self.assertRaisesRegex(ValueError,'SOURCE_DIMENSION_HOLD'):gen.generate(c,Path(temp))
            self.assertEqual(list(Path(temp).iterdir()),[])

    def test_local_parity_bad_syntax(self):
        for strings in [[],['10','1'],['102']]:
            with self.assertRaises(ValueError):gen.rows(strings)

    def test_invalid_graph_and_degree(self):
        c=copy.deepcopy(self.cases[0]);c['A'][1]=[0,0]
        with self.assertRaises(ValueError):gen.actions(c)
        c=copy.deepcopy(self.cases[0]);c['HB']=['11']
        with self.assertRaises(ValueError):gen.actions(c)

    def test_local_kernel_is_complete_by_enumeration(self):
        for c in self.cases:
            for key in ['HA','HB']:
                width=len(c[key][0]);basis=gen.kernel(gen.rows(c[key]),width)
                span={0}
                for r in basis:span|={s^r for s in list(span)}
                self.assertEqual(span,set(audit.codewords(c[key])))

    def test_entry_and_logical_mutants(self):
        stem=self.made['source180']['stem'];n,m=read_code(ROOT/'data/matrices/untiered',stem)
        m[0][0]^=1
        with self.assertRaises(ValueError):validate(n,m)
        n,m=read_code(ROOT/'data/matrices/untiered',stem);m[2][0]=0
        with self.assertRaises(ValueError):validate(n,m)

    def test_unknown_original_not_given_source_distance(self):
        c=self.cases[3];r=self.made[c['id']];n,m=read_code(ROOT/'data/matrices/untiered',r['stem'])
        out=evidence.assess(c,n,m,self.checked[c['id']],{'maxsat':'c d_lb: 3\nc d_ub: 20\n','cc':'c d_lb: 4\nc d_ub: 10\n'})
        self.assertEqual(out['source_upper_word_gate'],'NOT_APPLICABLE');self.assertEqual(out['reference_range'],[None,None])
        self.assertEqual(out['engines']['maxsat']['ub'],20);self.assertEqual(out['actual_verified_upper'],10)

    def test_missing_numeric_not_filled(self):
        c=self.cases[3];r=self.made[c['id']];n,m=read_code(ROOT/'data/matrices/untiered',r['stem'])
        out=evidence.assess(c,n,m,self.checked[c['id']],{'maxsat':'c status: TIMEOUT (child killed after -cpu-lim)\ns UNKNOWN\n'})
        self.assertIsNone(out['engines']['maxsat']['lb']);self.assertIsNone(out['engines']['maxsat']['ub'])
        self.assertEqual(out['numeric_smoke_gate'],'INCOMPLETE')

    def test_source_exact_and_missing_minimum_mutants(self):
        c=self.cases[0];r=self.made[c['id']];n,m=read_code(ROOT/'data/matrices/untiered',r['stem'])
        with self.assertRaises(ValueError):evidence.assess(c,n,m,self.checked[c['id']],{'maxsat':'c d_lb: 5\nc d_ub: 5\no 5\n'})
        c=self.cases[3];r=self.made[c['id']];n,m=read_code(ROOT/'data/matrices/untiered',r['stem'])
        with self.assertRaisesRegex(ValueError,'lacks actual minimum word'):evidence.assess(c,n,m,self.checked[c['id']],{'maxsat':'c d_lb: 2\nc d_ub: 2\no 2\n'})

    def test_invalid_word_and_cross_engine_bound_mutants(self):
        c=self.cases[3];r=self.made[c['id']];n,m=read_code(ROOT/'data/matrices/untiered',r['stem'])
        with self.assertRaises(ValueError):evidence.assess(c,n,m,self.checked[c['id']],{'maxsat':'c d_lb: 2\nc d_ub: 10\nc witness X: 0\n'})
        with self.assertRaises(ValueError):evidence.assess(c,n,m,self.checked[c['id']],{'maxsat':'c d_lb: 11\nc d_ub: 12\n'})

    def test_twenty_four_bytes_and_refuse_overwrite(self):
        with tempfile.TemporaryDirectory() as temp:
            out=Path(temp)
            for c in self.cases:
                r=gen.generate(c,out)
                for kind in ['Hx','Hz','Gx','Gz']:
                    name=r['stem']+'_'+kind+'.txt';self.assertEqual((out/name).read_bytes(),(ROOT/'data/matrices/untiered'/name).read_bytes())
                with self.assertRaises(FileExistsError):gen.generate(c,out)

    def test_cli_selection_and_unknown_claim_ceiling(self):
        base=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','54','--out','/tmp/gh202-never-executed','--dry-run']
        self.assertEqual(len(json.loads(subprocess.check_output(base,text=True))),12)
        self.assertEqual(len(json.loads(subprocess.check_output(base+['--family','TN'],text=True))),6)
        r=parse_claim('c d_lb: 3\nc d_ub: 9\n','unknown (original finite code)',100)
        self.assertEqual(r,dict(lb=3,ub=9,status='BOUNDED'))
        with self.assertRaises(ValueError):parse_claim('c d_lb: 101\nc d_ub: 102\n','unknown',100)
        self.assertFalse(Path('/tmp/gh202-never-executed').exists())


if __name__=='__main__':unittest.main()
