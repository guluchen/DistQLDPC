# DistQLDPC modifications to upstream code

This document lists changes made for the DistQLDPC project relative to
the embedded MaxCDCL MaxSAT engine (`src/solver/`). Upstream MaxCDCL is
MIT-licensed (see `src/solver/LICENSE`).

**Modifier:** Yu-Fang Chen <yfc@iis.sinica.edu.tw> (2025–2026)  
**Purpose:** QLDPC / CSS code minimum-distance computation via MaxSAT

---

## Application layer (`src/core/`)

New code, not derived from MaxCDCL.

### `src/core/distqldpc.cc`

| Area | Description |
|------|-------------|
| QLDPC encoding | MaxSAT formulation for stabilizer distance (Hx/Hz/Gx/Gz matrices) |
| Fork + pipe | Child runs solver; parent enforces wall-clock timeout (`-cpu-lim`) via `SIGKILL` |
| Bounds sync | Parent reads `TRY` / `LB` / `UB` / `RESULT` lines from pipe |
| Progress output | Default mode prints `c trying d:`, `c d_lb:`, `c d_ub:`, `c d:`, `o` |
| Quiet / debug | Default `verb=0`; child stdout to `/dev/null`; `-v` / `-debug` for solver log |
| CLI flags | `-no-card`, `-card-sinz`, `-card-mto`, `-card-both-force`, `-cpu-lim`, `-q` |
| Matrix path resolution (2026-10-11) | A bare code name resolves to `data/matrices/<code>` if its `_Hx.txt` exists there, else to the first of `data/matrices/tier0` … `tier5` containing it (benchmark matrices are organized in tier subdirectories, see `data/matrices/README.md`); a path containing `/` is used as given |
| Interleaved CSS split (GH-73, PI-approved 2026-10-09, experimental) | Default MaxCDCL path computes d = min(dX, dZ) by a global bound search over the X-type and Z-type halves (doubling feasibility probes, tie-break probes, ordered capped optimisation); only global bounds are forwarded; `-joint` keeps the original encoding |
| Per-half symmetry breaking (GH-85, interaction GH-73 x GH-75, experimental) | Split path only: candidate qubit permutations (GH-75 family) are kept for a CSS half only if GF(2) row-space checks prove they preserve rs(Hpar) and rs([Hpar;Glog]) of that half (plain maps only, no XZ-dual maps); optimum-preserving orbit clauses over the half variables (unit clause for transitive groups, orbit chain otherwise) in every oracle instance of that half. `-no-symbreak` = GH-73 split; `-symbreak-report` prints per-half generators/orbits; `-joint`, dumps and RoundingSat unchanged. See `optimization/experiments/GH-85/`. |
| Dual-half elimination (GH-87, extension of GH-73, experimental) | Split path only: if a qubit permutation (identity or GH-75 generic candidate family) is verified by GF(2) rank/row-space checks to map rs(Hz) onto rs(Hx) and rs([Hz;Gx]) onto rs([Hx;Gz]), then dX = dZ and the global bound search runs on the X half only (its bounds are global). `-no-dualskip` = GH-73 split; `-dualskip-report` prints the verified maps; `-joint`, dumps and RoundingSat unchanged. See `optimization/experiments/GH-87/`. |
| Dual-map bound sharing on the fresh-solver split (GH-107, port of GH-102's sharing to GH-92; experimental) | Split path only: with a verified XZ-dual map (detection as in GH-87), `-dualmode=share` (default) keeps both halves in the interleaved global bound search (fresh solver per probe) and writes every proven half lower bound into both halves (probes whose NONE is implied are skipped; UBs stay global; a shared lower bound above the incumbent refuses to answer). `-dualmode=skip` = GH-87/GH-92 X-half-only search; `-dualmode=off` (alias `-no-dualskip`) = GH-85 split; `-dualshare-stats` prints work counts. See `optimization/experiments/GH-107/`. |
| Frontier branching with a structural selector (GH-129 + GH-130; default since 2026-10-18, PI decision) | Split MaxSAT path only. `Solver::pickFrontierLit` (new, +190 lines in `src/solver/Solver.{h,cc}`): with frontier branching on, a decision first looks for an odd parity row of the half (true qubits of odd parity, some qubits unassigned), takes the row with the fewest unassigned qubits (ties by index) and decides its most active unassigned qubit (VSIDS or LRB score, whichever phase is current) to 1; if no row is odd, the normal decision is used. The half's parity rows are passed from `run_css_half()` (as GH-121 did); the odd-row state is updated lazily from the trail at each decision (< 1% of the profile). Only the decision order changes, never the formula. `-frontier=auto` (default) enables it per CSS half iff the half's parity matrix has fewer than 3 Tanner 4-cycles per row (sum over row pairs of C(\|r ∩ s\|, 2) divided by the number of nonzero rows), computed once before the search and printed with `-v`; `-frontier=off` = the search of main before GH-130 (byte-identical `-v` logs); `-frontier=on` = every half; `postsol` / `presol` = only after / before the probe's first solution; `-frontier-stats` per-probe counters, `-frontier-check` re-verifies the incremental row state (debug). Evidence: GH-129 (`on` everywhere: tiers 1-2 0.4-0.6x main on 5-seed medians, but every TN cell slower, refutations ~36% more time per conflict) and GH-130 (`auto`: BB/GB/LP cells 0.14-0.90x, TN cells identical to main, Tier 5 no cell worse, LP_714/LP_1020 solved 2.3-3.9x sooner). Caveats recorded in `optimization/experiments/GH-130/REPORT.md`: the 4-cycle count separates TN from BB/GB/LP on the bundled codes but was not shown to be the cause of the TN slowdown, and it depends on how the parity matrix is written (redundant rows raise it). |
| Odd-cap skip (GH-133; default on since 2026-10-21, PI decision; `-oddcap-skip=off` = previous search) | Split MaxSAT path only, `-oddcap-skip=on`: for a CSS half whose parity matrix H has only odd column weights every element of ker H has even weight (proof below, `src/cc/`), so an odd probe cap m is equivalent to the cap m - 1 and a NONE at an even cap 2t certifies the lower bound 2t + 2. Phase 1 (doubling caps): cap 1 is not probed (lb 2), and after a NONE the lower bound is raised to the next even value; Phase 2a: cap U-1 -> U-2 when U-1 is odd; Phase 2b/3: an odd optimisation cap U-1 (dual-half elimination) -> U-2. The decision per half is printed with `-v` (`c oddcap X: ...`). `-oddcap-skip=off` (default) leaves main's cap sequence byte for byte (identity verified on tier0+1 x 2 modes). The encoding, the cardinality constraints and the solver are unchanged. See `optimization/experiments/GH-133/`. |
| Verified upper-bound pre-pass for the MaxSAT split (GH-144; `-ub-pre=off\|on\|S`, default off) | Split MaxSAT path only. Before Phase 1 the GH-140 finder (`src/cc/cc_ubsearch.h`, `UbFinder`) runs on every half that has logicals (X half: H = Hz, G = Gx, S = Hx; Z half: H = Hx, G = Gz, S = Hz) for at most S seconds (`on` = 60 s), always looking for a word lighter than the current bound; a half stops after `-ub-pre-hits=H` (16) re-hits of the bound or max(`-ub-pre-plateau=P` (1000), 4 x the iteration of its last improvement) iterations without improvement (iteration based: deterministic for a given `-seed` unless S ends it). Every word is verified (`ubpre_verify`: Hpar e = 0 and Glog e != 0 directly on the input matrices, plus `distcc::verify_logical`); a failure discards the pre-pass. The lightest weight U0 is the initial UB (pipe `UB U0`, printed `c d_ub: U0`) and each half's lightest word its incumbent. With U0: Phase 1 still probes a half with a pre-pass incumbent but only at caps < U - 1; Phase 2a runs on both halves (not only on ties) with feasibility probes at U - 1 and reports the global lower bound after each probe; Phase 2b optimises each unfinished half with cap U - 1. `-ub-pre=off` or no verified word = main byte for byte (identity verified on tier0+1 x 2 modes). Soundness below (GH-144). See `optimization/experiments/GH-144/`. |
| Stern / Dumer collision mode of the shared finder (GH-146; `-ub-isd=off\|stern\|dumer[:P,L,W,B,R]`, default off) | Applies to the CC `-ub-search` finder and to the MaxSAT `-ub-pre` pre-pass (both use `UbFinder`). Per round: W Canteaut-Chabaud pivot swaps on the stored systematic columns (or a fresh elimination), a random split of the information set into two halves and a random window of L reduced rows; all subsets of size <= P of each half (`dumer`: the window pivot columns are elements too), bucketed by the window part of their column sum; every colliding pair with different detector parities is weighed, kept words go through the unchanged detector check, stabilizer local improvement and the driver's / pre-pass's independent verification. Single systematic words are also tried every round. Defaults from S0: P 2, L automatic (about log2 of the list size), W 32, B 1 round per iteration. `-ub-isd=off` (or no flag) = the GH-140 enumeration byte for byte (default path identical to GH-144's 6d2b7a1 on tier0+1). Soundness below (GH-146). See `optimization/experiments/GH-146/`. |
| CC engine switch (GH-124 S0, experimental) | `-engine=maxsat` (default) leaves the search above unchanged (byte-identical `-v` logs); `-engine=cc` runs the connected-cluster level search of `src/cc/` on the same CSS split through the same pipe protocol and output; `-engine=auto` is a structural selector (not the default): CC unless a half's parity matrix has a row of weight > 32 or, for n >= 64, a mean row weight > n/4 (pre-S1 rule; every bundled code goes to CC). `-seed=N` (timing seeds): N > 0 sets `random_seed` of every MaxCDCL solver on the MaxSAT path from the application layer (the engine source is unchanged; N = 0 or no flag keeps main's search byte for byte) and equals `-cc-seed=N` with the CC engine. A CC no-answer stop sends `RESULT -1 TRAP` on the pipe, and the parent withdraws the bounds it had received (MaxSAT never sends it). `find_dual_maps` additionally keeps the verified qubit maps (its report output is unchanged). Flags: `-seed`, `-cc-rules`, `-cc-dual`, `-ub-basis`, `-ub-search` and `-cc-ub-*` (GH-140), `-cc-seed`, `-cc-trace`, `-cc-stats`, `-cc-mutant` and `-cc-schedule` (tests only). Conflicting combinations are rejected (exit 1): CC flags without `-engine=cc\|auto`; `-joint`, `-roundingsat`, the dumps and `-native-parity-opb` with `-engine=cc\|auto`; the cardinality flags and `-dualshare-stats` with `-engine=cc` (`-engine=auto` warns about the flags its choice ignores). See `optimization/experiments/GH-124/`. |

### `src/cc/` (GH-124, experimental; new code, not derived from MaxCDCL or any third-party code)

Optional engine, off by default (PI 2026-10-16): enable with `-engine=cc` (or `-engine=auto`); `-ub-basis` is on by default inside CC (`-ub-basis=off` disables it). Algorithm: Dumer-Kovalev-Pryadko connected clusters (IEEE TIT 2017); the skeleton was studied in Quantinuum's Qubitserf (MIT), no code copied. DistQLDPC additions and how to switch each one on or off are listed in README, "Connected-cluster (CC) engine".

| File | Description |
|------|-------------|
| `cc_half.h`, `cc_half.cc` | Exact connected-cluster (CC) level search for one CSS half (Dumer, Kovalev, Pryadko 2017): clusters grown from a seed along one odd parity row at a time; syndrome-free clusters below the level are dead ends (a nontrivial one is reported as an inconsistency); rules `excl` (sibling exclusion), `pack` (disjoint odd-row packing bound), `orbf` (orbit seeds from the GH-85 verified per-half orbits, replacing the index rule), `mrv` (fewest-candidate branching), `parity` (GH-133: odd levels skipped on a half whose column weights are all odd; per-node parity check), `leaf` (GH-133: Zobrist hash from column to qubit; the closing qubit is looked up at budget 1, and at budget 2 each candidate is completed by one lookup), `overlap` (GH-138: a minimum logical meets every same-type stabilizer row g in at most floor(\|g\|/2) qubits; incremental counters, the rest of a tight row is forbidden); uint64 bitsets with an incremental syndrome; `-cc-seed` relabeling; test-only mutants 1-3 (1 forbidden set not restored, 2 packing prune `>=`, 3 orbit seed rule off by one) and 5-7 (5 parity forced on a half with an even column weight, 6 leaf budget off by one, 7 leaf closure without the detector check) and 8-10 (GH-138: 8 overlap limit off by one, 9 parity checks used as stabilizer rows, 10 even-weight tie cut). |
| `cc_ubsearch.h`, `cc_ubsearch.cc` (GH-140, GH-146) | Randomized low-weight logical finder for one CSS half (`-ub-search`): random information sets (random column order, Gauss-Jordan elimination of H with pivots in that order, systematic kernel basis), words of 1-2 (optionally 3) systematic basis vectors below a weight threshold, detector check (G c != 0), greedy local improvement by same-type stabilizer rows; deterministic per seed; test mutant 11 (no detector check and no improvement). GH-146 collision mode (`-ub-isd`): Stern / Dumer collision step with Canteaut-Chabaud pivot swaps (`cc_swap`, `isd_round`, `iterate_isd`), parser `parse_isd`. |
| `cc_driver.h`, `cc_driver.cc` | Driver: start-up detector check (rank[H;G] + rank S = n and commutation), both halves interleaved level by level (cheaper half first) or one half under a verified XZ-dual map, stop rule (a hit at level w ends the run once the other half's lower bound is >= w), anytime `TRY`/`LB`/`UB`/`RESULT` lines, witness verification (H e = 0, independent GF(2) rank test against the same-type stabilizers, dual image check), its own check of the XZ-dual map (pi(rs Hz) = rs Hx and pi(rs Hx) = rs Hz), always-on traps (`RESULT -1 TRAP`, never a value; earlier bounds withdrawn), optional `-ub-basis`, `-cc-trace`, `-cc-stats`; test-only sequential schedule (`-cc-schedule=sequential`) and driver mutant 4 (stop rule without the other half's lower bound, run under the sequential schedule). |

Tests: `tests/test_cc_engine.cc` (`make test-cc`): brute-force oracle on random halves and random consistent CSS
codes (planted shifts, self-dual codes), every rule subset, relabeling seeds, the forked pipe driver (both
schedules), and the four mutants, each of which must change an answer. `tests/test_cc_flags.sh`
(`make test-cc-flags`): engine flag conflicts and invalid CC flag and `-seed` values are rejected, valid
combinations answer, `-engine=auto` decisions on sparse and generated dense codes, and bound withdrawal after a trap.
The MaxCDCL engine under `src/solver/` is unchanged by GH-124.

GH-133 (`parity`, `leaf`; both on by default inside CC, `-cc-rules=excl,pack,orbf` restores the GH-124 engine).
*Parity theorem.* Let H be the half's parity matrix with every column weight odd (rows that are empty are
dropped; a row listing a qubit twice counts it once, as the engine stores it). For every vector v over GF(2),
sum_i (H v)_i = sum_i sum_j H_ij v_j = sum_j v_j (sum_i H_ij) = sum_j v_j colwt_j = sum_j v_j = |v| (mod 2),
since every colwt_j is odd. Hence (i) wt(syn(S)) = |S| (mod 2) for every cluster S, and (ii) every element of
ker H - every logical and every stabilizer - has even weight, so every odd level is empty and an EMPTY level 2t
certifies the lower bound 2t + 2 (level 1 is empty: the driver starts a qualifying half at level 2 and emits
`LB 2`). At a node with |S| = s, target w and r = w - s qubits still to add, syn(e \ S) = syn(S) for every
completion e, so by (i) r = wt(syn(S)) (mod 2); a mismatch prunes. For even w this is implied by (i)
(r = w - s = s = wt(syn(S)) mod 2), so the per-node check never prunes on a qualifying half (`parprune` is
0 in every run) and the "+1 on a lower bound L whose parity differs from wt(syn(S))" of the proposal is
vacuous (r = L is already excluded by the parity of r, so L + 1 > r iff L > r): the gain of the rule is the
level skip. The rule is never applied when some column weight is even (the premise fails; GB_144_12_12 and
BB_144_14_14 have even column weights). *Leaf.* The lookups enumerate exactly the closing children of the
branching leaf (free qubit = not in S and not forbidden; nontrivial closure = detector parity nonzero;
syndrome-free S + a of weight w - 1 handled as the branching does), so every level verdict is unchanged;
only the node count drops. The spec's literal leaf mutant ("ignore the forbidden set") is a sound
weakening (a forbidden closing qubit gives a genuine element of F; a closing qubit already in S gives a
syndrome-free set of weight w - 2, trivial under the level precondition and rejected by the detector
check), so it was replaced by mutants 6 and 7. Tests: 64 rule subsets x 3 relabeling seeds on random
halves (a third with all column weights made odd), the GH-124 rule set as a driver configuration, Part D
(MaxSAT split with `-oddcap-skip` off/on against enumeration), and the three new mutants, each of which
must change half-level verdicts.

