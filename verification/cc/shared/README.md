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

The production C++ policy calls the C functions in `src/cc/cc_pack_row.h`.
The checker translates those same definitions through `pack_row_ast.c`.
`VerifPackCallback.callback_tally_body` proves the free count and stamp clash
for the entire declared row. `callback_mark_body` proves exactly which
array updates the second function performs. Both contracts allow a null
row pointer when the row has zero length.

The differential fixture `test_pack_integration.cpp` drives the production
`HalfSearch` entry point on connected repetition-code graphs, with two seeds
and three policy configurations. To check one built tree from its root, run

```sh
c++ -O2 -std=c++17 -Isrc/cc verification/cc/shared/test_pack_integration.cpp build/cc_half.o build/cc_level.o -lz -o /tmp/cc-pack-integration
/tmp/cc-pack-integration
```

### From a checked weight level to a CSS distance

For arbitrary binary PCMs, `CSSSearchSchedule.finish_from_pcm` starts the
two lower bounds at 1 and the upper bound at the sentinel n+1. It proves
that closing these bounds gives exactly the CSS distance in the mathematical
model. Its event premises distinguish exhausted levels, verified physical
witnesses and interrupted searches. A permutation certified to transport
logical supports in both directions preserves the distance, including the
no-logical case (`DualDistance.equal_half_distance`). Uniformly odd PCM
columns justify skipping odd weights. The separate Clight proof
`VerifPollAbort.body_dfs_abort` shows a scheduled, true-returning native
poll yields ABORTED after updating the counters.

`EvenOverlapLimit.exempt_overlap_limit` derives the tighter limit for a
stabilizer after removing its preferred qubit. `IndexRowBridge` relates
machine free-count and stamp tests to sets of physical qubits, and
`CSRWordTraversal` covers all words in the syndrome. For erasure pruning,
`ErasureBasisMap.original_column` lifts the solved triangular equations
back through the recorded XOR reductions to an original physical column.
A producer still has to establish that its pivot sequence and reductions
actually describe the input.

The native overlap policy borrows a C view for one synchronous level.
`VerifOverlapRows` proves both complete row updates, including empty
slices and exemptions. `VerifOverlapOwner` proves the production C
callback forwards the correct view, qubit and direction to the column
function. Its contract is the one used by `VerifOverlapDispatch` in DFS.
`OverlapRollback` proves equality of every slack and block count after a
matched column entry and exit on a well-formed CSR column. Several tight
rows can block the same qubit. `OverlapChildState` permits recursion to
change the event statistics and accounts for the selected qubit's extra
block. It requires the child to return with its input search arrays restored.

The full `cc_update_overlap` column body is checked in `VerifOverlapUpdate`
under the native CSR bounds and signed counter preconditions. All three
C overlap bodies refer to the same layout and updates in the policy
translation. `OverlapSharedBlocks` proves the search and the callback
own one block buffer across their two Clight type environments.
`VerifSeedOverlap` checks both enabled seed dispatches in `cc_run_level`.

The production distance driver uses three C operations from
`cc_distance_bounds.h`. `NativeBoundAlgebra` proves that an exhausted
weight and the optional parity skip preserve a finite half's lower bound.
`NativeBoundSafety` uses this result to justify both signed increments
and proves the two-half stopping inequality with an absent half represented
by the largest signed integer. `VerifDriverBounds` proves the complete C bodies for all three operations.

For a recursive node with more than three picks remaining and the overlap
callback enabled, `VerifEnabledVisit` checks the C statements that select
a child, invoke DFS and undo the overlap update. `VerifEnabledSiblings`
checks the entire sibling loop. `VerifEnabledUndo` composes that loop with
its following rollback loop. A child may update event counters. Every
normal or early exit restores the parent's slack and block arrays and
preserves the parent prefix of the trace. The recursive call and the
support toggle have contracts. Connecting all recursive entry paths and
establishing the callback preconditions from the constructor data are
still obligations for a proof of the optimized executable.

`OverlapTargetProgress` tracks the first child belonging to a target
through sibling exclusions and the actual list of newly blocked qubits.
If no remaining target qubit belongs to that list, each stays selectable
in the child, even when several stabilizer rows tighten at once. It also
proves that the loop reports EMPTY exactly when every child returns EMPTY.
`EffectiveRowTarget` proves the corresponding finite-set saturation
property for an ordinary stabilizer and for the effective row with its
tie-breaking qubit removed. `VerifOverlapGuard` checks the actual short
circuit tests and the signed remaining-weight comparison that selects
the enabled loop.

