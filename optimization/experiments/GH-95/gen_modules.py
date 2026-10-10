#!/usr/bin/env python3
"""GH-95 stage-1 generator (the tool that produced the src/engine/ commits): split MaxCDCL Solver.cc (7eadd54) into src/engine/ modules.

usage: gen_modules.py ORIG_SOLVER_CC REPO_ROOT K
  K = number of modules extracted so far (in EXTRACTION order); K=0 is the scaffold, K=15 final.
Writes REPO_ROOT/src/engine/{Engine.cc,EngineInternal.h,<modules>.cc}. Code lines are copied
verbatim (CRLF preserved); only whole top-level definitions are moved.

usage: gen_modules.py --check [REPO_ROOT]
  Regenerates the final layout (K=15) from `git show 7eadd54:src/solver/Solver.cc` into a
  temporary directory and byte-compares it with REPO_ROOT/src/engine/ (exit 1 on mismatch).
  Together with the line-coverage assertion below this proves that every line of the
  original Solver.cc (from line 117 on) is in exactly one engine file, unchanged."""
import sys, os, subprocess, tempfile, filecmp

if len(sys.argv) >= 2 and sys.argv[1] == '--check':
    repo = os.path.abspath(sys.argv[2] if len(sys.argv) > 2 else '.')
    with tempfile.TemporaryDirectory() as t:
        o = os.path.join(t, 'Solver.cc')
        open(o, 'wb').write(subprocess.run(['git', '-C', repo, 'show', '7eadd54:src/solver/Solver.cc'],
                                           capture_output=True, check=True).stdout)
        subprocess.run([sys.executable, os.path.abspath(__file__), o, t, '15'], check=True)
        a, b = os.path.join(t, 'src', 'engine'), os.path.join(repo, 'src', 'engine')
        fa, fb = sorted(os.listdir(a)), sorted(os.listdir(b))
        bad = [f for f in fa if f not in fb or not filecmp.cmp(os.path.join(a, f), os.path.join(b, f), shallow=False)]
        bad += [f for f in fb if f not in fa]
        print('GH95_MODULE_CHECK files=%d mismatched=%s' % (len(fa), bad or 'none'))
        sys.exit(1 if bad else 0)

orig, root, K = sys.argv[1], sys.argv[2], int(sys.argv[3])
raw = open(orig, encoding='utf-8', newline='').read()
assert raw.endswith('\r\n') and '\n' not in raw.replace('\r\n', '')
L = raw[:-2].split('\r\n')          # L[0] is line 1
N = len(L)                          # 7228
def lines(a, b): return L[a-1:b]

HEADER = lines(1, 34)
LINEAGE = lines(35, 84)
PROLOGUE = lines(85, 116)
INTERNAL = [(805, 820), (1079, 1079), (2539, 2556), (3152, 3153)]
DROP = {117, 804, 1078, 3151, 7228}  # blank separator lines