GH-138 (`overlap`; in the default `-cc-rules` of branch `experiment/gh-138-overlap` as a candidate,
`-cc-rules=excl,pack,orbf,parity,leaf` restores the GH-133 engine). Source of the inequality: J. Y. Lee,
arXiv:2610.06820, App. A rule (iv), used from the published description only; the forbidding of the rest of a
tight row is DistQLDPC's addition.

*Setting.* Half with parity checks H, detector rows G and nontrivial set F = {v : H v = 0, G v != 0} (X half:
H = Hz, G = Gx; Z half: H = Hx, G = Gz). K = the rows of the half's stabilizer generators (X half: rows of Hx;
Z half: rows of Hz). Every row g of K satisfies H g = 0 and G g = 0 (the driver's start-up detector check
verifies both: even overlap of every stabilizer row with every parity row and every detector row;
`HalfSearch` re-checks them and refuses the input otherwise). Rows are deduplicated; a qubit listed twice
cancels. lim_g = floor(|g|/2).

*Lemma 1 (Lee).* If e in F has minimum weight in F, then |e & g| <= lim_g for every g in K.
Proof: e + g satisfies H(e + g) = He + Hg = 0 and G(e + g) = Ge + Gg = Ge != 0, so e + g in F, and
|e + g| = |e| + |g| - 2|e & g|. If |e & g| > |g|/2 then |e + g| < |e|, contradicting minimality; since
|e & g| is an integer, |e & g| <= |g|/2 is |e & g| <= floor(|g|/2). (Only K rows are used, never H rows: a
row h of H is in general not in ker H, so e + h is not in F; mutant 9 uses H and must fail.)

