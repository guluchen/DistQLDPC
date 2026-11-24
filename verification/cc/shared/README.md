# Proofs for the production CC level traversal

These modules use the Clight translation of `src/cc/cc_level.c`. The
C traversal descends from the C++/C performance candidate at commit
`ca80fd7`. Proofs were developed on x86-64 Linux with Coq
8.18.0, CompCert 3.13.1, VST 2.14 and MathComp 2.1.0 (SSReflect and Algebra).

## What the contracts establish

| Result | Theorem | Conditions |
|---|---|---|
| The C detector returns one exactly when any stored detector bit is set. | `VerifPackedDetector.body_detected_bits` | The supplied read-only words satisfy their C layout. A zero-word detector may use a null pointer. |
| Stored words detect a nonzero logical response over GF(2). | `DetectorMatrix.packed_matrix_nonzero` | The bit order matches the detector rows and all padding bits are zero. |
| The one-qubit leaf test accepts exactly when toggling physical qubit q gives a zero check syndrome and a nonzero detector response. | `LeafMatrix.leaf_matrix_exact` | The sparse column lists the physical rows of q without duplicates. Matrices, dimensions, support and q are arbitrary. |
| The first C rejection in `closes` returns zero and preserves caller storage. | `VerifClosesCount.body_closes_count` | Valid offset bounds and a column degree unequal to the stored odd-row count. `LeafMatrix.count_mismatch_nonzero` explains why this cannot discard a completion when those counts represent the matrix state. |
| The full C function `closes` scans the addressed CSR column and packed syndrome. It accepts when the degree matches the odd count, every listed bit is set, and at least one logical parity word differs from the candidate column. | `VerifClosesBody.body_closes` | The contract specifies readable storage, valid array bounds and a positive logical word count. All paths preserve the caller's storage. |
| The result of that C contract is exactly the matrix test after one qubit flip. | `ClosureMatrix.closes_value_pcm` | CSR incidence contains each physical row of the column once. Packed words contain the current syndrome, logical response and logical column, with zero padding. The stored odd count represents the physical syndrome. |
| The C function `toggle` flips each incident syndrome bit, adjusts the odd count, XORs the column key, and updates every packed logical parity word. | `VerifToggleBody.body_toggle` | The contract requires valid CSR and packed storage, representable intermediate counts, and sufficient space for the addressed logical column. |
| XORing the packed response with a represented column implements addition of that column over GF(2). Repeating the update restores the words. | `ToggleModel.packed_flip`, `packed_rollback` | The two packed word lists have equal length and use the same bit order. |
| The postcondition of C `toggle` represents the syndrome, its cardinality, the logical response and the syndrome hash of the updated qubit support. | `SparseSyndrome.toggle_pcm` | The CSR slice is the ordered encoding of the distinct incident physical rows. The original counts, packed words and keys represent the input matrices. |
| Applying the physical sparse column twice restores every bit in the original syndrome buffer, including unused bits in its last word. | `SparseRollback.sparse_words_restore` | All row addresses are within the packed buffer. The scans use the same order and may include repeated entries. |
| The C function `flip` calls `toggle` and applies any extra row XORs in the supplied CSR slice, preserving the physical odd-row count and logical response from `toggle`. | `VerifFlipBody.body_flip` | Covers a null policy, a policy without extra rows, and a valid redundant-row CSR table. The contract describes the exact word writes. Correct construction of the redundant columns belongs to the caller. |
| Equal physical syndromes have equal signatures. A complete bucket and the physical leaf test find every eligible leaf even when distinct columns collide. | `SyndromeHash.signature_toggle`, `bucket_complete` | The bucket contains every key match. |
| The C function `closing_qubit` returns the first free candidate in the matching chain that passes the physical leaf test, or returns −1 on exhaustion. | `VerifLookup.body_closing_qubit`, `HashProbe.physical_lookup` | The arrays satisfy the C bounds. The mathematical absence result additionally requires the bucket to contain every eligible candidate. |
| Probing a power-of-two table visits every possible slot within one circuit of the table. A sentinel and increasing links give a finite search with a unique result. | `HashProbe.visit_slot`, `finite_lookup`, `unique_lookup` | The word mask represents table size minus one, there is an empty slot, and every nonterminal link goes to a larger in-range qubit. |
| Sibling exclusion partitions every target that meets the child list. | `SiblingExclusion.dfs_siblings_partition` | The selected child is present and earlier children are absent. The unique index is the first hit in the actual child order. |
| A terminal C DFS call returns FOUND exactly for zero odd-check count and a lit detector bit, updates the two counters and records the witness size on success. | `VerifDfsLeaf.body_dfs_terminal` | The depth equals the target weight and the poll pointer is null. `DetectorMatrix.terminal_bits_correct` interprets the decision for a represented PCM and detector matrix. |

