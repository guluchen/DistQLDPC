/*
 * DistQLDPC — randomized low-weight logical finder for one CSS half (GH-140, CC engine, -ub-search).
 *
 * Copyright (C) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Clean-room implementation written from the published one-paragraph descriptions of random-information-set
 * search (Lee-Brickell style enumeration of p <= 2 systematic rows; QDistRnd / dist-m4ri "RW") and from the
 * mathematics below. No third-party code was read.
 *
 * Half (one Pauli type, n qubits): parity checks H, detector rows G, same-type stabilizer rows S (rs S lies in
 * ker [H; G], verified by the CC driver's start-up detector check). The half's code is C = ker H; a word c in C is
 * a nontrivial logical iff G c != 0 (odd overlap with some detector row).
 *
 * One iteration (random information set):
 *   1. a random column order pi (Fisher-Yates driven by splitmix64; deterministic for a given seed);
 *   2. Gauss-Jordan elimination of H with pivot columns taken greedily in the order pi: pivot columns P (|P| = r =
 *      rank H), information set I = the other K = n - r columns. Reduced row i has pivot P_i and entries A[i][j] on I.
 *   3. ker H has the systematic basis c_j = e_j + sum_i A[i][j] e_{P_i} (j in I): c_j is in ker H since row i of the
 *      reduced matrix gives (H c_j)_i = A[i][j] + A[i][j] = 0, and the c_j are independent (identity on I).
 *   4. enumerate the words c_j (weight 1 + |A_j|), c_j + c_k (weight 2 + |A_j ^ A_k|) and, on small K, c_j + c_k + c_l;
 *      a word is kept when its weight is at most target - 1 + slack and its detector parity G c is nonzero
 *      (G c = G c_j + G c_k [+ G c_l], G c_j = G e_j + sum_i A[i][j] G e_{P_i}).
 *   5. local improvement of each kept word c: while some stabilizer row g of S has |c & g| > |g| / 2, replace c by
 *      c + g (same logical class: G g = 0 and H g = 0; weight drops by 2|c & g| - |g| > 0).
 *   The lightest kept word of weight < target is returned. Every returned word is in ker H with G c != 0 by
 *   construction; the driver verifies it again independently (H e = 0, e not in rs S by its own rank test) before
 *   it is reported as an upper bound.
 *
 * Test mutant 11 (-cc-mutant=11): the detector check of step 4 is skipped (trivial words accepted) and step 5 too
 * (local improvement would mostly cancel a trivial word to the empty word); the driver's verification must reject
 * such words (TRAP). Mutant 12 is a driver mutant (cc_driver.h).
 *
 * GH-146 collision mode (-ub-isd=stern|dumer[:p,l,w]; isd > 0 below). Written from the published descriptions of
 * Stern's algorithm (1988), Dumer's / Finiasz-Sendrier's split with an overlapping window, and the Canteaut-Chabaud
 * random walk on information sets; no third-party code was read. Steps 2-3 are kept (systematic basis c_j of
 * ker H over the information set I, reduced rows A); only the enumeration and the re-randomisation change:
 *   a. re-randomisation (Canteaut-Chabaud): instead of a fresh elimination every iteration, w pivot swaps: take a
 *      random information column j with A_j != 0 and a random reduced row i with A[i][j] = 1; adding row i to every
 *      other row with a 1 in column j makes j the pivot of row i and the old pivot P_i an information column. On
 *      the stored columns this is: A_j' += A_j + e_i for every information column j' != j with A[i][j'] = 1, and
 *      the new information column P_i has the column vector A_j (relabel j <-> P_i). The systematic invariant
 *      (each c_j in ker H, identity on I) is preserved exactly (GF(2) row operations). A full random elimination
 *      runs at the start and every `isd_refresh` iterations.
 *   b. collision (Stern): split I at random into two halves I1, I2 and pick a random window Z of l reduced rows;
 *      enumerate all subsets of size <= p of I1 (list L1) and of I2 (list L2); the key of a subset T is the window
 *      part of sum_{j in T} A_j (l bits). Pairs (T1, T2) with equal keys give words c = sum_{j in T1 u T2} c_j with
 *      no 1 in the window; their weight |T1| + |T2| + |sum A_j| is computed for every colliding pair (bucket sort of
 *      L1 by key). Dumer / Finiasz-Sendrier variant (isd = 2): the window pivot columns P_i (i in Z) are elements
 *      too, split with I1 / I2; such an element contributes e_i to the key and nothing to the word (it stands for a
 *      1 of the word inside the window), so words with up to p ones per side on I u P_Z are matched.
 *   Kept words (weight <= threshold, detector check, local improvement) are handled exactly as in steps 4-5; single
 *   basis words c_j are also tried every round. One "iteration" (the unit counted by the stop rules) is `isd_batch`
 *   such rounds (default 1); the lightest word of the iteration is returned.
 */