*Lemma 2 (level).* At level w (precondition: F has no element of weight < w, established by the driver's
contiguous levels and, on a parity half, by the parity theorem for the skipped odd levels) every element of
F of weight w has minimum weight, so Lemma 1 applies to all of them.

*Lemma 3 (forbidding).* Let S be a node (cluster) and e in F with |e| = w and S subset of e. Then
|S & g| <= |e & g| <= lim_g for every g, and if |S & g| = lim_g then e & g = S & g, i.e. e contains no qubit
of g \ S. Hence the strict prune (|S & g| > lim_g) never fires on a subset of a weight-w element of F, and the
set Forb_ov(S) = union of g \ S over the tight rows (|S & g| = lim_g, including the rows with lim_g = 0, which
are forbidden from the start of the level) is disjoint from every weight-w element of F that contains S.
Forb_ov(S) depends on S only (not on the order in which S was built); the engine keeps the counters
slack_g = lim_g - |S & g| incrementally on every qubit added to or removed from S (seeds and children) and adds
/ removes the forbids when a counter reaches / leaves 0. With the forbids in force no qubit that would make a
row exceed its limit can be added, so the strict prune is implied and never needs a separate test.

*The even tie.* For even |g| a minimum logical may have |e & g| = |g|/2, and then e + g is another minimum
logical with |(e + g) & g| = |g|/2. Equal weight does not contradict minimality, so the tie cannot be cut by
Lemma 1; cutting it (limit |g|/2 - 1 for even |g|) removes both e and e + g, and with no canonical choice
between them a level can lose every minimum element (mutant 10 does exactly this and fails on 2112 of 19 200
ladders). The rule therefore uses the exact limit floor(|g|/2) for odd and even |g| alike, and the forbid at
|S & g| = floor(|g|/2) is not a tie-break: it is Lemma 3 (one more qubit of g would violate the strict
inequality). For odd |g| = 2t + 1 the limit t is already "tight" (t + 1 > |g|/2), so no tie exists.