`NativeHalfExists` proves that stacking the detector rows underneath the
checks raises the rank exactly when the half admits a detected logical
operator. `ValidatedHalfStart` proves that the supplied detector and the
row-space definition have equal distance under the driver's mathematical
orthogonality and rank checks. The finite distance lies between one and
the number of columns. An empty half takes the mathematical sentinel
`n+1`.

The seed policy moves a stabilizer row’s exempt qubit to the active seed.
When a row has limit zero, the C update transfers just that row’s contribution
between two qubit block counts. `VerifSeedMove` checks all paths, including
the old-equals-new shortcut. `VerifSeedVisit` checks the whole CSR column on
entry and exit. `VerifRememberBlock` checks both nested loops of
`cc_seed_block_done` and the calls that remember the earliest exhausted orbit
member on each eligible row. These body proofs assume valid CSR slices and
indices. `ExemptionRollback` proves that undoing a list of directed transfers
in the same iteration order restores every qubit count, including repeated
indices. `PCMOverlapHits` connects the overlap hit list with the finite-set
stabilizer bound under its explicit incidence and slack hypotheses.

For each physical qubit, `SeedTransferTrace` proves that its block count
plus the number of zero-limit rows exempting it stays constant when a
seed is changed. `SeedColumnRestore` uses this invariant on the actual CSR
visit in both directions. Once recursive search gives back the same search
arrays, the exit restores both the exemptions and all qubit counts, even if
the event counter changed. `EmptySeedColumns` and `EmptyOrbitBlocks` cover
empty columns with no allocated row storage. `SeedSharedView` and
`RootOwnerMemory` identify the actual shared buffers and policy owner field
used by both callbacks.

`VerifRootAdmission` checks the full blocked-or-free seed branch of the
production C loop with overlap enabled. The blocked branch leaves the
witness buffer untouched. The free branch counts the seed, enters and
undoes its column and support, and preserves the returned trace. The
recursive DFS has a contract at depth one. `VerifPolicySeeds` checks
the full non-null-policy seed loop under two statement contracts. Only
EMPTY permits permanent orbit exclusion and advancing to the next seed.
The two contracts describe visiting one seed and committing its exhausted
orbit. Their integration with the mutable owner, the recursive DFS contract
and the constructor are further proof obligations.

## Recheck

With the Coq libraries on the load path and `clightgen` on PATH, run
`make -C verification/cc check-shared-level`. An out-of-tree VST build
can be selected with `VST_ROOT`; `CLIGHTGEN` can specify its matching
CompCert installation. The checker generates a fresh Clight AST, compiles
the modules in order and passes every project module to the Coq kernel
checker. MathComp provides finite sets, cardinality, ordinal indices, the
first-match sequence lemmas, finite fields and matrix operations.

The non-null tie-break/overlap seed loop is covered by
`ConcreteSeedSafety.native_root_driver_from_tables`. The theorem threads the
same physical reference-count array from seed entry through DFS return,
exemption restoration and the exhausted-orbit update. Its entry conditions
specify the CSR sizes, index ranges and stable exemptions. Its callee contracts
still govern DFS and flip, and the old pointer tests require separate
weak-pointer assertions. `FunctionPointerGuard.function_guard_at_entry`
checks why a pure VST function resource at offset zero with no permission at
offset minus one cannot supply that weak-pointer assertion. This conditional
loop theorem alone does not certify a normally initialized native executable.

### Prepared production entry

The production half search takes its callback options from the configuration
once per level and passes them to `cc_run_prepared_level`. The public C
wrapper `cc_run_level` also accepts callers using nullable fields. For this
version `check.py` regenerates `flag_level_ast.v` from the production file.
The three C files in `reference/` reproduce the earlier translation
`level_ast.v` at commit b558c89. They serve the earlier contracts and the
cross-version function-body check. Compiling the C++ half search uses only
the production source.

`PreparedPolicyOptions.prepared_source_has_numeric_guards` checks the
actual prepared traversal, DFS and flip ASTs. The seed, overlap, and
block-completion dispatch proofs cover enabled and disabled calls with
no separate pointer-validity resource for the callback. On EMPTY,
`PreparedRootOrbit.prepared_complete_orbit` verifies incrementing the
shared counts and calling the exhausted-block handler on those arrays.
`PreparedRootLoop.body_prepared_root_control` covers the whole policy
seed loop under its two substatement contracts. The DFS callee, caller
representation and total termination still require integration before the
optimized executable can be claimed correct for every input PCM.

