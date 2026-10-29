# GH-172: static triangular4.8.8 color-code library

Date2026-10-29; [issue172](https://github.com/guluchen/DistQLDPC/issues/172).
Base main6083e662c621f3b66defd434cfae31a028d483c4.
Branch codex/color488-library. Current gate: local algebra PASS, Linux pending.

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
