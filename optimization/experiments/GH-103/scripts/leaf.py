#!/usr/bin/env python3
"""Leaf (self) sample attribution from a macOS `sample` call graph.
usage: leaf.py SAMPLE.txt [funcsubstr ...]  -> per-function self samples, and per file:line for given funcs."""
import sys, re, collections
lines = open(sys.argv[1], errors='replace').read().split('\n')
pat = re.compile(r'^([ +!:|]*)(\d+) (.*)$')
ents = []
started = False
for l in lines:
    if l.startswith('Call graph:'): started = True; continue
    if not started: continue
    if l.startswith('Total number in stack') or l.startswith('Sort by top'): break
    m = pat.match(l)
    if not m: continue
    ents.append((len(m.group(1)), int(m.group(2)), m.group(3)))
selff = collections.Counter(); byline = collections.defaultdict(collections.Counter)
for k, (d, c, s) in enumerate(ents):
    # self = count minus sum of direct children counts
    ch = 0
    for d2, c2, s2 in ents[k+1:]:
        if d2 <= d: break
        if d2 == min(e[0] for e in ents[k+1:k+2]) : pass
    # direct children: entries with depth == next depth until depth<=d
    j = k+1; cd = None
    while j < len(ents) and ents[j][0] > d:
        if cd is None: cd = ents[j][0]
        if ents[j][0] == cd: ch += ents[j][1]
        j += 1
    sc = c - ch
    if sc <= 0: continue
    fn = re.sub(r'\s+\(in [^)]*\).*$', '', s)
    fn = re.sub(r'^\?\?\?.*', '???', fn)
    selff[fn] += sc
    fl = re.search(r'([A-Za-z_]+\.(?:cc|h)):(\d+)', s)
    byline[fn][fl.group(0) if fl else '?'] += sc
tot = sum(selff.values())
print('TOTAL', tot)
for fn, c in selff.most_common(25):
    print('%7d %5.1f%%  %s' % (c, 100.0*c/tot, fn[:110]))
for sub in sys.argv[2:]:
    for fn in selff:
        if sub in fn:
            print('==', fn[:100], selff[fn])
            for fl, c in byline[fn].most_common(30): print('   %6d %s' % (c, fl))
