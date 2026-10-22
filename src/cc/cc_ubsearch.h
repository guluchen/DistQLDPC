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
 */
#ifndef DISTQLDPC_CC_UBSEARCH_H
#define DISTQLDPC_CC_UBSEARCH_H

#include <stdint.h>
#include <vector>

#include "cc_half.h"

namespace distcc {

struct UbParams {
    int triples_max_k;   /* enumerate triples c_j + c_k + c_l when K <= this (0: never) */
    int slack;           /* local improvement on nontrivial words of weight <= target - 1 + slack */
    int li_cap;          /* at most this many local improvements per iteration */
    int mutant;          /* 11: detector check skipped */
    UbParams() : triples_max_k(0), slack(4), li_cap(64), mutant(0) {}
};

struct UbStats {
    uint64_t iterations, kept, nontrivial, li_gain, found;
    double seconds;
    UbStats() : iterations(0), kept(0), nontrivial(0), li_gain(0), found(0), seconds(0) {}
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

    const uint64_t* det_of(int j);
    void build_word(const int* js, int cnt, std::vector<uint64_t>& c) const;
    int local_improve(std::vector<uint64_t>& c, int wt);
};

} /* namespace distcc */

#endif