## Search and distance over arbitrary matrices

`MinimumPrefix.minimum_prefix_odd` proves that every nonempty proper subset
of a minimum logical support has an odd check. If such a subset were closed,
the subset or its complement in the target would be a lighter logical
operator. `odd_row_hits_residual` shows that every odd check touches a qubit
that still has to be added.

`LevelSearch.descend` branches on an odd check, removes each explored
sibling from future branches and stops at closed prefixes. The soundness
and completeness proofs cover every seed and every smaller weight.
`distance_index_spec` returns the minimum when a logical operator exists.
`distance_index_empty` establishes the exhaustion sentinel otherwise.
`CSSLevelDistance.css_distance_exact` derives the two detector matrices
from the input row spaces with MathComp, combines the half distances and
proves minimality for mixed Pauli weight (the union of the X and Z supports).
`css_distance_empty` covers an empty logical set.

`DetectorRank.validated_detector` connects a supplied detector matrix to
the same row-space test. It uses the orthogonality and rank conditions
checked by the production driver. For any vector with zero check syndrome,
all its input detectors vanish exactly when it is in the stabilizer row space.

The native early return for a closed prefix at any interior depth is
covered by `VerifClosedPrefix.body_dfs_closed` when polling is disabled.
It returns EMPTY for a trivial prefix and INCONSISTENT for an early
logical witness, records its depth, and increments the correct budget
and node counters. This distinction matters when testing a lower bound.

`MinimumOverlap.minimum_overlap` proves that a minimum representative
occupies at most half of a stabilizer's support. `ChargeBound.charge_bound`
proves the capacity inequality for charges on the odd rows. Its disjoint
unit-charge specialization `packing_bound` gives the packing rule.

`IndexPacking.scan_keeps_target` follows the greedy first-odd-row scan.
It proves the guard keeps every fitting completion even if a wrapped
stamp leaves extra marks. `ParityPrune.parity_prune` proves that if all
physical columns have odd weight, then a completion needs the prescribed
parity of remaining moves. `OrbitSeed.representative_covers` proves that
a valid support has an image of equal weight containing the earliest
orbit's representative and avoiding all earlier orbits, assuming the
input orbits are certified by coordinate automorphisms.

`OrbitLevel.orbit_minimum_level` lifts this argument to executable
weight levels. It runs the search from a representative with every
earlier orbit excluded. Every minimum weight is reachable and all
smaller levels are empty under the stated automorphism and scheduling
conditions. `RedundantState.extra_preserves_physical` relates the
redundant-row byte writes of `flip` to the physical syndrome and count.
Its rollback theorem covers repeated indices in the extra CSR slice.

For positive odd count at depth one short of the target, the actual DFS
calls the verified leaf lookup. `VerifOneLeft.body_dfs_one_left`
proves both outcomes for a null policy and poll. It returns EMPTY on
exhaustion or writes the selected qubit to the last path position and
records the full witness size. The proof derives the returned index
range from the table representation and scan trace.

`VerifSeedIndex.body_index_seeds` follows the full `cc_run_level` body
for the no-policy entry with initially clear block counts. It visits
seeds in index order and returns the first nonempty child outcome, or
EMPTY when every seed is exhausted. Each exit records which previous
seeds are blocked, the seed counter, and the head of a successful path.
The argument is modular. The concrete flip and recursive DFS must
satisfy the selected-state, rollback, and result contracts of
`seed_flip` and `seed_dfs` before this theorem can be used for the CLI.
The orbit-policy seed callbacks have an additional concrete interface.

The one-move shortcut now connects the physical return value to the
abstract recursive search. `LeafShortcut.unrolled_equals_search` covers
every depth and row ordering used by the model. With certified bucket
coverage and physical CSR/detector layouts, `NativeLeafChoice.native_leaf_misses`
identifies exhaustion of all free qubits and `native_leaf_found` ties
the actual returned index to membership, cardinality, zero syndrome and
nonzero detection. `RowTally.row_tally` computes the exact machine count
and clash bits for a CSR row. `no_candidate_exact` checks the zero-count
branch, including the maximum representable 32-bit row length.

