"""Independent polynomial/physical/Smith/CSS/source and log-semantics contracts."""
import copy
import json
from pathlib import Path
import random
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/codegen'))
import polynomial_minors as gen
import validate_polynomial_minors as audit
import validate_css as css
import audit_polynomial_minors_smoke as logs
from verify_css_witness import verify_witness

CASES=json.loads(gen.CASE_PATH.read_text())
DIRECTORY=ROOT/'data/matrices/untiered'


class MinorTests(unittest.TestCase):
    def test_all_frozen_matrices_independent_smith_and_literal_entries(self):
        for c in CASES:
            n,hx,hz,r=gen.checks(c);xx,zz,p=audit.reconstruct(c)
            self.assertEqual((hx,hz),(xx,zz))
            self.assertEqual((r['rank_Hx'],r['rank_Hz'],r['k']),
                             (p['predicted_rank_Hx'],p['predicted_rank_Hz'],p['predicted_k']))
            self.assertEqual(n,3*c['lift'])
            self.assertNotEqual(r['rank_Hx'],r['rank_Hz'])

    def test_complete_frozen_logicals_words_and_indecomposability(self):
        for c in CASES:
            r=audit.audit_case(c,DIRECTORY)
            self.assertEqual(r['canonical_support_components'],[3*c['lift']])
            self.assertEqual(r['k'],c['k'])
            if c['lift']>=85:
                word=next(w for w in r['actual_words'] if w['origin'].startswith('first primitive row'))
                self.assertEqual(word['weight'],54)

    def test_random_tiny_polynomial_smith_and_physical_cases(self):
        rng=random.Random(209);accepted=0
        for _ in range(200):
            n=rng.choice([3,5,7,9,11]);c=dict(id='tiny',lift=n,t=0,q=[0])
            for key in ('a','b','c'):c[key]=rng.sample(range(n),2)
            try:_,hx,hz,r=gen.checks(c)
            except ValueError as e:
                self.assertIn('all minors vanish',str(e));continue
            c['k']=r['k'];xx,zz,p=audit.reconstruct(c)
            self.assertEqual((hx,hz),(xx,zz))
            self.assertEqual(r['k'],p['predicted_k'])
            self.assertFalse(any(css.dot(x,z) for x in hx for z in hz))
            accepted+=1
            if accepted==30:break
        self.assertEqual(accepted,30)

    def test_random_independent_cyclic_products(self):
        rng=random.Random(2091)
        for n in (3,5,9,17):
            for _ in range(20):
                x,y=rng.randrange(1 << n),rng.randrange(1 << n)
                a=[(x >> i)&1 for i in range(n)];b=[(y >> i)&1 for i in range(n)]
                self.assertEqual(gen.product(x,y,n),audit.bits(audit.cyclic_product(a,b,n)))

    def test_modular_aliases_cancel_in_gf2(self):
        self.assertEqual(gen.poly([0,9],9),0)
        self.assertEqual(audit.polynomial([0,9],9),[])
        self.assertEqual(gen.product(1 << 8,1 << 2,9),1 << 1)

    def test_transpose_and_right_circulant_convention(self):
        p=gen.poly([0,1,3],9)
        self.assertEqual(gen.transpose(p,9),gen.poly([0,8,6],9))
        self.assertEqual(gen.transpose(gen.transpose(p,9),9),p)
        hx,_,_=audit.reconstruct(CASES[0])
        self.assertEqual(hx[0]&511,gen.poly([0,8,6],9))
        self.assertEqual(hx[1]&511,gen.poly([1,0,7],9))

    def test_new_lift_cannot_inherit_source_dimension(self):
        c=dict(CASES[2],k=80)
        with self.assertRaises(ValueError):gen.checks(c)
        with self.assertRaises(ValueError):audit.source(c)

    def test_wrong_specialization_or_source_ranks_rejected(self):
        for c in (dict(CASES[0],lift=8),dict(CASES[0],t=1),dict(CASES[0],q=[0,1]),
                  dict(CASES[1],source_ranks=[117,58])):
            with self.assertRaises(ValueError):gen.checks(c)

    def test_zero_entries_or_zero_minors_rejected(self):
        for c in (dict(CASES[0],a=[]),dict(CASES[0],a=[0],b=[0],c=[0])):
            with self.assertRaises(ValueError):gen.checks(c)
            with self.assertRaises(ValueError):audit.source(c)

    def test_published_word_and_both_asymmetric_logical_halves(self):
        c=CASES[1];r=audit.audit_case(c,DIRECTORY)
        n,m=css.read_code(DIRECTORY,r['stem']);w=c['source_word']
        verify_witness(n,m,w['half'],w['support'])
        self.assertEqual(r['actual_verified_half_uppers']['X'],12)
        self.assertGreaterEqual(r['actual_verified_half_uppers']['Z'],12)
        with self.assertRaises(ValueError):verify_witness(n,m,'X',[0])

    def test_stabilizer_cannot_replace_a_logical_basis(self):
        n,m=css.read_code(DIRECTORY,'PM_27_4_unknown');bad=copy.deepcopy(m)
        bad[2][0]=bad[1][0]
        with self.assertRaises(ValueError):css.validate(n,bad)

    def test_physical_entry_mutant(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory);c=CASES[0];stem='PM_27_4_unknown'
            for kind in ('Hx','Hz','Gx','Gz'):(path/(stem+'_'+kind+'.txt')).write_bytes((DIRECTORY/(stem+'_'+kind+'.txt')).read_bytes())
            p=path/(stem+'_Hz.txt');text=p.read_text().splitlines()
            row=text[1].split();row[0]=str(1-int(row[0]));text[1]=' '.join(row);p.write_text('\n'.join(text)+'\n')
            with self.assertRaises(ValueError):audit.audit_case(c,path)

    def test_generator_refuses_overwrite(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory);gen.generate(CASES[0],path)
            with self.assertRaises(FileExistsError):gen.generate(CASES[0],path)

    def test_components_are_rowbasis_invariant(self):
        self.assertEqual(audit.components([[3,12],[]],4),[2,2])
        # The second displayed row has support in both components. Canonical
        # rowspaces must detect the direct sum despite this basis mixing.
        self.assertEqual(audit.components([[3,15],[]],4),[2,2])

    def test_equivalent_reflection_is_not_the_frozen_physical_convention(self):
        c=CASES[0];stem='PM_27_4_unknown';n,m=css.read_code(DIRECTORY,stem);N=c['lift']
        reflected=[[sum(((row >> (j*N+i))&1) << (j*N+(-i)%N)
                         for j in range(3) for i in range(N)) for row in rows] for rows in m]
        self.assertEqual(css.validate(n,reflected)['k'],4)
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)
            for kind,rows in zip(('Hx','Hz','Gx','Gz'),reflected):
                (path/(stem+'_'+kind+'.txt')).write_text('\n'.join(' '.join(str((r >> i)&1) for i in range(n)) for r in rows)+'\n')
            with self.assertRaises(ValueError):audit.audit_case(c,path)

    def test_unknown_claim_and_raw_fields_are_separate(self):
        c=CASES[2];r=audit.audit_case(c,DIRECTORY);n,m=css.read_code(DIRECTORY,r['stem'])
        observed=logs.assess(c,n,m,r,{'maxsat':'c d_lb: 1\nc d_ub: 84\ns UNKNOWN\n'})
        self.assertIsNone(observed['published_lower'])
        self.assertIsNone(observed['published_exact'])
        self.assertEqual(observed['engines']['maxsat']['lb'],1)
        self.assertEqual(observed['source_upper_word_gate'],'NOT_APPLICABLE')

    def test_timeout_without_bounds_stays_incomplete(self):
        c=CASES[0];r=audit.audit_case(c,DIRECTORY);n,m=css.read_code(DIRECTORY,r['stem'])
        raw='c status: TIMEOUT (child killed after -cpu-lim)\ns UNKNOWN\n'
        observed=logs.assess(c,n,m,r,{'maxsat':raw})
        self.assertIsNone(observed['engines']['maxsat']['lb'])
        self.assertIsNone(observed['engines']['maxsat']['ub'])
        self.assertEqual(observed['numeric_smoke_gate'],'INCOMPLETE')

    def test_exact_without_actual_minimum_word_cannot_be_confirmed(self):
        c=CASES[0];r=audit.audit_case(c,DIRECTORY);n,m=css.read_code(DIRECTORY,r['stem'])
        r=dict(r,actual_words=[w for w in r['actual_words'] if w['weight']!=4])
        raw='c d_lb: 4\nc d_ub: 4\no 4\n'
        observed=logs.assess(c,n,m,r,{'maxsat':raw,'cc':raw})
        self.assertIsNone(observed['confirmed_exact'])
        self.assertEqual(observed['exact_minimum_word_gate'],'INCOMPLETE')
        self.assertEqual(observed['reported_upper_word_gate'],'INCOMPLETE')

    def test_invalid_native_word_rejected(self):
        c=CASES[0];r=audit.audit_case(c,DIRECTORY);n,m=css.read_code(DIRECTORY,r['stem'])
        with self.assertRaises(ValueError):logs.assess(c,n,m,r,{'maxsat':'c d_lb: 1\nc d_ub: 6\nc witness X: 0\ns UNKNOWN\n'})


if __name__=='__main__':unittest.main()
