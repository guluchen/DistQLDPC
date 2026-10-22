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
#include <cmath>

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

const int ISD_MAX_L = 20;   /* GH-146: at most 2^20 buckets */

double now_s() {
    return std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
}

} /* namespace */

UbFinder::UbFinder(const SparseRows& H, const SparseRows& G, const SparseRows& S, uint64_t seed, const UbParams& p)
    : n_(H.cols), W_((H.cols + 63) / 64), m_(0), r_(0), K_(0), rw_(1), kw_(1), p_(p), rng_(seed), hit_(false),
      l_(0), batch_(1), isd_ready_(false), rounds_(0)
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
    if (p_.isd) {   /* GH-146: window size (automatic: ~log2 of the list size; a deterministic function of the code) */
        if (p_.isd < 0 || p_.isd > 2 || p_.isd_p < 1 || p_.isd_p > 2 || p_.isd_walk < 0 || p_.isd_refresh < 0 || p_.isd_batch < 1)
            ub_fatal("invalid collision-mode parameters");
        p_.evo_mu = 0;
        auto list_size = [](double h, int pp) { return pp == 1 ? 1 + h : 1 + h + h * (h - 1) / 2; };
        const double h0 = K_ / 2.0;
        if (p_.isd_l >= 0) l_ = p_.isd_l;
        else {
            const double ls = list_size(h0, p_.isd_p);
            l_ = (int)(std::log2(ls) + 0.5);
        }
        if (l_ > ISD_MAX_L) l_ = ISD_MAX_L;
        if (l_ > r_) l_ = r_;
        if (l_ < 0) l_ = 0;
        batch_ = p_.isd_batch;
        rowperm_.resize((size_t)r_);
        for (int i = 0; i < r_; i++) rowperm_[i] = i;
        win_.assign((size_t)l_, 0);
        head_.assign(((size_t)1 << l_) + 1, 0);
    }
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

/* steps 1-3: a random column order (evolution: a mutated copy of a population member), Gauss-Jordan elimination
 * with pivots in that order, the information set and its systematic columns A_j, their weights 1 + |A_j| */
