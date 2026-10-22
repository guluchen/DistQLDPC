/*
 * DistQLDPC — randomized low-weight logical finder for one CSS half (GH-140, CC engine, -ub-search).
 *
 * Copyright (C) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * See cc_ubsearch.h for the method and its correctness argument. Clean-room code.
 */
#include "cc_ubsearch.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <algorithm>
#include <chrono>

namespace distcc {

namespace {

uint64_t splitmix(uint64_t& s) {
    uint64_t z = (s += 0x9e3779b97f4a7c15ULL);
    z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9ULL;
    z = (z ^ (z >> 27)) * 0x94d049bb133111ebULL;
    return z ^ (z >> 31);
}

[[noreturn]] void ub_fatal(const char* msg) {
    fprintf(stderr, "error: cc ub-search: %s\n", msg);
    abort();
}

struct Cand {
    int w;
    int cnt;
    int j[3];
};

double now_s() {
    return std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
}

} /* namespace */

UbFinder::UbFinder(const SparseRows& H, const SparseRows& G, const SparseRows& S, uint64_t seed, const UbParams& p)
    : n_(H.cols), W_((H.cols + 63) / 64), m_(0), r_(0), K_(0), rw_(1), kw_(1), p_(p), rng_(seed), hit_(false)
{
    if (n_ <= 0) ub_fatal("half without qubits");
    if (G.cols != n_ || (S.cols != n_ && !S.rows.empty())) ub_fatal("column count mismatch");
    for (size_t r = 0; r < H.rows.size(); r++) {
        std::vector<uint64_t> row((size_t)W_, 0);
        bool any = false;
        for (size_t t = 0; t < H.rows[r].size(); t++) {
            const int q = H.rows[r][t];
            if (q < 0 || q >= n_) ub_fatal("row entry out of range");
            row[(size_t)q >> 6] ^= 1ULL << (q & 63);
        }
        for (int w = 0; w < W_; w++) any |= row[w] != 0;
        if (!any) continue;
        H0_.insert(H0_.end(), row.begin(), row.end());
        m_++;
    }
    const int k = (int)G.rows.size();
    kw_ = (k + 63) / 64;
    if (kw_ < 1) kw_ = 1;
    dm_.assign((size_t)n_ * kw_, 0);
    for (int j = 0; j < k; j++)
        for (size_t t = 0; t < G.rows[j].size(); t++) {
            const int q = G.rows[j][t];
            if (q < 0 || q >= n_) ub_fatal("detector entry out of range");
            dm_[(size_t)q * kw_ + (j >> 6)] ^= 1ULL << (j & 63);
        }
    for (size_t r = 0; r < S.rows.size(); r++) {
        std::vector<int> g(S.rows[r]);
        std::sort(g.begin(), g.end());
        std::vector<int> h;
        for (size_t t = 0; t < g.size(); t++) {
            if (g[t] < 0 || g[t] >= n_) ub_fatal("stabilizer entry out of range");
            if (t + 1 < g.size() && g[t] == g[t + 1]) { t++; continue; }
            h.push_back(g[t]);
        }
        if (!h.empty()) srows_.push_back(h);
    }
    /* rank of H (identity order) */
    {
        std::vector<uint64_t> M(H0_);
        int rank = 0;
        for (int c = 0; c < n_ && rank < m_; c++) {
            const int w = c >> 6;
            const uint64_t b = 1ULL << (c & 63);
            int piv = -1;
            for (int i = rank; i < m_; i++)
                if (M[(size_t)i * W_ + w] & b) { piv = i; break; }
            if (piv < 0) continue;
            if (piv != rank)
                for (int t = 0; t < W_; t++) std::swap(M[(size_t)piv * W_ + t], M[(size_t)rank * W_ + t]);
            for (int i = rank + 1; i < m_; i++)
                if (M[(size_t)i * W_ + w] & b)
                    for (int t = 0; t < W_; t++) M[(size_t)i * W_ + t] ^= M[(size_t)rank * W_ + t];
            rank++;
        }
        r_ = rank;
    }
    K_ = n_ - r_;
    rw_ = (r_ + 63) / 64;
    if (rw_ < 1) rw_ = 1;
    perm_.resize((size_t)n_);
    for (int q = 0; q < n_; q++) perm_[q] = q;
    piv_.assign((size_t)r_, -1);
    ispiv_.assign((size_t)n_, 0);
    fidx_.assign((size_t)n_, -1);
    fmask_.assign((size_t)W_, 0);
    At_.assign((size_t)K_ * rw_, 0);
    wt1_.assign((size_t)K_, 0);
    det_.assign((size_t)K_ * kw_, 0);
    detok_.assign((size_t)K_, 0);
    cbuf_.assign((size_t)W_, 0);
}

const uint64_t* UbFinder::det_of(int j) {
    uint64_t* d = &det_[(size_t)j * kw_];
    if (!detok_[j]) {
        const uint64_t* e = &dm_[(size_t)fc_[j] * kw_];
        for (int t = 0; t < kw_; t++) d[t] = e[t];
        const uint64_t* a = &At_[(size_t)j * rw_];
        for (int w = 0; w < rw_; w++) {
            uint64_t x = a[w];
            while (x) {
                const int i = w * 64 + __builtin_ctzll(x);
                x &= x - 1;
                const uint64_t* g = &dm_[(size_t)piv_[i] * kw_];
                for (int t = 0; t < kw_; t++) d[t] ^= g[t];
            }
        }
        detok_[j] = 1;
    }
    return d;
}

void UbFinder::build_word(const int* js, int cnt, std::vector<uint64_t>& c) const {
    std::fill(c.begin(), c.end(), 0);
    for (int a = 0; a < cnt; a++) {
        const int col = fc_[js[a]];
        c[(size_t)col >> 6] ^= 1ULL << (col & 63);
        const uint64_t* x = &At_[(size_t)js[a] * rw_];
        for (int w = 0; w < rw_; w++) {
            uint64_t y = x[w];
            while (y) {
                const int i = w * 64 + __builtin_ctzll(y);
                y &= y - 1;
                c[(size_t)piv_[i] >> 6] ^= 1ULL << (piv_[i] & 63);
            }
        }
    }
}

/* greedy descent: add a stabilizer row g with |c & g| > |g| / 2 while one exists (strictly lowers the weight) */
int UbFinder::local_improve(std::vector<uint64_t>& c, int wt) {
    bool changed = true;
    while (changed) {
        changed = false;
        for (size_t r = 0; r < srows_.size(); r++) {
            const std::vector<int>& g = srows_[r];
            int ov = 0;
            for (size_t t = 0; t < g.size(); t++) ov += (int)((c[(size_t)g[t] >> 6] >> (g[t] & 63)) & 1);
            if (2 * ov > (int)g.size()) {
                for (size_t t = 0; t < g.size(); t++) c[(size_t)g[t] >> 6] ^= 1ULL << (g[t] & 63);
                wt -= 2 * ov - (int)g.size();
                changed = true;
            }
        }
    }
    return wt;
}

bool UbFinder::iterate(int target, std::vector<int>& out) {
    const double t0 = now_s();
    st_.iterations++;
    out.clear();
    hit_ = false;
    if (K_ <= 0 || target <= 1) { st_.seconds += now_s() - t0; return false; }
    /* 1. random column order */
    for (int i = n_ - 1; i > 0; i--) {
        const int j = (int)(splitmix(rng_) % (uint64_t)(i + 1));
        std::swap(perm_[i], perm_[j]);
    }
    /* 2. Gauss-Jordan elimination with pivots in that order */
    M_ = H0_;
    std::fill(ispiv_.begin(), ispiv_.end(), 0);
    int rank = 0;
    for (int pi = 0; pi < n_ && rank < r_; pi++) {
        const int c = perm_[pi];
        const int w = c >> 6;
        const uint64_t b = 1ULL << (c & 63);
        int piv = -1;
        for (int i = rank; i < m_; i++)
            if (M_[(size_t)i * W_ + w] & b) { piv = i; break; }
        if (piv < 0) continue;
        uint64_t* R = &M_[(size_t)rank * W_];
        if (piv != rank) {
            uint64_t* P = &M_[(size_t)piv * W_];
            for (int t = 0; t < W_; t++) std::swap(P[t], R[t]);
        }
        for (int i = 0; i < m_; i++) {
            if (i == rank) continue;
            uint64_t* X = &M_[(size_t)i * W_];
            if (X[w] & b)
                for (int t = 0; t < W_; t++) X[t] ^= R[t];
        }
        piv_[rank] = c;
        ispiv_[c] = 1;
        rank++;
    }
    if (rank != r_) ub_fatal("rank changed under a column permutation");
    /* 3. information set and the systematic basis (A columns over the pivot rows) */
    fc_.clear();
    std::fill(fmask_.begin(), fmask_.end(), 0);
    for (int pi = 0; pi < n_; pi++) {
        const int c = perm_[pi];
        if (ispiv_[c]) { fidx_[c] = -1; continue; }
        fidx_[c] = (int)fc_.size();
        fc_.push_back(c);
        fmask_[(size_t)c >> 6] |= 1ULL << (c & 63);
    }
    std::fill(At_.begin(), At_.end(), 0);
    for (int i = 0; i < r_; i++) {
        const uint64_t* R = &M_[(size_t)i * W_];
        for (int w = 0; w < W_; w++) {
            uint64_t x = R[w] & fmask_[w];
            while (x) {
                const int col = w * 64 + __builtin_ctzll(x);
                x &= x - 1;
                At_[(size_t)fidx_[col] * rw_ + (i >> 6)] |= 1ULL << (i & 63);
            }
        }
    }
    std::fill(detok_.begin(), detok_.end(), 0);
    for (int j = 0; j < K_; j++) {
        int c = 1;
        const uint64_t* a = &At_[(size_t)j * rw_];
        for (int w = 0; w < rw_; w++) c += __builtin_popcountll(a[w]);
        wt1_[j] = c;
    }
    /* 4. enumerate p = 1, 2 (3 on small K); keep nontrivial words of weight <= thr (thr follows the lightest one) */
    int best_raw = target - 1;
    std::vector<Cand> cands;
    auto thr = [&]() { return best_raw + p_.slack; };
    auto consider = [&](int w, int cnt, int a, int b, int c) {
        st_.kept++;
        uint64_t acc = 0;
        if (p_.mutant == 11) acc = 1;   /* mutant 11: no detector check */
        else {
            const uint64_t* da = det_of(a);
            const uint64_t* db = cnt > 1 ? det_of(b) : NULL;
            const uint64_t* dc = cnt > 2 ? det_of(c) : NULL;
            for (int t = 0; t < kw_; t++) {
                uint64_t x = da[t];
                if (db) x ^= db[t];
                if (dc) x ^= dc[t];
                acc |= x;
            }
        }
        if (!acc) return;
        st_.nontrivial++;
        if (w < best_raw) best_raw = w;
        Cand cd;
        cd.w = w; cd.cnt = cnt; cd.j[0] = a; cd.j[1] = b; cd.j[2] = c;
        if (cands.size() < (1u << 16)) cands.push_back(cd);
    };
    for (int j = 0; j < K_; j++)
        if (wt1_[j] <= thr()) consider(wt1_[j], 1, j, -1, -1);
    std::vector<uint64_t> x((size_t)rw_);
    for (int j = 0; j < K_; j++) {
        const uint64_t* a = &At_[(size_t)j * rw_];
        for (int k = j + 1; k < K_; k++) {
            const uint64_t* b = &At_[(size_t)k * rw_];
            int c = 2;
            for (int w = 0; w < rw_; w++) c += __builtin_popcountll(a[w] ^ b[w]);
            if (c <= thr()) consider(c, 2, j, k, -1);
        }
    }
    if (K_ <= p_.triples_max_k) {
        for (int j = 0; j < K_; j++) {
            const uint64_t* a = &At_[(size_t)j * rw_];
            for (int k = j + 1; k < K_; k++) {
                const uint64_t* b = &At_[(size_t)k * rw_];
                for (int w = 0; w < rw_; w++) x[w] = a[w] ^ b[w];
                for (int l = k + 1; l < K_; l++) {
                    const uint64_t* d = &At_[(size_t)l * rw_];
                    int c = 3;
                    for (int w = 0; w < rw_; w++) c += __builtin_popcountll(x[w] ^ d[w]);
                    if (c <= thr()) consider(c, 3, j, k, l);
                }
            }
        }
    }
    /* 5. local improvement of the lightest kept words */
    bool found = false;
    int best = target;
    if (!cands.empty()) {
        std::stable_sort(cands.begin(), cands.end(), [](const Cand& u, const Cand& v) { return u.w < v.w; });
        const int lim = thr();
        std::vector<uint64_t> bestw((size_t)W_, 0);
        int done = 0;
        for (size_t t = 0; t < cands.size() && done < p_.li_cap; t++) {
            const Cand& cd = cands[t];
            if (cd.w > lim) break;
            build_word(cd.j, cd.cnt, cbuf_);
            int w = cd.w;
            const int w2 = p_.mutant == 11 ? w : local_improve(cbuf_, w);   /* mutant 11: no improvement either */
            if (w2 < w) st_.li_gain++;
            w = w2;
            done++;
            if (w == target) hit_ = true;
            if (w > 0 && w < best) {
                best = w;
                bestw = cbuf_;
                found = true;
            }
        }
        if (found) {
            for (int wd = 0; wd < W_; wd++) {
                uint64_t y = bestw[wd];
                while (y) {
                    out.push_back(wd * 64 + __builtin_ctzll(y));
                    y &= y - 1;
                }
            }
            if ((int)out.size() != best) ub_fatal("word weight bookkeeping");
            st_.found++;
        }
    }
    st_.seconds += now_s() - t0;
    return found;
}

} /* namespace distcc */