`PhysicalPrunes.physical_distance` connects a search with combined pruning
to the minimum-distance index even when no logical operator exists. The
MathComp search applies greedy packing, a feasible integer charge bound
and stabilizer overlap to an ordered list of candidates. The hypotheses
state which rows are odd, that the qubit order covers the coordinates,
and that each stabilizer preserves syndrome and detector values.
`LocalCharge.scaled_bound` proves the local-degree charges and all
residual-capacity raises stay feasible using integer division.
`TiebreakTarget.even_tie_contains_first` separately justifies the
exemption for a canonical minimum at an equal-weight stabilizer tie.
The default orbit schedule and its C++ exemption updates still need to
select and maintain that canonical target.

`VerifPolicyParity.body_policy_parity` covers the actual C return when
a non-null policy enables the parity cut. It checks the machine low bit,
signed subtraction bounds and the three counters touched by this path.
`SiblingCounters.rollback_siblings` proves that undoing prior exclusions
in forward order restores arbitrary inherited machine counts.
`LeafAPI.body_leaf_api` checks the actual C lookup under a contract whose
caller supplies a table image. The C function chooses its own outcome.
`PCMLeafAPI.physical_leaf_image` constructs this contract from physical
matrix layouts, the XOR keys and coverage of the matching-key bucket.
The returned qubit therefore has the PCM completion property and a miss
excludes every free one-move completion.

The C++ constructor allocates two arrays initialized to −1 and calls
the C function `cc_build_leaf_index`. Its VST contract records every
descending insertion, including linear probing across collisions and wrap.
`BuiltLookup.insertion_finishes` shows a free slot is reachable under
the capacity and mask conditions. `BucketPipeline.exact_bucket` identifies
the chain members exactly by column key, including when many columns have
the same key. `BuiltPCM.body_leaf_for_built_pcm` applies these results to
the C leaf lookup. Given the builder postcondition and physical PCM layout,
a hit is an eligible completion and a miss excludes every free completion.

The native CLI theorem still requires the concrete recursive child traversal
and rollback, child selection, orbit and policy callbacks, and the driver
that constructs the physical arrays and detector basis. Private correction
`9fa8df2` also replaces out-of-range vector subscripts in C++ CSR pointer
construction with pointer addition. Timing results refer to the frozen
candidate identified separately in the benchmark records.

In this private derivative, the C odd-row loop calls `cc_lowest_bit`
on each nonzero word. `LowestWord.lowest_bit_correct` identifies the
least set position for every such 64-bit word. `WordScan.scan_exact`
proves that clearing it on each iteration enumerates exactly the set
positions without repetition, and `scan_finite` establishes termination.
`VerifLowestBit` checks the global table initializer and the helper body
in the level traversal's own Clight translation. The original timed C
uses the compiler builtin and remains separately identified by its hash.

The one-move theorem in `PCMSearchStep` connects the positive-syndrome
DFS body to a physically populated PCM table and the parity-prune contract.
`VerifLastPair` and `VerifLastPairClosed` check the dispatch after adding
the first of two moves. A shorter logical prefix sets INCONSISTENT.
`VerifSiblingRollback` checks the actual native restoration loop for
arbitrary inherited counters, including repeated qubit labels.
`TableTotal` supplies existence of a construction history. The finite-set
theorem in `ErasureProjection` proves a necessary test for completions
when the projection kills the chosen region; the construction of that
projection by the production callback is a separate obligation.

The epoch routines are the C definitions reached by both native row packing
and the policy scratch arrays. `VerifEpoch` verifies ordinary allocation of
one or two fresh tags and the exact array writes at unsigned rollover.
`EpochFreshness` shows that no slot bearing a previous tag can be mistaken
for a fresh slot given the recorded tag-range invariant.

`OrbitPreferred` takes the earliest orbit over all minimum logical
supports. It proves that a minimum support preferred under that seed's own
order contains its representative and avoids every exhausted orbit. The C
row-gather proof preserves the order of the free qubits in a CSR row and
preserves the unused suffix of the destination buffer.

## Recheck

With the Coq libraries on the load path and `clightgen` on PATH, run
`make -C verification/cc check-shared-level`. An out-of-tree VST build
can be selected with `VST_ROOT`; `CLIGHTGEN` can specify its matching
CompCert installation. The checker generates a fresh Clight AST, compiles
the modules in order and passes every project module to the Coq kernel
checker. MathComp provides finite sets, cardinality, ordinal indices, the
first-match sequence lemmas, finite fields and matrix operations.