# Unity order (= order of first appearance in the original Solver.cc).
MODULES = [
 ('State', 'Option table, Solver constructor and destructor.',
  [(118, 255)]),
 ('Inprocessing', 'Inprocessing: learnt-clause vivification (Maple_LCM / Maple_CM simplifyLearnt*,\n * simplePropagate, simpleAnalyze*), failed-literal detection, original-clause minimisation.',
  [(256, 803), (821, 1077), (1080, 1260), (2557, 2656)]),
 ('ClauseDB', 'Clause database: variable creation, clause addition, watcher attach/detach/removal,\n * satisfied test, clause relocation and garbage collection.',
  [(1261, 1495), (7089, 7227)]),
 ('Propagation', 'Trail and unit propagation: backtracking (cancelUntil, cancelUntilBeginning),\n * uncheckedEnqueue, propagate, and lPropagate (propagation followed by hardening).',
  [(1496, 1534), (1889, 2080), (3017, 3030), (5147, 5184)]),
 ('Heuristics', 'Decision heuristics and restart support: pickBranchLit, rebuildOrderHeap,\n * progressEstimate, the Luby sequence, clause-activity average.',
  [(1535, 1580), (2841, 2858), (3484, 3496), (3857, 3899)]),
 ('Analysis', 'Hard-conflict analysis: first-UIP learning, minimisation (litRedundant, binResMinimize),\n * analyzeFinal, on-the-fly clause reduction, all-UIP and first-UIP collection helpers.',
  [(1581, 1888), (2081, 2187), (2894, 3016)]),
 ('SoftConflict', 'MaxSAT soft-conflict analysis: soft conflicts and quasi soft conflicts\n * (analyzeSoftConflict, simplifyConflictClause, analyzeQuasiSoftConflict, simplifyQuasiConflictClause).',
  [(2188, 2530), (4428, 4691)]),
 ('ClauseReduction', 'Learnt-clause database reduction (reduceDB, reduceDB_Tier2, reduceDB_core), removal of\n * satisfied clauses, top-level simplify, clause splitting, removeLearntClauses.',
  [(2531, 2538), (2657, 2840), (2859, 2893), (3031, 3150), (3154, 3212), (5109, 5146)]),
 ('Hardening', 'Hardening (bound-driven fixing of soft literals): harden, reduceHardens, moreHarden,\n * hardenForRestart, hardenFromQuasiSoftConflict.',
  [(3213, 3258), (4342, 4427), (4692, 4766), (5876, 5987)]),
 ('Lookahead', 'Lower-bound lookahead: LK propagation, lookback, inconsistent-set bookkeeping, auxiliary\n * variable heap and selection, lookahead, lookaheadForRestart, fixByLookahead.',
  [(3259, 3483), (3900, 4341), (4767, 5056), (5105, 5108)]),
 ('Search', 'Search driver: search (CDCL + branch-and-bound loop) and solve_ (UB/LB iteration,\n * restarts, DistQLDPC multi-instance controls).',
  [(3497, 3856), (6452, 6888)]),
 ('Objective', 'Objective and bound management (DistQLDPC hooks): bounds pipe (TRY/LB/UB), cost\n * bound accessors, incumbent tracking and printing, checkSolution.',
  [(5185, 5275)]),
 ('Preprocessing', 'Soft-literal preprocessing: conflicting soft literals, partition into disjoint\n * inconsistent sets, initial conflict detection (with its simple LK helpers), hard clauses for soft clauses.',
  [(5057, 5104), (5276, 5875)]),
 ('Cardinality', 'Dynamic auxiliary variables and cardinality encodings (Sinz sequential counter, MTO).',
  [(5988, 6451)]),
 ('Export', 'Instance export: toDimacs, toWcnf, toOpb.',
  [(6889, 7088)]),
]
SHORT = {'State': 'options, constructor/destructor', 'Inprocessing': 'vivification, failed literals, clause minimisation',
 'ClauseDB': 'variables, clauses, watchers, garbage collection', 'Propagation': 'trail, backtracking, unit propagation',
 'Heuristics': 'branching, order heaps, Luby restarts', 'Analysis': 'hard-conflict analysis and learning',
 'SoftConflict': 'soft / quasi-soft conflict analysis', 'ClauseReduction': 'learnt-clause DB reduction, simplify, splitting',
 'Hardening': 'bound-driven hardening', 'Lookahead': 'lower-bound lookahead', 'Search': 'search() and solve_()',
 'Objective': 'bounds pipe, incumbent, solution check', 'Preprocessing': 'soft-literal partition, initial conflicts',
 'Cardinality': 'auxiliary variables, Sinz/MTO encodings', 'Export': 'DIMACS / WCNF / OPB writers'}
EXTRACTION = ['Export', 'Objective', 'Cardinality', 'Preprocessing', 'Hardening', 'Lookahead',
              'SoftConflict', 'Analysis', 'Heuristics', 'Search', 'Propagation',
              'ClauseReduction', 'ClauseDB', 'Inprocessing', 'State']
assert sorted(EXTRACTION) == sorted(m[0] for m in MODULES)

# coverage check: every line 117..N exactly once
owner = {}
def claim(a, b, who):
    for i in range(a, b+1):
        assert i not in owner, (i, owner.get(i), who)
        owner[i] = who
