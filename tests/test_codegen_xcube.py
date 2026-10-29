#!/usr/bin/env python3
"""Independent source incidence/disjoint logical proof mutants, no search."""
import copy,json,random,subprocess,sys,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts/codegen'))
from xcube import build,generate,CASES
from validate_xcube import certify,detector_family,physical_components
from validate_css import read_code,validate
from verify_css_witness import verify_witness

class XCube(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cases=json.loads(CASES.read_text());cls.c=cls.cases[0];cls.stem=f'XCB_{cls.c["n"]}_{cls.c["k"]}_unknown';cls.n,cls.m=read_code(ROOT/'data/matrices/untiered',cls.stem);cls.cert=json.loads((ROOT/'optimization/experiments/GH-190/raw/certificates'/f'{cls.stem}.json').read_text())
    def test_complete_first_certificate(self):self.assertEqual(certify(self.c,self.cert,self.n,self.m)['independent_overall_lower'],3)
    def test_all_fixed_source_ranks(self):
        for c in self.cases:
            cert,_,_=build(c);self.assertEqual(cert['k'],6*c['L']-3)
    def test_cube_edge_mutant(self):
        m=copy.deepcopy(self.m);m[0][0]^=3
        with self.assertRaises(ValueError):certify(self.c,self.cert,self.n,m)
    def test_incoming_vertex_star_mutant(self):
        m=copy.deepcopy(self.m);m[1][0]^=3
        with self.assertRaises(ValueError):certify(self.c,self.cert,self.n,m)
    def test_commuting_wrong_source_presentation(self):
        m=copy.deepcopy(self.m);m[0][0]^=m[0][1];validate(self.n,m)
        with self.assertRaises(ValueError):certify(self.c,self.cert,self.n,m)
    def test_incomplete_detector_count(self):
        r=copy.deepcopy(self.cert['detectors']['X']);r.pop()
        with self.assertRaisesRegex(ValueError,'incomplete'):detector_family(self.n,r,self.m[1],self.m[0],15,3)
    def test_incomplete_detector_quotient(self):
        r=copy.deepcopy(self.cert['detectors']['X']);r[0]=r[1]
        with self.assertRaisesRegex(ValueError,'quotient'):detector_family(self.n,r,self.m[1],self.m[0],15,3)
    def test_missing_representative(self):
        r=copy.deepcopy(self.cert['detectors']['X']);r[0]['equivalent_supports'].pop()
        with self.assertRaisesRegex(ValueError,'count'):detector_family(self.n,r,self.m[1],self.m[0],15,3)
    def test_overlapping_representatives(self):
        r=copy.deepcopy(self.cert['detectors']['X']);r[0]['equivalent_supports'][1]=r[0]['support']
        with self.assertRaisesRegex(ValueError,'overlap'):detector_family(self.n,r,self.m[1],self.m[0],15,3)
    def test_wrong_coset_disjoint_line(self):
        r=copy.deepcopy(self.cert['detectors']['X']);r[0]['equivalent_supports'][1]=r[1]['support']
        with self.assertRaisesRegex(ValueError,'coset'):detector_family(self.n,r,self.m[1],self.m[0],15,3)
    def test_parameter_identity(self):
        cert=copy.deepcopy(self.cert);cert['parameter_sha256']='0'*64
        with self.assertRaisesRegex(ValueError,'identity'):certify(self.c,cert,self.n,self.m)
    def test_logical_quotient_mutant(self):
        m=copy.deepcopy(self.m);m[2][0]=m[2][1]
        with self.assertRaises(ValueError):validate(self.n,m)
    def test_false_stabilizer_upper(self):
        qs=[q for q in range(self.n) if (self.m[0][0]>>q)&1]
        with self.assertRaises(ValueError):verify_witness(self.n,self.m,'X',qs)
    def test_random_physical_relabels_preserve_generic_coset_certificate(self):
        rng=random.Random(190)
        for _ in range(5):
            perm=list(range(self.n));rng.shuffle(perm)
            def move(w):return sum(((w>>q)&1)<<perm[q] for q in range(self.n))
            for half,parity,stab in [('X',self.m[1],self.m[0]),('Z',self.m[0],self.m[1])]:
                r=copy.deepcopy(self.cert['detectors'][half])
                for row in r:
                    row['support']=[perm[q] for q in row['support']];row['equivalent_supports']=[[perm[q] for q in qs] for qs in row['equivalent_supports']]
                self.assertEqual(len(detector_family(self.n,r,list(map(move,parity)),list(map(move,stab)),15,3)),15)
        self.assertEqual(physical_components(4,[15],[3]),1);self.assertEqual(physical_components(4,[3,12],[3,12]),2)
    def test_byte_regeneration_and_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            out,certs=Path(d)/'out',Path(d)/'certs';stem=generate(self.c,out,certs)
            for kind in ['Hx','Hz','Gx','Gz']:self.assertEqual((out/f'{stem}_{kind}.txt').read_bytes(),(ROOT/'data/matrices/untiered'/f'{stem}_{kind}.txt').read_bytes())
            self.assertEqual((certs/f'{stem}.json').read_bytes(),(ROOT/'optimization/experiments/GH-190/raw/certificates'/f'{stem}.json').read_bytes())
            with self.assertRaises(FileExistsError):generate(self.c,out,certs)
    def test_cli_explicit4_and_default12(self):
        base=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','54','--dry-run','--out','/tmp/not-allocated']
        r=subprocess.run(base+['--family','XCB'],capture_output=True,text=True,check=True);self.assertEqual(len(json.loads(r.stdout)),4)
        r=subprocess.run(base,capture_output=True,text=True,check=True);self.assertEqual(len(json.loads(r.stdout)),12)
        r=subprocess.run(base+['--family','XCB','--stems','HGP_13_1_unknown'],capture_output=True,text=True);self.assertNotEqual(r.returncode,0)

if __name__=='__main__':unittest.main()