*Theorem (exactness with the other rules).* Each of the other rules is exact by an argument that fixes one
weight-w element e* of F (excl: the e of the node; orbf: the image pi(e) under a verified automorphism; the
packing bound and the no-candidate dead end: any e extending the node; parity: any e; leaf: the closing
children) and shows that a node S subset of e* with forbidden set disjoint from e* is visited and branches
on a row that still has a candidate in e* \ S. Adding the overlap rule changes the forbidden set of S by
Forb_ov(S), which by Lemma 3 is disjoint from every weight-w element of F containing S, in particular from
e* (whichever e* the other argument chose; Lemma 2 makes e* minimum without any condition on how it was
chosen), and it prunes no subset of e*. So every such argument goes through unchanged:
- excl: the first candidate of the branching row in e* is not overlap-forbidden; earlier siblings are not in
  e*, so the sibling forbids stay disjoint from e*.
- pack: the candidate sets exclude forbidden qubits; every selected odd row still needs its own qubit of
  e* \ S, which is free, so |S| + p > w still excludes e*; an odd row with no free qubit cannot be completed
  inside e*.
- orbf: the automorphism pi need NOT map K rows to K rows (a verified automorphism preserves rs H and
  rs [H; G], hence F and weights, but not the individual generator rows); the argument only needs pi(e) to be
  a weight-w element of F, and Lemma 2 + Lemma 1 apply to pi(e) directly with the original rows g. Part A of
  the tests uses row sets K that are not invariant under the planted symmetry (random elements of
  ker [H; G]) to exercise exactly this.
