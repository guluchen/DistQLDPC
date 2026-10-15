/*
 * DistQLDPC — connected-cluster (CC) level search for one CSS half (GH-124, experimental).
 *
 * Copyright (C) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * See cc_half.h for the definitions, the exactness argument and the rules. Clean-room code.
 */
#include "cc_half.h"

#include <stdio.h>
#include <stdlib.h>
#include <algorithm>

namespace distcc {

namespace {

uint64_t splitmix64(uint64_t& s) {
    uint64_t z = (s += 0x9e3779b97f4a7c15ULL);
    z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9ULL;
    z = (z ^ (z >> 27)) * 0x94d049bb133111ebULL;
    return z ^ (z >> 31);
}

/* Fisher-Yates over 0..n-1 driven by splitmix64 (deterministic for a given state). */
void shuffle_ints(std::vector<int>& v, uint64_t& s) {
    for (int i = (int)v.size() - 1; i > 0; i--) {
        const int j = (int)(splitmix64(s) % (uint64_t)(i + 1));
        std::swap(v[i], v[j]);
    }
}

[[noreturn]] void fatal(const char* msg) {
    fprintf(stderr, "error: cc: %s\n", msg);
    abort();
}

} /* namespace */

HalfSearch::HalfSearch(const SparseRows& H, const SparseRows& G, const std::vector<int>& orbit_of,
                       const Rules& rules, uint64_t relabel_seed, int mutant)
    : n_(H.cols), m_(0), k_(0), kw_(1), mw_(1), maxrow_(1), rules_(rules), mutant_(mutant),
      orbit_mode_(false), w_(0), nodd_(0), stamp_(0), res_(NULL), incons_(false)
{
    if (n_ <= 0) fatal("half without qubits");
    if (G.cols != n_) fatal("detector column count differs from H");

    /* Relabeling (identity for seed 0): new label of original qubit q is new_of[q]. */
    std::vector<int> new_of((size_t)n_);
    for (int q = 0; q < n_; q++) new_of[q] = q;
    uint64_t rs = relabel_seed;
    if (relabel_seed != 0) shuffle_ints(new_of, rs);
    to_orig_.assign((size_t)n_, 0);
    for (int q = 0; q < n_; q++) to_orig_[new_of[q]] = q;

    /* Rows of H (empty rows never become odd and are dropped), in relabeled order. */
    std::vector<int> rows;
    for (size_t r = 0; r < H.rows.size(); r++)
        if (!H.rows[r].empty()) rows.push_back((int)r);
    if (relabel_seed != 0) shuffle_ints(rows, rs);
    m_ = (int)rows.size();
    mw_ = (m_ + 63) / 64;
    if (mw_ < 1) mw_ = 1;
    rstart_.assign((size_t)m_ + 1, 0);
    std::vector<std::vector<uint32_t> > rq((size_t)m_);
    for (int i = 0; i < m_; i++) {
        const std::vector<int>& src = H.rows[(size_t)rows[i]];
        for (size_t t = 0; t < src.size(); t++) {
            if (src[t] < 0 || src[t] >= n_) fatal("row entry out of range");
            rq[i].push_back((uint32_t)new_of[src[t]]);
        }
        std::sort(rq[i].begin(), rq[i].end());
        rq[i].erase(std::unique(rq[i].begin(), rq[i].end()), rq[i].end());
        if ((int)rq[i].size() > maxrow_) maxrow_ = (int)rq[i].size();
    }
    for (int i = 0; i < m_; i++) rstart_[i + 1] = rstart_[i] + (uint32_t)rq[i].size();
    rq_.reserve(rstart_[m_]);
    for (int i = 0; i < m_; i++) rq_.insert(rq_.end(), rq[i].begin(), rq[i].end());

    /* qubit -> rows (ascending relabeled row index) */
    cstart_.assign((size_t)n_ + 1, 0);
    for (size_t t = 0; t < rq_.size(); t++) cstart_[rq_[t] + 1]++;
    for (int q = 0; q < n_; q++) cstart_[q + 1] += cstart_[q];
    cr_.assign(rq_.size(), 0);
    {
        std::vector<uint32_t> fill(cstart_.begin(), cstart_.end() - 1);
        for (int i = 0; i < m_; i++)
            for (uint32_t t = rstart_[i]; t < rstart_[i + 1]; t++) cr_[fill[rq_[t]]++] = (uint32_t)i;
    }

    /* detector masks */
    k_ = (int)G.rows.size();
    kw_ = (k_ + 63) / 64;
    if (kw_ < 1) kw_ = 1;
    gmask_.assign((size_t)n_ * kw_, 0);
    for (int j = 0; j < k_; j++) {
        std::vector<int> sup = G.rows[(size_t)j];
        std::sort(sup.begin(), sup.end());
        sup.erase(std::unique(sup.begin(), sup.end()), sup.end());
        for (size_t t = 0; t < sup.size(); t++) {
            if (sup[t] < 0 || sup[t] >= n_) fatal("detector entry out of range");
            gmask_[(size_t)new_of[sup[t]] * kw_ + (j >> 6)] |= 1ULL << (j & 63);
        }
    }

    /* seeds: orbit representatives (orbf with nontrivial verified orbits) or every qubit (index rule) */
    bstart_.clear();
    block_.clear();
    bstart_.push_back(0);
    int norb = 0;
    std::vector<int> oid;
    if (rules_.orbf && (int)orbit_of.size() == n_) {
        oid.assign((size_t)n_, -1);
        std::vector<int> id_of((size_t)n_, -1);
        for (int q = 0; q < n_; q++) {
            const int o = orbit_of[q];
            if (o < 0 || o >= n_) fatal("orbit id out of range");
            if (id_of[o] < 0) id_of[o] = norb++;
            oid[q] = id_of[o];
        }
    }
    if (norb > 0 && norb < n_) {
        orbit_mode_ = true;
        std::vector<std::vector<uint32_t> > members((size_t)norb);
        for (int q = 0; q < n_; q++) members[oid[q]].push_back((uint32_t)new_of[q]);
        for (int o = 0; o < norb; o++) std::sort(members[o].begin(), members[o].end());
        /* orbit order: by representative = smallest relabeled member (orbits are forbidden by
         * their index in this order, never by comparing labels) */
        std::vector<int> order((size_t)norb);
        for (int o = 0; o < norb; o++) order[o] = o;
        std::sort(order.begin(), order.end(),
                  [&members](int a, int b) { return members[a][0] < members[b][0]; });
        for (int i = 0; i < norb; i++) {
            const std::vector<uint32_t>& mem = members[order[i]];
            seed_.push_back((int)mem[0]);
            block_.insert(block_.end(), mem.begin(), mem.end());
            bstart_.push_back((uint32_t)block_.size());
        }
    } else {
        for (int q = 0; q < n_; q++) {
            seed_.push_back(q);
            block_.push_back((uint32_t)q);
            bstart_.push_back((uint32_t)block_.size());
        }
    }

    syn_.assign((size_t)mw_, 0);
    gpar_.assign((size_t)kw_, 0);
    blk_.assign((size_t)n_, 0);
    mark_.assign((size_t)n_, 0);
}

inline void HalfSearch::toggle(int q) {
    for (uint32_t i = cstart_[q], e = cstart_[q + 1]; i < e; i++) {
        const uint32_t r = cr_[i];
        uint64_t& wd = syn_[r >> 6];
        const uint64_t b = 1ULL << (r & 63);
        wd ^= b;
        nodd_ += (wd & b) ? 1 : -1;
    }
    const uint64_t* g = &gmask_[(size_t)q * kw_];
    for (int j = 0; j < kw_; j++) gpar_[j] ^= g[j];
}

inline bool HalfSearch::gpar_nonzero() const {
    uint64_t acc = 0;
    for (int j = 0; j < kw_; j++) acc |= gpar_[j];
    return acc != 0;
}

void HalfSearch::record_witness(int size) {
    res_->witness.clear();
    for (int i = 0; i < size; i++) res_->witness.push_back(to_orig_[cur_[i]]);
    std::sort(res_->witness.begin(), res_->witness.end());
}

bool HalfSearch::dfs(int size) {
    ++res_->nodes;
    if (size == w_) {
        if (nodd_ == 0 && gpar_nonzero()) {
            record_witness(size);
            return true;
        }
        return false;
    }
    if (nodd_ == 0) {   /* syndrome-free cluster below the level: dead end */
        ++res_->closed;
        if (gpar_nonzero()) {   /* an element of F lighter than w: precondition violated (driver trap) */
            incons_ = true;
            record_witness(size);
            return true;
        }
        return false;
    }

    /* scan the odd rows in index order: packing bound, no-candidate dead end, branching row */
    const bool pack = rules_.pack, mrv = rules_.mrv;
    const uint64_t st = ++stamp_;
    int p = 0, brow = -1;
    uint32_t bcnt = UINT32_MAX;
    for (int wi = 0; wi < mw_ && !(brow >= 0 && !pack && !mrv); wi++) {
        uint64_t x = syn_[wi];
        while (x) {
            const int r = wi * 64 + __builtin_ctzll(x);
            x &= x - 1;
            const uint32_t* a = &rq_[rstart_[r]];
            const uint32_t* e = &rq_[rstart_[r + 1]];
            if (pack) {
                uint32_t cnt = 0, clash = 0;
                for (const uint32_t* t = a; t < e; ++t) {
                    const uint32_t free_q = blk_[*t] == 0;
                    cnt += free_q;
                    clash |= free_q & (uint32_t)(mark_[*t] == st);
                }
                const bool disjoint = !clash;
                if (cnt == 0) {
                    ++res_->nocand;
                    return false;
                }
                if (disjoint) {
                    ++p;
                    if (mutant_ == 2 ? size + p >= w_ : size + p > w_) {
                        ++res_->packprune;
                        return false;
                    }
                    /* marking forbidden qubits too is harmless: only free qubits can clash */
                    for (const uint32_t* t = a; t < e; ++t) mark_[*t] = st;
                }
                if (mrv) {
                    if (cnt < bcnt) { bcnt = cnt; brow = r; }
                } else if (brow < 0) {
                    brow = r;
                }
            } else if (mrv) {
                uint32_t cnt = 0;
                for (const uint32_t* t = a; t < e; ++t) cnt += blk_[*t] ? 0u : 1u;
                if (cnt < bcnt) { bcnt = cnt; brow = r; }
            } else {
                brow = r;
                break;
            }
        }
    }
    if (brow < 0) return false;   /* unreachable: nodd_ > 0 */

    uint32_t* cb = &cand_[(size_t)size * (size_t)maxrow_];
    int nc = 0;
    for (uint32_t t = rstart_[brow], e = rstart_[brow + 1]; t < e; t++)
        if (!blk_[rq_[t]]) cb[nc++] = rq_[t];
    int excluded = 0;
    bool hit = false;
    for (int i = 0; i < nc; i++) {
        const int a = (int)cb[i];
        blk_[a]++;
        toggle(a);
        cur_[size] = a;
        hit = dfs(size + 1);
        toggle(a);
        blk_[a]--;
        if (hit) break;
        if (rules_.excl) {   /* sibling exclusion: a is forbidden in the later siblings */
            blk_[a]++;
            excluded = i + 1;
        }
    }
    if (mutant_ != 1)   /* restore the forbidden set (mutant 1 leaves it) */
        for (int i = 0; i < excluded; i++) blk_[cb[i]]--;
    return hit;
}

LevelResult HalfSearch::run_level(int w) {
    LevelResult r;
    if (w < 1 || w > n_) return r;
    res_ = &r;
    w_ = w;
    incons_ = false;
    std::fill(syn_.begin(), syn_.end(), 0);
    std::fill(gpar_.begin(), gpar_.end(), 0);
    std::fill(blk_.begin(), blk_.end(), 0);
    nodd_ = 0;
    cur_.assign((size_t)w, -1);
    cand_.assign((size_t)w * (size_t)maxrow_ + 1, 0);
    for (size_t i = 0; i < seed_.size(); i++) {
        const int s = seed_[i];
        if (!blk_[s]) {   /* a seed is never forbidden, except through mutant 1's leak */
            r.seeds++;
            blk_[s]++;
            toggle(s);
            cur_[0] = s;
            const bool hit = dfs(1);
            toggle(s);
            blk_[s]--;
            if (hit) {
                r.verdict = incons_ ? LEVEL_INCONSISTENT : LEVEL_FOUND;
                res_ = NULL;
                return r;
            }
        }
        /* seed rule: index rule forbids the seed; orbit rule forbids its whole orbit (mutant 3: nothing) */
        if (!(orbit_mode_ && mutant_ == 3))
            for (uint32_t t = bstart_[i]; t < bstart_[i + 1]; t++) blk_[block_[t]]++;
    }
    res_ = NULL;
    return r;
}

} /* namespace distcc */
