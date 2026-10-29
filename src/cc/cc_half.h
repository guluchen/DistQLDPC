/*
 * DistQLDPC — connected-cluster (CC) level search for one CSS half (GH-124, experimental).
 *
 * Copyright (C) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Clean-room implementation written from the mathematics below and from DistQLDPC's own code
 * (Dumer, Kovalev, Pryadko, "Distance verification for classical and quantum LDPC codes",
 * IEEE Trans. Inf. Theory 63(7), 2017). No third-party code.
 *
 * Half (one Pauli type, n qubits): parity checks H (rows of 0/1) and detector rows G.
 *   F = { v : H v = 0, G v != 0 }   (G v != 0: odd overlap with some row of G).
 *   X half: H = Hz, G = Gx.   Z half: H = Hx, G = Gz   (DistQLDPC's convention, see CssHalf).
 *
 * Level w (precondition, guaranteed by the driver: F has no element of weight < w):
 *   decide whether F has an element of weight exactly w.
 *
 * Exactness. Qubits are adjacent iff they share a row of H. Let e in F with |e| = w = min weight.
 *  (1) For every nonempty proper subset S of e, syn(S) = H S != 0: otherwise S and e\S are both in
 *      ker H, G S + G (e\S) = G e != 0, so one of them is in F and lighter than e.
 *  (2) Hence every odd row of S contains an odd number >= 1 of qubits of e\S (syn(e) = 0), so a
 *      cluster grown from a seed in e by adding, at each step, one qubit of ONE odd row of S can
 *      always reach e; the branch over all candidates of that row contains a branch inside e.
 *  (3) A syndrome-free cluster S with |S| < w is a dead end (by (1) it is not a proper subset of a
 *      minimum-weight element; and it is not itself in F, since that would contradict the
 *      precondition -- the search reports that case as an inconsistency, a driver trap).
 *  Rules (each keeps at least one element of F of weight w reachable):
 *   excl  sibling exclusion: after the branch that adds qubit a at a node is exhausted, a is
 *         forbidden in the later sibling branches of that node (restored on backtrack). If e
 *         extends the node, the first candidate (in branch order) that lies in e is kept, and only
 *         earlier siblings, which are not in e, become forbidden.
 *   pack  disjoint odd-row packing: greedily select odd rows (index order) whose candidate sets
 *         (qubits not in S and not forbidden) are pairwise disjoint; each selected row needs its
 *         own qubit of e\S, so |S| + p > w prunes; an odd row with no candidate is a dead end.
 *   orbf  orbit seeds: with verified per-half orbits O_1..O_k (GH-85, find_half_symmetry; ordered
 *         by representative), seed only r_i in O_i and forbid every qubit of O_1..O_{i-1}. Every
 *         e in F can be moved by a verified automorphism (weight and F preserved) so that its
 *         first met orbit O_j contains r_j in its support and it avoids O_1..O_{j-1}. Replaces the
 *         index rule (seed s, qubits q < s forbidden), which is used without orbits.
 *   mrv   branch on the odd row with the fewest candidates (default: the lowest-index odd row).
 *   parity (GH-133) even-weight shortcut, active only when EVERY column of H (every qubit's number
 *         of rows, empty rows dropped) is odd. Then for every vector v,
 *             sum_i (H v)_i = sum_j colwt_j v_j = |v|  (mod 2),
 *         i.e. wt(syn(S)) = |S| (mod 2) for every cluster S, and every element of ker H (every
 *         element of F) has even weight. (a) Every odd level is empty: run_level(w) with w odd
 *         returns EMPTY without a search, and the driver does not even call it (an EMPTY level 2t
 *         certifies the lower bound 2t+2). (b) At a node with |S| = s, syndrome weight nodd and
 *         target w the number r = w - s of qubits still to add satisfies r = nodd (mod 2), since
 *         syn(e \ S) = syn(S) and wt(syn(e \ S)) = |e \ S| (mod 2); a mismatch prunes. For even w
 *         the invariant wt(syn(S)) = |S| (mod 2) makes (b) hold automatically (r = w - s = s = nodd
 *         mod 2), so (b) never prunes on a half that qualifies: it is a free consistency check whose
 *         only effect is on the parity mutant (below). Adding 1 to any lower bound L on r whose
 *         parity differs from nodd (L' = L + 1) is likewise implied: r = L is excluded by the
 *         parity of r, so L' > r iff L > r. The gain of the rule is therefore the level skip alone.
 *   leaf  (GH-133; dist-m4ri's "last column must equal the syndrome" idea) at remaining budget 1
 *         the cluster closes iff syn(S) equals the column of a qubit a that is free (not in S, not
 *         forbidden): a hash from column to qubits replaces the branch; at budget 2, for each
 *         candidate a of the branching row (in branch order, sibling exclusion as usual) the cluster
 *         closes iff syn(S) + col(a) is the column of a free qubit b: a lookup replaces the recursion.
 *         Closures are accepted only when the detector parity of the closed cluster is nonzero
 *         (nontrivial), exactly as the branching leaf does; a syndrome-free S + a of weight w - 1 is
 *         handled as the branching does (dead end, or inconsistency if nontrivial). The verdict of
 *         every node is unchanged (the lookup enumerates exactly the closing children).
 *   overlap (GH-138; J. Y. Lee, arXiv:2610.06820, rule (iv), plus DistQLDPC's forbidding) with K = rows of the
 *         half's STABILIZER generators (X half: rows of Hx; Z half: rows of Hz; every row g satisfies H g = 0 and
 *         G g = 0, checked at construction). For e in F and g in K, e + g is in ker H with G(e + g) = G e != 0, so
 *         e + g is in F and |e + g| = |e| + |g| - 2|e & g|. Under the level precondition every element of F of
 *         weight w is of minimum weight, hence |e & g| <= lim_g = floor(|g|/2) for every g (else e + g is
 *         lighter). A node S has an extension e of weight w in F only if |S & g| <= |e & g| <= lim_g, and if
 *         |S & g| = lim_g then e & g = S & g: every qubit of g \ S is outside every such e. The rule keeps the
 *         counters ov_g = |S & g| incrementally and, when ov_g reaches lim_g, forbids g \ S for the subtree
 *         (rows with lim_g = 0, i.e. |g| = 1, are forbidden from the start); the forbidden qubits leave the
 *         candidate lists and the packing bound. The strict prune |S & g| > lim_g is implied (no forbidden qubit
 *         is ever added). Exactness: no node that is a subset of ANY weight-w element of F is pruned, and no such
 *         element meets a qubit forbidden by the rule, so every argument of the other rules (which keep one
 *         chosen weight-w element e* reachable with S a subset of e* and no forbidden qubit in e*) is unchanged.
 *         The even-|g| tie (|e & g| = |g|/2, e + g of equal weight) is NOT cut: lim_g = |g|/2 allows it; cutting
 *         it would drop both e and e + g (mutant 10). With the leaf rule, children of remaining budget 1 or 2
 *         (whose subtrees are lookups only) skip the counter updates: a closure found there is a weight-w element
 *         of F and meets every limit by itself. Full proof: MODIFICATIONS.md (GH-138).
 *   tiebreak (GH-162, default off, acts only with overlap; the first(g) tie-break idea of Qubitserf 04b9349, S.
 *         Cercelescu, MIT, re-derived here) cuts the even-|g| tie soundly. Seeds r_1, r_2, .. with blocks O_1, O_2, ..
 *         (orbits, or single qubits under the index rule); while r_i is searched, O_1..O_{i-1} are forbidden. For each
 *         seed fix a total order pi_i whose FIRST qubit is r_i (here: r_i, then the qubits of O_1..O_{i-1} in block
 *         order, then the rest in descending relabeled label), and compare supports by e <_i e' iff the pi_i-first qubit
 *         of e (+) e' lies in e. (A) Let j be the smallest index such that some weight-w element of F contains r_j and
 *         avoids O_1..O_{j-1} (j exists: move any element by a verified automorphism so that its first met block's
 *         member becomes the representative). Then EVERY weight-w element of F avoids O_1..O_{j-1}: an element meeting
 *         O_i, i < j, could be moved into the set of index i (its first met block), contradicting the choice of j.
 *         (B) Let e* be the <_j-least weight-w element of F. Some element contains r_j, the pi_j-first qubit, so e* does;
 *         by (A) e* avoids O_1..O_{j-1}: e* is a target of seed r_j. (C) For every even row g of K with
 *         |e* & g| = |g|/2, first_j(g) is in e*: otherwise e* + g (in F, weight w, differs from e* exactly on g) contains
 *         first_j(g) and is <_j e*. Hence |e* & g'| <= |g|/2 - 1 = floor(|g'|/2) for g' = g \ {first_j(g)}: while r_j is
 *         searched, the rule counts g' with the limit |g|/2 - 1 and the ordinary overlap forbidding (g' \ S once
 *         tight; first(g) stays free); no node S inside e* is pruned and no qubit of e* is forbidden. A first(g) in
 *         O_1..O_{j-1} (forbidden) makes the tie impossible, which (C) also covers. Every other rule keeps an ARBITRARY
 *         fixed weight-w target reachable (excl: only siblings outside the target before its first candidate are
 *         forbidden; pack/leaf/mrv/parity: counting and lookups over free qubits; overlap: every weight-w element
 *         satisfies the limits) except the seed rule, which needs (A)+(B). So seed r_j finds an element of weight w
 *         (unless an earlier seed already did; every hit is a genuine element, checked). Seeds other than r_j may prune
 *         anything: a FOUND is always genuine and the level is decided by r_j's search. The orders differ between seeds
 *         (one global order is not needed); the relabeling (-cc-seed) only changes the labels. The dual map and the stop
 *         rule act between halves and are unaffected. An order that does not put r_i first breaks (B) (mutant 18).
 *         Full proof: MODIFICATIONS.md (GH-162).
 *   erasure (GH-195, default off; the erasure bound idea of Qubitserf 04b9349, S. Cercelescu, MIT, re-derived here) needs pack.
 *         At a node S whose packing scan found disjoint odd rows j_1..j_p with free candidate sets R_1..R_p, let R be their
 *         union, E the free qubits outside R (free: not in S, not forbidden) and extra = (w - |S|) - p. Any target e* kept
 *         by the other rules (S subset of e*, e* disjoint from the forbidden set, e* in F, |e*| = w) has an odd number >= 1
 *         of qubits of e* \ S in each packed row (odd in syn(S), even in syn(e*)), all free, hence in the disjoint R_i:
 *         |(e* \ S) \ R| <= extra. So e* = S + y + z with y a subset of R, z a subset of E, |z| <= extra. With extra <= 2
 *         the rule decides the relaxation "some y subset of R, z subset of E, |z| <= extra with H_R y = H(S + z) and
 *         G(S + z + y) != 0" (no weight condition on y) and prunes when there is none. Decision: the columns of R are
 *         eliminated (peeling of rows with one region qubit, then dense elimination of the rest with the detector labels
 *         carried along). If ker H_R holds a y with G y != 0 the rule gives up. Otherwise back-substitution on the pivot
 *         rows gives, exactly, a 64-lane vector phi with phi H_R = 0 (the leaf rule's random row keys on the other rows)
 *         and a map F with F H_R = G_R (full-width labels); then for every v: phi.Hv != 0 implies H v outside colspace(H_R),
 *         and H v = H_R y implies G(v + y) = G v + F H v. The node is pruned iff every z has phi.H(S + z) != 0 or
 *         G(S + z) + F H(S + z) = 0 (singles through the leaf hash table, pairs through a pair table keyed by XOR of column
 *         keys, built lazily; qubits on a pivot row are projected explicitly). A fingerprint collision only makes the rule give up.
 *         The rule never prunes a node that is a subset of a kept target, so every other rule's argument (and tiebreak's
 *         Lemmas A-C) is unchanged. Gate (cost only): extra <= 2 and |R| <= 128 (Qubitserf also requires 2|S| + 2 <= w; that
 *         size gate was measured as slower on every Tier 2-5 code tried, optimization/experiments/GH-195). Full proof: MODIFICATIONS.md
 *         (GH-195).
 */
