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
#include <chrono>
#include <iterator>

namespace distcc {

namespace {

/* GH-227 erasure gate: monotonic clock in seconds (only sampled tests read it) */
inline double er_clock() {
    return std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
}

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

/* GH-183 (-cc-roworder=bfs): the seed-anchored reversed BFS order of the rows (see cc_half.h). rows: the input row list
 * (original row ids, in index order); new_of: relabeled label of each original qubit; the start qubit is relabeled label
 * 0. Returns the rows in the new order. Mutant 19 drops the last row of the result, mutant 20 does not restart the BFS. */
std::vector<int> reversed_bfs_rows(const SparseRows& H, const std::vector<int>& rows, const std::vector<int>& new_of, int n,
                                   int mutant) {
    const int mr = (int)rows.size();
    std::vector<std::vector<int> > rs((size_t)mr), cols((size_t)n);
    for (int i = 0; i < mr; i++) {
        const std::vector<int>& src = H.rows[(size_t)rows[i]];
        for (size_t t = 0; t < src.size(); t++)
            if (src[t] >= 0 && src[t] < n) rs[i].push_back(new_of[src[t]]);   /* range is checked by the caller */
        std::sort(rs[i].begin(), rs[i].end());
        rs[i].erase(std::unique(rs[i].begin(), rs[i].end()), rs[i].end());
        for (size_t t = 0; t < rs[i].size(); t++) cols[(size_t)rs[i][t]].push_back(i);   /* ascending row index */
    }
    std::vector<int> order;
    order.reserve((size_t)mr);
    std::vector<char> seen((size_t)mr, 0);
    for (size_t t = 0; t < cols[0].size(); t++) {
        const int i = cols[0][t];
        if (!seen[i]) { seen[i] = 1; order.push_back(i); }
    }
    size_t head = 0;
    for (int start = -1; start < mr; start++) {
        if (start >= 0) {
            if (mutant == 20) break;   /* mutant 20: no restart, unreachable rows are lost */
            if (seen[start]) continue;
            seen[start] = 1;
            order.push_back(start);
        }
        while (head < order.size()) {
            const int j = order[head++];
            for (size_t a = 0; a < rs[j].size(); a++) {
                const std::vector<int>& cr = cols[(size_t)rs[j][a]];
                for (size_t b = 0; b < cr.size(); b++)
                    if (!seen[cr[b]]) { seen[cr[b]] = 1; order.push_back(cr[b]); }
            }
        }
    }
    std::reverse(order.begin(), order.end());
    if (mutant == 19 && !order.empty()) order.pop_back();   /* mutant 19: the last row (a row of the seed) is dropped */
    std::vector<int> out;
    out.reserve(order.size());
    for (size_t i = 0; i < order.size(); i++) out.push_back(rows[(size_t)order[i]]);
    return out;
}

[[noreturn]] void fatal(const char* msg) {
    fprintf(stderr, "error: cc: %s\n", msg);
    abort();
}

/* GF(2) row normal form: sorted support, a qubit listed twice cancels */
std::vector<int> gf2_support(const std::vector<int>& src) {
    std::vector<int> g(src);
    std::sort(g.begin(), g.end());
    std::vector<int> h;
    for (size_t t = 0; t < g.size(); t++) {
        if (t + 1 < g.size() && g[t] == g[t + 1]) { t++; continue; }
        h.push_back(g[t]);
    }
    return h;
}

std::vector<int> sym_diff(const std::vector<int>& a, const std::vector<int>& b) {
    std::vector<int> r;
    std::set_symmetric_difference(a.begin(), a.end(), b.begin(), b.end(), std::back_inserter(r));
    return r;
}

/* GH-181: the distinct pair sums r = a + b of rows a, b of src (original labels) with 0 < |r| <= max(|a|, |b|) that
 * are not rows of src, lightest first, ties by the sorted support, at most cap rows. Only pairs sharing a qubit can
 * qualify (|r| = |a| + |b| - 2 |a & b|), so pairs are enumerated through the qubit -> rows lists. Each result is
 * recomputed from its two parents before it is returned (a construction check of r in the row space of src). */
std::vector<std::vector<int> > pair_sums(const std::vector<std::vector<int> >& src_in, int n, size_t cap) {
    std::vector<std::vector<int> > src;
    for (size_t r = 0; r < src_in.size(); r++) {
        std::vector<int> g = gf2_support(src_in[r]);
        for (size_t t = 0; t < g.size(); t++)
            if (g[t] < 0 || g[t] >= n) fatal("row entry out of range");
        if (!g.empty()) src.push_back(g);
    }
    std::sort(src.begin(), src.end());
    src.erase(std::unique(src.begin(), src.end()), src.end());
    const size_t m = src.size();
    std::vector<std::vector<uint32_t> > rows_of((size_t)n);
    for (size_t r = 0; r < m; r++)
        for (size_t t = 0; t < src[r].size(); t++) rows_of[(size_t)src[r][t]].push_back((uint32_t)r);
    /* overlap counts |a & b| for every later row b sharing a qubit with a (no allocation per pair); only pairs with
     * |a| + |b| - 2 |a & b| <= max(|a|, |b|) build their sum */
    std::vector<std::pair<std::vector<int>, uint64_t> > cand;
    std::vector<int> cnt(m, 0);
    std::vector<uint32_t> touched;
    for (size_t a = 0; a < m; a++) {
        touched.clear();
        for (size_t t = 0; t < src[a].size(); t++) {
            const std::vector<uint32_t>& rs = rows_of[(size_t)src[a][t]];
            for (size_t i = 0; i < rs.size(); i++)
                if (rs[i] > a) { if (cnt[rs[i]]++ == 0) touched.push_back(rs[i]); }
        }
        std::sort(touched.begin(), touched.end());
        for (size_t i = 0; i < touched.size(); i++) {
            const uint32_t b = touched[i];
            const size_t wa = src[a].size(), wb = src[b].size();
            const size_t ws = wa + wb - 2 * (size_t)cnt[b];
            cnt[b] = 0;
            if (ws == 0 || ws > std::max(wa, wb)) continue;
            std::vector<int> r = sym_diff(src[a], src[b]);
            if (std::binary_search(src.begin(), src.end(), r)) continue;
            cand.push_back(std::make_pair(r, (uint64_t)a * (uint64_t)m + b));
        }
    }
    std::sort(cand.begin(), cand.end(), [](const std::pair<std::vector<int>, uint64_t>& x, const std::pair<std::vector<int>, uint64_t>& y) {
        if (x.first.size() != y.first.size()) return x.first.size() < y.first.size();
        if (x.first != y.first) return x.first < y.first;
        return x.second < y.second;
    });
    std::vector<std::vector<int> > out;
    for (size_t t = 0; t < cand.size() && out.size() < cap; t++) {
        if (!out.empty() && out.back() == cand[t].first) continue;
        const uint64_t pr = cand[t].second;
        if (sym_diff(src[(size_t)(pr / m)], src[(size_t)(pr % m)]) != cand[t].first) fatal("redundant row is not the sum of its parents");
        out.push_back(cand[t].first);
    }
    return out;
}

} /* namespace */

HalfSearch::HalfSearch(const SparseRows& H, const SparseRows& G, const std::vector<int>& orbit_of,
                       const Rules& rules, uint64_t relabel_seed, int mutant, const SparseRows* K,
                       int roworder, bool tb_asc)
    : n_(H.cols), m_(0), k_(0), kw_(1), mw_(1), maxrow_(1), rules_(rules), mutant_(mutant), roworder_(roworder),
      orbit_mode_(false), allodd_(false), par_(false), mincw_(0), maxcw_(0), hmask_(0),
      ovr_(false), nk_(0), kminw_(0), kmaxw_(0), kzero_(0), ktie_(0), tb_(false), ovtight_(0), ovforbid_(0),
      lbminr_(3), lbgap_(0), lbauto_(40), lbautomin_(100000), lbany_(false), lbraise_(true),
      mx_(0), mxw_(0), ux_(0), ncls_(1), xminw_(0), xmaxw_(0), nk0_(0), nkx_(0), kxminw_(0), kxmaxw_(0), xu_(false), ovtightx_(0),
      er_(false), er_sizegate_(false), er_verify_(false), er_live_(false), er_thr_(false), er_kmask_(0), er_kmask8_(0), np_(0), estamp_(0), pmask_(0), epscan_(0), w_(0), nodd_(0),
      synkey_(0), stamp_(0), res_(NULL), incons_(false), poll_fn_(NULL), poll_ctx_(NULL), poll_mask_(0x3FFF), abort_(false), ext_(false)
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
    if (roworder_ != ROWORDER_INDEX && roworder_ != ROWORDER_BFS) fatal("unknown row order");
    if (roworder_ == ROWORDER_BFS) {   /* GH-183: internal row index = reversed seed-anchored BFS (a row permutation) */
        for (size_t i = 0; i < rows.size(); i++) {
            const std::vector<int>& src = H.rows[(size_t)rows[i]];
            for (size_t t = 0; t < src.size(); t++)
                if (src[t] < 0 || src[t] >= n_) fatal("row entry out of range");
        }
        rows = reversed_bfs_rows(H, rows, new_of, n_, mutant_);
    }
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

