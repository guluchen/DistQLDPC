# GH-95 Tier0 result — engine refactor stage 1 (search-identical)

**Verdict: PASS.** Every Tier0 item below passed; no trace, result or statistic differs from
7eadd54. Tier1 timing is left to the coordinator.

- Baseline: main `7eadd54`, frozen Mac binary `frozen-main7e/distqldpc`
  (sha256 `6bdcaa2523cdcbeae5164cedbf54c9ac0f9e64f9a91c3da7ef4b804df393db9d`). A local rebuild of
  7eadd54 (`scratchpad/gh95/base`) has a byte-identical `__text`, and it supplied the baseline
  `maxcdcl`.
- Candidate code: branch `refactor/gh-95-engine-modules`, code-final commit `f95675e`. The commits
  after it add only files under `optimization/experiments/GH-95/`. Cross-repo tree `bbd2851`.
- Frozen candidate: `frozen95/cand/distqldpc`
  sha256 `de88d7ffd7bba6900eecd2e75861c3c0aedd92532024317c08db8e397543f9a9`
  (`frozen95/cand/maxcdcl` sha256 `ea06b46bcdbac38cb0c23432ea2097834726e58798cc0fc033d8bf7edc4ad484`),
  both chmod a-w, built with `make CXX="c++ -Wno-reserved-user-defined-literal"` (Apple clang 21.0.0,
  flags unchanged: `-Isrc/solver -Wall -Wno-parentheses -O3 -g -D __STDC_LIMIT_MACROS -D __STDC_FORMAT_MACROS -DNDEBUG`).
- Host: Mac (Apple M-series, 12 CPUs). Solver batches ran at most 4 jobs in parallel, under the
  Mac timing lock (`GH-95 trace batch Sat Oct 10 10:52:24 CST 2026`, held 10:54:45 to 11:32:02).

## What changed

`src/solver/Solver.cc` (7228 lines) became `src/engine/` (see PROPOSAL.md for the module map):
`Engine.cc` (unity TU: upstream header, MaxCDCL lineage, former prologue, include list),
`EngineInternal.h`, and 15 modules: State, Inprocessing, ClauseDB, Propagation, Heuristics,
Analysis, SoftConflict, ClauseReduction, Hardening, Lookahead, Search, Objective,
Preprocessing, Cardinality, Export. The Makefile compiles `src/engine/Engine.cc` into the
object `build/Solver.o`.

Deviation from PROPOSAL.md: the object keeps the name `build/Solver.o`; it was not renamed
to `Engine.o`. Renaming it would also need an edit to `.github/workflows/ci.yml`, and the
available GitHub token has no `workflow` scope, so that push was refused. The object's link
position and its flags are the same as before.

Verbatim-move proof: `python3 -B optimization/experiments/GH-95/gen_modules.py --check .` takes
`git show 7eadd54:src/solver/Solver.cc`, rebuilds the final layout with the generator that made
the commits, and byte-compares it with `src/engine/`:

```
GH95_MODULE_CHECK files=17 mismatched=none
```

The generator asserts that each line of the original from line 117 on (everything after the
prologue) lands in exactly one engine file, or is one of the five listed blank separator
lines. Lines 1-116 (header, lineage, prologue) are copied verbatim into `Engine.cc`, and the
header is also copied into every module.

## Codegen (`__text`)

| binary | 7eadd54 `__text` | candidate `__text` | delta | per-function code (`scripts/fncmp.py`) |
|---|---:|---:|---:|---|
| `bin/distqldpc` | 224336 | 224336 | **0 bytes** | 272/272 functions identical; 96 at a different rank |
| `bin/maxcdcl`   | 182984 | 182984 | **0 bytes** | 225/225 functions identical; 96 at a different rank |

The full `size -m` output (all segments and sections) is the same for both binaries. The
`__text` bytes are not the same (sha prefix `b517fb7e…` vs `92e0d717…`), because grouping the
code into modules changes where some engine functions sit. `fncmp.py` compares each function's
disassembly with absolute addresses removed: branch and call targets are compared as
symbol+offset, and ADRP pages and the page offsets that use them are masked. The static
initializer `__GLOBAL__sub_I_Solver.cc` is renamed `__GLOBAL__sub_I_Engine.cc`; its code is
identical. At the scaffold commit the whole `__text` is byte-identical to 7eadd54. After that,
every commit keeps the `__text` size at 224336 and every function identical
(`raw/fncmp_commits.txt`). The final function order follows the unity include order, and
inside each module the original order is kept.

## Tier0 checks

### Smoke and GH58 regressions (candidate = `cand95/bin/distqldpc`, same sha as frozen)

```
$ bash scripts/smoke_test.sh
DistQLDPC smoke validation passed            (exit=0)
$ python3 -B scripts/test_partition_soft_literals.py
Partition adjacent oracles passed: 11 total inputs, 1024 assignments each.   (exit=0)
$ c++ -Wno-reserved-user-defined-literal -Isrc/solver -Wall -Wno-parentheses -O3 -g -D__STDC_LIMIT_MACROS -D__STDC_FORMAT_MACROS -DNDEBUG tests/test_partition_soft_literals.cc build/SimpSolver.o build/Solver.o build/Options.o build/System.o -lz -o build/test_partition_soft_literals
$ build/test_partition_soft_literals
GH58_PARTITION_ORACLE_PASS cases=80 no_conflict=1   (exit=0)
```

Hosted CI (`ubuntu-latest`, GCC, `make --jobs`) on the branch push `f95675e`: run 38016275935
**success**. It compiled `g++ ... -c -o build/Solver.o src/engine/Engine.cc`, passed smoke and
both partition validations, and printed `GH58_PARTITION_ORACLE_PASS cases=80 no_conflict=1`.