#ifndef DISTQLDPC_CC_UBSEARCH_H
#define DISTQLDPC_CC_UBSEARCH_H

#include <stdint.h>
#include <string>
#include <vector>

#include "cc_half.h"

namespace distcc {

struct UbParams {
    int triples_max_k;   /* enumerate triples c_j + c_k + c_l when K <= this (0: never) */
    int slack;           /* local improvement on nontrivial words of weight <= target - 1 + slack */
    int li_cap;          /* at most this many local improvements per iteration */
    int mutant;          /* 11: detector check skipped */
    int evo_mu;          /* > 0: permutation evolution (QDistEvol-like): keep the evo_mu fittest column orders and derive
                            each new order from a random one of them by 1..max(1, n/50) random transpositions (fitness:
                            lightest nontrivial word of the iteration, then the mean weight of the nontrivial systematic
                            words); 0: a fresh random order every iteration */
    /* GH-146 collision mode */
    int isd;             /* 0: GH-140 enumeration (-ub-isd=off); 1: Stern (default since 2026-10-23, PI); 2: Dumer / Finiasz-Sendrier (window columns as elements) */
    int isd_p;           /* subsets of size <= p per side (1..3) */
    int isd_l;           /* window rows (< 0: automatic, ~log2 of the list size) */
    int isd_walk;        /* Canteaut-Chabaud pivot swaps per round (0: a fresh random elimination every round) */
    int isd_refresh;     /* a fresh random elimination every this many rounds (0: never after the first) */
    int isd_batch;       /* rounds per iteration (>= 1) */
    UbParams() : triples_max_k(0), slack(4), li_cap(64), mutant(0), evo_mu(0),
                 isd(1), isd_p(2), isd_l(-1), isd_walk(32), isd_refresh(0), isd_batch(1) {}
};

/* a kept candidate word: sum of cnt systematic basis words c_j (information indices j[0..cnt-1]) */
struct UbCand {
    int w;
    int cnt;
    int j[6];
};

struct UbStats {
    uint64_t iterations, kept, nontrivial, li_gain, found;
    uint64_t rounds, collisions, coll_nt;   /* GH-146 collision mode: rounds, colliding pairs, of them nontrivial */
    double seconds;
    UbStats() : iterations(0), kept(0), nontrivial(0), li_gain(0), found(0), rounds(0), collisions(0), coll_nt(0), seconds(0) {}
};

class UbFinder {
public:
    /* H, G, S: the half's parity checks, detector rows and same-type stabilizer rows (n = H.cols columns). */
    UbFinder(const SparseRows& H, const SparseRows& G, const SparseRows& S, uint64_t seed, const UbParams& p);

    /* One random information set. Returns true and the support (ascending qubit labels) of the lightest
     * nontrivial word of weight < target found in this iteration; false if none. */
    bool iterate(int target, std::vector<int>& out);

