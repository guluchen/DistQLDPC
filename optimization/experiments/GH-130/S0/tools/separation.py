#!/usr/bin/env python3
"""GH-130: separation of candidate structural properties between halves where GH-129's frontier rule helped
(BB/GB/LP: every tier1-4 cell < 0.9; tier5 faster) and where it hurt (TN: every tier3-4 cell > 1, tier5 slower).
Labels are by family only for this evaluation; the selector itself uses the matrix property, never the name.
usage: separation.py half_structure.json"""
import json, sys
H = json.load(open(sys.argv[1]))
props = [('rw_mean', 'mean row weight'), ('rw_max', 'max row weight'), ('deg_mean', 'mean qubit degree'),
         ('deg_min', 'min qubit degree'), ('deg_max', 'max qubit degree'), ('nb_mean', 'mean row neighbours'),
         ('ov_mean', 'mean overlap of adjacent rows'), ('frac_ov2', 'share of adjacent row pairs with overlap >= 2'),
         ('cyc4_per_row', 'Tanner 4-cycles per row'), ('cand_mean', 'odd-row repair candidates per qubit (sum_r (w_r - 1))'),
         ('red', 'row redundancy (m - rank) / m')]
print('| property | scope | help (BB/GB/LP) range | hurt (TN) range | separates? | margin (hurt min / help max) |')
print('|---|---|---|---|---|---:|')
for k, name in props:
    for scope, tiers in (('tier1-5', ('tier1', 'tier2', 'tier3', 'tier4', 'tier5')), ('tier0-5', None)):
        sel = [h for h in H if tiers is None or h['tier'] in tiers]
        a = [h[k] for h in sel if not h['stem'].startswith('TN')]; b = [h[k] for h in sel if h['stem'].startswith('TN')]
        sep = 'yes' if min(b) > max(a) else ('yes (reversed)' if max(b) < min(a) else 'no')
        m = (min(b) / max(a) if max(a) else float('inf')) if sep == 'yes' else ''
        ms = ('inf (help max 0)' if m == float('inf') else f'{m:.2f}') if m != '' else '-'
        print(f'| {name} | {scope} | {min(a)}-{max(a)} | {min(b)}-{max(b)} | {sep} | {ms} |')