`PreparedTablesDriver.native_root_driver_from_tables` now composes both
substatements for an installed overlap and seed tie-break policy. It uses
validated CSR tables, the entered and restored exemption, and the actual
orbit scan. `PreparedDeadline` checks the callback mask and both possible
callback answers. `PreparedRecursiveCall` permits a fresh interruption
at each visit. The root propagates that outcome without excluding its
remaining orbit. `PreparedMinimumExclusion` connects all completed
root positions to the MathComp minimum-distance theorem, given the
per-root search refinement.

`NativeRootFlip.body_flip_for_prepared_root` discharges the root's flip
call on physical packed arrays. `PreparedPhysicalPCM` proves restoration
of the syndrome, odd count, detector words and hash on the checked column
slice, including redundant rows. The prepared DFS proofs cover polling,
terminal depth, an early closed prefix, the parity cut and the one-move
lookup. A complete recursive DFS refinement, the C++ policy producer
and whole-program termination are still open.

`PreparedPCMDepth.body_flip_from_one_pcm` proves the production `flip` body
for every legal prefix of an encoded PCM. The assumptions describe the
initial physical rows, CSR bounds, and detector storage. `PhysicalPrefixInvariant`
uses MathComp finite sets to propagate those properties through the path.

`PreparedSiblingRestore.complete_recursive_sibling_scan` covers the child
loop with overlap enabled and more than three qubits left to choose. It
uses the same DFS contract at every depth. On every exit it restores the
shared block counters, slack and incoming path prefix. EMPTY records every
visited child as empty. An interrupted call records only the preceding
empty siblings. `PreparedTargetCoverage` connects those records to the
first child that retains a target. Its hypothesis about that child's
recursive report remains a proof obligation for the full DFS body.

The compiled terminal DFS branch now has a CSS-level postcondition in
`PreparedCSSTerminal`. For an encoded state, distinct trace entries and
a valid detector basis, a noninterrupted call at the weight limit returns
FOUND exactly when the trace is a nontrivial logical operator. Its Hamming
weight is the number of selected qubits. A due poll may return ABORT and
preserves the previous witness size. `PreparedMatrixPath` transports the
required matrix products across any legal sequence of flips.
`PreparedArenaScan` keeps the current candidate row in the parent and
lends the array suffix to deeper calls. The recursive callee and the
C++ candidate producer still have separate refinement obligations.

At an interior node with at least three moves left,
`PreparedBudgetArena.scan_native_candidate_arena` covers the compiled
child loop and exclusion rollback for either value of the cached overlap
flag. It carries the level's actual weight into the recursive callee.
`PreparedScanFromPCM` shows that filtering the chosen odd PCM row
retains a qubit of every compatible target and connects it to the
sibling scan's EMPTY condition. The row order can be arbitrary.
The result requires the physical block counts to match availability
and any enabled overlap updates to preserve the other target qubits.

`PreparedTerminalTrace` binds a terminal FOUND to the active prefix of
the actual C trace buffer. `PreparedOpenPair` verifies the two-move
lookup dispatch with the same block, syndrome and key arrays used by
the parent.

The installed seed loop and its DFS callee share the weight stored in the C
level. `PreparedBudgetDriver.one_weight_through_recursive_driver` specializes
the search report at that weight on every eligible seed, including when the
same witness buffer is reused for successive levels. It assumes the seed
tables, callback admission condition and recursive DFS contract.

At two remaining moves, `PreparedPCMLeafVisit.actual_fast_sibling_loop`
verifies the compiled sibling and undo loops on the shared flip heap and
candidate arena. If the first flip closes the syndrome, the early
return saves the shorter witness length. Otherwise the hash-table lookup
checks the remaining qubit. The individual branch theorems in
`PreparedShortCSS` and `PreparedPhysicalPair` relate the stored trace
and length to a CSS logical witness.

`PreparedInitialLookup` derives the live lookup preconditions from a
valid initial PCM representation and a protected prefix.
`PreparedChildPrefix` proves that the filtered row extends that prefix
with a fresh qubit and keeps the selected qubits blocked. The loop
theorem takes the reachable-state representation and the interpretation
of the returned trace as premises.