    /* the last iteration met a nontrivial word of weight exactly target (a re-hit of the current bound; needs
     * slack >= 1, since words heavier than target - 1 + slack are not kept) */
    bool last_hit() const { return hit_; }

    int n() const { return n_; }
    int isd_l() const { return l_; }          /* GH-146: effective window size (collision mode) */
    int isd_batch() const { return batch_; }  /* GH-146: rounds per iteration (collision mode) */
    int rank() const { return r_; }
    int dim() const { return K_; }
    const UbStats& stats() const { return st_; }
    UbStats& stats() { return st_; }

private:
    int n_, W_, m_, r_, K_, rw_, kw_;
    UbParams p_;
    uint64_t rng_;
    bool hit_;
    std::vector<uint64_t> H0_;               /* m_ rows x W_ words */
    std::vector<uint64_t> dm_;               /* qubit -> detector mask (kw_ words) */
    std::vector<std::vector<int> > srows_;   /* stabilizer rows (sparse, GF(2)-reduced) */
    std::vector<int> perm_;
    /* per-iteration work */
    std::vector<uint64_t> M_;                /* reduced H */
    std::vector<int> piv_;                   /* pivot column of reduced row i */
    std::vector<char> ispiv_;
    std::vector<int> fc_, fidx_;             /* information set columns (order pi), column -> index or -1 */
    std::vector<uint64_t> fmask_;            /* information set as an n-bit mask */
    std::vector<uint64_t> At_;               /* K_ rows x rw_ words: A column j over the pivot rows */
    std::vector<int> wt1_;
    std::vector<uint64_t> det_;              /* K_ x kw_ detector parity of c_j (lazy) */
    std::vector<char> detok_;
    std::vector<uint64_t> cbuf_;             /* candidate word (W_ words) */
    UbStats st_;
    /* GH-146 collision mode */
    int l_, batch_;
    bool isd_ready_;
    uint64_t rounds_;
    std::vector<int> rowperm_, elems_, win_;
    std::vector<uint32_t> ekey_;             /* element key (window part of its column) */
    std::vector<int> einfo_;                 /* element -> information index, or -1 for a window pivot element */
    struct Sub { uint32_t key; int a, b, c; int ninfo; };   /* subset of one side: up to 3 information indices (-1: none) */
    std::vector<Sub> L1_, L2_;
    std::vector<uint64_t> X1_;               /* L1 subset vectors (sum A_j, rw_ words each), in bucket order */
    std::vector<uint64_t> D1_;               /* L1 subset detector parities (kw_ words each), in bucket order */
    std::vector<int> head_;                  /* bucket starts (2^l + 1) */
    std::vector<Sub> L1s_;                   /* L1 in bucket order */
    struct Member { int best; double mean; std::vector<int> perm; };
    std::vector<Member> pop_;                /* evolution population (evo_mu > 0) */

    const uint64_t* det_of(int j);
    void eliminate_random();                 /* steps 1-3: random column order, elimination, systematic columns */
    bool cc_swap();                          /* GH-146: one Canteaut-Chabaud pivot swap */
    void isd_round(int& best_raw, std::vector<UbCand>& cands);
    bool iterate_isd(int target, std::vector<int>& out);
    void build_side(const int* el, int cnt, std::vector<Sub>& L);
    void build_word(const int* js, int cnt, std::vector<uint64_t>& c) const;
    int local_improve(std::vector<uint64_t>& c, int wt);
};

/* GH-146: parse "off" | "stern[:P,L,W,B,R]" | "dumer[:P,L,W,B,R]" into the isd* fields of p (empty field = default);
 * false on a malformed value. isd_desc: "" for isd = 0, else ", collision stern p 2 l 15 walk 8 batch 12 refresh 0". */
bool parse_isd(const char* s, UbParams& p);
std::string isd_desc(const UbParams& p, const UbFinder& f);

} /* namespace distcc */

#endif