- parity: the parity theorem and the per-node check concern |e| and syn(S) only; unchanged.
- leaf: the budget-1 lookup and the budget-2 meet accept only free qubits, so they respect the forbids. With
  the leaf rule on, children of remaining budget 1 (completed by the budget-2 lookup) and 2 (meet nodes, whose
  children are lookups, not counted as nodes) do not update the counters (an implementation shortcut, a sound
  weakening): every closure found below them is a weight-w element of F, hence minimum, and satisfies every
  limit by Lemma 1, so their forbids could only remove closures that do not exist. Node counts are unchanged.
- The syndrome-free-cluster trap (a nontrivial syndrome-free cluster below w) can be hidden by the rule only
  when the precondition is already violated; every witness is still verified by the independent GF(2) test.

*Mutants (must fail; `make test-cc`).* 8: limit floor(|g|/2) - 1 (off by one: a row is tight one qubit early;
2880/19 200 ladders wrong). 9: the parity checks H used as K (3776/19 200). 10: the even-|g| tie cut (2112/19 200).
Statistics (`-cc-stats`): `ovtight` (rows that became tight), `ovforbid` (qubits turned from free to forbidden).
The strict prune is implied by the forbids and never fires, so its count is not printed; the pruning effect is
the node reduction against `-cc-rules=excl,pack,orbf,parity,leaf` (exact, deterministic node counts).
*Evidence.* `optimization/experiments/GH-138/REPORT.md` (Tier 1-4 panel PASS, Tier 5: BB_756/864/1080 lb 28 -> 30).
*Side note (not adopted).* Lemma 1 holds for every element of rs K, not only for the generator rows; adding the
pair sums g1 + g2 whose limit is not implied by the rows (e.g. TN rows of weight 9 sharing 2-3 qubits) cut a
further 0-17 % of the nodes on TN_250 / TN_144 / BB_288 but cost more time than they saved (S0 of GH-138).