void UbFinder::eliminate_random() {
    /* 1. random column order (evolution: a mutated copy of a population member once the population is full) */
    if (p_.evo_mu > 0 && (int)pop_.size() >= p_.evo_mu) {
        perm_ = pop_[(size_t)(splitmix(rng_) % pop_.size())].perm;
        const int mx = std::max(1, n_ / 50);
        const int m = 1 + (int)(splitmix(rng_) % (uint64_t)mx);
        for (int t = 0; t < m; t++) {
            const int a = (int)(splitmix(rng_) % (uint64_t)n_), b = (int)(splitmix(rng_) % (uint64_t)n_);
            std::swap(perm_[a], perm_[b]);
        }
    } else {
        for (int i = n_ - 1; i > 0; i--) {
            const int j = (int)(splitmix(rng_) % (uint64_t)(i + 1));
            std::swap(perm_[i], perm_[j]);
        }
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
}

bool UbFinder::iterate(int target, std::vector<int>& out) {
    if (p_.isd) return iterate_isd(target, out);   /* GH-146 collision mode */
    const double t0 = now_s();
    st_.iterations++;
    out.clear();
    hit_ = false;
    if (K_ <= 0 || target <= 1) { st_.seconds += now_s() - t0; return false; }
    eliminate_random();
    /* 4. enumerate p = 1, 2 (3 on small K); keep nontrivial words of weight <= thr (thr follows the lightest one) */
    int best_raw = target - 1;
    std::vector<UbCand> cands;
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
        UbCand cd;
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
    int fit_best = 1 << 30;   /* evolution fitness: lightest nontrivial word of this iteration (any weight) */
    if (!cands.empty()) {
        std::stable_sort(cands.begin(), cands.end(), [](const UbCand& u, const UbCand& v) { return u.w < v.w; });
        const int lim = thr();
        std::vector<uint64_t> bestw((size_t)W_, 0);
        int done = 0;
        for (size_t t = 0; t < cands.size() && done < p_.li_cap; t++) {
            const UbCand& cd = cands[t];
            if (cd.w > lim) break;
            build_word(cd.j, cd.cnt, cbuf_);
            int w = cd.w;
            const int w2 = p_.mutant == 11 ? w : local_improve(cbuf_, w);   /* mutant 11: no improvement either */
            if (w2 < w) st_.li_gain++;
            w = w2;
            done++;
            if (w > 0 && w < fit_best) fit_best = w;
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
    if (p_.evo_mu > 0) {   /* evolution: fitness (fit_best, mean weight of the nontrivial systematic words) */
        double sum = 0;
        int cnt = 0;
        for (int j = 0; j < K_; j++) {
            const uint64_t* dj = det_of(j);
            uint64_t acc = 0;
            for (int t = 0; t < kw_; t++) acc |= dj[t];
            if (acc) { sum += wt1_[j]; cnt++; }
        }
        Member mb;
        mb.best = fit_best;
        mb.mean = cnt ? sum / cnt : 1e18;
        auto worse = [](const Member& a, const Member& b) { return a.best != b.best ? a.best > b.best : a.mean > b.mean; };
        if ((int)pop_.size() < p_.evo_mu) { mb.perm = perm_; pop_.push_back(mb); }
        else {
            size_t wi = 0;
            for (size_t t = 1; t < pop_.size(); t++) if (worse(pop_[t], pop_[wi])) wi = t;
            if (worse(pop_[wi], mb)) { mb.perm = perm_; pop_[wi] = mb; }
        }
    }
    st_.seconds += now_s() - t0;
    return found;
}

/* ---- GH-146 collision mode (see cc_ubsearch.h) ---- */

/* one Canteaut-Chabaud pivot swap: information column j (A_j != 0) and a reduced row i with A[i][j] = 1 exchange
 * roles; rows i' != i with A[i'][j] = 1 get row i added, i.e. A_j' += A_j + e_i for every information column j'
 * with A[i][j'] = 1; the new information column P_i keeps the stored vector A_j */
bool UbFinder::cc_swap() {
    for (int tries = 0; tries < 16; tries++) {
        const int j = (int)(splitmix(rng_) % (uint64_t)K_);
        uint64_t* a = &At_[(size_t)j * rw_];
        int pc = 0;
        for (int w = 0; w < rw_; w++) pc += __builtin_popcountll(a[w]);
        if (pc == 0) continue;   /* c_j = e_j: a qubit outside every check; no pivot in this column */
        int t = (int)(splitmix(rng_) % (uint64_t)pc), i = -1;
        for (int w = 0; w < rw_ && i < 0; w++) {
            const int c = __builtin_popcountll(a[w]);
            if (t >= c) { t -= c; continue; }
            uint64_t x = a[w];
            for (int u = 0; u < t; u++) x &= x - 1;
            i = w * 64 + __builtin_ctzll(x);
        }
        for (int w = 0; w < rw_; w++) cbuf_[w] = a[w];   /* cbuf_ has W_ >= rw_ words */
        const int wi = i >> 6;
        const uint64_t bi = 1ULL << (i & 63);
        cbuf_[wi] ^= bi;
        for (int jj = 0; jj < K_; jj++) {
            if (jj == j) continue;
            uint64_t* x = &At_[(size_t)jj * rw_];
            if (x[wi] & bi)
                for (int w = 0; w < rw_; w++) x[w] ^= cbuf_[w];
        }
        std::swap(fc_[j], piv_[i]);
        return true;
    }
    return false;
}

/* all subsets of size <= p (p = 1, 2) of the elements el[0..cnt-1], with their keys */
void UbFinder::build_side(const int* el, int cnt, std::vector<Sub>& L) {
    L.clear();
    Sub e0; e0.key = 0; e0.a = e0.b = e0.c = -1; e0.ninfo = 0;
    L.push_back(e0);
    for (int x = 0; x < cnt; x++) {
        Sub s1; s1.key = ekey_[el[x]]; s1.a = einfo_[el[x]]; s1.b = s1.c = -1; s1.ninfo = s1.a >= 0;
        L.push_back(s1);
        if (p_.isd_p < 2) continue;
        for (int y = x + 1; y < cnt; y++) {
            Sub s2; s2.key = s1.key ^ ekey_[el[y]]; s2.c = -1;
            const int ia = einfo_[el[x]], ib = einfo_[el[y]];
            if (ia >= 0) { s2.a = ia; s2.b = ib; } else { s2.a = ib; s2.b = -1; }
            s2.ninfo = (ia >= 0) + (ib >= 0);
            L.push_back(s2);
        }
    }
}

/* one collision round on the current information set; appends nontrivial kept words to cands */
void UbFinder::isd_round(int& best_raw, std::vector<UbCand>& cands) {
    auto thr = [&]() { return best_raw + p_.slack; };
    auto consider = [&](int w, const int* js, int cnt) {
        st_.kept++;
        uint64_t acc = 0;
        if (p_.mutant == 11) acc = 1;   /* mutant 11: no detector check */
        else {
            for (int t = 0; t < kw_; t++) {
                uint64_t x = 0;
                for (int u = 0; u < cnt; u++) x ^= det_of(js[u])[t];
                acc |= x;
            }
        }
        if (!acc) return;
        st_.nontrivial++;
        if (w < best_raw) best_raw = w;
        UbCand cd;
        cd.w = w; cd.cnt = cnt;
        for (int u = 0; u < 6; u++) cd.j[u] = u < cnt ? js[u] : -1;
        if (cands.size() < (1u << 16)) cands.push_back(cd);
    };
    /* single basis words (cheap; not all of them collide on the window) */
    for (int j = 0; j < K_; j++)
        if (wt1_[j] <= thr()) consider(wt1_[j], &j, 1);
    /* random window of l reduced rows */
    for (int t = 0; t < l_; t++) {
        const int u = t + (int)(splitmix(rng_) % (uint64_t)(r_ - t));
        std::swap(rowperm_[t], rowperm_[u]);
        win_[t] = rowperm_[t];
    }
    /* elements: the information indices, plus (Dumer) the window pivot columns */
    const int nel = K_ + (p_.isd == 2 ? l_ : 0);
    elems_.resize((size_t)nel);
    ekey_.resize((size_t)nel);
    einfo_.resize((size_t)nel);
    for (int e = 0; e < nel; e++) {
        elems_[e] = e;
        if (e < K_) {
            const uint64_t* a = &At_[(size_t)e * rw_];
            uint32_t k = 0;
            for (int t = 0; t < l_; t++) k |= (uint32_t)((a[win_[t] >> 6] >> (win_[t] & 63)) & 1) << t;
            ekey_[e] = k;
            einfo_[e] = e;
        } else {
            ekey_[e] = 1u << (e - K_);
            einfo_[e] = -1;
        }
    }
    for (int i = nel - 1; i > 0; i--) {   /* random split */
        const int j = (int)(splitmix(rng_) % (uint64_t)(i + 1));
        std::swap(elems_[i], elems_[j]);
    }
    const int h1 = nel / 2;
    build_side(elems_.data(), h1, L1_);
    build_side(elems_.data() + h1, nel - h1, L2_);
    /* bucket L1 by key (counting sort) with the subset vectors sum A_j */
    const size_t nb = (size_t)1 << l_;
    std::fill(head_.begin(), head_.end(), 0);
    for (size_t t = 0; t < L1_.size(); t++) head_[L1_[t].key + 1]++;
    for (size_t b = 0; b < nb; b++) head_[b + 1] += head_[b];
    L1s_.resize(L1_.size());
    X1_.resize(L1_.size() * (size_t)rw_);
    D1_.resize(L1_.size() * (size_t)kw_);
    std::vector<int> fill(head_.begin(), head_.end() - 1);
    for (size_t t = 0; t < L1_.size(); t++) {
        const Sub& sb = L1_[t];
        const int q = fill[sb.key]++;
        L1s_[q] = sb;
        uint64_t* x = &X1_[(size_t)q * rw_];
        for (int w = 0; w < rw_; w++) x[w] = 0;
        if (sb.a >= 0) { const uint64_t* y = &At_[(size_t)sb.a * rw_]; for (int w = 0; w < rw_; w++) x[w] ^= y[w]; }
        if (sb.b >= 0) { const uint64_t* y = &At_[(size_t)sb.b * rw_]; for (int w = 0; w < rw_; w++) x[w] ^= y[w]; }
        uint64_t* dd = &D1_[(size_t)q * kw_];   /* detector parity of the subset's word */
        for (int t = 0; t < kw_; t++) dd[t] = 0;
        if (sb.a >= 0) { const uint64_t* y = det_of(sb.a); for (int t = 0; t < kw_; t++) dd[t] ^= y[t]; }
        if (sb.b >= 0) { const uint64_t* y = det_of(sb.b); for (int t = 0; t < kw_; t++) dd[t] ^= y[t]; }
    }
    /* match L2 against the buckets */
    std::vector<uint64_t> vb((size_t)rw_), db((size_t)kw_);
    const bool precheck = p_.mutant != 11;   /* mutant 11: no detector check anywhere */
    for (size_t t = 0; t < L2_.size(); t++) {
        const Sub& s2 = L2_[t];
        const int lo = head_[s2.key], hi = head_[s2.key + 1];
        if (lo == hi) continue;
        for (int w = 0; w < rw_; w++) vb[w] = 0;
        if (s2.a >= 0) { const uint64_t* y = &At_[(size_t)s2.a * rw_]; for (int w = 0; w < rw_; w++) vb[w] ^= y[w]; }
        if (s2.b >= 0) { const uint64_t* y = &At_[(size_t)s2.b * rw_]; for (int w = 0; w < rw_; w++) vb[w] ^= y[w]; }
        for (int u = 0; u < kw_; u++) db[u] = 0;
        if (s2.a >= 0) { const uint64_t* y = det_of(s2.a); for (int u = 0; u < kw_; u++) db[u] ^= y[u]; }
        if (s2.b >= 0) { const uint64_t* y = det_of(s2.b); for (int u = 0; u < kw_; u++) db[u] ^= y[u]; }
        for (int q = lo; q < hi; q++) {
            const Sub& s1 = L1s_[q];
            const int ni = s1.ninfo + s2.ninfo;
            if (ni == 0) continue;   /* only window elements: the zero word */
            st_.collisions++;
            if (precheck) {   /* trivial word (equal detector parities): skip before counting its weight */
                const uint64_t* d1 = &D1_[(size_t)q * kw_];
                uint64_t df = 0;
                for (int u = 0; u < kw_; u++) df |= d1[u] ^ db[u];
                if (!df) continue;
            }
            st_.coll_nt++;
            const int lim = thr();
            int c = ni;
            const uint64_t* x = &X1_[(size_t)q * rw_];
            for (int w = 0; w < rw_ && c <= lim; w++) c += __builtin_popcountll(x[w] ^ vb[w]);
            if (c > lim) continue;
            int js[4], cnt = 0;
            if (s1.a >= 0) js[cnt++] = s1.a;
            if (s1.b >= 0) js[cnt++] = s1.b;
            if (s2.a >= 0) js[cnt++] = s2.a;
            if (s2.b >= 0) js[cnt++] = s2.b;
            consider(c, js, cnt);
        }
    }
}

bool UbFinder::iterate_isd(int target, std::vector<int>& out) {
    const double t0 = now_s();
    st_.iterations++;
    out.clear();
    hit_ = false;
    if (K_ <= 0 || target <= 1) { st_.seconds += now_s() - t0; return false; }
    int best_raw = target - 1;
    int best = target;
    std::vector<uint64_t> bestw((size_t)W_, 0);
    bool found = false;
    std::vector<UbCand> cands;
    for (int b = 0; b < batch_; b++) {
        /* re-randomisation: a fresh elimination at the start / every isd_refresh rounds / with walk 0, else swaps */
        if (!isd_ready_ || p_.isd_walk == 0 || (p_.isd_refresh > 0 && rounds_ % (uint64_t)p_.isd_refresh == 0)) {
            eliminate_random();
            isd_ready_ = true;
        } else {
            for (int t = 0; t < p_.isd_walk; t++) cc_swap();
            std::fill(detok_.begin(), detok_.end(), 0);
            for (int j = 0; j < K_; j++) {
                int c = 1;
                const uint64_t* a = &At_[(size_t)j * rw_];
                for (int w = 0; w < rw_; w++) c += __builtin_popcountll(a[w]);
                wt1_[j] = c;
            }
        }
        rounds_++;
        st_.rounds++;
        cands.clear();
        isd_round(best_raw, cands);
        if (cands.empty()) continue;
        /* local improvement of the lightest kept words of this round (indices refer to this information set) */
        std::stable_sort(cands.begin(), cands.end(), [](const UbCand& u, const UbCand& v) { return u.w < v.w; });
        const int lim = best_raw + p_.slack;
        int done = 0;
        std::vector<uint64_t> cw((size_t)W_);
        for (size_t t = 0; t < cands.size() && done < p_.li_cap; t++) {
            const UbCand& cd = cands[t];
            if (cd.w > lim) break;
            build_word(cd.j, cd.cnt, cw);
            int w = cd.w;
            const int w2 = p_.mutant == 11 ? w : local_improve(cw, w);
            if (w2 < w) st_.li_gain++;
            w = w2;
            done++;
            if (w == target) hit_ = true;
            if (w > 0 && w < best) {
                best = w;
                bestw = cw;
                found = true;
                if (best - 1 < best_raw) best_raw = best - 1;   /* later rounds look below the new best */
            }
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
    st_.seconds += now_s() - t0;
    return found;
}

bool parse_isd(const char* s, UbParams& p) {
    UbParams d;   /* defaults */
    p.isd = 0; p.isd_p = d.isd_p; p.isd_l = d.isd_l; p.isd_walk = d.isd_walk; p.isd_batch = d.isd_batch;
    p.isd_refresh = d.isd_refresh;
    if (!strcmp(s, "off")) return true;
    const char* rest = NULL;
    if (!strncmp(s, "stern", 5)) { p.isd = 1; rest = s + 5; }
    else if (!strncmp(s, "dumer", 5)) { p.isd = 2; rest = s + 5; }
    else return false;
    if (!*rest) return true;
    if (*rest != ':') return false;
    rest++;
    if (!*rest) return false;   /* "stern:" without fields */
    const long long lo[5] = { 1, 0, 0, 1, 0 }, hi[5] = { 2, 20, 100000, 4096, 1000000000 };
    int* dst[5] = { &p.isd_p, &p.isd_l, &p.isd_walk, &p.isd_batch, &p.isd_refresh };
    for (int f = 0; f < 5; f++) {
        const char* e = rest;
        while (*e && *e != ',') e++;
        if (e > rest) {
            long long v = 0;
            for (const char* q = rest; q < e; q++) {
                if (*q < '0' || *q > '9') return false;
                v = v * 10 + (*q - '0');
                if (v > hi[f]) return false;
            }
            if (v < lo[f]) return false;
            *dst[f] = (int)v;
        }
        if (!*e) return true;
        rest = e + 1;
    }
    return false;   /* more than 5 fields */
}

std::string isd_desc(const UbParams& p, const UbFinder& f) {
    if (!p.isd) return "";
    char buf[200];
    snprintf(buf, sizeof(buf), ", collision %s p %d l %d walk %d batch %d refresh %d", p.isd == 2 ? "dumer" : "stern",
             p.isd_p, f.isd_l(), p.isd_walk, f.isd_batch(), p.isd_refresh);
    return buf;
}

} /* namespace distcc */