    /* GH-181 sparse: redundant rows R (pair sums of H's rows, original labels, then relabeled; with relabel_seed != 0
     * their order is shuffled as well). Mutant 22 removes the first qubit of every redundant row after the check. */
    ux_ = 64 * mw_;
    if (rules_.sparse) {
        std::vector<std::vector<int> > R = pair_sums(H.rows, n_, (size_t)4 * (size_t)m_);
        std::vector<std::vector<uint32_t> > Rn;   /* relabeled; order: weight, then relabeled support */
        for (size_t j = 0; j < R.size(); j++) {
            std::vector<int>& src = R[j];
            if (mutant_ == 22 && !src.empty()) src.erase(src.begin());
            std::vector<uint32_t> g;
            for (size_t t = 0; t < src.size(); t++) g.push_back((uint32_t)new_of[src[t]]);
            std::sort(g.begin(), g.end());
            Rn.push_back(g);
        }
        std::sort(Rn.begin(), Rn.end(), [](const std::vector<uint32_t>& x, const std::vector<uint32_t>& y) {
            return x.size() != y.size() ? x.size() < y.size() : x < y;
        });
        mx_ = (int)Rn.size();
        mxw_ = (mx_ + 63) / 64;
        xstart_.assign((size_t)mx_ + 1, 0);
        for (int j = 0; j < mx_; j++) {
            const std::vector<uint32_t>& g = Rn[(size_t)j];
            const int wt = (int)g.size();
            if (j == 0 || wt < xminw_) xminw_ = wt;
            if (j == 0 || wt > xmaxw_) xmaxw_ = wt;
            if (wt > maxrow_) maxrow_ = wt;
            xq_.insert(xq_.end(), g.begin(), g.end());
            xstart_[j + 1] = (uint32_t)xq_.size();
        }
        xcstart_.assign((size_t)n_ + 1, 0);
        for (size_t t = 0; t < xq_.size(); t++) xcstart_[xq_[t] + 1]++;
        for (int q = 0; q < n_; q++) xcstart_[q + 1] += xcstart_[q];
        xcr_.assign(xq_.size(), 0);
        std::vector<uint32_t> fill(xcstart_.begin(), xcstart_.end() - 1);
        for (int j = 0; j < mx_; j++)
            for (uint32_t t = xstart_[j]; t < xstart_[j + 1]; t++) xcr_[fill[xq_[t]]++] = (uint32_t)(ux_ + j);
        /* weight classes over the unified rows (pack / mrv scan order) */
        const int nw = mw_ + mxw_;
        std::vector<int> wts;
        for (int r = 0; r < m_; r++) wts.push_back((int)(rstart_[r + 1] - rstart_[r]));
        for (int j = 0; j < mx_; j++) wts.push_back((int)(xstart_[j + 1] - xstart_[j]));
        std::sort(wts.begin(), wts.end());
        wts.erase(std::unique(wts.begin(), wts.end()), wts.end());
        ncls_ = (int)wts.size();
        wcls_.assign((size_t)ncls_ * (size_t)nw, 0);
        for (int r = 0; r < m_; r++) {
            const int c = (int)(std::lower_bound(wts.begin(), wts.end(), (int)(rstart_[r + 1] - rstart_[r])) - wts.begin());
            wcls_[(size_t)c * nw + (r >> 6)] |= 1ULL << (r & 63);
        }
        for (int j = 0; j < mx_; j++) {
            const int u = ux_ + j;
            const int c = (int)(std::lower_bound(wts.begin(), wts.end(), (int)(xstart_[j + 1] - xstart_[j])) - wts.begin());
            wcls_[(size_t)c * nw + (u >> 6)] |= 1ULL << (u & 63);
        }
    }
    if (xcstart_.empty()) xcstart_.assign((size_t)n_ + 1, 0);

    /* parity rule: column weights (a row listing a qubit twice counts once, as in rq above) */
    allodd_ = true;
    mincw_ = n_ > 0 ? (int)(cstart_[1] - cstart_[0]) : 0;
    maxcw_ = mincw_;
    for (int q = 0; q < n_; q++) {
        const int cw = (int)(cstart_[q + 1] - cstart_[q]);
        if (!(cw & 1)) allodd_ = false;
        if (cw < mincw_) mincw_ = cw;
        if (cw > maxcw_) maxcw_ = cw;
    }
    par_ = rules_.parity && (allodd_ || mutant_ == 5);

