# GH-173: HGP from degree-three Gallager LDPC factors

Date2026-10-29, [issue173](https://github.com/guluchen/DistQLDPC/issues/173).
Base main6083e662c621f3b66defd434cfae31a028d483c4;
branch codex/gallager-hgp-library. Local algebra PASS, Linux proof/smoke pending.

Three proposals: selected fixed first-seed Gallager(3,4) factors + HGP;
deferred higher-dimensional toric/homological CSS; deferred covering/discovery
BB provenance targets. Prior GH153/154/172 and coverage ledger reviewed.
Open issues and remote branches checked; issue claimed on hub15 before code.
This is input-library reconstruction, not solver/performance adoption.

Sources, complete sampler/product coordinates, rank/dimension/commutation
argument, provenance and distance semantics in GALLAGER_HGP.md. Gallager's
primary book pages7/13/14/15/17/18/19 were rendered and visually read because
the PDF text encoding is broken; only its SHA256 and URL/page metadata are
retained, not its copyrighted file or images. Theorem2.4 is a typical-ensemble
growth result, never a distance guarantee for each seed. HGP Theorems1/15
read from Tillich–Zémor0903.0566v2. No source programs, matrices, external
distance tools or author implementations read/copied/run.

Preregistered classical n8/12/20/28/36/44, seed0, one sample per size with no
screening/resampling. Raw column3/row4 weights, sparse ORIGINAL-row basis
selected in source order, actual ranks4/7/13/19/25/31; quantum(N,k) are
(80,16),(193,25),(569,49),(1145,81),(1921,121),(2897,169).
All raw/selected factor and quantum graphs connected. Quantum row weights5..7.
No assumption that cycle-code factors or fixed-base cyclic lifts supply the
same asymptotic regime. These are finite LDPC-ensemble representatives;
an explicit deterministic expander-factor family remains a separate gap.

Local validation:10 new tests plus34 existing tests; independent reverse-shuffle,
set elimination, physical-column product reconstruction, actual GF(2) ranks,
full logical quotient bases/pairing and tensor-swap duality; initial all-ones
product upper words; all30 untiered inputs/81 total inventory. All24 new files
reproduce byte for byte, prior24 rows/96 matrices unchanged. No same-(N,k)
peer across current/pending library branches. LegacyCOLOR unit's default-HGP
inventory assertion made manifest-based because HGP now contains18 inputs;
its explicit COLOR checks and the runner's HGP default remain unchanged.
Tiny classical<=8-bit/17-qubit quantum units only on Mac, no source-distance
or solver experiment there.

Linux plan: bounded one-core4GiB/60s CPU/90s wall independent classical
kernel enumeration over at most8192 words, then six explicit-subset default
MaxSAT and six CC60s serial runs with the same resource backstop/null stdin.
The raw source claim is <=classical n with an algebraic word, not an invented
published exact distance. Audit each engine against the independently derived
product distance, preserving missing fields and verifying actual supports.
Any disagreement is a scientific escalation. New results PLAUSIBLE until
an independent implementation/search and GF(2) word check complete. Retain
all raw identities/logs/weight enumerators; unresolved proofs become unexecuted
allocated-server packages. No broad sweeps or longer CI diagnostics.

Scientific semantics changed: no.
PI action required: main integration and any dedicated-server allocation.
No PR/main/gh-pages push, tier/name/default/solver/QDistSAT change.
