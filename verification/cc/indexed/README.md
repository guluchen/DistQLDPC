# Indexed and certified CC search

All commands take the qubit count and the two original CSS parity-check matrices in physical column order. The default DistQLDPC executable is built separately.

```sh
# Linux x86-64, Coq 8.18.0, VST 2.14, 64-bit OCaml, native Coq libraries and Python 3.10+
make -j1 VST_ROOT=/path/to/VST-2.14 proof all test
# From verification/cc/indexed
mx=../../../data/matrices/tier0/COLOR_7_1_3_Hx.txt
mz=../../../data/matrices/tier0/COLOR_7_1_3_Hz.txt
python3 certified.py 7 "$mx" "$mz"
./pcm-proved --distance 7 "$mx" "$mz" 100000000 63
./pcm-indexed --distance 7 "$mx" "$mz" 100000000 63
```

Use `CCV_BASE_PROOF=/absolute/path/to/proof` to use an already checked build of the **same** parent Coq development. For the timing build, append `-flto -march=x86-64-v3` to the default C flags. The compiler must support x86-64-v3 on the target host. Indexed sources rely on GCC/Clang count-trailing-zeros for nonzero words.

| Entry | How it obtains a result | Verification |
|---|---|---|
| `certified.py` | On supported sizes a standalone C program proposes a pure Pauli witness using shuffled GF(2) elimination, stabilizer descent and pair combinations. A separate verifier reads the original PCMs, checks this witness and excludes all smaller vectors on both halves (or validates an X/Z symmetry transfer). The indexed solver can supply a second suggestion. | Packed certificates have a kernel-checked mixed-distance theorem at every supported width. [CCBoundReplay.v](CCBoundReplay.v) gives the alternative using the released VST-proved C bounded queries. |
| `pcm-proved` | Uses compact PCM preparation, the released packed certificate checker where applicable, checked X/Z symmetry and the released C search. | Retains the parent verification chain. [CCCompactPrepare.v](CCCompactPrepare.v) proves identical preparation for every raw input. [CCRawDual.v](CCRawDual.v) verifies the symmetry certificate on the original rows. |
| `pcm-indexed` | Runs sparse CC directly and returns a witness and distance. | Experimental. The two C functions for gathering selected bits and flipping indexed bits have VST body proofs. The new C search and allocation logic still require end-to-end refinement proofs. |

`certified.py` derives the exclusion threshold from the bits of the proposed witness. A witness proves an upper bound. Both lower bounds must close before the driver reports an exact distance. Failed bounded verification returns UNKNOWN (exit 3). If the indexed solver produces no usable witness, the wrapper can invoke `pcm-proved`, which can also certify EMPTY. Each stage has its own per-half iteration budget. The default rule mask for bounded C replay is 39 (sibling exclusion, packing, leaf closure and minimum remaining values). The indexed proposal uses mask 63.

At widths through 64 the command runs the checked dense driver directly. At the default budget the C upper-witness pass applies through width 756. Packed checks use up to 378 or 756 physical columns and check/detector rows per half. Oversized models or inconclusive packed checks fall through to other checked routes. The small driver can also use the parent's 189-bit certificate. When the XOR of the check rows is all ones, every kernel vector has even weight. The packed certificate proves this condition per half and skips an impossible odd weight. With `--row-order=reverse-bfs` the C adviser visits the Tanner graph starting at qubit zero, restarts on disconnected components, and reverses the discovered check rows. The checker picks rows from its own copy of the PCM. `kernel_advised_rows` proves that this step preserves every original kernel vector. The default uses the input row order. The 378-bit checker combines independently verified orbit generators, verifies all required pair entries of its syndrome filter and checks the disjointness of each proposed packing. The row accessor cache is pointwise equal to the source rows. The proof of function equality uses Coq's standard functional extensionality axiom. Both larger certificates are assembled from the parent's 189-bit representation and their proofs are recompiled against the parent library. C row choices, filter signatures and upper witnesses are advice.

To check a separately supplied pure witness, feed its side and bit string on two lines to `pcm-check N HX HZ BUDGET RULES`. Rule masks from 0 to 63 are supported for the C bounded query. The packed verifiers can also be run directly as `pcm-wide N HX HZ` or `pcm-large N HX HZ` with the same two-line input.

