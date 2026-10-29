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
 *   sparse (GH-181, opt-in) redundant sparse checks. R = the distinct pair sums r = h1 + h2 of rows of H with
 *         0 < |r| <= max(|h1|, |h2|), not equal to a row of H (deduplicated; at most 4 m rows, lightest first, ties by
 *         the sorted original support). Every r in R lies in the row space of H (checked at construction by
 *         recomputing h1 + h2), so r.e = 0 for EVERY e in ker H. Every argument that uses an odd row h of S only
 *         through "h.e = 0 for every e in ker H" therefore holds for an odd r of R as well: r.(e \ S) = r.S = 1, so
 *         e \ S meets r. Used in: pack (after the odd rows of H, in R's order, with the same disjointness test, so the
 *         packing of a node can only grow: every node pruned without the token is pruned with it), the
 *         no-candidate dead end (an odd r with no free qubit), mrv (the branch over the free qubits of an odd r
 *         contains a branch inside e, exactly as in (2)), and xorunit. NOT used for: syndrome-freeness (nodd, the
 *         size-w test), parity (column weights and wt(syn) are those of H), the leaf lookup (columns of H) and
 *         overlap (rows of H are stabilizers of the other type, not elements of ker H: test mutant 9). Credit:
 *         Qubitserf 04b9349 augment_sparse_checks (S. Cercelescu, MIT; idea only, no code), Puchert and Tillmann,
 *         arXiv:2004.03387 (forbidden-set cuts from redundant parity checks).
 *   sparseov (GH-181, opt-in) redundant stabilizer rows for overlap: the distinct pair sums g = g1 + g2 of rows of K
 *         with 0 < |g| <= max(|g1|, |g2|), not equal to a row of K (at most 4 |K| rows, same order rule). Each satisfies
 *         H g = 0 and G g = 0 (checked with K's rows), so e + g is in F and the GH-138 argument applies with g's own
 *         limit floor(|g|/2). Counted separately (ovtightx).
 *   xorunit (GH-181, opt-in) XOR unit propagation at every node of remaining budget >= 2, to a fixpoint, over the rows
 *         of H (and of R with sparse). Let e be any element of ker H with S a subset of e and no forbidden qubit in e
 *         (every rule above keeps its chosen target e* of this kind), and u a row with exactly one free qubit q.
 *         (a) u even (u.S = 0): u.(e \ S) = 0 and e \ S meets u at most in q, so q is not in e: q is forbidden for the
 *         subtree (restored on return). (b) u odd: e \ S meets u, so q is in e; u becomes the branching row (one
 *         child; complete by (2)). (c) u odd with no free qubit: dead end. The forbids keep every such e, so they
 *         chain with excl, orbf and the overlap forbids (a tight stabilizer row can leave a row with one free qubit).
 *         Kept per row: the number of free qubits (updated on every change of the forbidden set) and bitsets of the
 *         rows with one / no free qubit. Credit: Okada and Kasai, cpm-ldpc-distance (forced unit).
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
    bool sparse, sparseov, xorunit;   /* GH-181 (default off) */
    Rules() : excl(true), pack(true), orbf(true), mrv(false), parity(true), leaf(true), overlap(true),
              sparse(false), sparseov(false), xorunit(false) {}
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
    /* GH-181 (zero unless the tokens are on) */
    uint64_t spack;            /* sparse: packing rows contributed by redundant rows (summed over nodes) */
    uint64_t sprune;           /* sparse: packing prunes reached only through redundant rows */
    uint64_t snocand;          /* sparse: odd redundant row without candidate */
    uint64_t ovtightx;         /* sparseov: tight events on redundant stabilizer rows */
    uint64_t xuforbid;         /* xorunit: qubits forbidden by an even row with one free qubit */
    uint64_t xuforced;         /* xorunit: nodes branching on an odd row with one free qubit */
    uint64_t xudead;           /* xorunit: odd row without free qubit after propagation */
    bool skipped;              /* parity: odd level, EMPTY without a search */
    std::vector<uint64_t> by_budget;   /* nodes by remaining budget w - |S| (index 0..w; diagnostic, -cc-stats) */
    std::vector<int> witness;  /* FOUND / INCONSISTENT: support in ORIGINAL qubit labels, ascending */
    LevelResult() : verdict(LEVEL_EMPTY), nodes(0), seeds(0), closed(0), nocand(0), packprune(0), parprune(0),
                    leaf1(0), leaf2(0), ovtight(0), ovforbid(0),
                    spack(0), sprune(0), snocand(0), ovtightx(0), xuforbid(0), xuforced(0), xudead(0), skipped(false) {}
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
 * both e and e + g when |e & g| = |g|/2). GH-181 mutants (numbers 15-18 are taken by GH-157 / GH-162):
 * 19 every redundant row of sparse has one qubit flipped (its first qubit removed: not in the row space of H),
 * 20 xorunit branches on an even row with one free qubit as if it were forced (instead of forbidding the qubit),
 * 21 sparseov takes its pair sums from H instead of K (no check; not stabilizers of this half).
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
    /* GH-181: redundant rows in use (sparse: rows of R; sparseov: added stabilizer rows) and their weight ranges */
    int sparse_rows() const { return mx_; }
    int sparse_min_weight() const { return xminw_; }
    int sparse_max_weight() const { return xmaxw_; }
    int sparseov_rows() const { return nkx_; }
    int sparseov_min_weight() const { return kxminw_; }
    int sparseov_max_weight() const { return kxmaxw_; }
    bool xorunit_active() const { return xu_; }

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
    int nk_, kminw_, kmaxw_, kzero_;
    std::vector<uint32_t> kstart_, kq_;
    std::vector<uint32_t> kcstart_, kcr_;
    std::vector<int> klim_;
    std::vector<int32_t> slack_;            /* per row: lim_g - |S & g| (0: tight, the rest of g forbidden) */
    uint64_t ovtight_, ovforbid_;           /* per-level counters (copied into the LevelResult) */
    /* GH-181 sparse: redundant rows R (relabeled, ascending); row j has the unified index ux_ + j (ux_ = 64 mw_, so its
     * syndrome bit lives in syn_ words mw_..mw_ + mxw_ - 1 and never disturbs nodd_ or the scans of H's rows) */
    int mx_, mxw_, ux_, xminw_, xmaxw_;
    std::vector<uint32_t> xstart_, xq_;     /* redundant row -> qubits */
    std::vector<uint32_t> xcstart_, xcr_;   /* qubit -> unified indices of its redundant rows */
    /* sparseov: rows nk0_..nk_-1 of K are the added pair sums */
    int nk0_, nkx_, kxminw_, kxmaxw_;
    /* xorunit: free-qubit count per unified row, bitsets of rows with one / no free qubit, trail of unit forbids */
    bool xu_;
    uint64_t ovtightx_;                     /* sparseov: per-level counter */
    std::vector<int32_t> freecnt_;
    std::vector<uint64_t> unit_, zero_;
    std::vector<uint32_t> xtrail_;

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
    void blk_up(uint32_t q);                /* forbidden-set changes (xorunit keeps its counters) */
    void blk_down(uint32_t q);
    void xu_count(uint32_t q, int d);
    bool xu_propagate(int size, int& forced); /* false: dead end; forced: unified index of an odd unit row or -1 */
    bool expand(int size, int forced);
    void ov_add(int q);
    void ov_del(int q);
    bool gpar_nonzero() const;
    bool gpar_nonzero_with(int q) const;
    bool column_is_syndrome(int q) const;
    int closing_qubit() const;              /* free qubit whose column equals syn_ with a nontrivial closure, or -1 */
    bool dfs(int size);
    void record_witness(int size);
};

} /* namespace distcc */

#endif