    /* leaf rule: Zobrist keys per row and per qubit (column = XOR of its rows), hash table key -> qubits */
    {
        uint64_t ks = 0x5851f42d4c957f2dULL;
        rowkey_.assign((size_t)m_, 0);
        for (int i = 0; i < m_; i++) rowkey_[i] = splitmix64(ks);
        colkey_.assign((size_t)n_, 0);
        for (int q = 0; q < n_; q++)
            for (uint32_t i = cstart_[q], e = cstart_[q + 1]; i < e; i++) colkey_[q] ^= rowkey_[cr_[i]];
        size_t sz = 4;
        while (sz < 2 * (size_t)n_) sz <<= 1;
        hmask_ = (uint64_t)sz - 1;
        htab_.assign(sz, -1);
        hnext_.assign((size_t)n_, -1);
        for (int q = n_ - 1; q >= 0; q--) {   /* descending insertion: chains ascend (branch order) */
            uint64_t i = colkey_[q] & hmask_;
            for (;;) {
                const int32_t h = htab_[i];
                if (h < 0) { htab_[i] = q; break; }
                if (colkey_[h] == colkey_[q]) { hnext_[q] = h; htab_[i] = q; break; }
                i = (i + 1) & hmask_;
            }
        }
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

    /* overlap (GH-138): stabilizer rows K (mutant 9: the parity checks H instead), deduplicated; each row must
     * satisfy H g = 0 and G g = 0 (then e + g is in F for every e in F), otherwise the input is rejected */
    if (rules_.overlap) {
        const SparseRows* src = mutant_ == 9 ? &H : K;
        std::vector<std::vector<uint32_t> > kr;
        if (src) {
            if (src->cols != n_ && src->cols != 0 && !src->rows.empty()) fatal("stabilizer column count differs from H");
            for (size_t r = 0; r < src->rows.size(); r++) {
                std::vector<uint32_t> g;
                for (size_t t = 0; t < src->rows[r].size(); t++) {
                    const int q = src->rows[r][t];
                    if (q < 0 || q >= n_) fatal("stabilizer entry out of range");
                    g.push_back((uint32_t)new_of[q]);
                }
                std::sort(g.begin(), g.end());
                /* a qubit listed twice cancels over GF(2) */
                std::vector<uint32_t> h;
                for (size_t t = 0; t < g.size(); t++) {
                    if (t + 1 < g.size() && g[t] == g[t + 1]) { t++; continue; }
                    h.push_back(g[t]);
                }
                if (!h.empty()) kr.push_back(h);
            }
        }
        std::sort(kr.begin(), kr.end());
        kr.erase(std::unique(kr.begin(), kr.end()), kr.end());
        nk0_ = (int)kr.size();
        /* GH-181 sparseov: pair sums of K's rows (mutant 24: of H's rows), relabeled, appended after K's rows */
        const SparseRows* psrc = mutant_ == 24 ? &H : src;
        if (rules_.sparseov && psrc && !psrc->rows.empty()) {
            std::vector<std::vector<int> > P = pair_sums(psrc->rows, n_, (size_t)4 * (size_t)std::max(nk0_, 1));
            std::vector<std::vector<uint32_t> > add;
            for (size_t j = 0; j < P.size(); j++) {
                std::vector<uint32_t> g;
                for (size_t t = 0; t < P[j].size(); t++) g.push_back((uint32_t)new_of[P[j][t]]);
                std::sort(g.begin(), g.end());
                if (!std::binary_search(kr.begin(), kr.begin() + nk0_, g)) add.push_back(g);
            }
            std::sort(add.begin(), add.end());
            add.erase(std::unique(add.begin(), add.end()), add.end());
            kr.insert(kr.end(), add.begin(), add.end());
            nkx_ = (int)add.size();
        }
        if (mutant_ != 9) {   /* H g = 0 and G g = 0 for every row g (mutant 24: the added rows are not checked) */
            std::vector<uint8_t> par((size_t)m_, 0);
            std::vector<uint64_t> gp((size_t)kw_, 0);
            const size_t kcheck = mutant_ == 24 ? (size_t)nk0_ : kr.size();
            for (size_t r = 0; r < kcheck; r++) {
                std::fill(par.begin(), par.end(), 0);
                std::fill(gp.begin(), gp.end(), 0);
                for (size_t t = 0; t < kr[r].size(); t++) {
                    const uint32_t q = kr[r][t];
                    for (uint32_t i = cstart_[q], e = cstart_[q + 1]; i < e; i++) par[cr_[i]] ^= 1;
                    for (int j = 0; j < kw_; j++) gp[j] ^= gmask_[(size_t)q * kw_ + j];
                }
                for (int i = 0; i < m_; i++)
                    if (par[i]) fatal("stabilizer row with odd overlap with a parity check (not in ker H)");
                for (int j = 0; j < kw_; j++)
                    if (gp[j]) fatal("stabilizer row detected by a detector row (not trivial)");
            }
        }
        nk_ = (int)kr.size();
        ovr_ = nk_ > 0;
        kstart_.assign((size_t)nk_ + 1, 0);
        klim_.assign((size_t)nk_, 0);
        /* tiebreak (GH-162; the first(g) tie-break idea of Qubitserf 04b9349, S. Cercelescu, MIT): a row g of even weight
         * gets the limit |g|/2 - 1 on g' = g \ {f_g}, f_g = first(g) in the order pi_i of the current seed r_i: r_i first,
         * then the qubits of the exhausted blocks O_1..O_{i-1} (block order), then the base order (descending relabeled
         * label, tbrank_). In run_level: f_g = r_i on the rows through r_i (tb_seed), else the first qubit of g in an
         * exhausted block (kexfb_, tb_block_done), else the base-first member (kexbase_). Sound by the per-seed lex-min
         * argument (cc_half.h). Mutant 17: the tie is cut on the full row (limit |g|/2 - 1, no exempt qubit); mutant 18:
         * the base order alone for every row, also through the seed (the seed comes last: an orbit-incompatible order). */
        tb_ = rules_.tiebreak && mutant_ != 17;
        if (tb_) {
            tbrank_.assign((size_t)n_, 0);
            for (int q = 0; q < n_; q++) tbrank_[q] = tb_asc ? (uint32_t)q : (uint32_t)(n_ - 1 - q);   /* GH-183 -cc-tbbase */
        }
        kex_.assign((size_t)nk_, -1);
        kexbase_.assign((size_t)nk_, -1);
        kexfb_.assign((size_t)nk_, -1);
        for (int i = 0; i < nk_; i++) {
            const int wt = (int)kr[i].size();
            int lim = wt / 2;
            if (mutant_ == 8) lim = wt / 2 - 1;                       /* off by one */
            if (mutant_ == 10 && !(wt & 1)) lim = wt / 2 - 1;         /* even-weight tie cut */
            if (rules_.tiebreak && !(wt & 1)) {                       /* GH-162 (mutant 17: no exempt qubit) */
                lim = wt / 2 - 1;
                if (tb_) {
                    uint32_t f = kr[i][0];
                    for (size_t t = 1; t < kr[i].size(); t++)
                        if (tbrank_[kr[i][t]] < tbrank_[f]) f = kr[i][t];
                    kex_[i] = kexbase_[i] = (int32_t)f;
                }
                ktie_++;
            }
            if (lim < 0) lim = 0;
            klim_[i] = lim;
            if (lim == 0) kzero_++;
            if (i == 0 || wt < kminw_) kminw_ = wt;
            if (i == 0 || wt > kmaxw_) kmaxw_ = wt;
            if (i >= nk0_ && (i == nk0_ || wt < kxminw_)) kxminw_ = wt;
            if (i >= nk0_ && (i == nk0_ || wt > kxmaxw_)) kxmaxw_ = wt;
            kstart_[i + 1] = kstart_[i] + (uint32_t)wt;
            kq_.insert(kq_.end(), kr[i].begin(), kr[i].end());
        }
        kcstart_.assign((size_t)n_ + 1, 0);
        for (size_t t = 0; t < kq_.size(); t++) kcstart_[kq_[t] + 1]++;
        for (int q = 0; q < n_; q++) kcstart_[q + 1] += kcstart_[q];
        kcr_.assign(kq_.size(), 0);
        std::vector<uint32_t> fill(kcstart_.begin(), kcstart_.end() - 1);
        for (int i = 0; i < nk_; i++)
            for (uint32_t t = kstart_[i]; t < kstart_[i + 1]; t++) kcr_[fill[kq_[t]]++] = (uint32_t)i;
        slack_.assign((size_t)nk_, 0);
    }

    if (rules_.charge) {   /* GH-157 scratch */
        lbrs_.assign((size_t)m_ + 1, 0);
        lbrq_.assign((size_t)rstart_[m_] + 1, 0);
        lbw_.reset(n_, m_);
        lbany_ = true;
    }
    syn_.assign((size_t)(mw_ + mxw_), 0);   /* GH-181: words mw_.. hold the redundant rows */
    gpar_.assign((size_t)kw_, 0);
    xu_ = rules_.xorunit;
    ext_ = mx_ > 0 || nkx_ > 0 || xu_;
    if (xu_) {
        freecnt_.assign((size_t)64 * (size_t)(mw_ + mxw_), 1 << 30);   /* padding entries never reach 0 or 1 */
        unit_.assign((size_t)(mw_ + mxw_), 0);
        zero_.assign((size_t)(mw_ + mxw_), 0);
    }
    blk_.assign((size_t)n_, 0);
    mark_.assign((size_t)n_, 0);

    /* erasure (GH-195): scratch (the pair table is built lazily, erasure_pair_table_build) */
    er_ = rules_.erasure && rules_.pack;
    er_live_ = er_ && rules_.erasure_start == 0;
    if (er_) {
        prow_.assign((size_t)m_ + (size_t)mx_ + 1, 0);
        ecnt_.assign((size_t)m_, 0);
        esole_.assign((size_t)m_, 0);
        erows_.assign((size_t)m_, 0);
        eqs_.assign((size_t)n_, 0);
        ephi_ = rowkey_;
        eF_.assign((size_t)m_ * kw_, 0);
        elab_.assign((size_t)kw_, 0);
        etl_.assign((size_t)kw_, 0);
        eidx_.assign((size_t)n_, 0);
        /* fixed-size buffers (raw pointer writes in the test): region <= 128 qubits (larger regions are declined while
         * they are collected), touched rows <= m_, queue <= m_ + 128 * max column weight, affected qubits <= n_ */
        ereg_.assign((size_t)n_ + 1, 0);
        etouch_.assign((size_t)m_ + 1, 0);
        equeue_.assign((size_t)m_ + 128 * (size_t)maxcw_ + 1, 0);
        epq_.assign(129, 0);
        epr_.assign(129, 0);
        epiv_.assign(129, 0);
        echg_.assign(2 * 129, 0);
        ebas_.assign(129 * (size_t)mw_, 0);
        eblab_.assign(129 * (size_t)kw_, 0);
        eaff_.assign((size_t)n_ + 1, 0);
        eah_.assign((size_t)n_ + 1, 0);
        eal_.assign(((size_t)n_ + 1) * kw_, 0);
        /* GH-227 cost gate: every class starts on (the GH-195 behaviour until its samples say otherwise) */
        er_thr_ = rules_.erasure_gate == ERASURE_GATE_COST;
        if (er_thr_) {
            uint32_t k = rules_.erasure_sample;
            if (k == 0 || (k & (k - 1))) fatal("erasure gate: sample period must be a power of 2");
            er_kmask_ = k - 1;
            er_kmask8_ = (k <= (1u << 28) ? 8 * k : k) - 1;
            const size_t nc = 3 * (size_t)(ER_RMAX + 1);
            er_cnt_.assign(nc, 0);
            er_lvl_.assign(nc, 0);
            er_on_.assign(nc, 1);
            er_tt_.assign(nc, 0);
            er_st_.assign(nc, 0);
            er_ns_.assign(nc, 0);
        }
    }}

/* erasure (GH-195): the table of all qubit pairs keyed by the XOR of their column keys (n <= 2048: at most ~2.1M pairs). It
 * is built after n/2 tests have reached the pair stage with the scan (whose work, n lookups per test, then equals the
 * build cost), so short runs never pay for it; larger halves always scan. */
void HalfSearch::erasure_pair_table_build() {
    const size_t np = (size_t)n_ * (size_t)(n_ - 1) / 2;
    size_t sz = 4;
    while (sz < 2 * np) sz <<= 1;
    pmask_ = (uint64_t)sz - 1;
    phead_.assign(sz, -1);
    pnext_.reserve(np);
    pa_.reserve(np);
    pb_.reserve(np);
    for (int a = 0; a < n_; a++)
        for (int b = a + 1; b < n_; b++) {
            const uint64_t slot = (colkey_[a] ^ colkey_[b]) & pmask_;
            pa_.push_back((uint32_t)a);
            pb_.push_back((uint32_t)b);
            pnext_.push_back(phead_[slot]);
            phead_[slot] = (int32_t)(pa_.size() - 1);
        }
}


/* ---------------- GH-157: charge node lower bound ---------------- */

LbWork::LbWork() : st(0) {
    lcm[0] = 1;
    for (int d = 1; d <= 32; d++) {
        int64_t a = lcm[d - 1], b = d;
        while (b) { const int64_t t = a % b; a = b; b = t; }
        lcm[d] = lcm[d - 1] / a * d;   /* lcm(1..32) = 144403552893600 < 2^48 */
    }
}

void LbWork::reset(int nq, int maxrows) {
    cnt.assign((size_t)nq, 0);
    load.assign((size_t)nq, 0);
    mk.assign((size_t)nq, 0);
    st = 0;
    y.assign((size_t)(maxrows > 0 ? maxrows : 1), 0);
}

/* Charge (see cc_half.h). Pass 1: c_j = number of the k sets containing j (lazily reset by stamp), D = max c_j.
 * Pass 2: y_u = L / max_{j in u} c_j (scaled by L = lcm(1..D)); loads. Pass 3: raise. Exact integer arithmetic:
 * Y <= k L <= k 2^48, no overflow for k < 2^15 (k is at most the number of rows of H; checked). */
int lb_charge(const uint32_t* rs, const uint32_t* rq, int k, int r, LbWork& w, int mutant, bool raise) {
    const uint64_t st = ++w.st;
    int D = 0;
    for (int i = 0; i < k; i++) {
        if (rs[i] == rs[i + 1]) return LB_DEAD;
        for (uint32_t t = rs[i]; t < rs[i + 1]; t++) {
            const uint32_t j = rq[t];
            if (w.mk[j] != st) { w.mk[j] = st; w.cnt[j] = 0; w.load[j] = 0; }
            if (++w.cnt[j] > D) D = w.cnt[j];
        }
    }
    return lb_charge_counted(rs, rq, k, r, w, mutant, raise, D);
}

/* lb_charge after the counting pass: w.cnt[j] = c_j and w.load[j] = 0 for every j in the sets, D = max c_j, no empty set */
int lb_charge_counted(const uint32_t* rs, const uint32_t* rq, int k, int r, LbWork& w, int mutant, bool raise, int D) {
    if (D > 32 || k >= (1 << 15)) return 0;   /* idle: denominators too large for the scaled integers */
    const int64_t L = w.lcm[D];
    const int64_t R = r < 0 ? -1 : (int64_t)r * L;
    int64_t Y = 0;
    for (int i = 0; i < k; i++) {   /* local-degree charge; stops as soon as the sum exceeds r */
        int dm = 0;
        for (uint32_t t = rs[i]; t < rs[i + 1]; t++) if (w.cnt[rq[t]] > dm) dm = w.cnt[rq[t]];
        int64_t yi = L / dm;
        if (mutant == 15) yi += L / D;   /* mutant: charge inflated by 1/D (infeasible) */
        w.y[i] = yi;
        Y += yi;
        if (R >= 0 && Y > R) return (int)((Y + L - 1) / L);
    }
    if (!raise) return (int)((Y + L - 1) / L);
    for (int i = 0; i < k; i++)
        for (uint32_t t = rs[i]; t < rs[i + 1]; t++) w.load[rq[t]] += w.y[i];
    for (int i = 0; i < k; i++) {   /* raise: y_u += min residual capacity of its qubits (keeps feasibility) */
        int64_t s = L;
        for (uint32_t t = rs[i]; t < rs[i + 1]; t++) { const int64_t res = L - w.load[rq[t]]; if (res < s) s = res; }
        if (s <= 0) continue;
        w.y[i] += s;
        Y += s;
        for (uint32_t t = rs[i]; t < rs[i + 1]; t++) w.load[rq[t]] += s;
        if (R >= 0 && Y > R) break;
    }
    return (int)((Y + L - 1) / L);
}

/* GH-157: evaluate the charge at the current node (pack did not prune; the caller checked the budget, |U| and the gap
 * gate). The candidate sets of the odd rows are copied once (index order, c_j counted on the way) and handed to
 * lb_charge_counted, the second half of lb_charge, which the tests compare against brute force. Returns true if the node
 * is empty (the bound exceeds the remaining budget, or an odd row has no available qubit). */
bool HalfSearch::lb_prune(int size) {
    const int r = w_ - size;
    ++res_->lbeval;
    int k = 0, D = 0;
    uint32_t nq = 0;
    const uint64_t st = ++lbw_.st;   /* counting stamp (the copy pass also counts c_j, as lb_charge's first pass) */
    lbrs_[0] = 0;
    for (int wi = 0; wi < mw_; wi++) {
        uint64_t x = syn_[wi];
        while (x) {
            const int row = wi * 64 + __builtin_ctzll(x);
            x &= x - 1;
            for (uint32_t t = rstart_[row], e = rstart_[row + 1]; t < e; t++) {
                const uint32_t qb = rq_[t];
                if (blk_[qb]) continue;
                lbrq_[nq++] = qb;
                if (lbw_.mk[qb] != st) { lbw_.mk[qb] = st; lbw_.cnt[qb] = 0; lbw_.load[qb] = 0; }   /* lb_charge's counting */
                if (++lbw_.cnt[qb] > D) D = lbw_.cnt[qb];
            }
            if (lbrs_[k] == nq) { ++res_->lbdead; return true; }   /* odd row without an available qubit */
            lbrs_[++k] = nq;
        }
    }
    if (rules_.charge) {
        const int b = lb_charge_counted(&lbrs_[0], &lbrq_[0], k, r, lbw_, mutant_, lbraise_, D);
        if (b > r) { ++res_->chgprune; ++res_->lbprune_by_budget[(size_t)r]; return true; }
    }
    return false;
}

template <bool E> inline void HalfSearch::toggle(int q) {
    for (uint32_t i = cstart_[q], e = cstart_[q + 1]; i < e; i++) {
        const uint32_t r = cr_[i];
        uint64_t& wd = syn_[r >> 6];
        const uint64_t b = 1ULL << (r & 63);
        wd ^= b;
        nodd_ += (wd & b) ? 1 : -1;
    }
    if (E) for (uint32_t i = xcstart_[q], e = xcstart_[q + 1]; i < e; i++) {   /* GH-181 redundant rows (not in nodd_) */
        const uint32_t u = xcr_[i];
        syn_[u >> 6] ^= 1ULL << (u & 63);
    }
    synkey_ ^= colkey_[q];
    const uint64_t* g = &gmask_[(size_t)q * kw_];
    for (int j = 0; j < kw_; j++) gpar_[j] ^= g[j];
}

/* GH-181 xorunit: q left (d = -1) or rejoined (d = +1) the free qubits; update the free counts of its rows */
void HalfSearch::xu_count(uint32_t q, int d) {
    for (int pass = 0; pass < 2; pass++) {
        const uint32_t* a = pass == 0 ? cr_.data() + cstart_[q] : xcr_.data() + xcstart_[q];
        const uint32_t* e = pass == 0 ? cr_.data() + cstart_[q + 1] : xcr_.data() + xcstart_[q + 1];
        for (const uint32_t* t = a; t < e; ++t) {
            const uint32_t u = *t;
            const int32_t c = (freecnt_[u] += d);
            const uint64_t b = 1ULL << (u & 63);
            if (c == 1) unit_[u >> 6] |= b; else unit_[u >> 6] &= ~b;
            if (c == 0) zero_[u >> 6] |= b; else zero_[u >> 6] &= ~b;
        }
    }
}

template <bool E> inline void HalfSearch::blk_up(uint32_t q) {
    if (blk_[q]++ == 0 && E && xu_) xu_count(q, -1);
}

template <bool E> inline void HalfSearch::blk_down(uint32_t q) {
    if (--blk_[q] == 0 && E && xu_) xu_count(q, +1);
}

/* overlap (GH-138): q joins S. A row g that reaches its limit (|S & g| = floor(|g|/2)) forbids all its qubits
 * (those in S are blocked anyway; the count is undone symmetrically by ov_del). */
template <bool E> inline void HalfSearch::ov_add(int q) {
    if (tb_) { ov_add_tb<E>(q); return; }
    for (uint32_t i = kcstart_[q], e = kcstart_[q + 1]; i < e; i++) {
        const uint32_t g = kcr_[i];
        if (--slack_[g] == 0) {
            ++ovtight_;
            if (E && (int)g >= nk0_) ++ovtightx_;   /* GH-181 sparseov row */
            uint64_t nf = 0;
            for (const uint32_t *t = &kq_[kstart_[g]], *te = &kq_[kstart_[g + 1]]; t < te; ++t) { nf += blk_[*t] == 0; blk_up<E>(*t); }
            ovforbid_ += nf;
        }
    }
}

/* overlap: q leaves S (exact inverse of ov_add) */
template <bool E> inline void HalfSearch::ov_del(int q) {
    if (tb_) { ov_del_tb<E>(q); return; }
    for (uint32_t i = kcstart_[q], e = kcstart_[q + 1]; i < e; i++) {
        const uint32_t g = kcr_[i];
        if (slack_[g]++ == 0)
            for (const uint32_t *t = &kq_[kstart_[g]], *te = &kq_[kstart_[g + 1]]; t < te; ++t) blk_down<E>(*t);
    }
}

/* tiebreak (GH-162): as ov_add/ov_del on g' = g \ {kex_[g]} (kex_ = -1: the whole row). The exempt qubit is neither
 * counted nor forbidden: when g' is tight, the tie |S & g| = |g|/2 is still allowed through first(g). */
template <bool E> inline void HalfSearch::ov_add_tb(int q) {
    for (uint32_t i = kcstart_[q], e = kcstart_[q + 1]; i < e; i++) {
        const uint32_t g = kcr_[i];
        const int32_t x = kex_[g];
        if (x == q) continue;
        if (--slack_[g] == 0) {
            ++ovtight_;
            if (E && (int)g >= nk0_) ++ovtightx_;   /* GH-181 sparseov row */
            uint64_t nf = 0;
            for (const uint32_t *t = &kq_[kstart_[g]], *te = &kq_[kstart_[g + 1]]; t < te; ++t)
                if ((int32_t)*t != x) { nf += blk_[*t] == 0; blk_up<E>(*t); }   /* blk_up: GH-181 xorunit counters */
            ovforbid_ += nf;
        }
    }
}

template <bool E> inline void HalfSearch::ov_del_tb(int q) {
    for (uint32_t i = kcstart_[q], e = kcstart_[q + 1]; i < e; i++) {
        const uint32_t g = kcr_[i];
        const int32_t x = kex_[g];
        if (x == q) continue;
        if (slack_[g]++ == 0)
            for (const uint32_t *t = &kq_[kstart_[g]], *te = &kq_[kstart_[g + 1]]; t < te; ++t)
                if ((int32_t)*t != x) blk_down<E>(*t);
    }
}

/* tiebreak (GH-162): set the exempt qubit of row g to x with S empty. Only rows of limit 0 (|g| = 2) hold forbids at S
 * empty (g minus its exempt qubit); they are moved with the exemption. */
inline void HalfSearch::tb_set(uint32_t g, int32_t x) {
    const int32_t old = kex_[g];
    if (old == x) return;
    if (klim_[g] == 0) {   /* forbidden set g \ {old} becomes g \ {x} (blk_up/down: GH-181 xorunit counters) */
        blk_down<true>((uint32_t)x);
        ovforbid_ += blk_[old] == 0;
        blk_up<true>((uint32_t)old);
    }
    kex_[g] = x;
}

/* tiebreak: exempt qubits for the order pi_i of seed s = r_i (on) -- r_i first, then the qubits of the earlier orbits
 * O_1..O_{i-1} (in seed-block order), then the base order. Rows through r_i get r_i; the others keep their exemption
 * between seeds (kexfb_: first qubit of the row in an exhausted orbit, else kexbase_). off: undo the rows through r_i. */
void HalfSearch::tb_seed(int s, bool on) {
    for (uint32_t i = kcstart_[s], e = kcstart_[s + 1]; i < e; i++) {
        const uint32_t g = kcr_[i];
        if (kexbase_[g] < 0) continue;
        tb_set(g, on ? (int32_t)s : kexfb_[g] >= 0 ? kexfb_[g] : kexbase_[g]);
    }
}

/* tiebreak: orbit/seed block i is exhausted (it is forbidden for the later seeds); every row meeting it that has no
 * exempt qubit in an earlier block takes its first qubit in block i (mutant 18 keeps the base order) */
void HalfSearch::tb_block_done(size_t bi) {
    for (uint32_t t = bstart_[bi]; t < bstart_[bi + 1]; t++) {
        const uint32_t q = block_[t];
        for (uint32_t i = kcstart_[q], e = kcstart_[q + 1]; i < e; i++) {
            const uint32_t g = kcr_[i];
            if (kexbase_[g] < 0 || kexfb_[g] >= 0) continue;
            kexfb_[g] = (int32_t)q;
            tb_set(g, (int32_t)q);
        }
    }
}

inline bool HalfSearch::gpar_nonzero() const {
    uint64_t acc = 0;
    for (int j = 0; j < kw_; j++) acc |= gpar_[j];
    return acc != 0;
}

/* detector parity of S + q nonzero (mutant 7: no detector check at a leaf closure) */
inline bool HalfSearch::gpar_nonzero_with(int q) const {
    if (mutant_ == 7) return true;
    const uint64_t* g = &gmask_[(size_t)q * kw_];
    uint64_t acc = 0;
    for (int j = 0; j < kw_; j++) acc |= gpar_[j] ^ g[j];
    return acc != 0;
}

/* exact test col(q) == syn_: same weight and every row of q odd (keys are only a filter) */
inline bool HalfSearch::column_is_syndrome(int q) const {
    const uint32_t a = cstart_[q], e = cstart_[q + 1];
    if ((int)(e - a) != nodd_) return false;
    for (uint32_t i = a; i < e; i++) {
        const uint32_t r = cr_[i];
        if (!((syn_[r >> 6] >> (r & 63)) & 1)) return false;
    }
    return true;
}

/* leaf: the first free qubit (ascending, the branch order of any odd row, every one of which it lies in)
 * whose column equals the syndrome and whose closure is nontrivial; -1 if none */
inline int HalfSearch::closing_qubit() const {
    uint64_t i = synkey_ & hmask_;
    for (;;) {
        const int32_t h = htab_[i];
        if (h < 0) return -1;
        if (colkey_[h] == synkey_) {
            for (int q = h; q >= 0; q = hnext_[q])
                if (blk_[q] == 0 && column_is_syndrome(q) && gpar_nonzero_with(q)) return q;
            return -1;
        }
        i = (i + 1) & hmask_;
    }
}

inline int HalfSearch::key_head(uint64_t key) const {
    uint64_t i = key & hmask_;
    for (;;) {
        const int32_t h = htab_[i];
        if (h < 0 || colkey_[h] == key) return h;
        i = (i + 1) & hmask_;
    }
}

/* erasure (GH-195): true iff no completion S + y + z exists with y a subset of the region R (free qubits of the packed
 * rows prow_[0..np_-1], all marked with stamp st), z a set of at most `extra` eligible qubits (free, outside R), H(S + y + z)
 * = 0 and G(S + y + z) != 0. See cc_half.h for the argument; every test below that answers "a completion may exist"
 * returns false (no prune), and false is also returned whenever the test gives up. */
bool HalfSearch::erasure_excludes(int extra, uint64_t st) {
    return kw_ == 1 ? erasure_test<1>(extra, st) : erasure_test<0>(extra, st);
}

/* KW = 1: one detector word (k <= 64), compile-time loops; KW = 0: kw_ words */
template <int KW>
bool HalfSearch::erasure_test(int extra, uint64_t st) {
    const int kw = KW ? KW : kw_;
    estamp_ += 2;
    const uint64_t peeled = estamp_, affected = estamp_ + 1;
    /* region (declined above 128 qubits) */
    uint32_t* const reg = ereg_.data();
    int nreg = 0;
    for (int i = 0; i < np_; i++) {
        const uint32_t r = prow_[i];
        const bool red = (int)r >= ux_ && mx_ > 0;   /* GH-181 redundant row (a sum of rows of H) */
        const uint32_t* t = red ? &xq_[xstart_[r - ux_]] : &rq_[rstart_[r]];
        const uint32_t* e = red ? &xq_[xstart_[r - ux_ + 1]] : &rq_[rstart_[r + 1]];
        for (; t < e; ++t)
            if (blk_[*t] == 0) {
                if (nreg == 128) return false;
                reg[nreg++] = *t;
            }
    }
    /* per-row counts of region qubits and their XOR */
    uint32_t* const touch = etouch_.data();
    int32_t* const cnt = ecnt_.data();
    uint32_t* const sole = esole_.data();
    int ntouch = 0;
    for (int t = 0; t < nreg; t++) {
        const uint32_t q = reg[t];
        for (uint32_t i = cstart_[q], e = cstart_[q + 1]; i < e; i++) {
            const uint32_t r = cr_[i];
            if (cnt[r]++ == 0) { touch[ntouch++] = r; sole[r] = 0; }
            sole[r] ^= q;
        }
    }
    /* peeling: a row with exactly one unpeeled region qubit makes it a pivot (that qubit is in no kernel vector) */
    uint32_t* const que = equeue_.data();
    int nq = 0;
    for (int t = 0; t < ntouch; t++)
        if (cnt[touch[t]] == 1) que[nq++] = touch[t];
    uint32_t* const pq = epq_.data();
    uint32_t* const pr_of = epr_.data();
    int npeel = 0;
    for (int h = 0; h < nq; h++) {
        const uint32_t r = que[h];
        if (cnt[r] != 1) continue;
        const uint32_t q = sole[r];
        eqs_[q] = peeled;
        pq[npeel] = q;
        pr_of[npeel++] = r;
        for (uint32_t i = cstart_[q], e = cstart_[q + 1]; i < e; i++) {
            const uint32_t r2 = cr_[i];
            sole[r2] ^= q;
            if (--cnt[r2] == 1) que[nq++] = r2;
        }
    }
    for (int t = 0; t < ntouch; t++) cnt[touch[t]] = 0;
    /* dense elimination of the residual stopping set (its columns avoid every peel pivot row), labels carried along */
    uint32_t* const piv_of = epiv_.data();
    int rank = 0;
    if (npeel < nreg)
        for (int t = 0; t < nreg; t++) {
            const uint32_t q = reg[t];
            if (eqs_[q] == peeled) continue;
            uint64_t* col = &ebas_[(size_t)rank * mw_];
            uint64_t* lab = &eblab_[(size_t)rank * kw];
            for (int j = 0; j < mw_; j++) col[j] = 0;
            for (uint32_t i = cstart_[q], e = cstart_[q + 1]; i < e; i++) col[cr_[i] >> 6] |= 1ULL << (cr_[i] & 63);
            const uint64_t* g = &gmask_[(size_t)q * kw];
            for (int j = 0; j < kw; j++) lab[j] = g[j];
            for (int b = 0; b < rank; b++)
                if ((col[piv_of[b] >> 6] >> (piv_of[b] & 63)) & 1) {
                    const uint64_t* bv = &ebas_[(size_t)b * mw_];
                    for (int j = 0; j < mw_; j++) col[j] ^= bv[j];
                    const uint64_t* bl = &eblab_[(size_t)b * kw];
                    for (int j = 0; j < kw; j++) lab[j] ^= bl[j];
                }
            int piv = -1;
            for (int j = 0; j < mw_; j++)
                if (col[j]) { piv = j * 64 + __builtin_ctzll(col[j]); break; }
            if (piv < 0) {   /* a kernel vector of H_R; detected (nonzero label): the relaxation is not refuted, give up */
                uint64_t acc = 0;
                for (int j = 0; j < kw; j++) acc |= lab[j];
                if (acc) { ++res_->ergiveup; return false; }
                continue;
            }
            piv_of[rank++] = (uint32_t)piv;
        }
    /* back-substitution: phi (phi H_R = 0) and F (F H_R = G_R) on the pivot rows; the other rows keep phi = rowkey_, F = 0.
     * Dense pivots in reverse order (a basis vector has no earlier pivot), then peeled qubits in reverse peel order (a
     * peeled qubit's other rows are non-pivot rows, dense pivots or pivots of later peeled qubits). */
    uint32_t* const chg = echg_.data();
    int nchg = 0;
    for (int b = rank; b-- > 0;) {
        const uint32_t pr = piv_of[b];
        const uint64_t* bv = &ebas_[(size_t)b * mw_];
        uint64_t h = 0;
        uint64_t* F = &eF_[(size_t)pr * kw];
        const uint64_t* bl = &eblab_[(size_t)b * kw];
        for (int j = 0; j < kw; j++) elab_[j] = bl[j];
        for (int wi = 0; wi < mw_; wi++)
            for (uint64_t x = bv[wi]; x; x &= x - 1) {
                const uint32_t r = (uint32_t)(wi * 64 + __builtin_ctzll(x));
                if (r == pr) continue;
                h ^= ephi_[r];
                const uint64_t* Fr = &eF_[(size_t)r * kw];
                for (int j = 0; j < kw; j++) elab_[j] ^= Fr[j];
            }
        ephi_[pr] = h;
        for (int j = 0; j < kw; j++) F[j] = elab_[j];
        erows_[pr] = estamp_;
        chg[nchg++] = pr;
    }
    for (int t = npeel; t-- > 0;) {
        const uint32_t q = pq[t], pr = pr_of[t];
        uint64_t h = 0;
        uint64_t* F = &eF_[(size_t)pr * kw];
        const uint64_t* g = &gmask_[(size_t)q * kw];
        for (int j = 0; j < kw; j++) F[j] = g[j];   /* F[pr] is 0 here (pr is assigned once) and not read below */
        for (uint32_t i = cstart_[q], e = cstart_[q + 1]; i < e; i++) {
            const uint32_t r = cr_[i];
            if (r == pr) continue;
            h ^= ephi_[r];
            const uint64_t* Fr = &eF_[(size_t)r * kw];
            for (int j = 0; j < kw; j++) F[j] ^= Fr[j];
        }
        ephi_[pr] = h;
        erows_[pr] = estamp_;
        chg[nchg++] = pr;
    }
    bool result = true;
    if (er_verify_)   /* test hook: every region column projects to (0, 0) */
        for (int t = 0; t < nreg; t++) {
            const uint32_t q = reg[t];
            uint64_t h = 0;
            const uint64_t* g = &gmask_[(size_t)q * kw];
            for (int j = 0; j < kw; j++) elab_[j] = g[j];
            for (uint32_t i = cstart_[q], e = cstart_[q + 1]; i < e; i++) {
                h ^= ephi_[cr_[i]];
                const uint64_t* Fr = &eF_[(size_t)cr_[i] * kw];
                for (int j = 0; j < kw; j++) elab_[j] ^= Fr[j];
            }
            uint64_t acc = h;
            for (int j = 0; j < kw; j++) acc |= elab_[j];
            if (acc) fatal("erasure: region column does not project to zero");
        }
    /* target: projection of S, from its syndrome (odd rows) and detector parities (mutant 23: S ignored) */
    uint64_t th = 0;
    uint64_t tl[KW ? KW : 1];
    uint64_t* tlp = KW ? tl : &etl_[0];
    if (mutant_ == 26) for (int j = 0; j < kw; j++) tlp[j] = 0;
    else {
        for (int j = 0; j < kw; j++) tlp[j] = gpar_[j];
        for (int wi = 0; wi < mw_; wi++)
            for (uint64_t x = syn_[wi]; x; x &= x - 1) {
                const uint32_t r = (uint32_t)(wi * 64 + __builtin_ctzll(x));
                th ^= ephi_[r];
                if (erows_[r] == estamp_) {
                    const uint64_t* Fr = &eF_[(size_t)r * kw];
                    for (int j = 0; j < kw; j++) tlp[j] ^= Fr[j];
                }
            }
    }
    /* label tests: a != tl, a ^ b != tl */
    auto ne1 = [&](const uint64_t* a) { for (int j = 0; j < kw; j++) if (a[j] != tlp[j]) return true; return false; };
    auto ne2 = [&](const uint64_t* a, const uint64_t* b) {
        for (int j = 0; j < kw; j++) if ((a[j] ^ b[j]) != tlp[j]) return true;
        return false;
    };
    auto eligible = [this, st](uint32_t q) { return blk_[q] == 0 && mark_[q] != st; };
    uint32_t* const aff = eaff_.data();
    uint64_t* const ah = eah_.data();
    uint64_t* const al = eal_.data();
    int naff = 0;
    {   /* z empty: S + y itself */
        bool nz = false;
        for (int j = 0; j < kw; j++) nz |= tlp[j] != 0;
        if (th == 0 && nz) { result = false; goto done; }
    }
    if (extra == 0) goto done;
    /* affected qubits: eligible qubits on an assigned row; projection = (colkey_, G column) plus, per assigned row, the
     * change (phi ^ rowkey_, F) */
    naff = 0;
    for (int c = 0; c < nchg; c++) {
        const uint32_t r = chg[c];
        const uint64_t dh = ephi_[r] ^ rowkey_[r];
        const uint64_t* Fr = &eF_[(size_t)r * kw];
        for (uint32_t t = rstart_[r], e = rstart_[r + 1]; t < e; t++) {
            const uint32_t q = rq_[t];
            int32_t a;
            if (eqs_[q] != affected) {
                if (!eligible(q)) continue;
                eqs_[q] = affected;
                a = eidx_[q] = naff;
                aff[naff++] = q;
                ah[a] = colkey_[q];
                const uint64_t* g = &gmask_[(size_t)q * kw];
                uint64_t* l = &al[(size_t)a * kw];
                for (int j = 0; j < kw; j++) l[j] = g[j];
            } else a = eidx_[q];
            ah[a] ^= dh;
            uint64_t* l = &al[(size_t)a * kw];
            for (int j = 0; j < kw; j++) l[j] ^= Fr[j];
        }
    }
    /* single affected qubit */
    for (int a = 0; a < naff; a++)
        if (ah[a] == th && ne1(&al[(size_t)a * kw])) { result = false; goto done; }
    /* single unchanged qubit: projection (colkey_, G column) */
    for (int q = key_head(th); q >= 0; q = hnext_[q])
        if (eqs_[q] != affected && eligible((uint32_t)q) && ne1(&gmask_[(size_t)q * kw])) { result = false; goto done; }
    if (extra == 1) goto done;
    /* pairs: affected + affected through a small hash table (affected b inserted after it is checked against the earlier
     * ones; equal hashes chained), affected + unchanged through the leaf hash table */
    if (etab_.size() < 2 * (size_t)naff + 2) {
        size_t sz = 4;
        while (sz < 2 * (size_t)naff + 2) sz <<= 1;
        etab_.assign(sz, -1);
        etabst_.assign(sz, 0);
    }
    if (enext_.size() < (size_t)naff) enext_.resize((size_t)n_ + 1);
    {
        const uint64_t tm = (uint64_t)etab_.size() - 1;
        int32_t* const tab = etab_.data();
        uint64_t* const tst = etabst_.data();
        int32_t* const nxt = enext_.data();
        for (int a = 0; a < naff; a++) {
            const uint64_t want = th ^ ah[a];
            const uint64_t* la = &al[(size_t)a * kw];
            for (uint64_t i = want & tm; tst[i] == estamp_; i = (i + 1) & tm)
                if (ah[tab[i]] == want) {
                    for (int32_t b = tab[i]; b >= 0; b = nxt[b])
                        if (ne2(la, &al[(size_t)b * kw])) { result = false; goto done; }
                    break;
                }
            for (int q = key_head(want); q >= 0; q = hnext_[q])
                if (eqs_[q] != affected && eligible((uint32_t)q) && ne2(la, &gmask_[(size_t)q * kw])) { result = false; goto done; }
            uint64_t i = ah[a] & tm;
            while (tst[i] == estamp_ && ah[tab[i]] != ah[a]) i = (i + 1) & tm;
            if (tst[i] == estamp_) nxt[a] = tab[i];
            else { nxt[a] = -1; tst[i] = estamp_; }
            tab[i] = a;
        }
    }
    /* unchanged + unchanged */
    if (phead_.empty() && n_ >= 2 && n_ <= 2048 && ++epscan_ > (uint64_t)n_ / 2) erasure_pair_table_build();
    if (!phead_.empty()) {
        for (int32_t pi = phead_[th & pmask_]; pi >= 0; pi = pnext_[pi]) {
            const uint32_t a = pa_[pi], b = pb_[pi];
            if ((colkey_[a] ^ colkey_[b]) != th) continue;
            if (eqs_[a] == affected || eqs_[b] == affected || !eligible(a) || !eligible(b)) continue;
            if (ne2(&gmask_[(size_t)a * kw], &gmask_[(size_t)b * kw])) { result = false; goto done; }
        }
    } else {
        for (int a = 0; a < n_; a++) {
            if (eqs_[a] == affected || !eligible((uint32_t)a)) continue;
            for (int q = key_head(th ^ colkey_[a]); q >= 0; q = hnext_[q])
                if (q != a && eqs_[q] != affected && eligible((uint32_t)q) &&
                    ne2(&gmask_[(size_t)a * kw], &gmask_[(size_t)q * kw])) { result = false; goto done; }
        }
    }
done:
    /* restore phi = rowkey_ and F = 0 on the assigned rows */
    for (int c = 0; c < nchg; c++) {
        const uint32_t r = chg[c];
        ephi_[r] = rowkey_[r];
        uint64_t* F = &eF_[(size_t)r * kw];
        for (int j = 0; j < kw; j++) F[j] = 0;
    }
    return result;
}

void HalfSearch::record_witness(int size) {
    res_->witness.clear();
    for (int i = 0; i < size; i++) res_->witness.push_back(to_orig_[cur_[i]]);
    std::sort(res_->witness.begin(), res_->witness.end());
}

template <bool E> bool HalfSearch::dfs(int size) {
    ++res_->nodes;
    ++res_->by_budget[(size_t)(w_ - size)];
    if (poll_fn_ && !(res_->nodes & poll_mask_) && poll_fn_(poll_ctx_)) {   /* GH-140: abort requested */
        abort_ = true;
        return true;
    }
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
    /* parity: the qubits still to add must have the parity of the syndrome weight (implied for even w on a
     * qualifying half, see cc_half.h; it prunes only under mutant 5) */
    if (par_ && ((w_ - size - nodd_) & 1)) {
        ++res_->parprune;
        return false;
    }
    /* leaf, budget 1: the closing qubit (if any) is looked up instead of branching */
    const bool leaf = rules_.leaf;
    if (leaf && size == w_ - 1) {
        ++res_->leaf1;
        const int q = closing_qubit();
        if (q < 0) return false;
        cur_[size] = q;
        record_witness(size + 1);
        return true;
    }
    if (E && xu_) {   /* GH-181 xorunit: unit propagation (forbids undone on return) */
        const size_t mark = xtrail_.size();
        int forced = -1;
        bool hit = false;
        if (xu_propagate(size, forced)) hit = expand<E>(size, forced);
        while (xtrail_.size() > mark) {
            blk_down<E>(xtrail_.back());
            xtrail_.pop_back();
        }
        return hit;
    }
    return expand<E>(size, -1);
}

/* GH-181 xorunit, to a fixpoint: an even row with one free qubit forbids it (mutant 23: branches on it instead); then an
 * odd row without free qubit is a dead end (false), and an odd row with one free qubit is returned in forced */
bool HalfSearch::xu_propagate(int size, int& forced) {
    (void)size;
    forced = -1;
    const int nw = mw_ + mxw_;
    for (;;) {
        bool changed = false;
        for (int wi = 0; wi < nw; wi++) {
            uint64_t x = unit_[wi] & ~syn_[wi];   /* even rows with one free qubit */
            while (x) {
                const uint32_t u = (uint32_t)(wi * 64 + __builtin_ctzll(x));
                x &= x - 1;
                if (freecnt_[u] != 1) continue;   /* changed by a forbid earlier in this pass */
                const uint32_t *a, *e;
                if ((int)u < ux_) { a = &rq_[rstart_[u]]; e = &rq_[rstart_[u + 1]]; }
                else { a = &xq_[xstart_[u - ux_]]; e = &xq_[xstart_[u - ux_ + 1]]; }
                const uint32_t* t = a;
                while (t < e && blk_[*t]) ++t;
                if (t == e) fatal("xorunit: free count out of sync");
                if (mutant_ == 23) { forced = (int)u; return true; }
                blk_up<true>(*t);
                xtrail_.push_back(*t);
                ++res_->xuforbid;
                changed = true;
            }
        }
        if (!changed) break;
    }
    for (int wi = 0; wi < nw; wi++)
        if (zero_[wi] & syn_[wi]) { ++res_->xudead; return false; }
    for (int wi = 0; wi < nw; wi++) {
        const uint64_t x = unit_[wi] & syn_[wi];
        if (x) { forced = wi * 64 + __builtin_ctzll(x); break; }
    }
    return true;
}

/* the node's bound scan and branching (forced >= 0: branch on that row, GH-181 xorunit) */
template <bool E> __attribute__((always_inline)) inline bool HalfSearch::expand(int size, int forced) {
    const bool leaf = rules_.leaf;
    const bool meet = leaf && size == w_ - (mutant_ == 6 ? 3 : 2);   /* budget 2: lookup instead of recursion */

    /* scan the odd rows in index order: packing bound, no-candidate dead end, branching row */
    const bool pack = rules_.pack, mrv = rules_.mrv || (E && rules_.sparsemrv && mx_ > 0);   /* GH-181 sparsemrv */
    const uint64_t st = ++stamp_;
    int p = 0, brow = -1;
    /* GH-157: charge only where a hitting-set bound can exceed the remaining budget (tau <= |U| = nodd_) */
    const bool lbon = lbany_ && w_ - size >= lbminr_ && nodd_ > w_ - size;

    uint32_t bcnt = UINT32_MAX;
    /* GH-181 sparse (pack or mrv): the odd rows of H and R are scanned by weight class, lightest first (within a class
     * by unified index, H's rows first); without the token one class holds every row of H (index order, as before) */
    const bool cls = E && rules_.sparse && (pack || mrv);
    const int ncls = cls ? ncls_ : 1;
    const int nw = cls ? mw_ + mxw_ : mw_;
    int pr = 0;   /* redundant rows in the packing */
    for (int c = 0; c < ncls && !(brow >= 0 && !pack && !mrv); c++)
    for (int wi = 0; wi < nw && !(brow >= 0 && !pack && !mrv); wi++) {
        uint64_t x = syn_[wi];
        if (cls) x &= wcls_[(size_t)c * (size_t)nw + (size_t)wi];
        const bool red = E && wi >= mw_;
        while (x) {
            const int r = wi * 64 + __builtin_ctzll(x);
            x &= x - 1;
            const uint32_t* a = red ? &xq_[xstart_[r - ux_]] : &rq_[rstart_[r]];
            const uint32_t* e = red ? &xq_[xstart_[r - ux_ + 1]] : &rq_[rstart_[r + 1]];
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
                    if (red) ++res_->snocand;
                    return false;
                }
                if (disjoint) {
                    ++p;
                    if (red) { ++res_->spack; ++pr; }
                    if (mutant_ == 2 ? size + p >= w_ : size + p > w_) {
                        ++res_->packprune;
                        if (pr > 0) ++res_->sprune;
                        return false;
                    }
                    if (er_live_) prow_[p - 1] = (uint32_t)r;   /* erasure (GH-195): packed rows */
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
    if (cls && !mrv) {   /* the branching row stays the lowest-index odd row of H */
        brow = -1;
        for (int wi = 0; wi < mw_ && brow < 0; wi++)
            if (syn_[wi]) brow = wi * 64 + __builtin_ctzll(syn_[wi]);
    }
    if (E && forced >= 0) {   /* GH-181 xorunit: an odd row with one free qubit (mutant 23: an even one) */
        brow = forced;
        ++res_->xuforced;
    }
    if (brow < 0) return false;   /* unreachable: nodd_ > 0 */
    /* gap gate: evaluated only when the packing is within lb-gap of pruning (r - p <= gap; prunes concentrate at
     * r = p); without pack always. Skipping an evaluation only skips a sound prune. */
    if (lbon && (!pack || w_ - size - p <= lbgap_) && lb_prune(size)) return false;
    /* erasure (GH-195): at most `extra` qubits of a kept target lie outside the packed rows' candidates (mutant 25: one
     * fewer is assumed); gate (cost only): extra <= 2 (test hook: also 2|S| + 2 <= w) */
    /* GH-227 cost gate (-cc-erasure-gate=cost): per class (remaining budget, extra), every erasure_sample-th eligible node is a
     * sample (test timed, never pruned, subtree searched and timed); the other eligible nodes are tested only while the class
     * is on. Skipping a test or a prune is always sound; the test itself is unchanged. */
    int erc = -1;          /* class of a sampled node whose test would prune (its subtree is timed below) */
    double ert0 = 0, ertt = 0;
    if (er_live_ && pack) {
        const int extra = (w_ - size) - p - (mutant_ == 25 ? 1 : 0);
        if (extra >= 0 && extra <= 2 && (!er_sizegate_ || 2 * size + 2 <= w_)) {
            bool smp = false;
            int c = -1;
            if (er_thr_) {
                const int rr = w_ - size;
                c = 3 * (rr < ER_RMAX ? rr : ER_RMAX) + extra;
                /* period K while the class is on, 8 K while it is off (an off sample costs a test that is not otherwise run) */
                smp = (er_cnt_[(size_t)c]++ & (er_on_[(size_t)c] ? er_kmask_ : er_kmask8_)) == 0;
            }
            if (!er_thr_ || smp || er_on_[(size_t)c]) {
                ++res_->ercalls;
                np_ = p;
                if (smp) {
                    ++res_->ersample;
                    ert0 = er_clock();
                    const bool ex = erasure_excludes(extra, st);
                    const double t1 = er_clock();
                    ertt = t1 - ert0;
                    if (ex) { erc = c; ert0 = t1; }
                    else {
                        er_sample_done(c, ertt, false, 0);
                        if (mutant_ == 27) return false;   /* mutant 27: a sample the test does not exclude is pruned */
                    }
                } else if (erasure_excludes(extra, st)) {
                    ++res_->erprune;
                    return false;
                }
            } else {
                ++res_->erskip;
                if (mutant_ == 28) return false;   /* mutant 28: a node of an off class is pruned without the test */
            }
        }
    }

    uint32_t* cb = &cand_[(size_t)size * (size_t)maxrow_];
    int nc = 0;
    {
        const bool red = E && brow >= ux_;
        const uint32_t* a = red ? &xq_[xstart_[brow - ux_]] : &rq_[rstart_[brow]];
        const uint32_t* e = red ? &xq_[xstart_[brow - ux_ + 1]] : &rq_[rstart_[brow + 1]];
        for (const uint32_t* t = a; t < e; ++t)
            if (!blk_[*t]) cb[nc++] = *t;
    }
    int excluded = 0;
    bool hit = false;
    /* overlap: the counters are updated only for children of remaining budget >= 3. A child of budget 1 (completed
     * by the meet lookup) or 2 (a meet node, whose children are lookups and are not counted as nodes) gains nothing:
     * every closure found below it is an element of F of weight w, hence of minimum weight, and satisfies every
     * overlap limit by itself, so its forbids could only remove closures that do not exist (a sound omission; the
     * node counts are unchanged, the row updates are saved). Without the leaf rule every child is updated. */
    const bool ovrc = ovr_ && !meet && !(rules_.leaf && size + 1 >= w_ - 2);
    for (int i = 0; i < nc; i++) {
        const int a = (int)cb[i];
        blk_up<E>((uint32_t)a);
        toggle<E>(a);
        if (ovrc) ov_add<E>(a);
        cur_[size] = a;
        if (meet) {   /* the child S + a is closed by one more qubit iff syn(S + a) is a free column */
            if (nodd_ == 0) {   /* as dfs(size + 1) would: dead end, or an inconsistency if nontrivial */
                ++res_->closed;
                if (gpar_nonzero()) {
                    incons_ = true;
                    record_witness(size + 1);
                    hit = true;
                }
            } else {
                ++res_->leaf2;
                const int q = closing_qubit();
                if (q >= 0) {
                    cur_[size + 1] = q;
                    record_witness(size + 2);
                    hit = true;
                }
            }
        } else {
            hit = dfs<E>(size + 1);
        }
        if (ovrc) ov_del<E>(a);
        toggle<E>(a);
        blk_down<E>((uint32_t)a);
        if (hit) break;
        if (rules_.excl) {   /* sibling exclusion: a is forbidden in the later siblings */
            blk_up<E>((uint32_t)a);
            excluded = i + 1;
        }
    }
    if (mutant_ != 1)   /* restore the forbidden set (mutant 1 leaves it) */
        for (int i = 0; i < excluded; i++) blk_down<E>(cb[i]);
    if (erc >= 0) er_sample_done(erc, ertt, true, er_clock() - ert0);   /* GH-227: the time this prune would have saved */
    return hit;
}

/* GH-227 cost gate: record one sample of class c and re-decide the class (on iff saved > (1 + margin) x test time) */
void HalfSearch::er_sample_done(int c, double test_s, bool pruned, double sub_s) {
    const size_t i = (size_t)c;
    er_tt_[i] += test_s;
    if (pruned) er_st_[i] += sub_s;
    er_ns_[i] += 1;
    er_lvl_[i]++;
    er_on_[i] = er_st_[i] > (1 + rules_.erasure_margin) * er_tt_[i];
}

/* GH-227: -cc-stats snapshot of the classes, then the sums are halved (recent levels weigh more) */
void HalfSearch::er_level_end(LevelResult& r) {
    for (size_t i = 0; i < er_on_.size(); i++) {
        if (er_ns_[i] <= 0) continue;
        r.erclass.push_back((double)(i / 3));
        r.erclass.push_back((double)(i % 3));
        r.erclass.push_back(er_on_[i] ? 1.0 : 0.0);
        r.erclass.push_back(er_ns_[i]);
        r.erclass.push_back(1e6 * er_tt_[i] / er_ns_[i]);
        r.erclass.push_back(1e6 * er_st_[i] / er_ns_[i]);
        r.erclass.push_back((double)er_lvl_[i]);
        er_tt_[i] *= 0.5;
        er_st_[i] *= 0.5;
        er_ns_[i] *= 0.5;
        er_lvl_[i] = 0;
    }
}

LevelResult HalfSearch::run_level(int w) {
    LevelResult r;
    if (w < 1 || w > n_) return r;
    if (par_ && (w & 1)) {   /* parity: every element of ker H has even weight, so an odd level is empty */
        r.skipped = true;
        return r;
    }
    res_ = &r;
    w_ = w;
    incons_ = false;
    abort_ = false;
    std::fill(syn_.begin(), syn_.end(), 0);
    std::fill(gpar_.begin(), gpar_.end(), 0);
    std::fill(blk_.begin(), blk_.end(), 0);
    nodd_ = 0;
    synkey_ = 0;
    ovtight_ = ovforbid_ = 0;
    ovtightx_ = 0;
    if (xu_) {   /* GH-181: every qubit free; free count = row weight */
        xtrail_.clear();
        std::fill(unit_.begin(), unit_.end(), 0);
        std::fill(zero_.begin(), zero_.end(), 0);
        for (int u = 0; u < m_; u++) freecnt_[u] = (int32_t)(rstart_[u + 1] - rstart_[u]);
        for (int j = 0; j < mx_; j++) freecnt_[ux_ + j] = (int32_t)(xstart_[j + 1] - xstart_[j]);
        for (size_t u = 0; u < freecnt_.size(); u++) {
            if (freecnt_[u] == 1) unit_[u >> 6] |= 1ULL << (u & 63);
            if (freecnt_[u] == 0) zero_[u >> 6] |= 1ULL << (u & 63);
        }
    }
    if (ovr_) {   /* overlap: counters reset; rows with limit 0 (|g| = 1) forbid their qubits for the whole level */
        for (int g = 0; g < nk_; g++) {
            slack_[g] = klim_[g];
            if (tb_) { kex_[g] = kexbase_[g]; kexfb_[g] = -1; }
            if (klim_[g] == 0)
                for (uint32_t t = kstart_[g]; t < kstart_[g + 1]; t++) {
                    if (tb_ && (int32_t)kq_[t] == kex_[g]) continue;   /* tiebreak: |g| = 2, first(g) stays free */
                    ovforbid_ += blk_[kq_[t]] == 0;
                    blk_up<true>(kq_[t]);
                }
        }
    }
    cur_.assign((size_t)w, -1);
    cand_.assign((size_t)w * (size_t)maxrow_ + 1, 0);
    r.by_budget.assign((size_t)w + 1, 0);
    if (rules_.charge) r.lbprune_by_budget.assign((size_t)w + 1, 0);
    for (size_t i = 0; i < seed_.size(); i++) {
        const int s = seed_[i];
        /* mutant 3 (orbit seed rule off by one): the seed rule's forbidding of O_i is applied BEFORE the
         * search from r_i, so O_1..O_i (not O_1..O_{i-1}) are forbidden apart from r_i itself; this loses
         * every element of F that needs two qubits of its first orbit */
        const bool m3 = orbit_mode_ && mutant_ == 3;
        if (m3)
            for (uint32_t t = bstart_[i]; t < bstart_[i + 1]; t++) blk_up<true>(block_[t]);
        /* tiebreak (GH-162): pi_i puts r_i first (mutant 18: not done); before the seed check, since a row {r_i, x} of
         * the base order may forbid r_i */
        const bool tbs = tb_ && mutant_ != 18;
        if (tbs) tb_seed(s, true);
        /* a seed is never forbidden by an earlier seed, except through mutant 1's leak */
        if (blk_[s] == (m3 ? 1u : 0u)) {
            r.seeds++;
            if (!m3) blk_up<true>((uint32_t)s);
            toggle<true>(s);
            if (ovr_) ov_add<true>(s);
            cur_[0] = s;
            const bool hit = ext_ ? dfs<true>(1) : dfs<false>(1);
            if (ovr_) ov_del<true>(s);
            toggle<true>(s);
            if (!m3) blk_down<true>((uint32_t)s);
            if (hit) {
                if (tbs) tb_seed(s, false);
                r.verdict = abort_ ? LEVEL_ABORTED : incons_ ? LEVEL_INCONSISTENT : LEVEL_FOUND;
                if (abort_) r.witness.clear();
                r.ovtight = ovtight_;
                r.ovforbid = ovforbid_;
                r.ovtightx = ovtightx_;
                res_ = NULL;
                return r;
            }
        }
        if (tbs) tb_seed(s, false);
        /* seed rule: index rule forbids the seed; orbit rule forbids its whole orbit (mutant 3: done above) */
        if (!m3)
            for (uint32_t t = bstart_[i]; t < bstart_[i + 1]; t++) blk_up<true>(block_[t]);
        if (tbs) tb_block_done(i);
    }
    r.ovtight = ovtight_;
    r.ovforbid = ovforbid_;
    r.ovtightx = ovtightx_;
    res_ = NULL;
    lb_auto_update(r);
    if (er_thr_ && er_live_) er_level_end(r);   /* GH-227 */
    if (er_ && !er_live_ && r.nodes >= rules_.erasure_start) er_live_ = true;   /* GH-195: from the next level on */
    return r;
}

/* GH-157 -cc-lb-auto: after a completed EMPTY level with at least lbautomin_ evaluations, the node lower bound is
 * switched off for the rest of this half when fewer than lbauto_ percent of the evaluations pruned (cost-benefit
 * guard; skipping evaluations is always sound, and the decision depends only on deterministic counters). */
void HalfSearch::lb_auto_update(LevelResult& r) {
    if (!lbany_ || lbauto_ <= 0 || r.lbeval < lbautomin_) return;
    const uint64_t pr = r.chgprune;
    if (100 * pr < (uint64_t)lbauto_ * r.lbeval) {
        lbany_ = false;
        r.lbswitchoff = true;
    }
}

} /* namespace distcc */
