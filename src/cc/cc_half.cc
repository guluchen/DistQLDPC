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
                       const Rules& rules, uint64_t relabel_seed, int mutant, const SparseRows* K)
    : n_(H.cols), m_(0), k_(0), kw_(1), mw_(1), maxrow_(1), rules_(rules), mutant_(mutant),
      orbit_mode_(false), allodd_(false), par_(false), mincw_(0), maxcw_(0), hmask_(0),
      ovr_(false), nk_(0), kminw_(0), kmaxw_(0), kzero_(0), ovtight_(0), ovforbid_(0), lbminr_(3), lbgap_(0), lbany_(false), lbcheck_(false), chg_(false), chgL_(1), ecv_(false), w_(0), nodd_(0),
      synkey_(0), stamp_(0), res_(NULL), incons_(false), poll_fn_(NULL), poll_ctx_(NULL), poll_mask_(0x3FFF), abort_(false)
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
        if (mutant_ != 9) {   /* H g = 0 and G g = 0 for every row g */
            std::vector<uint8_t> par((size_t)m_, 0);
            std::vector<uint64_t> gp((size_t)kw_, 0);
            for (size_t r = 0; r < kr.size(); r++) {
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
        for (int i = 0; i < nk_; i++) {
            const int wt = (int)kr[i].size();
            int lim = wt / 2;
            if (mutant_ == 8) lim = wt / 2 - 1;                       /* off by one */
            if (mutant_ == 10 && !(wt & 1)) lim = wt / 2 - 1;         /* even-weight tie cut */
            if (lim < 0) lim = 0;
            klim_[i] = lim;
            if (lim == 0) kzero_++;
            if (i == 0 || wt < kminw_) kminw_ = wt;
            if (i == 0 || wt > kmaxw_) kmaxw_ = wt;
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

    if (rules_.charge || rules_.ecover) {   /* GH-157 scratch */
        lbrs_.assign((size_t)m_ + 1, 0);
        lbrq_.assign((size_t)rstart_[m_] + 1, 0);
        lbw_.reset(n_, m_);
        lbany_ = true;
        /* charge: scaled integers y(d) = L/d, L = lcm(1..max column weight) (every c_j <= the column weight);
         * idle if the maximum column weight exceeds 32 (L would not fit comfortably) or H has >= 2^15 rows */
        chg_ = rules_.charge && maxcw_ <= 32 && m_ < (1 << 15);
        for (int d = 0; d <= 32; d++) chgyv_[d] = 0;
        if (chg_) {
            chgL_ = lbw_.lcm[maxcw_ < 1 ? 1 : maxcw_];
            for (int d = 1; d <= maxcw_; d++) chgyv_[d] = chgL_ / d + (mutant_ == 15 ? chgL_ / maxcw_ : 0);
            lcnt_.assign((size_t)n_, 0);
            lload_.assign((size_t)n_, 0);
            lmk_.assign((size_t)n_, 0);
        }
        ecv_ = rules_.ecover;
        if (ecv_) {
            e2c_.assign((size_t)n_, 0);
            e2mk_.assign((size_t)n_, 0);
            e3mk_.assign((size_t)n_, 0);
            e2own_.assign((size_t)n_, -1);
            u2_.assign((size_t)m_ + 1, 0);
        }
    }

    syn_.assign((size_t)mw_, 0);
    gpar_.assign((size_t)kw_, 0);
    blk_.assign((size_t)n_, 0);
    mark_.assign((size_t)n_, 0);
}

/* ---------------- GH-157: charge / ecover node lower bounds ---------------- */

LbWork::LbWork() : st(0), st2(0) {
    lcm[0] = 1;
    for (int d = 1; d <= 32; d++) {
        int64_t a = lcm[d - 1], b = d;
        while (b) { const int64_t t = a % b; a = b; b = t; }
        lcm[d] = lcm[d - 1] / a * d;   /* lcm(1..32) = 144403552893600 < 2^48 */
    }
}

void LbWork::reset(int nq, int maxrows) {
    cnt.assign((size_t)nq, 0);
    c2.assign((size_t)nq, 0);
    own.assign((size_t)nq, -1);
    load.assign((size_t)nq, 0);
    mk.assign((size_t)nq, 0);
    mk2.assign((size_t)nq, 0);
    st = st2 = 0;
    const size_t m = (size_t)(maxrows > 0 ? maxrows : 1);
    y.assign(m, 0);
    match.assign(m, -1);
    par.assign(m, -1);
    base.assign(m, 0);
    q.assign(m, 0);
    used.assign(m, 0);
    blos.assign(m, 0);
    astart.assign(m + 1, 0);
}

/* Charge (see cc_half.h). Pass 1: c_j = number of the k sets containing j (lazily reset by stamp), D = max c_j.
 * Pass 2: y_u = L / max_{j in u} c_j (scaled by L = lcm(1..D)); loads. Pass 3: raise. Exact integer arithmetic:
 * Y <= k L <= k 2^48, no overflow for k < 2^15 (k is at most the number of rows of H; checked). */
int lb_charge(const uint32_t* rs, const uint32_t* rq, int k, int r, LbWork& w, int mutant) {
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
    if (D > 32 || k >= (1 << 15)) return 0;   /* idle: denominators too large for the scaled integers */
    const int64_t L = w.lcm[D];
    int64_t Y = 0;
    for (int i = 0; i < k; i++) {
        int dm = 0;
        for (uint32_t t = rs[i]; t < rs[i + 1]; t++) if (w.cnt[rq[t]] > dm) dm = w.cnt[rq[t]];
        int64_t yi = L / dm;
        if (mutant == 15) yi += L / D;   /* mutant: charge inflated by 1/D (infeasible) */
        w.y[i] = yi;
        Y += yi;
        for (uint32_t t = rs[i]; t < rs[i + 1]; t++) w.load[rq[t]] += yi;
    }
    const int64_t R = r < 0 ? -1 : (int64_t)r * L;
    if (R >= 0 && Y > R) return (int)((Y + L - 1) / L);
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

/* Edmonds' blossom algorithm (BFS from each exposed vertex, blossom contraction by base relabelling), O(V^3);
 * graphs here have at most a few dozen vertices. Written from the textbook description of the algorithm. */
namespace {
struct Blossom {
    LbWork& w;
    int n;
    explicit Blossom(LbWork& ww, int nv) : w(ww), n(nv) {}
    int lca(int a, int b) {
        std::fill(w.used.begin(), w.used.begin() + n, 0);
        for (;;) {
            a = w.base[a];
            w.used[a] = 1;
            if (w.match[a] < 0) break;
            a = w.par[w.match[a]];
        }
        for (;;) {
            b = w.base[b];
            if (w.used[b]) return b;
            b = w.par[w.match[b]];
        }
    }
    void mark_path(int v, int b, int child) {
        while (w.base[v] != b) {
            w.blos[w.base[v]] = w.blos[w.base[w.match[v]]] = 1;
            w.par[v] = child;
            child = w.match[v];
            v = w.par[w.match[v]];
        }
    }
    int find_path(int root) {
        std::fill(w.used.begin(), w.used.begin() + n, 0);
        std::fill(w.par.begin(), w.par.begin() + n, -1);
        for (int i = 0; i < n; i++) w.base[i] = i;
        w.used[root] = 1;
        int qh = 0, qt = 0;
        w.q[qt++] = root;
        while (qh < qt) {
            const int v = w.q[qh++];
            for (int t = w.astart[v]; t < w.astart[v + 1]; t++) {
                const int to = w.adj[t];
                if (w.base[v] == w.base[to] || w.match[v] == to) continue;
                if (to == root || (w.match[to] >= 0 && w.par[w.match[to]] >= 0)) {
                    const int cb = lca(v, to);
                    std::fill(w.blos.begin(), w.blos.begin() + n, 0);
                    mark_path(v, cb, to);
                    mark_path(to, cb, v);
                    for (int i = 0; i < n; i++)
                        if (w.blos[w.base[i]]) {
                            w.base[i] = cb;
                            if (!w.used[i]) { w.used[i] = 1; w.q[qt++] = i; }
                        }
                } else if (w.par[to] < 0) {
                    w.par[to] = v;
                    if (w.match[to] < 0) return to;
                    const int t2 = w.match[to];
                    w.used[t2] = 1;
                    w.q[qt++] = t2;
                }
            }
        }
        return -1;
    }
};
} /* namespace */

int max_matching(int nv, const std::vector<int>& ea, const std::vector<int>& eb, int stop, LbWork& w) {
    if (nv <= 0) return 0;
    if ((int)w.match.size() < nv) w.reset((int)w.cnt.size(), nv);
    /* adjacency (CSR), self-loops dropped */
    std::fill(w.astart.begin(), w.astart.begin() + nv + 1, 0);
    const int ne = (int)ea.size();
    for (int e = 0; e < ne; e++) if (ea[e] != eb[e]) { w.astart[ea[e] + 1]++; w.astart[eb[e] + 1]++; }
    for (int v = 0; v < nv; v++) w.astart[v + 1] += w.astart[v];
    w.adj.resize((size_t)w.astart[nv] + 1);
    {
        std::vector<int>& fill = w.q;   /* q is free here: reused as the fill pointer */
        for (int v = 0; v < nv; v++) fill[v] = w.astart[v];
        for (int e = 0; e < ne; e++) if (ea[e] != eb[e]) { w.adj[fill[ea[e]]++] = eb[e]; w.adj[fill[eb[e]]++] = ea[e]; }
    }
    std::fill(w.match.begin(), w.match.begin() + nv, -1);
    int msz = 0;
    for (int e = 0; e < ne; e++)   /* greedy start */
        if (ea[e] != eb[e] && w.match[ea[e]] < 0 && w.match[eb[e]] < 0) { w.match[ea[e]] = eb[e]; w.match[eb[e]] = ea[e]; msz++; }
    Blossom bl(w, nv);
    for (int v = 0; v < nv && (stop < 0 || msz < stop); v++) {
        if (w.match[v] >= 0 || w.astart[v] == w.astart[v + 1]) continue;
        int u = bl.find_path(v);
        if (u < 0) continue;
        msz++;
        while (u >= 0) {   /* augment along the alternating path */
            const int pv = w.par[u], ppv = w.match[pv];
            w.match[u] = pv;
            w.match[pv] = u;
            u = ppv;
        }
    }
    return msz;
}

/* Edge cover (see cc_half.h). U' greedy in index order: a set is admitted iff none of its qubits already lies in 2
 * admitted sets (mutant 16: every set admitted). A qubit's second admitted set adds the edge (first, second); with
 * mutant 16 every further set adds an edge to the first one as well. The search selects U' the same way. */
int lb_ecover(const uint32_t* rs, const uint32_t* rq, int k, int r, LbWork& w, int mutant, bool* exact, int* nsel) {
    const uint64_t st = ++w.st2;
    int ns = 0;
    w.ea.clear();
    w.eb.clear();
    for (int i = 0; i < k; i++)
        if (rs[i] == rs[i + 1]) { *exact = false; *nsel = 0; return LB_DEAD; }
    for (int i = 0; i < k; i++) {
        bool ok = true;
        if (mutant != 16)
            for (uint32_t t = rs[i]; t < rs[i + 1]; t++) {
                const uint32_t j = rq[t];
                if (w.mk2[j] == st && w.c2[j] >= 2) { ok = false; break; }
            }
        if (!ok) continue;
        const int v = ns++;
        for (uint32_t t = rs[i]; t < rs[i + 1]; t++) {
            const uint32_t j = rq[t];
            if (w.mk2[j] != st) { w.mk2[j] = st; w.c2[j] = 0; w.own[j] = -1; }
            if (w.c2[j] == 0) w.own[j] = v;
            else { w.ea.push_back(w.own[j]); w.eb.push_back(v); }
            w.c2[j]++;
        }
    }
    *exact = ns == k;
    *nsel = ns;
    /* |U'| - floor(|U'|/2) <= |U'| - nu <= |U'|: decided without the matching when either end settles it */
    if (r >= 0 && ns <= r) return ns;
    if (r >= 0 && ns - ns / 2 > r) return ns - ns / 2;
    const int nu = max_matching(ns, w.ea, w.eb, r >= 0 ? ns - r : -1, w);
    return ns - nu;
}

/* candidate sets of the odd rows (index order) as CSR in lbrs_/lbrq_ (ecover, and the test cross-check) */
void HalfSearch::lb_build_sets(int& k) {
    k = 0;
    uint32_t nq = 0;
    lbrs_[0] = 0;
    for (int wi = 0; wi < mw_; wi++) {
        uint64_t x = syn_[wi];
        while (x) {
            const int row = wi * 64 + __builtin_ctzll(x);
            x &= x - 1;
            for (uint32_t t = rstart_[row], e = rstart_[row + 1]; t < e; t++) {
                const uint32_t qb = rq_[t];
                if (!blk_[qb]) lbrq_[nq++] = qb;
            }
            lbrs_[++k] = nq;
        }
    }
}

/* GH-157 ecover: admit one odd row to U' iff none of its free qubits already lies in 2 admitted rows (mutant 16:
 * always); rows are offered in index order */
inline void HalfSearch::lb_admit_row(int row, uint64_t st, int& nu2) {
    const uint32_t* a = &rq_[rstart_[row]];
    const uint32_t* e = &rq_[rstart_[row + 1]];
    if (mutant_ != 16)
        for (const uint32_t* t = a; t < e; ++t)
            if (!blk_[*t] && e2mk_[*t] == st && e2c_[*t] >= 2) return;
    for (const uint32_t* t = a; t < e; ++t) {
        const uint32_t j = *t;
        if (blk_[j]) continue;
        if (e2mk_[j] != st) { e2mk_[j] = st; e2c_[j] = 0; }
        if (e2c_[j] < 255) e2c_[j]++;
    }
    u2_[nu2++] = row;
}

/* GH-157: evaluate charge, then ecover, at the current node (pack did not prune; the caller checked the budget, |U|
 * and the gap gate). Both bounds are computed on the search state exactly as lb_charge / lb_ecover compute them on
 * explicit sets (same row order, same integers); the test hook set_lb_check compares the decisions. Returns true if
 * the node is empty (a bound exceeds the remaining budget, or an odd row has no available qubit). */
bool HalfSearch::lb_prune(int size, uint64_t st) {
    const int r = w_ - size;
    ++res_->lbeval;
    if (chg_) {
        bool dead = false;
        const int64_t L = chgL_, R = (int64_t)r * L;
        /* c_j for the free qubits of the odd rows (loads reset) */
        for (int wi = 0; wi < mw_; wi++) {
            uint64_t x = syn_[wi];
            while (x) {
                const int row = wi * 64 + __builtin_ctzll(x);
                x &= x - 1;
                for (uint32_t t = rstart_[row], e = rstart_[row + 1]; t < e; t++) {
                    const uint32_t j = rq_[t];
                    if (blk_[j]) continue;
                    if (lmk_[j] != st) { lmk_[j] = st; lcnt_[j] = 0; lload_[j] = 0; }
                    ++lcnt_[j];
                }
            }
        }
        /* local-degree charge y_u = L / max_{j in N(u) & A} c_j, and loads */
        int64_t Y = 0;
        for (int wi = 0; wi < mw_ && !dead; wi++) {
            uint64_t x = syn_[wi];
            while (x) {
                const int row = wi * 64 + __builtin_ctzll(x);
                x &= x - 1;
                const uint32_t* a = &rq_[rstart_[row]];
                const uint32_t* e = &rq_[rstart_[row + 1]];
                int dm = 0;
                for (const uint32_t* t = a; t < e; ++t) if (!blk_[*t] && lcnt_[*t] > dm) dm = lcnt_[*t];
                if (dm == 0) { dead = true; break; }
                const int64_t yi = chgyv_[dm];
                Y += yi;
                for (const uint32_t* t = a; t < e; ++t) if (!blk_[*t]) lload_[*t] += yi;
            }
        }
        bool raised = false;
        if (!dead && Y <= R) {   /* raise, row by row in the same order */
            raised = true;
            for (int wi = 0; wi < mw_ && Y <= R; wi++) {
                uint64_t x = syn_[wi];
                while (x && Y <= R) {
                    const int row = wi * 64 + __builtin_ctzll(x);
                    x &= x - 1;
                    const uint32_t* a = &rq_[rstart_[row]];
                    const uint32_t* e = &rq_[rstart_[row + 1]];
                    int64_t sl = L;
                    for (const uint32_t* t = a; t < e; ++t) if (!blk_[*t] && L - lload_[*t] < sl) sl = L - lload_[*t];
                    if (sl <= 0) continue;
                    Y += sl;
                    for (const uint32_t* t = a; t < e; ++t) if (!blk_[*t]) lload_[*t] += sl;
                }
            }
        }
        const bool prune = !dead && Y > R;
        if (lbcheck_) {
            int k = 0;
            lb_build_sets(k);
            const int b = lb_charge(&lbrs_[0], &lbrq_[0], k, r, lbw_, 0);
            if ((b == LB_DEAD) != dead || (!dead && (b > r) != prune)) fatal("GH-157 check: in-search charge differs from lb_charge");
        }
        if (dead) { ++res_->lbdead; return true; }
        if (prune) { ++res_->chgprune; if (raised) ++res_->chgraise; ++res_->lbprune_by_budget[(size_t)r]; return true; }
    } else if (rules_.charge && lbcheck_) {   /* charge idle (column weight > 32): lb_charge must be idle too */
        int k = 0;
        lb_build_sets(k);
        const int b = lb_charge(&lbrs_[0], &lbrq_[0], k, r, lbw_, 0);
        if (b == LB_DEAD || b > r) fatal("GH-157 check: idle in-search charge but lb_charge prunes");
    }
    if (ecv_) {
        int nu2 = 0;
        {   /* U': greedy in index order */
            for (int wi = 0; wi < mw_; wi++) {
                uint64_t x = syn_[wi];
                while (x) {
                    const int row = wi * 64 + __builtin_ctzll(x);
                    x &= x - 1;
                    bool any = false;
                    for (uint32_t t = rstart_[row], e = rstart_[row + 1]; t < e && !any; t++) any = !blk_[rq_[t]];
                    if (!any) { ++res_->lbdead; return true; }
                    lb_admit_row(row, st, nu2);
                }
            }
        }
        const int ns = nu2;
        if (ns == nodd_) ++res_->ecexact;
        bool prune;
        if (ns <= r) prune = false;                     /* |U'| - nu <= |U'| */
        else if (ns - ns / 2 > r) prune = true;         /* |U'| - nu >= |U'| - floor(|U'|/2) */
        else {   /* edges: qubits in 2 admitted rows (mutant 16: every further row adds an edge to the first) */
            std::vector<int>& ea = lbw_.ea;
            std::vector<int>& eb = lbw_.eb;
            ea.clear();
            eb.clear();
            for (int v = 0; v < ns; v++) {
                const int row = u2_[v];
                for (uint32_t t = rstart_[row], e = rstart_[row + 1]; t < e; t++) {
                    const uint32_t j = rq_[t];
                    if (blk_[j]) continue;
                    if (e3mk_[j] != st) { e3mk_[j] = st; e2own_[j] = v; }
                    else { ea.push_back(e2own_[j]); eb.push_back(v); }
                }
            }
            const int nu = max_matching(ns, ea, eb, ns - r, lbw_);
            prune = ns - nu > r;
        }
        if (lbcheck_) {
            int k = 0;
            lb_build_sets(k);
            bool ex = false;
            int nsel = 0;
            const int b = lb_ecover(&lbrs_[0], &lbrq_[0], k, r, lbw_, mutant_, &ex, &nsel);
            if (b == LB_DEAD || (b > r) != prune || nsel != ns) fatal("GH-157 check: in-search ecover differs from lb_ecover");
        }
        if (prune) { ++res_->ecprune; ++res_->lbprune_by_budget[(size_t)r]; return true; }
    }
    return false;
}

inline void HalfSearch::toggle(int q) {
    for (uint32_t i = cstart_[q], e = cstart_[q + 1]; i < e; i++) {
        const uint32_t r = cr_[i];
        uint64_t& wd = syn_[r >> 6];
        const uint64_t b = 1ULL << (r & 63);
        wd ^= b;
        nodd_ += (wd & b) ? 1 : -1;
    }
    synkey_ ^= colkey_[q];
    const uint64_t* g = &gmask_[(size_t)q * kw_];
    for (int j = 0; j < kw_; j++) gpar_[j] ^= g[j];
}

/* overlap (GH-138): q joins S. A row g that reaches its limit (|S & g| = floor(|g|/2)) forbids all its qubits
 * (those in S are blocked anyway; the count is undone symmetrically by ov_del). */
inline void HalfSearch::ov_add(int q) {
    for (uint32_t i = kcstart_[q], e = kcstart_[q + 1]; i < e; i++) {
        const uint32_t g = kcr_[i];
        if (--slack_[g] == 0) {
            ++ovtight_;
            uint64_t nf = 0;
            for (const uint32_t *t = &kq_[kstart_[g]], *te = &kq_[kstart_[g + 1]]; t < te; ++t) nf += blk_[*t]++ == 0;
            ovforbid_ += nf;
        }
    }
}

/* overlap: q leaves S (exact inverse of ov_add) */
inline void HalfSearch::ov_del(int q) {
    for (uint32_t i = kcstart_[q], e = kcstart_[q + 1]; i < e; i++) {
        const uint32_t g = kcr_[i];
        if (slack_[g]++ == 0)
            for (const uint32_t *t = &kq_[kstart_[g]], *te = &kq_[kstart_[g + 1]]; t < te; ++t) blk_[*t]--;
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

void HalfSearch::record_witness(int size) {
    res_->witness.clear();
    for (int i = 0; i < size; i++) res_->witness.push_back(to_orig_[cur_[i]]);
    std::sort(res_->witness.begin(), res_->witness.end());
}

bool HalfSearch::dfs(int size) {
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
    const bool meet = leaf && size == w_ - (mutant_ == 6 ? 3 : 2);   /* budget 2: lookup instead of recursion */

    /* scan the odd rows in index order: packing bound, no-candidate dead end, branching row */
    const bool pack = rules_.pack, mrv = rules_.mrv;
    const uint64_t st = ++stamp_;
    int p = 0, brow = -1;
    /* GH-157: charge/ecover only where a hitting-set bound can exceed the remaining budget (tau <= |U| = nodd_) */
    const bool lbon = lbany_ && w_ - size >= lbminr_ && nodd_ > w_ - size;

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
    /* gap gate: evaluated only when the packing is within lb-gap of pruning (r - p <= gap; prunes concentrate at
     * r = p); without pack always. Skipping an evaluation only skips a sound prune. */
    if (lbon && (!pack || w_ - size - p <= lbgap_) && lb_prune(size, st)) return false;

    uint32_t* cb = &cand_[(size_t)size * (size_t)maxrow_];
    int nc = 0;
    for (uint32_t t = rstart_[brow], e = rstart_[brow + 1]; t < e; t++)
        if (!blk_[rq_[t]]) cb[nc++] = rq_[t];
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
        blk_[a]++;
        toggle(a);
        if (ovrc) ov_add(a);
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
            hit = dfs(size + 1);
        }
        if (ovrc) ov_del(a);
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
    if (ovr_) {   /* overlap: counters reset; rows with limit 0 (|g| = 1) forbid their qubits for the whole level */
        for (int g = 0; g < nk_; g++) {
            slack_[g] = klim_[g];
            if (klim_[g] == 0)
                for (uint32_t t = kstart_[g]; t < kstart_[g + 1]; t++) {
                    ovforbid_ += blk_[kq_[t]] == 0;
                    blk_[kq_[t]]++;
                }
        }
    }
    cur_.assign((size_t)w, -1);
    cand_.assign((size_t)w * (size_t)maxrow_ + 1, 0);
    r.by_budget.assign((size_t)w + 1, 0);
    if (rules_.charge || rules_.ecover) r.lbprune_by_budget.assign((size_t)w + 1, 0);
    for (size_t i = 0; i < seed_.size(); i++) {
        const int s = seed_[i];
        /* mutant 3 (orbit seed rule off by one): the seed rule's forbidding of O_i is applied BEFORE the
         * search from r_i, so O_1..O_i (not O_1..O_{i-1}) are forbidden apart from r_i itself; this loses
         * every element of F that needs two qubits of its first orbit */
        const bool m3 = orbit_mode_ && mutant_ == 3;
        if (m3)
            for (uint32_t t = bstart_[i]; t < bstart_[i + 1]; t++) blk_[block_[t]]++;
        /* a seed is never forbidden by an earlier seed, except through mutant 1's leak */
        if (blk_[s] == (m3 ? 1u : 0u)) {
            r.seeds++;
            if (!m3) blk_[s]++;
            toggle(s);
            if (ovr_) ov_add(s);
            cur_[0] = s;
            const bool hit = dfs(1);
            if (ovr_) ov_del(s);
            toggle(s);
            if (!m3) blk_[s]--;
            if (hit) {
                r.verdict = abort_ ? LEVEL_ABORTED : incons_ ? LEVEL_INCONSISTENT : LEVEL_FOUND;
                if (abort_) r.witness.clear();
                r.ovtight = ovtight_;
                r.ovforbid = ovforbid_;
                res_ = NULL;
                return r;
            }
        }
        /* seed rule: index rule forbids the seed; orbit rule forbids its whole orbit (mutant 3: done above) */
        if (!m3)
            for (uint32_t t = bstart_[i]; t < bstart_[i + 1]; t++) blk_[block_[t]]++;
    }
    r.ovtight = ovtight_;
    r.ovforbid = ovforbid_;
    res_ = NULL;
    return r;
}

} /* namespace distcc */