GH-140 (`-ub-search=off|on|budget:S`; off by default inside CC). *What it adds.* Per searched half (with a verified
dual map: the X half only, its words mapped to the Z half and verified there too) a `UbFinder` (cc_ubsearch.h). The
driver time-slices it with the level ladder in the same thread: at the top of every ladder iteration and, through
`HalfSearch::set_poll`, every 16 384 search nodes inside a level (`dfs` checks a node-count mask and calls the
callback; returning true unwinds the search like a hit and `run_level` reports `LEVEL_ABORTED`; the search state is
reset at the start of every level, so nothing leaks). The finder is due while its accumulated time (everything spent
inside the poll loop) is below `ub_pre + share * elapsed` (share / 16 after `ub_hits` iterations re-found the current
U without improving it, or after max(64, 4 x the iteration count of the last improvement) iterations without one), and never beyond `ub_cap`. *Why every reported bound stays valid.* (1) Each systematic word
c_j = e_j + sum_i A[i][j] e_{P_i} satisfies H c_j = 0 (reduced row i reads A[i][j] + A[i][j] = 0), so all sums are in
ker H; the finder keeps only words with G c != 0 (nontrivial: with the complete detectors checked at start-up,
ker [H; G] = rs S), and local improvement adds rows g of S, which keeps c in ker H and G c unchanged (G g = 0). (2)
Independently of (1), the driver verifies every word with `verify_in_half` (H e = 0 and e not in rs S by its own
echelon of S), and the dual image in the other half, before it lowers ub_h / U; a failure is a trap (no answer).
(3) The termination rule is unchanged: d = U once LB >= U, where every lb_h comes from the exhaustive levels and U is
the weight of a verified nontrivial logical. Abandoning a level when U <= w leaves lb_h = w unchanged (no bound is
derived from an incomplete level); that half is then never picked again because lb_h >= U. A finder word lighter
than a half's certified lower bound is a contradiction and traps (`lb > ub`), as for CC witnesses. *Tests.*
`make test-cc` Part E: the finder alone on 400 halves (every word in ker H, nontrivial, below the target, >= the
true half distance; same seed gives the same words), the driver with the finder in 8 configurations (pre-pass,
share 0.9 with a poll at every node, late starts that make levels abandoned, dual off, sequential schedule,
`-ub-basis=off`, finder-only), rotated surface codes d = 3, 4 (weight-2 stabilizers lighter than d); mutants 11 (no
detector check: the driver's verification stops the run) and 12 (mutant 11 + no driver verification: wrong answers)
must fail. `make test-cc-flags`: flag values, conflicts, `-v` lines, finder-only output, mutants 11/12 on BB_90_8_10.
*Evidence.* `optimization/experiments/GH-140/REPORT.md`.

GH-144 (`-ub-pre=off|on|S`, split MaxSAT path, `src/core/distqldpc.cc`; off by default). *What it adds.* A pre-pass
(`ub_prepass`) that runs GH-140's `UbFinder` on both halves before `min_distance_css_interleaved` starts Phase 1 (row
above), and four changes to the bound search that apply only when the pre-pass produced a verified word (`seeded`):
Phase 1 keeps probing a half whose only incumbent is a pre-pass word (`h.pre`) but skips every cap c with c >= U - 1
(GH-133 cap rule applied first) and ends when the next doubling cap is >= U - 1; Phase 2a runs while both halves are
unfinished (main: only while their incumbents tie) with feasibility probes at U - 1 (U - 2 on an all-odd-column half
when U - 1 is odd) and pipes the global lower bound min(U, lb of the unfinished halves) after each probe; Phase 2b
optimises each unfinished half with cap U - 1 (main: U). *Why every reported bound and the answer stay valid.*
(1) *The pre-pass bound.* The half instance that every probe of half h solves is, by `build_css_half`, exactly
F_h = {x : Hpar x = 0, Glog x != 0} (XOR rows of Hpar, activation literals a_j = <Glog_j, x> mod 2, the clause OR a_j,
unit soft clauses = Hamming weight). `ubpre_verify` checks Hpar e = 0 and <Glog_j, e> = 1 for some j on the input
matrices, independently of the finder's bit arrays (and `distcc::verify_logical` must agree: Hpar e = 0, e not in
rs S by its own echelon form), so every used word e lies in F_h and d_h <= |e|. Hence U0 = min over the halves of
verified weights satisfies d = min(dX, dZ) <= U0, and "UB U0" is a valid upper bound attained by a witness. The GH-85
orbit clauses preserve, for every w, the existence of a solution of weight <= w, so the instance optimum is d_h as
well; GH-133's parity fact (all column weights odd => every element of ker Hpar has even weight) makes every verified
word of such a half even, so U0 is even when it comes from such a half. A word that fails verification discards the
whole pre-pass (warning on stderr), and the search runs as without the flag. (2) *Lower bounds.* The pre-pass derives
no lower bound. Every lb_h still comes from a NONE of a probe on F_h (no solution of weight <= cap), from GH-133's
parity step, or from GH-107's sharing of proven lower bounds over a verified dual map, all unchanged. Skipping Phase 1
caps >= U - 1 only removes probes. A Phase 2a NONE at cap U - 1 proves that F_h has no element of weight <= U - 1,
i.e. lb_h = U (at cap U - 2 on an all-odd half with U - 1 odd: no element of weight <= U - 2 and none of odd weight
U - 1); a Phase 2b NONE at cap U - 1 proves the same, and an OPT v < U is the optimum of F_h. The lower bound piped
after a Phase 2a probe, min(U, lb_h of the unfinished halves), is at most min_h lb_h <= d because every finished half
has lb_h >= the U at which it finished >= the current U. LBs are piped only when they increase (monotone). (3)
*Termination.* The run returns U when both halves are finished, i.e. every half has lb_h >= U (NONE at U - 1) or has
its optimum computed; then d >= U, and U is attained (a verified pre-pass word or a solver solution), so d = U - the
same final argument as main's. A FOUND / OPT below U in any phase is a solver solution, which lowers U exactly as in
main. (4) *GH-107.* Shared lower bounds are still proven NONE bounds; with a verified dual map dX = dZ <= U, so a
shared lb > U remains a contradiction (no answer), as before. (5) *Timing and semantics.* The pre-pass counts toward
`-cpu-lim`; it uses wall time only through the cap S; the encoding, the cardinality constraints, the solver and the
output format are unchanged; without the flag (or `-ub-pre=off`) no line of the `-v` log changes. *Tests.* `make
test-cc` Part F: the MaxSAT driver with the pre-pass on the 200 random Part B codes (exhaustive enumeration as the
oracle) in 8 configurations (budget 1 s; pre-passes cut after 1-3 iterations, so U0 > d on 180 of 1 600 runs and
Phase 1 FOUND / Phase 2a FOUND / Phase 2b OPT below a seeded U are exercised; `-oddcap-skip=off`, `-seed=5`,
`-dualmode=off`, `-dualmode=skip`, `-no-symbreak`, `-card-mto`): RESULT = enumeration, every UB >= d, LBs monotone <= d;
test mutant 1 (finder without its detector check: trivial words reach the verification and must be rejected; answers
stay correct) and mutant 2 (mutant 1 + words used unverified: wrong answers on the codes and on rotated surface codes
d = 3..5). `make test-cc-flags`: values, conflicts (`-engine=cc`, `-joint`, `-roundingsat`, tuning flags without
`-ub-pre`), `-v` lines, the first `c d_ub` line, the probe caps on BB_90_8_10, no output with `-ub-pre=off`.
*Evidence.* `optimization/experiments/GH-144/REPORT.md`.

