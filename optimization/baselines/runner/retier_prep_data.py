#!/usr/bin/env python3
"""Build the frozen input set for the 2026-11-04 re-tier panel.
Run from rt-20261104/ with src-main checked out at main 02879a93 and branches pr210..pr214.
data/<group>/<stem>_{Hx,Hz,Gx,Gz}.txt, groups t0..t5 (current tiers), untiered, pr210..pr214.
Writes codes.json with sha256 of every file and the claim used for consistency checks."""
import csv, hashlib, io, json, os, re, subprocess, sys

SRC = 'src-main'
out = []


def git(*a):
    return subprocess.run(['git', '-C', SRC] + list(a), check=True, capture_output=True).stdout


def claim_from_text(t):
    t = t.strip()
    m = re.match(r'exact (\d+)', t)
    if m: return dict(kind='exact', lo=int(m.group(1)), hi=int(m.group(1)), text=t)
    m = re.match(r'<= ?(\d+)', t)
    if m:
        lo = re.search(r'published lower (\d+)', t)
        return dict(kind='upper', lo=int(lo.group(1)) if lo else None, hi=int(m.group(1)), text=t)
    m = re.match(r'estimate (\d+)', t)
    if m:
        lo = re.search(r'published lower (\d+)', t)
        return dict(kind='estimate', lo=int(lo.group(1)) if lo else None, hi=None, est=int(m.group(1)), text=t)
    raise ValueError(t)


def stem_claim(stem):
    f = stem.split('_')[3]
    if f.isdigit(): return dict(kind='stem', lo=int(f), hi=int(f), text=stem)
    if f.startswith('ge'): return dict(kind='stem', lo=int(f[2:]), hi=None, text=stem)
    a, b = f.split('to'); return dict(kind='stem', lo=int(a), hi=int(b), text=stem)


def put(group, stem, ref, srcdir, claim):
    os.makedirs(f'data/{group}', exist_ok=True)
    sha = {}
    for k in ('Hx', 'Hz', 'Gx', 'Gz'):
        b = git('show', f'{ref}:{srcdir}/{stem}_{k}.txt')
        open(f'data/{group}/{stem}_{k}.txt', 'wb').write(b)
        sha[k] = hashlib.sha256(b).hexdigest()
    out.append(dict(stem=stem, group=group, path=f'data/{group}/{stem}', ref=ref, srcdir=srcdir, claim=claim, sha256=sha))


for t in range(6):
    names = git('ls-tree', '--name-only', '02879a93', f'data/matrices/tier{t}/').decode().split()
    for p in sorted(names):
        if p.endswith('_Hx.txt'):
            s = os.path.basename(p)[:-7]
            put(f't{t}', s, '02879a93', f'data/matrices/tier{t}', stem_claim(s))
seen = set()
for ref, group in [('02879a93', 'untiered'), ('pr210', 'pr210'), ('pr211', 'pr211'), ('pr212', 'pr212'),
                   ('pr213', 'pr213'), ('pr214', 'pr214')]:
    rows = list(csv.DictReader(io.StringIO(git('show', f'{ref}:data/matrices/untiered/MANIFEST.csv').decode())))
    for r in rows:
        if r['stem'] in seen: continue
        seen.add(r['stem'])
        put(group, r['stem'], ref, 'data/matrices/untiered', claim_from_text(r['claimed_d']))
json.dump(out, open('codes.json', 'w'), indent=1)
from collections import Counter
print(len(out), Counter(c['group'] for c in out))