### `-v` traces: 50 codes x {default, -no-card, -card-sinz, -card-mto} + `-joint -no-card`

Command per run (from a 7eadd54 checkout, so both binaries read the same `data/matrices`):
`<bin> -v [mode flags] -cpu-lim=20 <code>`. Mode flags: `default` none; `nocard` `-no-card`;
`sinz` `-card-sinz`; `mto` `-card-mto`; `joint` `-joint -no-card`. stdout and stderr go to the
same file, and the exit status is recorded (`scripts/run_one.sh`, `scripts/batch.sh`,
`scripts/full.list`). There were 250 runs per binary.

Comparison rule (`cmp_traces.py`, fixed in PROPOSAL.md before any run): only
`detect_cpu=<x>s` is normalised. A run that 7eadd54 completed must be byte-identical, with an
equal exit status. For a run that 7eadd54 timed out, its child-search output minus the last
(possibly truncated) line must be a prefix of the candidate's child output, and the parent
summary header must match.

```
$ python3 -B optimization/experiments/GH-95/cmp_traces.py base cand full.list cand_rerun30
GH95_TRACE_SUMMARY runs=250 identical=77 prefix_ok=173 fail=0
```

| mode | identical (completed) | prefix_ok (timed out) | fail |
|---|---:|---:|---:|
| default | 16 | 34 | 0 |
| -no-card | 16 | 34 | 0 |
| -card-sinz | 17 | 33 | 0 |
| -card-mto | 16 | 34 | 0 |
| -joint -no-card | 12 | 38 | 0 |

For the 173 timed-out runs, the candidate trace contains the baseline's full flushed child
trace every time: 42 to 411 child lines, median 257. No candidate run stopped short of the
baseline under the same limit, so the planned `-cpu-lim=30` rerun was never needed (rerun list
empty). Per-run verdicts are in `raw/cmp_final.txt`; all 500 traces are in
`raw/traces.tar.gz`.

### Per-commit quick trace check

For each of the 18 commits from the scaffold to `f95675e`: build, then compare `scripts/quick.list`
(LP_34_20_2, LP_136_32_4, BB_72_12_6, TN_36_8_4, GB_144_12_8, PK_31 in default and
`-no-card`, plus LP_136_32_4 `-joint -no-card`; `-cpu-lim=20`) against the 7eadd54 traces:

```
18 of 18 commits: GH95_TRACE_SUMMARY runs=13 identical=11 prefix_ok=2 fail=0
```

The two prefix_ok runs are PK_31, which times out in both binaries. Details are in
`raw/quick_commits.txt`. Every commit built on macOS. Hosted CI built the final code with
GCC twice: the branch push `f95675e` and the cross-repo commit.

### maxcdcl oracle (`scripts/maxcdcl_cmp.sh`, `-cpu-lim=60`, all runs completed)

Outputs are compared in full; only rates (`N /sec`) and the numbers on time and memory lines
are normalised.

```
clq-n100e2500g1              IDENTICAL base[optimal: 91 ] cand[optimal: 91 ] exit=20
clq-n150e10058g1             IDENTICAL base[optimal: 115 ] cand[optimal: 115 ] exit=20
partition-retired-soft.wcnf  IDENTICAL base[optimal: 5 ] cand[optimal: 5 ] exit=20
BB_72_12_6.wcnf              IDENTICAL base[optimal: 6 ] cand[optimal: 6 ] exit=20
LP_136_32_4.wcnf             IDENTICAL base[optimal: 4 ] cand[optimal: 4 ] exit=20
TN_36_8_4.wcnf               IDENTICAL base[optimal: 4 ] cand[optimal: 4 ] exit=20
```

The three dumps came from `distqldpc -dump-wcnf=PATH -dump-only <code>`. The dumps written by
the two binaries are byte-identical (`raw/dumps_cmp.txt`), which also exercises `Export.cc`.

### Cross-repo QDistSAT benchmark

Branch `ci/xrepo-gh95` has one commit `bd966f7`, built with `git commit-tree` from tree
`bbd2851` with parent `7eadd54`.
`gh workflow run "QDistSAT cross-repo benchmark" --ref ci/xrepo-gh95` gave run 38016286108:
**success, "Scientific results match: YES"** (`raw/xrepo_summary.md`, `raw/xrepo_result.json`):

| Stem | Config | Baseline | Candidate | Semantic match |
|---|---|---|---|---|
| LP_136_32_4 | no-card | d=4 | d=4 | YES |
| LP_136_32_4 | card-mto | d=4 | d=4 | YES |
| BB_108_8_10 | no-card | d=10 | d=10 | YES |
| BB_108_8_10 | card-mto | d=10 | d=10 | YES |

## Left for later stages (deliberately not refactored)

- Giant functions are not split (`solve_` ~430 lines, `search` ~360, `lookahead` ~260,
  `analyzeSoftConflict` ~230, `partition` ~220). Extracting helpers changes inlining and
  codegen.
- The `Solver` class declaration stays in one block with its member order unchanged, because
  object layout drives codegen. Only a module-map comment was added. The `Minisat::Solver` API
  is not renamed.
- No hook or virtual interfaces for future propagators or lower-bound components; they would
  add code to the hot path. The module boundaries (Propagation, Analysis, Lookahead,
  Objective, Preprocessing) mark where those changes will go.
- Dead and commented-out upstream code is kept (`collectFirstUIP`, `identifyClausesToSplit`,
  `avgAct`, `litsEnqueue`, `simplifyLearnt_local`, `unitSoftLits_lt`, commented blocks). Removing
  it would change `__text`.
- `SimpSolver.cc`, `Options.cc` and `System.cc` remain separate translation units. Adding them
  to the unity TU would allow cross-TU inlining that the original build does not have.
