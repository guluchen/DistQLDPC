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
    bool excl, pack, orbf, mrv;
    Rules() : excl(true), pack(true), orbf(true), mrv(false) {}
};

enum LevelVerdict { LEVEL_EMPTY = 0, LEVEL_FOUND = 1, LEVEL_INCONSISTENT = 2 };

struct LevelResult {
    LevelVerdict verdict;
    uint64_t nodes;            /* search nodes (one per visited cluster, leaves included) */
    uint64_t seeds;            /* seeds started */
    uint64_t closed;           /* syndrome-free dead ends below the level */
    uint64_t nocand;           /* odd row without candidate (pack) */
    uint64_t packprune;        /* |S| + packing > w */
    std::vector<int> witness;  /* FOUND / INCONSISTENT: support in ORIGINAL qubit labels, ascending */
    LevelResult() : verdict(LEVEL_EMPTY), nodes(0), seeds(0), closed(0), nocand(0), packprune(0) {}
};

/* Test-only mutants (-cc-mutant=K): 1 forbidden set not restored on backtrack; 2 packing prune uses
 * >= instead of >; 3 orbit seeds without forbidding earlier orbits; 4 is a driver mutant. */
class HalfSearch {
public:
    /* H, G: the half's parity checks and detector rows (n = H.cols columns). orbit_of: per ORIGINAL
     * qubit the orbit id of the verified half automorphism group (empty: none). relabel_seed != 0
     * relabels qubits and rows deterministically (testing hook -cc-seed). */
    HalfSearch(const SparseRows& H, const SparseRows& G, const std::vector<int>& orbit_of,
               const Rules& rules, uint64_t relabel_seed, int mutant);

    /* Level w >= 1 (precondition: no element of F of weight < w). */
    LevelResult run_level(int w);

    int n() const { return n_; }
    bool orbit_seeds() const { return orbit_mode_; }
    int num_seeds() const { return (int)seed_.size(); }

private:
    int n_, m_, k_, kw_, mw_, maxrow_;
    Rules rules_;
    int mutant_;
    bool orbit_mode_;
    std::vector<uint32_t> rstart_, rq_;     /* rows -> qubits (relabeled, ascending) */
    std::vector<uint32_t> cstart_, cr_;     /* qubit -> rows (relabeled) */
    std::vector<uint64_t> gmask_;           /* qubit -> detector rows mask (kw_ words) */
    std::vector<int> to_orig_;              /* relabeled qubit -> original qubit */
    std::vector<int> seed_;                 /* seeds (relabeled), in order */
    std::vector<uint32_t> bstart_, block_;  /* qubits forbidden after seed i is exhausted */

    /* search state */
    int w_;
    std::vector<uint64_t> syn_;             /* odd rows of S */
    int nodd_;
    std::vector<uint64_t> gpar_;            /* detector parities of S */
    std::vector<uint32_t> blk_;             /* > 0: in S or forbidden */
    std::vector<uint64_t> mark_;            /* packing stamp (64-bit, never wraps) */
    uint64_t stamp_;
    std::vector<int> cur_;                  /* S as a stack */
    std::vector<uint32_t> cand_;            /* per-depth candidate buffers */
    LevelResult* res_;
    bool incons_;

    void toggle(int q);
    bool gpar_nonzero() const;
    bool dfs(int size);
    void record_witness(int size);
};

} /* namespace distcc */

#endif