GH-146 (`-ub-isd=off|stern|dumer[:P,L,W,B,R]`, `src/cc/cc_ubsearch.{h,cc}`; off by default). *What it adds.* A second
enumeration inside `UbFinder::iterate` for both users of the finder (CC `-ub-search`, MaxSAT `-ub-pre`); the drivers,
their schedules, stop rules and verification are unchanged. Written from the published algorithms (Stern 1988;
Dumer's and Finiasz-Sendrier's split with an overlapping window; the Canteaut-Chabaud random walk on information
sets); no third-party code was read. *Why every word is still a nontrivial logical.* (1) *Systematic invariant.* After
the first random elimination the finder stores, for each information column j, the column A_j of the reduced matrix
over the r pivot rows, so c_j = e_j + sum_i A[i][j] e_{P_i} is in ker H (row i reads A[i][j] + A[i][j] = 0). A
Canteaut-Chabaud swap picks an information column j with A_j != 0 and a pivot row i with A[i][j] = 1 and performs the
GF(2) row operations "add row i to every other row with a 1 in column j": column j becomes the unit vector e_i (the
new pivot of row i), the old pivot column P_i takes the vector A_j (it now has a 1 in row i and in every row that
received row i), and every other information column j' with A[i][j'] = 1 gets A_j' + A_j + e_i. Row operations keep
the row space of the reduced matrix equal to that of H, so the invariant (identity on the pivots, ker H spanned by
the c_j) holds after any number of swaps; `build_word` reconstructs a word from its information indices with the
current columns and pivots. (2) *Collision.* A colliding pair contributes the word sum_{j in T1 u T2} c_j (T1, T2
disjoint sets of information indices), which is in ker H by (1); in Dumer mode a window element contributes only to
the key and never to the word, so the word is still a sum of c_j. The weight used for the threshold is |T1| + |T2| +
|sum A_j| (exactly the word's weight). The detector-parity precheck skips pairs whose words have G c = 0 (trivial);
it is an optimization (a skipped word could only be trivial), and every kept word still passes the same check as in
GH-140 (G c != 0, computed from the cached detector parities of the c_j) before local improvement by rows of S (G g =
0, H g = 0: same logical class). (3) *Independent verification.* Unchanged: the CC driver verifies every word with
`verify_in_half` (H e = 0, e not in rs S by its own echelon form; with a dual map also the image) before it lowers
ub_h / U, and the MaxSAT pre-pass with `ubpre_verify` (H e = 0 and Glog e != 0 on the input matrices, plus
`distcc::verify_logical`); a failure traps (CC) or discards the pre-pass (MaxSAT). So no lower bound and no answer
depends on the collision step; it only changes which verified words are found and when. *Determinism.* The swaps,
splits and windows come from the finder's seeded splitmix64 stream, so the word sequence is fixed per `-seed` (the
pre-pass, being iteration based, stays deterministic). *Tests.* `make test-cc`: six collision configurations (Stern /
Dumer, P 1 and 2, windows automatic / 0 / 2 / 3, walks 0 / 1 / 8 / 32, batches 1-3, refresh 5) on the 400 Part B
halves (every word in ker H, nontrivial, below the target and >= the true half distance; same seed, same words; d_h
reached on >= 90 % of the halves is required, 400/400 observed), mutant 11 in collision mode (trivial words returned),
the CC driver in collision mode (pre-pass, late start, finder-only; mutant 11 must trap, mutant 12 - words reported
without verification - must answer wrongly), the MaxSAT pre-pass in collision mode (budget 1 s, cut after 2
iterations; mutant 1 stays correct, mutant 2 must answer wrongly) and rotated surface codes. `make test-cc-flags`:
values, conflicts (`-ub-isd` without a finder), `-v` lines, finder-only output, mutants 11/12 with `stern` and
`dumer` on BB_90_8_10. *Evidence.* `optimization/experiments/GH-146/REPORT.md`.

