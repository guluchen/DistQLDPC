#!/usr/bin/env python3
"""GH-85: compare per-half verified generator sets/orbits with GH-75's joint report.
Usage: cmp_gh75.py GH75_automorphisms.json GH85_half_automorphisms.json"""
import json, sys
a = json.load(open(sys.argv[1]))['codes']; b = {c['stem']: c for c in json.load(open(sys.argv[2]))['codes']}
print('stem | GH-75 joint orbits (plain gens, dual gens) | X half orbits/gens | Z half orbits/gens | half gens == GH-75 plain gens')
for c in a:
    s = c['stem']; plain = {g[6:] for g in c['generators'] if g.startswith('plain ')}
    nd = sum(g.startswith('dual ') for g in c['generators'])
    X, Z = b[s]['X'], b[s]['Z']
    same = set(X['generators']) == plain == set(Z['generators'])
    print(f"{s} | {c['orbits']} ({len(plain)}, {nd}) | {X['orbits']}/{len(X['generators'])} | {Z['orbits']}/{len(Z['generators'])} | {'YES' if same else 'NO'}")