#ifndef DISTQLDPC_CC_HALF_H
#define DISTQLDPC_CC_HALF_H

#include <stdint.h>
#include <vector>

namespace distcc {

/* 0/1 matrix as row supports (column indices); cols = number of qubits. */
struct SparseRows {
    int cols;
    std::vector<std::vector<int> > rows;
    SparseRows() : cols(0) {}
};

struct Rules {
    bool excl, pack, orbf, mrv, parity, leaf, overlap;
    bool tiebreak;   /* GH-162 (default off; acts only with overlap) */
    bool erasure;    /* GH-195 (default off; acts only with pack) */
    Rules() : excl(true), pack(true), orbf(true), mrv(false), parity(true), leaf(true), overlap(true), tiebreak(false),
              erasure(false) {}
};

/* LEVEL_ABORTED (GH-140): the poll callback asked to stop (the level is undecided; lb unchanged) */
enum LevelVerdict { LEVEL_EMPTY = 0, LEVEL_FOUND = 1, LEVEL_INCONSISTENT = 2, LEVEL_ABORTED = 3 };

struct LevelResult {
    LevelVerdict verdict;
    uint64_t nodes;            /* search nodes (one per visited cluster, leaves included) */
    uint64_t seeds;            /* seeds started */
    uint64_t closed;           /* syndrome-free dead ends below the level */
    uint64_t nocand;           /* odd row without candidate (pack) */
    uint64_t packprune;        /* |S| + packing > w */
    uint64_t parprune;         /* parity: w - |S| != wt(syn) mod 2 (never on a qualifying half, see cc_half.h) */
    uint64_t leaf1, leaf2;     /* leaf: budget-1 lookups; budget-2 lookups (one per candidate a) */
    uint64_t ovtight;          /* overlap: a stabilizer row reached |S & g| = floor(|g|/2) (rest of g forbidden) */
    uint64_t ovforbid;         /* overlap: qubits turned from free to forbidden by those events */
    uint64_t ercalls, erprune; /* erasure (GH-195): tests run; nodes pruned */
    uint64_t ergiveup;         /* erasure: tests abandoned because ker H_R holds a detected vector */
    bool skipped;              /* parity: odd level, EMPTY without a search */
    std::vector<uint64_t> by_budget;   /* nodes by remaining budget w - |S| (index 0..w; diagnostic, -cc-stats) */
    std::vector<int> witness;  /* FOUND / INCONSISTENT: support in ORIGINAL qubit labels, ascending */
    LevelResult() : verdict(LEVEL_EMPTY), nodes(0), seeds(0), closed(0), nocand(0), packprune(0), parprune(0),
                    leaf1(0), leaf2(0), ovtight(0), ovforbid(0), ercalls(0), erprune(0), ergiveup(0), skipped(false) {}
};

/* Test-only mutants (-cc-mutant=K), each able to change an answer: 1 sibling-exclusion forbidden set not
 * restored on backtrack; 2 packing prune uses >= instead of >; 3 orbit seed rule off by one (while r_i is
 * searched, O_1..O_i instead of O_1..O_{i-1} are forbidden, apart from r_i itself; no effect without
 * orbit seeds); 4 is a driver mutant (cc_driver.h); 5 parity rule applied although a column weight is even
 * (odd levels skipped and the parity check used on a half where the invariant fails); 6 leaf budget off by
 * one (the budget-2 meet is used at budget 3, so no cluster needing three more qubits is ever closed);
 * 7 leaf closures accepted without the detector check (trivial closures reported as found); GH-138 overlap
 * mutants: 8 limit off by one (floor(|g|/2) - 1: a row is tight one qubit early), 9 the parity checks H used as K
 * (rows of H are not in ker H in general), 10 the even-|g| tie cut (limit |g|/2 - 1 for even |g|, which loses
 * both e and e + g when |e & g| = |g|/2). GH-162 tiebreak (13 and 14 are GH-152's, 15 and 16 are reserved for GH-157):
 * 17 the naive tie cut through the tiebreak rule (every even row keeps first(g) and gets the limit |g|/2 - 1), 18
 * the seed is not put first in the tie-break order (first(g) is taken in the base order also on the rows through the
 * seed, where the seed comes last: an orbit-incompatible order). GH-195 erasure (19-21 are used by the open GH-181 / GH-183
 * branches): 22 the bound weakened by one (at most extra - 1 outside qubits are enumerated; the gate admits extra <= 3),
 * 23 the fixed support S ignored (the completion is asked for without S).
 * (GH-124 fix round 1: the S0 spec's literal mutant 3, "orbit seeds without forbidding earlier orbits", only
 * drops a restriction and is a sound weakening that can never change a level verdict, so it was replaced by
 * this non-equivalent orbit-rule mutant. GH-133: the spec's literal leaf mutant, "leaf lookup ignoring the
 * forbidden set", is likewise a sound weakening: a forbidden closing qubit gives a genuine element of F
 * (correct FOUND), and a closing qubit already in S gives a syndrome-free set of weight w - 2 < w, which is
 * trivial under the level precondition and is rejected by the detector check. Mutants 6 and 7 replace it.) */
class HalfSearch {
public:
    /* H, G: the half's parity checks and detector rows (n = H.cols columns). orbit_of: per ORIGINAL
     * qubit the orbit id of the verified half automorphism group (empty: none). relabel_seed != 0
     * relabels qubits and rows deterministically (testing hook -cc-seed). K (GH-138, rule overlap): rows of
     * the half's stabilizer generators, each with H g = 0 and G g = 0 (checked; NULL or no rows: rule idle). */
    HalfSearch(const SparseRows& H, const SparseRows& G, const std::vector<int>& orbit_of,
               const Rules& rules, uint64_t relabel_seed, int mutant, const SparseRows* K = NULL);

