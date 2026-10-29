#!/usr/bin/env python3
"""Original toric incidence/homology and graph-cover oracle regression tests."""
import json
from pathlib import Path
import random
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/codegen'));sys.path.insert(0,str(ROOT/'scripts'))
import toric
import validate_toric as independent
import validate_css as gf
import compute_logicals as logicals
import smoke_untiered as smoke


def sample(l):
    n,x,z=toric.checks(l)
    dense=lambda rows:[[((r>>q)&1) for q in range(n)] for r in rows]
    gx,gz=logicals.css_logical_nbit_rows(dense(x),dense(z))
    bits=lambda rows:[sum(v<<q for q,v in enumerate(row)) for row in rows]
    return n,[x,z,bits(gx),bits(gz)]


def exhaustive(n,parity,stabilizer):
    span=gf.basis(stabilizer)
    # Gray-code incremental syndrome enumerates every support, no graph oracle.
    best=n;syndrome=0;old=0
    columns=[sum(((r>>q)&1)<<i for i,r in enumerate(parity)) for q in range(n)]
    for i in range(1,1<<n):
        w=i^(i>>1);changed=w^old;old=w;syndrome^=columns[changed.bit_length()-1]
        weight=bin(w).count('1')
        if not syndrome and weight<best and not gf.contains(span,w):best=weight
    return best


class ToricTests(unittest.TestCase):
    def test_independent_geometry_and_ranks(self):
        for l in range(3,7):
            n,m=sample(l);r=independent.certify(l,n,m,True)
            self.assertEqual((r['k'],r['rank_Hx'],r['rank_Hz']),(2,l*l-1,l*l-1))
            self.assertEqual((r['primal_Z']['distance'],r['dual_X']['distance']),(l,l))

    def test_exhaustive_small_anchor_and_stabilizer_mutant(self):
        n,m=sample(3)
        for parity,stab,det in ((m[0],m[1],m[3]),(m[1],m[0],m[2])):
            graph,_=independent.incidence_graph(n,parity)
            self.assertEqual(exhaustive(n,parity,stab),3)
            self.assertEqual(independent.shortest_detected(graph,det)['distance'],3)
            # Treating a parity row as a detector must not create false logicals.
            with self.assertRaises(ValueError):independent.shortest_detected(graph,[parity[0]])

    def test_cover_oracle_all_roots_and_edge_cancellation(self):
        # root0 is a two-edge tail away from an odd triangle. A root0-only walk
        # has length7; modulo-two cancellation and all-root search must give3.
        ends=[(0,1),(1,2),(2,3),(3,4),(4,2)]
        graph=[[] for _ in range(5)]
        for q,(u,v) in enumerate(ends):graph[u].append((v,q));graph[v].append((u,q))
        r=independent.shortest_detected(graph,[1<<2])
        self.assertEqual(r['distance'],3);self.assertEqual(set(r['support']),{2,3,4})

    def test_random_graph_cover_vs_literal_supports(self):
        rng=random.Random(168)
        for _ in range(16):
            vertices=5;edges=[(i,(i+1)%vertices) for i in range(vertices)]+[(0,2),(1,3)]
            rng.shuffle(edges);parity=[0]*vertices;graph=[[] for _ in range(vertices)]
            for q,(u,v) in enumerate(edges):
                parity[u]^=1<<q;parity[v]^=1<<q;graph[u].append((v,q));graph[v].append((u,q))
            detector=rng.randrange(1,1<<len(edges))
            candidates=[w for w in range(1,1<<len(edges)) if not any(gf.dot(w,h) for h in parity) and gf.dot(w,detector)]
            if not candidates:
                with self.assertRaises(ValueError):independent.shortest_detected(graph,[detector])
            else:self.assertEqual(independent.shortest_detected(graph,[detector])['distance'],min(bin(w).count('1') for w in candidates))

    def test_seam_and_coordinate_mutants(self):
        n,m=sample(3)
        for index in (0,1):
            bad=[r[:] for r in m];bad[index][0]^=1<<2
            with self.assertRaises(ValueError):independent.certify(3,n,bad)
        with self.assertRaises(ValueError):toric.checks(2)
        with self.assertRaises(ValueError):independent.geometry(2)

    def test_singular_logical_quotient_mutant(self):
        n,m=sample(3);m[2][1]=m[2][0]
        with self.assertRaises(ValueError):independent.certify(3,n,m)

    def test_random_qubit_and_vertex_labels_preserve_distance(self):
        rng=random.Random(168);n,m=sample(3);perm=list(range(n));rng.shuffle(perm)
        moved=[[sum(((r>>i)&1)<<perm[i] for i in range(n)) for r in rows] for rows in m]
        rng.shuffle(moved[0]);rng.shuffle(moved[1]);gf.validate(n,moved)
        for parity,faces,det in ((moved[0],moved[1],moved[3]),(moved[1],moved[0],moved[2])):
            graph=independent.cellulation(n,parity,faces)
            self.assertEqual(independent.shortest_detected(graph,det)['distance'],3)

    def test_bundled_topology_and_winding_words(self):
        for c in json.loads(toric.CASES.read_text()):
            stem=f'TOR_{c["n"]}_2_unknown';n,m=gf.read_code(ROOT/'data/matrices/untiered',stem)
            r=independent.certify(c['length'],n,m)
            self.assertEqual(len(r['witnesses']),4)

    def test_regeneration_refuses_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            out=Path(d);stem=toric.generate(3,out)
            for p in out.glob('*.txt'):self.assertEqual(p.read_bytes(),(ROOT/'data/matrices/untiered'/p.name).read_bytes())
            with self.assertRaises(FileExistsError):toric.generate(3,out)

    def test_timeout_does_not_promote_published_distance(self):
        raw='c d_lb: -\nc d_ub: -\nc status: TIMEOUT (child killed after -cpu-lim)\ns UNKNOWN\n'
        self.assertEqual(smoke.parse(raw,38),dict(lb=None,ub=None,status='TIMEOUT_NO_BOUNDS'))


if __name__=='__main__':unittest.main()