The formal statements concern mathematical PCM inputs with the C storage and return contracts of the parent development. The file parser, allocation and marshalling, Coq extraction, native compilation and host runtime follow the [parent trust boundary](../README.md). An operating-system process boundary keeps writes by the candidate solver out of the verifier's address space. The compact preparation and upper-witness checker use extracted OCaml. The branch-and-bound search uses C.

The indexed implementation builds incident-row and incident-column arrays, checks transitive cyclic actions against both GF(2) row spaces, and indexes possible short syndrome repairs. Hash collisions retain branches. It also uses even-overlap ordering and redundant pair-XOR checks, following DistQLDPC rounds GH-162 and GH-181 and their project attribution. [CCShortSound.v](CCShortSound.v) states the algebraic filter conditions. [CCTieMinimum.v](CCTieMinimum.v) proves the ordering lemma for valid stabilizers. See [NOTICE](NOTICE) and [MODIFICATIONS.md](MODIFICATIONS.md).

`make proof` checks the SHA-256 identities of the two new C primitives and their normalized Clight programs, compiles the new modules and runs the Coq kernel checker on them with the parent checked library. `make test` exercises the direct C API, corrupted symmetry certificates, collisions, word-boundary orbit cases, malformed or nonminimal witness proposals, and raw-PCM end-to-end results against exhaustive small codes.

With `--pair-pack`, the search can use a sum of two checks as one additional member of a disjoint packing. The C adviser looks for an odd and an even row that agree on the already packed free qubits. Their GF(2) sum is an odd check whose remaining support is disjoint from the packing. The verifier recomputes its parity and support before using the extra lower bound. The optional rule can be combined with `--row-order=reverse-bfs`.

The C witness search starts with 64 shuffled information sets through width 189 and 8 at larger widths. If the packed checker does not certify that proposal, a second C search tries 512 sets. Only a strictly lighter proposal triggers a second packed verification. `--upper-rounds=N` selects a single explicit effort from 1 through 4096. Giving the same witness twice does not repeat an inconclusive packed check. Each accepted distance still goes through the independent verifier.

With `--sparse-checks`, C proposes pairs of original checks of weight at most 32. The checker constructs the XOR of the named rows itself. Short, distinct sums may supply additional constraints to select or pack. The original stabilizer spaces and the original physical coordinates still define the witness test and the distance theorem. The adviser keeps the total to at most three times the original row count and within the packed representation.

For inputs of 65–189 qubits the certified entry tries a three-lane Uint63 search first. Its words are the original checked 189-bit representation. It specializes the same pruning proofs and shares the C row-choice implementation with the 378- and 756-bit kernels. A capacity or search-budget return falls back to the wider verifier.

The packed verifier checks raw X/Z involutions before preparing a second half. The C adviser tests inversions of two cyclic coordinates with a shear at the wrap, and inversion with block reversal in multi-block cyclic inputs. Fingerprints filter candidates; Coq checks every row image in both directions, the coordinate involution, the witness on its actual side and the lower bound. No permutation, group parameters or distances are read from the input comments.

For one encoded qubit the C adviser can also propose disjoint arithmetic-progression supports for a logical detector. Coq checks their pairwise disjointness and equality modulo the check-row span. It checks that adding their common detector to the checks spans every logical detector that the search needs. An undetected logical word must then meet each support, proving the weight lower bound. A failed certificate falls back to CC search. On widths up to 378 the C adviser can also propose a grid translation with a shear at the wrap to remove additional equivalent search roots. Every proposed root map is checked against the actual parity and logical rows.

When no exact permutation of the raw row lists is found, a bounded C test can suggest a coordinate involution between their GF(2) spans. The extracted packed checker verifies the coordinate map, check-row inclusion and logical-detector inclusion before reusing the X lower bound on Z. This also supports inputs with different choices of generating rows.

The optional --erasure-pack uses the check equations restricted to the union of a saturated packing. If elimination over that region finds a contradiction, C returns the original row indices forming the odd equation. The extracted verifier reconstructs that sum and checks its disjointness against the packing. The option includes pair packing. The implementation currently tests saturated packings of two through eight rows and tracks up to 64 independent restricted equations. Declining a test leaves the ordinary CC search available.

With --class-parity the verifier can exclude an entire weight parity from one half. If the all-ones vector reduces to zero in the check row space, kernel words are even. If adjoining that vector makes every logical detector reduce to zero, a logical word must have odd weight. In both cases the skipped weight is justified on the input PCM.