    /* Level w >= 1 (precondition: no element of F of weight < w). */
    LevelResult run_level(int w);

    /* GH-140: poll callback, called when (nodes & mask) == 0 during run_level (default mask 0x3FFF: every 16384
     * search nodes; tests use 0); returning true aborts the level (verdict LEVEL_ABORTED, search state reset). NULL
     * (default): never called. The callback must not call back into this object. The search itself (node order,
     * verdicts) does not depend on the callback. */
    void set_poll(bool (*fn)(void*), void* ctx, uint64_t mask = 0x3FFF) { poll_fn_ = fn; poll_ctx_ = ctx; poll_mask_ = mask; }

    int n() const { return n_; }
    bool orbit_seeds() const { return orbit_mode_; }
    int num_seeds() const { return (int)seed_.size(); }
    /* parity rule: every column weight odd (nonempty rows only); min/max column weight for reports */
    bool all_odd_columns() const { return allodd_; }
    int min_col_weight() const { return mincw_; }
    int max_col_weight() const { return maxcw_; }
    /* the parity rule is in force on this half (rule on and all columns odd; mutant 5: rule on) */
    bool parity_active() const { return par_; }
    /* overlap rule (GH-138): in force (rule on and K has a nonempty row); K rows used (deduplicated), their
     * weight range, and the number of rows whose qubits are forbidden from the start (limit 0) */
    bool overlap_active() const { return ovr_; }
    int overlap_rows() const { return nk_; }
    int overlap_min_weight() const { return kminw_; }
    int overlap_max_weight() const { return kmaxw_; }
    int overlap_zero_rows() const { return kzero_; }
    /* tiebreak (GH-162): even rows replaced by g \ {first(g)} (before deduplication) */
    int tiebreak_rows() const { return ktie_; }
    /* erasure (GH-195): in force (rule and pack on); a pair table may be built (n <= 2048, lazily; otherwise pairs by a scan) */
    bool erasure_active() const { return er_; }
    bool erasure_pair_table() const { return n_ >= 2 && n_ <= 2048; }
    /* test hooks: sizegate = run the test only when also 2|S| + 2 <= w (a cost gate; fewer prunes, still sound);
     * verify = check phi H_R = 0 and F H_R = G_R on every region column (fatal on failure) */
    void set_erasure_test(bool sizegate, bool verify) { er_sizegate_ = sizegate; er_verify_ = verify; }

private:
    int n_, m_, k_, kw_, mw_, maxrow_;
    Rules rules_;
    int mutant_;
    bool orbit_mode_;
    bool allodd_, par_;
    int mincw_, maxcw_;
    std::vector<uint32_t> rstart_, rq_;     /* rows -> qubits (relabeled, ascending) */
    std::vector<uint32_t> cstart_, cr_;     /* qubit -> rows (relabeled) */
    std::vector<uint64_t> gmask_;           /* qubit -> detector rows mask (kw_ words) */
    std::vector<int> to_orig_;              /* relabeled qubit -> original qubit */
    std::vector<int> seed_;                 /* seeds (relabeled), in order */
    std::vector<uint32_t> bstart_, block_;  /* qubits forbidden after seed i is exhausted */
    /* leaf: Zobrist keys (row -> key, qubit -> XOR of its rows' keys) and an open-addressing table from
     * key to the first qubit with that key; hnext_ chains the qubits with equal keys (ascending) */
    std::vector<uint64_t> rowkey_, colkey_;
    std::vector<int32_t> htab_, hnext_;
    uint64_t hmask_;
    /* overlap (GH-138): stabilizer rows (relabeled, ascending), qubit -> rows, per-row limit and counter */
    bool ovr_;
    int nk_, kminw_, kmaxw_, kzero_, ktie_;
    std::vector<uint32_t> kstart_, kq_;
    std::vector<uint32_t> kcstart_, kcr_;
    std::vector<int> klim_;
    std::vector<int32_t> slack_;            /* per row: lim_g - |S & g| (0: tight, the rest of g forbidden) */
    /* tiebreak (GH-162): rule in force (not under mutant 17); base order rank per qubit (smaller = earlier); per row the
     * exempt qubit first(g) for the current seed and in the base order (-1: odd row or rule off) */
    bool tb_;
    std::vector<uint32_t> tbrank_;
    std::vector<int32_t> kex_, kexbase_, kexfb_;   /* kexfb_: exempt qubit in an exhausted seed block (-1: none yet) */
    uint64_t ovtight_, ovforbid_;           /* per-level counters (copied into the LevelResult) */
    /* erasure (GH-195): scratch for one test (see erasure_excludes) */
    bool er_, er_sizegate_, er_verify_;
    std::vector<uint32_t> prow_;            /* packed rows of the current scan */
    int np_;
    std::vector<uint32_t> ereg_;            /* region qubits */
    std::vector<int32_t> ecnt_;             /* per row: unpeeled region qubits in it (0 outside a test) */
    std::vector<uint32_t> esole_;           /* per row: XOR of those qubits */
    std::vector<uint32_t> etouch_, equeue_;
    std::vector<uint32_t> epq_, epr_;       /* peeled qubits and their pivot rows, in peel order */
    std::vector<uint64_t> eqs_;             /* per qubit stamp: peeled (== estamp_) or affected (== estamp_ + 1) */
    std::vector<uint64_t> erows_;           /* per row stamp: phi/F assigned in this test */
    uint64_t estamp_;
    std::vector<uint64_t> ebas_, eblab_;    /* dense basis: rank x mw_ (rows), rank x kw_ (labels) */
    std::vector<uint32_t> epiv_;
    std::vector<uint64_t> ecol_, elab_;     /* scratch column / label */
    std::vector<uint64_t> ephi_, eF_;       /* per row: phi (rowkey_ outside a test), F (m_ x kw_, zero outside a test) */
    std::vector<uint32_t> echg_;            /* rows assigned in this test */
    std::vector<uint32_t> eaff_;            /* eligible qubits on an assigned row */
    std::vector<int32_t> eidx_;             /* per affected qubit: its index in eaff_ */
    std::vector<uint64_t> eah_, eal_;       /* their projections (hash; label kw_ words) */
    std::vector<int32_t> etab_, enext_;     /* affected pairs: hash table (open addressing) -> chain of equal hashes */
    std::vector<uint64_t> etabst_;          /* per slot: stamp (== estamp_: in use) */
    std::vector<uint64_t> etl_;             /* target label (kw_ words) */
    std::vector<int32_t> phead_, pnext_;    /* pair table: bucket by (colkey a ^ colkey b) -> pairs (a < b) */
    std::vector<uint32_t> pa_, pb_;
    uint64_t pmask_, epscan_;               /* epscan_: tests that reached the pair stage without the table */