for name, _, rs in MODULES:
    for a, b in rs: claim(a, b, name)
for a, b in INTERNAL: claim(a, b, 'Internal')
for i in DROP:
    assert L[i-1].strip() == '', i
    claim(i, i, 'drop')
assert sorted(owner) == list(range(117, N+1)), set(range(117, N+1)) - set(owner)

def notice(what, body):
    return ['/*',
            ' * DistQLDPC engine -- ' + what,
            ' *',
            ' * ' + body,
            ' *',
            ' * Restructured from MaxCDCL src/solver/Solver.cc by DistQLDPC (GH-95, stage 1): code moved',
            ' * verbatim, search unchanged. The copyright and MIT permission notice above apply to the',
            ' * MaxCDCL / Maple_CM / Maple_LCM / MiniSat code contained in this file (see src/solver/LICENSE).',
            ' *',
            ' * Modifications Copyright (C) 2025-2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>, part of DistQLDPC',
            ' * (GPL-3.0-or-later when distributed as this project; see LICENSE, NOTICE, MODIFICATIONS.md).',
            ' */']
GUARD = lambda f: ['#ifndef DISTQLDPC_ENGINE_UNITY',
                   '#error "src/engine/%s is part of the engine unity build; compile src/engine/Engine.cc"' % f,
                   '#endif']

edir = os.path.join(root, 'src', 'engine')
os.makedirs(edir, exist_ok=True)
def write(fname, out):
    with open(os.path.join(edir, fname), 'w', encoding='utf-8', newline='') as f:
        f.write('\r\n'.join(out) + '\r\n')

extracted = set(EXTRACTION[:K])
mods = {m[0]: m for m in MODULES}

# EngineInternal.h
out = HEADER + [''] + notice('EngineInternal.h: file-scope helpers shared by several engine modules.',
    'Clause-ordering comparators and tuning macros that were file-scope in Solver.cc and are used\n * by more than one module. Included once by Engine.cc, before the modules.') + [
    '', '#ifndef DISTQLDPC_ENGINE_INTERNAL_H', '#define DISTQLDPC_ENGINE_INTERNAL_H', ''] + GUARD('EngineInternal.h') + ['']
for a, b in INTERNAL:
    out += lines(a, b) + ['']
out += ['#endif']
write('EngineInternal.h', out)

# modules
for name, desc, rs in MODULES:
    path = os.path.join(edir, name + '.cc')
    if name not in extracted:
        if os.path.exists(path): os.remove(path)
        continue
    out = HEADER + [''] + notice('module %s.cc' % name, desc) + [''] + GUARD(name + '.cc')
    for a, b in rs:
        out += lines(a, b)
    write(name + '.cc', out)

# Engine.cc
eng_notice = notice('Engine.cc: unity translation unit of the DistQLDPC MaxSAT engine.',
    'Holds the former Solver.cc prologue and #includes the engine modules in a fixed order, so the\n'
    ' * engine is still compiled as ONE translation unit (inlining and layout as in the original file).\n'
    ' * The modules are never compiled on their own. The MaxCDCL version lineage below is kept verbatim.')
out = HEADER + [''] + eng_notice + ['', '#define DISTQLDPC_ENGINE_UNITY', ''] + LINEAGE + PROLOGUE
out += ['', '#include "EngineInternal.h"']
inc = [m for m in MODULES if m[0] in extracted]
if inc:
    out += ['', '//=================================================================================================',
            '// Engine modules (unity order = order of first appearance in the original MaxCDCL Solver.cc):', '']
    w = max(len(m[0]) for m in inc) + 4
    for name, desc, _ in inc:
        short = SHORT[name]
        out += [('#include "%s.cc"' % name).ljust(w + 12) + '// ' + short]
rest = [i for i in range(117, N+1) if owner[i] not in extracted and owner[i] not in ('Internal',)]
if any(owner[i] != 'drop' for i in rest):
    out += [L[i-1] for i in rest]
    # keep exactly the original remaining text (drop lines included, so K=0 is ~identical to Solver.cc)
write('Engine.cc', out)
print('K=%d extracted=%s' % (K, EXTRACTION[:K]))
