#!/usr/bin/env python3
"""First-admissible sampling, independent product, tiny oracle and mutants."""
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
import expurgated_hgp as gen
import validate_expurgated_hgp as independent
from certify_expurgated_hgp import classical_distance
import validate_css as css
from verify_css_witness import verify_witness

CASES=json.loads(gen.CASES.read_text())


class ExpurgatedHGPTests(unittest.TestCase):
    def test_fixed_independent_reverse_stream_and_columns(self):
        for c in CASES:
            raw,h,indices,ps=gen.factor(c);rr,hh=independent.factors(c)
            self.assertEqual([set(q for q in range(c['classical_n']) if (row>>q)&1) for row in raw],rr)
            self.assertEqual(ps,independent.sample_permutations(c['classical_n'],0,c['sample_index']))
            N,k,x,z=gen.checks(c);self.assertEqual((x,z),independent.reconstruct(c))
            self.assertEqual((N,k),(c['n'],c['k']))

    def test_actual_full_quotients_and_structural_lower_bound(self):
        for c in CASES:
            N,m=css.read_code(ROOT/'data/matrices/untiered',f'HGP_{c["n"]}_{c["k"]}_unknown')
            result=independent.certify(c,N,m)
            self.assertEqual(result['structural_classical_lb'],4)
            self.assertLessEqual(max(result['quantum_row_weights']),7)
            self.assertEqual(result['screening_history'],c['screening_history'])

    def test_first_admissible_minimality_and_history_mutants(self):
        c=deepcopy(CASES[2]);self.assertEqual(c['sample_index'],1)
        self.assertGreater(c['screening_history'][0]['duplicate_pairs'],0)
        c['screening_history'][0]['duplicate_pairs']=0
        with self.assertRaises(ValueError):gen.factor(c)
        with self.assertRaises(ValueError):independent.factors(c)
        c=deepcopy(CASES[0]);c['sample_index']+=1
        with self.assertRaisesRegex(ValueError,'first admissible'):gen.factor(c)
        with self.assertRaisesRegex(ValueError,'earlier admissible'):independent.factors(c)

    def test_duplicate_sample_and_cap_caught(self):
        with self.assertRaisesRegex(ValueError,'without fallback'):gen.first_unique(4,0,max_samples=3)
        c=deepcopy(CASES[2]);c['sample_index']=0
        c['permutations']=independent.sample_permutations(32,0,0)
        c['screening_history']=[dict(sample=0,duplicate_pairs=0,accepted=True)]
        with self.assertRaises(ValueError):independent.factors(c)
        for cap in (0,10001):
            with self.assertRaises(ValueError):gen.first_unique(16,0,max_samples=cap)

    def test_tiny_distinct_column_code_and_complete_oracle(self):
        raw,ps,history=gen.first_unique(8,0)
        supports=[{q for q in range(8) if (row>>q)&1} for row in raw]
        proof=classical_distance(8,supports)
        brute=[w for w in range(1,256) if not any(sum((w>>q)&1 for q in row)%2 for row in supports)]
        self.assertEqual(proof['distance'],4)
        self.assertEqual(proof['distance'],min(bin(w).count('1') for w in brute))
        self.assertEqual(proof['enumerated_codewords'],len(brute)+1)

    def test_wrong_incidence_and_stabilizer_word_mutants(self):
        c=CASES[0];N,m=css.read_code(ROOT/'data/matrices/untiered',f'HGP_{c["n"]}_{c["k"]}_unknown')
        wrong=deepcopy(m);wrong[0][0]^=1
        with self.assertRaises(ValueError):independent.certify(c,N,wrong)
        wrong=deepcopy(m);wrong[2][0]=m[1][0]
        with self.assertRaises(ValueError):css.validate(N,wrong)
        support=[q for q in range(N) if (m[1][0]>>q)&1]
        with self.assertRaises(ValueError):verify_witness(N,m,'Z',support)

    def test_shuffle_and_sparse_row_mutants(self):
        c=deepcopy(CASES[0]);c['permutations'][1][0],c['permutations'][1][1]=c['permutations'][1][1],c['permutations'][1][0]
        with self.assertRaises(ValueError):gen.factor(c)
        with self.assertRaises(ValueError):independent.factors(c)
        c=deepcopy(CASES[0]);c['selected_rows'][0]=c['selected_rows'][1]
        with self.assertRaises(ValueError):gen.factor(c)
        with self.assertRaises(ValueError):independent.factors(c)

    def test_sample_zero_and_domain_separation(self):
        for n in (8,16,24):
            self.assertEqual([gen.permutation(n,0,b) for b in range(3)],independent.sample_permutations(n,0,0))
        self.assertNotEqual(gen.permutation(16,0,1,0),gen.permutation(16,0,1,1))

    def test_reproduction_and_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            stem=gen.generate(CASES[0],Path(d))
            for p in Path(d).glob('*.txt'):self.assertEqual(p.read_bytes(),(ROOT/'data/matrices/untiered'/p.name).read_bytes())
            with self.assertRaises(FileExistsError):gen.generate(CASES[0],Path(d))

    def test_explicit_smoke_subset(self):
        stems=[f'HGP_{c["n"]}_{c["k"]}_unknown' for c in CASES]
        cmd=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','0','--dry-run','--out','/tmp/unused-expurgated','--stems']+stems
        jobs=json.loads(subprocess.check_output(cmd,cwd=ROOT,text=True))
        self.assertEqual({x[-1].split('/')[-1] for x in jobs},set(stems));self.assertEqual(len(jobs),4)


if __name__=='__main__':unittest.main()