`PreparedPCMFastSearch.physical_two_move_search` discharges these
mathematical obligations for a filtered physical PCM row, starting with
the initial encoded matrices, table construction and protected parent
prefix. A caller can observe a valid CSS witness through its trace
predicate. FOUND uses the full length, while early closure uses the
shorter length. The theorem also excludes an EMPTY result when the
selected odd row covers a compatible minimum at this weight. It applies
to the compiled search and undo loops with two moves remaining. The
C++ host initialization, row producer and complete DFS body still
require integration.

`PreparedCSSRootPost.installed_root_proves_css_post` verifies the public
C seed loop against a CSS distance contract. An EMPTY result excludes
the current half distance when the orbit representatives cover a
preferred minimum and the recursive calls satisfy their contract.
A full-weight hit leaves a checked CSS witness in the trace. A shorter
hit retains a valid prefix at its own weight. Given the host's detector
rank checks and a certified incoming lower bound, `PreparedCertifiedBounds`
also relates the returned status to the canonical half distance. An
interrupted search supplies no tighter bound.

`PreparedPCMInterior` checks the recursive sibling and undo statements
under the same contract and machine weight as the caller. It requires
a covering odd row and the survival of the preferred target. The
overlap proofs derive this survival from the effective stabilizer rows,
their slack and the chosen representative's rank order. Separate
proofs cover the parity cut, early closure, last-qubit lookup and full
weight. `PreparedReadWitness` checks the signed length written by the
two-move leaf against the corresponding prefix of the C array.

The whole optimized command still requires a proof of the general DFS
function body, initialization and the policy that supplies the rows and
callbacks. These local and conditional guarantees apply to the C
traversal used by the optimized binary.

`PreparedVerifiedSeedRoot.prepared_root_from_seed_tables` derives seed
admission from the contents of the orbit, block and overlap tables. The
proof counts earlier orbit visits and tracks the exemption on each
zero-limit row as the seed changes. It shows that a preferred minimum
survives through its earliest representative. The initial counts,
effective stabilizer rows, orbit ordering and CSR table representation
are obligations of the caller. The result uses the recursive DFS
contract at the actual weight.

`PreparedPackingVerdict` establishes that a failed packing scan or an
over-budget feasible charge excludes compatible minima. The rows may
include redundant checks when their kernel contains the input kernel.
`PreparedReturnTrace` checks the final sampling branch and the return
instruction of DFS. Both paths return the result stored in the C local
and preserve the trace. The optional callback must return its borrowed
sample storage.

`PreparedInteriorExit.recursive_interior_through_return` checks the
general sibling loop, undo loop and return as a contiguous suffix of
the compiled DFS. When the sampling class is negative, the returned
status retains the CSS certificate and the parent regains its candidate
array. `PreparedSampleOwnerReturn` checks the recorded return using the
same owner field used by the overlap callback.

`PreparedFastRecursive.fast_search_with_recursive_contract` uses the
same minimum-distance and physical-witness contract for the two-move
shortcut as the general recursive search. It derives that result from
the original PCM, the odd branch row, the packed detector and the
compiled leaf lookup. Its hypotheses include the initial encoding and
the active search prefix.

`PreparedPrunedPCM.native_prune_excludes_compatible_minimum` checks the
entire C DFS body on a nonterminal branch rejected by packing or charge.
The level has at least two moves left, polling and parity are disabled,
and the installed chooser returns zero candidates with no erasure
sample. The proof follows the actual callback and both zero-iteration
loops. It relates the result to the original PCM, reads the active
prefix from the C trace, and preserves the block-array address and the
trace on return. It assumes the callback's contract and the checked
packing or charge evidence for these physical counters.

`PreparedInteriorEntry`, `PreparedChooseReturn` and
`PreparedSelectedReturn` also verify setup of a general nonterminal
node. The chooser borrows the shared owner field once. Its returned
count and candidate pointer reach the following subtree at exactly
the depth and weight stored in the C structures.

`PreparedInteriorGuards.enter_interior_on_live_flags` follows the C
function from entry to candidate initialization when there are at least
two moves left and a positive odd-check count. The poll flag may be
set if the incremented 64-bit node counter is between deadline checks.
The parity flag may be set if the remaining budget and the odd count
agree in parity. The two counters have the values written by C upon
entry to candidate selection. The proof also checks that appending
the remaining search to this prefix gives the full DFS body.
