#!/usr/bin/env python3
"""Finite tile boundary/pruning/rowspace-equivalence/actual-word guards."""
import copy
import itertools
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts/codegen'))
from tile import build,generate,CASES
from validate_tile import certify,reconstruct
from validate_css import read_code,dot
from review_tile_peers import invariant
from audit_tile_smoke import assess
CASES_LIST=json.loads(CASES.read_text());CERTS=ROOT/'optimization/experiments/GH-194/raw/certificates'


class Tile(unittest.TestCase):
    def setUp(self):
        self.c=CASES_LIST[0];self.n,self.m=read_code(ROOT/'data/matrices/untiered','TILE_288_8_unknown');self.cert=json.loads((CERTS/'TILE_288_8_unknown.json').read_text())
    def test_frozen_source(self):
        self.assertEqual([(c['B'],c['L'],c['n'],c['k']) for c in CASES_LIST],[(3,10,288,8),(4,13,512,18),(4,21,1152,18),(4,33,2592,18)])
        self.assertEqual(self.c['H'],[[0,0],[2,1],[2,2]]);self.assertEqual(self.c['V'],[[0,2],[1,2],[2,0]])
        for c in CASES_LIST[1:]:
            self.assertEqual(c['H'],[[0,0],[1,0],[3,0],[2,1],[2,3]]);self.assertEqual(c['V'],[[0,3],[1,0],[3,1],[3,2],[3,3]])
        self.assertEqual([c['published_exact'] for c in CASES_LIST],[12,None,None,None]);self.assertEqual([c['published_upper'] for c in CASES_LIST],[12,23,None,None])
    def test_random_tiny_boundary_and_pruning(self):
        rng=random.Random(194)
        for _ in range(30):
            B,L=rng.randrange(2,5),rng.randrange(1,5);grid=list(itertools.product(range(B),repeat=2));c=dict(B=B,L=L)
            c['H']=[list(p) for p in rng.sample(grid,rng.randrange(1,len(grid)+1))];c['V']=[list(p) for p in rng.sample(grid,rng.randrange(1,len(grid)+1))]
            c['ZH']=[[B-1-x,B-1-y] for x,y in c['V']];c['ZV']=[[B-1-x,B-1-y] for x,y in c['H']]
            n,hx,hz,cert=build(c);rr,qubits,removed,anchors=reconstruct(c)
            self.assertEqual([hx,hz],rr);self.assertEqual(cert['qubits'],qubits);self.assertEqual(cert['removed_qubits'],removed);self.assertEqual([cert['Xanchors'],cert['Zanchors']],anchors)
            self.assertFalse(any(dot(x,z) for x in hx for z in hz))
    def test_actual_all(self):
        for c in CASES_LIST:
            stem=f'TILE_{c["n"]}_{c["k"]}_unknown';n,m=read_code(ROOT/'data/matrices/untiered',stem);cert=json.loads((CERTS/(stem+'.json')).read_text());self.assertEqual(certify(c,cert,n,m)['k'],c['k'])
    def test_source_blue_partner_mutant(self):
        c=copy.deepcopy(self.c);c['ZH'][0]=[0,0]
        with self.assertRaises(ValueError):reconstruct(c)
    def test_entry_mutant(self):
        m=copy.deepcopy(self.m);m[0][0]^=1
        with self.assertRaises(ValueError):certify(self.c,self.cert,self.n,m)
    def test_wrong_but_commuting_source(self):
        c=copy.deepcopy(self.c);c['H'][0]=[1,0];c['ZH']=[[2-x,2-y] for x,y in c['V']];c['ZV']=[[2-x,2-y] for x,y in c['H']]
        n,hx,hz,cert=build(c);self.assertFalse(any(dot(x,z) for x in hx for z in hz))
        with self.assertRaises(ValueError):certify(self.c,self.cert,n,[hx,hz]+self.m[2:])
    def test_boundary_anchor_mutant(self):
        cert=copy.deepcopy(self.cert);cert['Xanchors'][0]=[100,100]
        with self.assertRaises(ValueError):certify(self.c,cert,self.n,self.m)
    def test_swapped_boundary_types_mutant(self):
        cert=copy.deepcopy(self.cert);cert['Xanchors'],cert['Zanchors']=cert['Zanchors'],cert['Xanchors']
        with self.assertRaises(ValueError):certify(self.c,cert,self.n,self.m)
    def test_certificate_qubit_mutant(self):
        cert=copy.deepcopy(self.cert);cert['qubits'][0],cert['qubits'][1]=cert['qubits'][1],cert['qubits'][0]
        with self.assertRaises(ValueError):certify(self.c,cert,self.n,self.m)
    def test_logical_mutant(self):
        m=copy.deepcopy(self.m);m[2][0]=0
        with self.assertRaises(ValueError):certify(self.c,self.cert,self.n,m)
    def test_actual_pruning_and_empty_rows(self):
        c=dict(B=2,L=1,H=[[0,0]],V=[[1,1]],ZH=[[0,0]],ZV=[[1,1]])
        n,hx,hz,cert=build(c);self.assertEqual(n,2);self.assertEqual(len(cert['removed_qubits']),6);self.assertEqual(hx,[3]);self.assertEqual(hz,[3]);self.assertEqual([hx,hz],reconstruct(c)[0])
    def test_invalid_support(self):
        c=copy.deepcopy(self.c);c['H'].append([0,0])
        with self.assertRaises(ValueError):build(c)
        with self.assertRaises(ValueError):reconstruct(c)
    def test_full_rowspace_invariant_exhaustive_tiny(self):
        rng=random.Random(194)
        for _ in range(40):
            n=rng.randrange(4,10);rows=[rng.randrange(1<<n) for _ in range(rng.randrange(1,6))];span={0}
            for w in rows:span|={v^w for v in list(span)}
            expected=[sum(bin(w).count('1')==t for w in span) for t in [1,2,3]];self.assertEqual(invariant(n,rows),expected)
            p=list(range(n));rng.shuffle(p);permuted=[sum(((w>>i)&1)<<p[i] for i in range(n)) for w in rows]
            self.assertEqual(invariant(n,permuted+permuted),expected)
    def test_peer_invariant_actual(self):
        r=json.loads((ROOT/'optimization/experiments/GH-194/raw/tanner-peer-review.json').read_text())
        self.assertEqual([invariant(self.n,rows) for rows in self.m[:2]],[[0,10,28],[0,10,30]])
        self.assertEqual(r['peer_XZ'],[[0,0,0],[0,0,0]]);self.assertFalse(r['used_provisional_peer_lower'])
    def test_regenerate_all_and_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            d=Path(d);out=d/'matrices';certs=d/'certs'
            for c in CASES_LIST:
                stem=generate(c,out,certs)
                for kind in ['Hx','Hz','Gx','Gz']:self.assertEqual((out/f'{stem}_{kind}.txt').read_bytes(),(ROOT/'data/matrices/untiered'/f'{stem}_{kind}.txt').read_bytes())
                self.assertEqual((certs/(stem+'.json')).read_bytes(),(CERTS/(stem+'.json')).read_bytes())
                with self.assertRaises(FileExistsError):generate(c,out,certs)
    def test_missing_raw_not_filled(self):
        c=certify(self.c,self.cert,self.n,self.m);raw='c status: TIMEOUT (child killed after -cpu-lim)\ns UNKNOWN\n';r=assess(self.c,self.n,self.m,c,dict(maxsat=raw,cc=raw))
        self.assertIsNone(r['engines']['maxsat']['lb']);self.assertEqual(r['numeric_smoke_gate'],'INCOMPLETE');self.assertEqual(r['source_upper_word_gate'],'INCOMPLETE')
    def test_source_exact_and_word_mutants(self):
        c=certify(self.c,self.cert,self.n,self.m)
        for raw in ['c d_lb: 13\nc d_ub: 15\n','c d_lb: 1\nc d_ub: 11\n','c d_lb: 1\nc d_ub: 12\nc witness X: 0\n','c d_lb: 12\nc d_ub: 12\no 12\n']:
            with self.assertRaises(ValueError):assess(self.c,self.n,self.m,c,dict(maxsat=raw,cc=raw))
    def test_smoke_selections_and_invalid_cli(self):
        base=[sys.executable,str(ROOT/'scripts/codegen/smoke_untiered.py'),'--cpu','54','--out','/tmp/GH194-NOT-ALLOCATED','--dry-run']
        for flags,count in [([],12),(['--family','TILE'],4)]:
            r=subprocess.run(base+flags,capture_output=True,text=True,check=True);self.assertEqual(len(json.loads(r.stdout)),count)
        r=subprocess.run([sys.executable,str(ROOT/'scripts/codegen/tile.py'),'--n','1','--certificates','/tmp/GH194-NOT-CREATED'],capture_output=True);self.assertNotEqual(r.returncode,0)


if __name__=='__main__':unittest.main()