    /* search state */
    int w_;
    std::vector<uint64_t> syn_;             /* odd rows of S */
    int nodd_;
    uint64_t synkey_;                       /* Zobrist key of syn_ (leaf) */
    std::vector<uint64_t> gpar_;            /* detector parities of S */
    std::vector<uint32_t> blk_;             /* > 0: in S or forbidden */
    std::vector<uint64_t> mark_;            /* packing stamp (64-bit, never wraps) */
    uint64_t stamp_;
    std::vector<int> cur_;                  /* S as a stack */
    std::vector<uint32_t> cand_;            /* per-depth candidate buffers */
    LevelResult* res_;
    bool incons_;
    bool (*poll_fn_)(void*);                /* GH-140 poll callback (NULL: none) */
    void* poll_ctx_;
    uint64_t poll_mask_;
    bool abort_;

    void toggle(int q);
    void ov_add(int q);
    void ov_del(int q);
    void ov_add_tb(int q);
    void ov_del_tb(int q);
    void tb_set(uint32_t g, int32_t x);
    void tb_seed(int s, bool on);
    void tb_block_done(size_t bi);
    bool gpar_nonzero() const;
    bool gpar_nonzero_with(int q) const;
    bool column_is_syndrome(int q) const;
    int closing_qubit() const;              /* free qubit whose column equals syn_ with a nontrivial closure, or -1 */
    int key_head(uint64_t key) const;       /* first qubit of the leaf hash chain with colkey_ == key, or -1 */
    bool erasure_excludes(int extra, uint64_t st);
    void erasure_pair_table_build();
    template <int KW> bool erasure_test(int extra, uint64_t st);
    bool dfs(int size);
    void record_witness(int size);
};

} /* namespace distcc */

#endif
