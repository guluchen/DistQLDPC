# GH-167: pair-partition CPM matrix library

Issue: https://github.com/guluchen/DistQLDPC/issues/167
Branch: codex/pair-partition-library
Base main: 6083e662c621f3b66defd434cfae31a028d483c4.
Status: six original reconstructions locally validated; Linux evidence pending.

## Proposal and source scope

Three proposals: (1) SELECTED: explicit pair-partition CPM codes from
Okada-Kasai arXiv:2607.14091v4 Sec II/VI and authoritative catalogue,
(2) noncyclic group-valued PP, (3) new finite-group Quantum Tanner cases.
Selected CPM instances add non-product construction coverage, a small anchor
and high-girth size ladder. Prior GH-153/154/156/159/160/164/165/166 records
informed source identity, independent checks, short limits and retention.
No solver/default changes or performance adoption; progressive timing gates
and QDistSAT solver PR benchmark are not invoked for a data-only work branch.

Six source exact claims: [[104,30,8]], [[276,98,14]], [[472,122,16]],
[[584,150,18]], [[1112,282,20]], [[1784,450,24]]. First is contributor-reported,
second is a pinned reconstructed-instance claim, last four carry independent
author catalogue certificates. Preserve that distinction; none is our own
distance proof until internally verified. The selected n=472 is girth8,d16,
not the separate girth6,d14 code with the same dimensions. Prefix PP proposed;
unknown stems remain. No duplicate variant is added to inflate coverage.

## Provenance and clean-room boundary

Original code from published mathematics; no third-party constructor,
verifier implementation or external distance solver read/copied/run.
For five website records, original binary reconstruction uses mathematical
exponent facts under the paper's published construction (handoff7.2). Original
website matrix/parameter files are not redistributed; no software-repo license
is imputed to the separately maintained website. Paper CC BY4.0 author/title/
source/license attribution retained. n=276 uses MIT-associated parameter data
from commit 9c2a6f212025d2dc5decbf264ce2a24ba6924101, Git blob
da6c20989f7757a3c81801bacaee7fe3ccd60527; full MIT notice in NOTICE.

Exact raw parameter SHA256 identities for all five website sources matched
the published manifest; the n=276 original JSON blob matched its pinned Git
identity. Independent checker binds case facts to offline projection digests
and, for website cases, canonical in-memory text matching source SHA256.
See raw/source-identities.json. No download of lower-bound proof programs or
promotion of source certificate output to our own verification.

## Correctness and local evidence

CPM row a meets column a-s. Pair equal D[j,l]-E[i,l] differences modulo P;
all relative circulants cancel in GF(2), proving Hx Hz^T=0. The reconstructed
matching is a certificate for these exponents, not the author's original
search seed. Ranks and k measured independently from binary matrices.
Full CSS logical spaces via existing compute_logicals.py --method bitset.
Written construction/cancellation/girth-orbit proof in PAIR_PARTITION.md.

Independent column-lift reconstruction imports neither generator nor logical
builder. Checks source identities, perfect matching/equations, incidence,
regularity, full GF(2)/logical quotient/pairing and direct Tanner girth.
Cyclic lift translation preserves all edges, so BFS from J check representatives
finds girth; each cycle support is checked. Disconnected graphs rejected.
No same-(n,k) peers in current tiers/untiered or pending GH-160/164/165/166
branches; committed source identities in raw/pending-branch-peers.json.

Mac (no solver execution):
- `python3 scripts/codegen/pair_partition.py --all --out /tmp/gh167-first --certificates /tmp/gh167-pairings.json`
- `python3 scripts/codegen/pair_partition.py --all --certificates optimization/experiments/GH-167/raw/pairings.json`
- `python3 scripts/codegen/validate_pair_partition.py --output optimization/experiments/GH-167/raw/construction.json`
- `python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json`
- test_codegen_pair_partition (12), twisted_torus (9), color666 (10), hgp (8),
  cycle (7): 46 tests pass; raw logs retained.
- All 24 matrix files and pairing certificates byte-identical; 30 untiered,
  81 total current-branch inventory entries pass independent GF(2) checks.

Tests catch an incorrect matching preserving column coverage, one-half shift
sign error, invalid exponent/prime/dimensions, changed source facts/digest,
singular logical quotient and missing stabilizer exclusion. They explicitly
verify a global shift sign change is a coordinate relabeling. Tiny random
valid pairings compare orbit-root girth with all-root BFS. n=104 both-half
support oracle excludes all nontrivial words of weight<=4 (each decomposes
into two subsets <=2), giving independent lower5, not claimed exact d8.

## Linux plan

Workflow pair-partition-library-smoke.yml: build unchanged solver, 46 units,
algebra/source/pairing/incidence/girth checks, byte-identical regeneration,
then six default MaxSAT and six CC 60s runs, serial one allocated core,
4 GiB address-space cap, 90s wall backstop, stdin /dev/null. Reuse our
GH-165 generic exact-claim audit with explicit PP prefix/cases; check raw
answers/bounds, source/binary/all input hashes and actual GF(2) witnesses.
Minimum weight words required for exact-result certification; no fictitious
word substituted for absent output. Missing numeric gates remain open.
No increased limits or broad parameter sweep; heavy work becomes a prepared
server package, never a Mac solver experiment. No server core assigned.

Source/run/job/binary IDs, actual bounds and durable outputs follow execution.
Any genuine result/source mismatch stops and escalates under AGENTS.md.

## Completion fields

What changed: six fixed PP inputs, generator/cases, pairing/source identity,
independent incidence/girth/GF(2) checks, manifest/provenance, tests and Linux
smoke package. Validation performed: local algebra, source pins, pairings,
logicals, girth, duplicate review, 46 tests and regeneration. Results: pass
local gates; actual CLI evidence pending. Unresolved: Linux smoke gates,
any independent exact completion, prior pending scientific items and PI main
integration approval. Scientific semantics changed: no. PI action required:
no to continue; yes before main integration or server execution; existing
hyperbolic n=1920 interpretation question remains pending.