Fix round 1 (S0a): the S0 spec's literal mutants 3 ("orbit seeds without forbidding earlier orbits") and 4 ("stop
rule without checking the other half's lower bound") are equivalent mutants as built: the first only drops a
restriction, so every level verdict stays exact; the second skips a check that the lockstep pick order (lowest
lower bound first; a mirrored dual half has lb = w) always satisfies at a hit. Neither could ever change an answer,
so the S0a gate "every mutant must fail" could not be met. Mutant 3 is now the orbit-rule off-by-one (O_1..O_i
forbidden while r_i is searched) and mutant 4 runs under the sequential schedule, where the skipped check matters.

---

## MaxCDCL engine patches (`src/solver/`)

These are modifications to upstream MIT code. Original copyright headers
in each file are unchanged.

### `Solver.h` / `Solver.cc`

#### Retired soft literals after preprocessing partition (GH58)

After partition replaces a conflicting soft set with its existing aggregate
representative, remove inactive entries from both unit and non-unit soft-literal
lists. Previously only the unit list was compacted, allowing initial lookahead
to enqueue `lit_Undef` from a retired auxiliary member. Preserve the existing
representative clauses, derived-cost accounting and surviving order; rebuild
heaps when either list loses members. This is a downstream correctness repair,
not a change to MaxSAT costs or quantum-code distance semantics. See
`optimization/investigations/GH58/` for the original failure and validation.

#### Bounds pipe (search progress → parent process)

- `setBoundsPipe(int write_fd)` — attach write end of pipe
- `emitTryUpdate(uint64_t)` — write `TRY <n>\n` at start of each outer UB iteration
- `emitBoundsUpdate()` — write `LB <n>\n` / `UB <n>\n` on bound changes
- `getCostLB()` / `getCostUB()` — accessors for current bounds
- `hasCostLB()` / `hasCostUB()` — whether bounds are known
- Member: `bounds_pipe_w`

#### Best solution on timeout / interrupt

- `noteBestSolution(uint64_t unsatSoft)` — track improving incumbent
- `printBestSolution()` — print best MaxSAT assignment found so far
- `getLastOptimalCost()` — last proven optimal cost when search completes
- Members: `bestSolutionFound`, `bestSup`, `lastOptimalCost`

#### Cardinality encoding modes

- Enum `CardinalityEncMode`: `OFF`, `BOTH`, `SINZ`, `MTO`, `BOTH_FORCE`
- Member: `cardinalityEncMode` (default `BOTH`)
- `addCardinalityConstraints()` respects mode:
  - `OFF` — soft-conflict only, no Sinz/MTO CNF
  - `SINZ` / `MTO` — single encoding
  - `BOTH` — Sinz if active soft lits ≤ 100, always MTO
  - `BOTH_FORCE` — Sinz + MTO regardless of problem size

#### Solve loop hooks

- Call `emitTryUpdate(UB)` when testing a new upper-bound candidate
- Call `emitBoundsUpdate()` after LB/UB updates
- Call `noteBestSolution()` when a better incumbent is found

#### Multi-instance search controls (GH-73)

- `initLB`, `strictUB`, `startAtCap`, `stopAtFirstSolution`: a known lower bound, a hard cap, starting
  at the cap, and feasibility-only runs, used by the interleaved CSS split
- `boundsLbCap`, `boundsUbCap`, `boundsHideLB`: emitted bounds are capped/suppressed to stay global
- Former function-local `static` heuristic state in `search()`, `lookahead()` and
  `addCardinalityConstraints()` is now per-instance (identical behaviour for a single instance)

---

## Files not modified for DistQLDPC integration

The following are included from upstream with headers intact but without
DistQLDPC-specific functional changes (as of this document):

- `SimpSolver.h`, `SimpSolver.cc`
- `SolverTypes.h`, `Dimacs.h`
- `mtl/*`, `utils/*`
- Legacy entry points: `Main.cc`, `glucose_Main.cc` (not built by root Makefile)

If you add further patches, extend this file and mention them in `NOTICE`.

---

## Contributing patches back to upstream

DistQLDPC-specific integration code (fork, QLDPC encoding, CLI) belongs
in `src/core/` under GPL.

Generic solver improvements that could benefit MaxCDCL users may be
offered to upstream under MIT, consistent with `src/solver/LICENSE`.
