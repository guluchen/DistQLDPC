# GH-172: static triangular4.8.8 color-code library

Date2026-10-29; [issue172](https://github.com/guluchen/DistQLDPC/issues/172).
Base main6083e662c621f3b66defd434cfae31a028d483c4.
Branch codex/color488-library. Current gate: local and Linux validation executed; numeric gates n1567/2887
INCOMPLETE. Seven unresolved engine proofs packaged, unexecuted.

Selected proposal: missing4.8.8 color-code specialization from original
mathematical face geometry. Deferred: growing-distance LDPC-factor HGP and
higher-dimensional homological CSS, both still coverage gaps. Prior GH156,
GH168 and GH171 plus the coverage ledger informed selection. No competing
issue/branch found; issue172 linked and claimed on hub15. This is library
reconstruction, not a solver-performance optimization or adoption experiment.

Source: Noah Shutty arXiv2609.21376v3 AppendixD; latest geometry agrees with
v1 notes. Complete independent coordinate specification, provenance boundary
and CSS/dimension/upper-witness argument are in COLOR488.md. Original scripts
and matrices GPL3+; no paper/source/program/circuit/matrix files copied or
license imputed. No external distance tool run. Static data-only matrices
do not encode the paper's measurement circuits or circuit-distance claims.

Six cases n31,71,199,647,1567,2887,k1; published static d7,11,19,35,55,75.
m1 is equivalent to the existing Steane code by an explicitly tested physical
column permutation, so it is omitted from the library. All new stems unknown.
Hx=Hz face incidence, full logicals from unchanged existing bitset builder.

Local checks:10 new units, independent reflected-wedge physical columns,
face-overlap CSS, actual ranks/full quotient bases/pairing, connected graph,
three-colorability and degrees, X/Z boundary/all-data words. Rank pairs are
15/15,35/35,99/99,323/323,783/783,1443/1443. The right boundary supplies
verified upper words7/11/19/35/55/75, never lower proofs. All30 untiered inputs
(81 including tiers) pass inventory checks. All24 files regenerate identically;
prior24 parsed manifest rows/96 matrices unchanged. No same-(n,k) peer across
current/pending libraries. Tiny tests only on Mac, no solver experiments.

Linux plan: unchanged build, prior34+new10 units, six explicit-subset default
MaxSAT and six CC runs, serial60s per cell, pinned one allocated runner CPU,
4GiB address-space cap,90s wall backstop, null stdin. Preserve every raw log,
source/binary/input hash, numeric missing field and exit status. Independent
construction witnesses may prove upper bounds, never fill missing CLI values.
Stronger one-engine lower/exact results remain PLAUSIBLE; missing numeric
gates or unfinished proofs become unexecuted dedicated-server job packages.

No source/solver/default/Makefile/tiered/QDistSAT changes. No performance tier
or seed-median claim. No PR/main/gh-pages push or server process launched.
The broader goal stays active; pending PI integration/other families remain.

Scientific semantics changed: no.
PI action required: yes for main integration and any dedicated-server allocation.

The pre-existing6.6.6 family-selection unit initially assumed COLOR always
contained exactly6 inputs. The new same-family specialization correctly makes
that12. Updated that test to compare family selection with the manifest and
also assert that an explicit legacy6.6.6 subset is unchanged. Initial failure
and corrected prior34-test pass retained. This changes only a stale test
inventory assumption, not the runner or scientific results.

## Linux evidence and results

Validated source1e6e5d088cbbadff945cc5e9013c9a336192ea85;
data commit971e8f953b637d0f5e5df43a1c20ab2045fd97da;
source treecc818c7020393e2fb3226bb24b28f3fc4db23d2c.
[Library run40864285459](https://github.com/guluchen/DistQLDPC/actions/runs/40864285459),
job123414982874 SUCCESS; ordinaryCI40864285394, job123414982500 SUCCESS.
All44 tests, full30/81 inventory, independent construction and24 fresh-file
comparisons passed. All12 selected60s serial CLI runs load and return
consistent results; source claims and independent mathematical upper words
are never substituted into missing engine fields. A successful workflow
execution does not turn incomplete numeric gates into passes.

| n | Published static d | MaxSAT lb/ub | CC lb/ub | Numeric gate |
|---:|---:|---|---|---|
| 31 | 7 | 7/7 SOLVED | 7/7 SOLVED | PASS |
| 71 | 11 | 11/11 SOLVED | 11/11 SOLVED | PASS |
| 199 | 19 | 9/19 | 19/19 SOLVED | PASS |
| 647 | 35 | 9/35 | 19/35 | PASS |
| 1567 | 55 | missing/missing | 18/55 | INCOMPLETE |
| 2887 | 75 | missing/missing | 15/75 | INCOMPLETE |

The n31/71 exact claims are independently cross-checked by MaxSAT and CC,
with actual verified words. For n199, CC exact19 is PLAUSIBLE pending the
other internal proof. CC-only stronger lower bounds19/19/18/15 at
n199/647/1567/2887 remain PLAUSIBLE. Common two-engine numeric lower bounds
are7/11/9/9/missing/missing, recorded separately in raw/bounds-review.json.
All source-distance upper bounds7/11/19/35/55/75 have explicitly reconstructed
X/Z boundary witnesses, independently checked against actual matrices.
MaxSAT additionally prints verified words7/11/19/35 for the first four cases.
CC does not print actual supports here; its numeric upper values are retained
without inventing a CLI witness. Construction supports are labeled separately.
No source-distance contradiction was observed.

Binary SHA25668f4157e2fb10371d6d35321cb53bd86151fac185172d98936d093a41203aa3a.
Full1111760-character job log, all per-engine argv/environment/source/binary/
input identities, raw logs, return codes, CSV results, DONE receipts and
audit.json are versioned in raw/actions/default/. Replay of the audit from
retained inputs is byte-identical. Every actual printed word and independent
boundary word is checked in GF(2). All prior24 manifest rows/96 matrices are
unchanged. Subsequent updates only retain results, reports and the separate
server package; validated generator/solver/input files are unchanged.

## Unexecuted completion package

runner/jobs.jsonl has7 only-unresolved default-seed jobs: MaxSAT n199;
both engines n647,1567,2887. Each has6h CPU,600s additional wall backstop,
4GiB and one explicitly allocated pinned yfclab2 core, serial null-stdin
execution. Total configured limits42h CPU/43h10m wall, not a runtime forecast.
No server core is assigned or process launched. Runner defaults to dry-run,
checks frozen case/job arguments and clean checkout, confirms hostname and
requires an allocation reference/free-core confirmation before execution.
The dry-run JSON is retained in raw/server-dryrun.json. No longer or repeated
CI diagnostics are substituted for the missing proofs.

Reproduction/algebra/replay commands are in COLOR488.md and runner/README.md.
Coverage remains incomplete for the two numeric gates and four stronger
lower/exact results; keep unknown stems and no QDistSAT mirror or tier moves.
Main integration and any dedicated-server run require PI decisions. Other
independent library construction can continue while these decisions wait.
