/*
 * DistQLDPC — candidate code automorphisms from the coloured Tanner graph (GH-152, experimental, -cc-aut=on).
 *
 * Copyright (C) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * See cc_aut.h. Clean-room code.
 *
 * Partition representation (as in McKay's description): lab[] lists the vertices so that every cell is a
 * contiguous range; a cell is named by its first index in lab (its "start"), len[start] is its size and
 * cell[v] the start of v's cell. Two partitions A (source) and B (target) are refined in lockstep with one shared
 * splitter queue: for a splitter cell S every vertex counts its neighbours in S; every cell met by S is split by
 * that count (members without neighbours in S first, then by increasing count). The split of every cell must be
 * the same in A and B (same cells met, same count multiset), otherwise no colour-preserving isomorphism maps A's
 * individualised vertices onto B's and the branch is refuted. New cells enter the queue by Hopcroft's rule (all
 * fragments if the split cell was queued, else all but the first largest one), so the result is the coarsest
 * equitable refinement. A discrete pair (A, B) defines the vertex map lab_A[i] -> lab_B[i], which is accepted only
 * after an explicit check that it maps every row support onto the support of its image row.
 */
#include "cc_aut.h"

#include <algorithm>
#include <set>

namespace distcc {

namespace {

struct Graph {
    int V, n;
    std::vector<int> type;            /* 0 qubit, 1 + c row of class c */
    std::vector<uint32_t> start, adj;
};

struct Part {
    std::vector<int> lab, pos, cell, len;
    int ncells;
};

class Refiner {
public:
    explicit Refiner(const Graph& g)
        : g_(g), inq_((size_t)g.V, 0), cntA_((size_t)g.V, 0), cntB_((size_t)g.V, 0), work_(0), limit_(0) {}

    uint64_t work() const { return work_; }
    void set_limit(uint64_t lim) { limit_ = lim; }
    bool out_of_work() const { return work_ > limit_; }

    void push(int s) { if (!inq_[(size_t)s]) { inq_[(size_t)s] = 1; q_.push_back(s); } }

    /* refine A and B in lockstep from the queued splitters; false: the splits differ (or the work limit hit) */
    bool refine(Part& A, Part& B) {
        size_t head = 0;
        bool ok = true;
        while (head < q_.size()) {
            const int s = q_[head++];
            inq_[(size_t)s] = 0;
            if (!ok) continue;   /* drain the queue */
            if (!split_by(A, B, s)) ok = false;
            if (work_ > limit_) ok = false;
            if (ok && A.ncells == g_.V) {   /* discrete: nothing left to split */
                for (size_t i = head; i < q_.size(); i++) inq_[(size_t)q_[i]] = 0;
                head = q_.size();
            }
        }
        q_.clear();
        return ok;
    }

private:
    const Graph& g_;
    std::vector<int> q_;
    std::vector<char> inq_;
    std::vector<uint32_t> cntA_, cntB_;
    uint64_t work_, limit_;
    std::vector<int> touA_, touB_;
    std::vector<std::pair<uint64_t, int> > keyA_, keyB_;
    std::vector<int> fragstart_;

    void count(const Part& P, int s, std::vector<uint32_t>& cnt, std::vector<int>& tou) {
        tou.clear();
        for (int i = s, e = s + P.len[(size_t)s]; i < e; i++) {
            const int u = P.lab[(size_t)i];
            for (uint32_t t = g_.start[(size_t)u], te = g_.start[(size_t)u + 1]; t < te; t++) {
                const int v = (int)g_.adj[t];
                if (cnt[(size_t)v]++ == 0) tou.push_back(v);
            }
            work_ += g_.start[(size_t)u + 1] - g_.start[(size_t)u];
        }
    }

    /* touched vertices sorted by (cell start, count) */
    void keys(const Part& P, const std::vector<int>& tou, const std::vector<uint32_t>& cnt, std::vector<std::pair<uint64_t, int> >& key) {
        key.clear();
        for (size_t i = 0; i < tou.size(); i++) {
            const int v = tou[i];
            key.push_back(std::make_pair(((uint64_t)(uint32_t)P.cell[(size_t)v] << 32) | cnt[(size_t)v], v));
        }
        std::sort(key.begin(), key.end());
    }

    /* split cell c of P; [b, e) is c's range of key (touched members, ascending count) */
    void split_cell(Part& P, int c, const std::vector<std::pair<uint64_t, int> >& key, size_t b, size_t e, bool push_frags) {
        const int L = P.len[(size_t)c];
        const int k = (int)(e - b);
        /* move the touched members to the back of the cell, in ascending count order (a placed member is never
         * displaced: the swap partner comes from the unplaced part, and v itself sits outside the placed part) */
        int back = c + L - k;
        for (size_t t = b; t < e; t++, back++) {
            const int v = key[t].second;
            const int pv = P.pos[(size_t)v];
            const int w = P.lab[(size_t)back];
            P.lab[(size_t)back] = v; P.pos[(size_t)v] = back;
            P.lab[(size_t)pv] = w; P.pos[(size_t)w] = pv;
        }
        /* fragments: untouched [c, c + L - k), then one per count value */
        fragstart_.clear();
        if (L - k > 0) fragstart_.push_back(c);
        for (size_t t = b; t < e; t++)
            if (t == b || (key[t].first & 0xffffffffULL) != (key[t - 1].first & 0xffffffffULL))
                fragstart_.push_back(c + L - k + (int)(t - b));
        if (fragstart_.size() <= 1) return;   /* no split */
        const bool queued = inq_[(size_t)c] != 0;
        int best = -1, bestlen = -1;
        for (size_t f = 0; f < fragstart_.size(); f++) {
            const int fs = fragstart_[f];
            const int fe = f + 1 < fragstart_.size() ? fragstart_[f + 1] : c + L;
            P.len[(size_t)fs] = fe - fs;
            for (int i = fs; i < fe; i++) P.cell[(size_t)P.lab[(size_t)i]] = fs;
            if (fe - fs > bestlen) { bestlen = fe - fs; best = fs; }
        }
        P.ncells += (int)fragstart_.size() - 1;
        if (push_frags)
            for (size_t f = 0; f < fragstart_.size(); f++) {
                const int fs = fragstart_[f];
                if (queued || fs != best) push(fs);
            }
    }

    bool split_by(Part& A, Part& B, int s) {
        if (A.len[(size_t)s] != B.len[(size_t)s]) return false;
        count(A, s, cntA_, touA_);
        count(B, s, cntB_, touB_);
        bool ok = touA_.size() == touB_.size();
        if (ok) {
            keys(A, touA_, cntA_, keyA_);
            keys(B, touB_, cntB_, keyB_);
            for (size_t i = 0; i < keyA_.size() && ok; i++) ok = keyA_[i].first == keyB_[i].first;
        }
        if (ok) {
            size_t b = 0;
            while (b < keyA_.size()) {
                const int c = (int)(keyA_[b].first >> 32);
                size_t e = b;
                while (e < keyA_.size() && (int)(keyA_[e].first >> 32) == c) e++;
                if (A.len[(size_t)c] != B.len[(size_t)c]) { ok = false; break; }
                split_cell(A, c, keyA_, b, e, true);    /* pushes the new cells (shared queue) */
                split_cell(B, c, keyB_, b, e, false);   /* identical fragment structure */
                b = e;
            }
        }
        for (size_t i = 0; i < touA_.size(); i++) cntA_[(size_t)touA_[i]] = 0;
        for (size_t i = 0; i < touB_.size(); i++) cntB_[(size_t)touB_[i]] = 0;
        return ok;
    }
};

/* individualise v (in the non-singleton cell starting at s): {v} at s, the rest at s + 1 */
void individualise(Part& P, int s, int v) {
    const int pv = P.pos[(size_t)v];
    const int w = P.lab[(size_t)s];
    P.lab[(size_t)s] = v; P.pos[(size_t)v] = s;
    P.lab[(size_t)pv] = w; P.pos[(size_t)w] = pv;
    const int L = P.len[(size_t)s];
    P.len[(size_t)s] = 1;
    P.len[(size_t)s + 1] = L - 1;
    for (int i = s + 1; i < s + L; i++) P.cell[(size_t)P.lab[(size_t)i]] = s + 1;
    P.ncells++;
}

/* Hopcroft push after individualise: all fragments but the first largest ({v} if L = 2, else the rest) */
void push_individualised(Refiner& R, const Part& P, int s) {
    if (P.len[(size_t)s + 1] > 1) R.push(s);
    else R.push(s + 1);
}

int first_nonsingleton(const Part& P) {
    for (int i = 0; i < (int)P.lab.size(); i += P.len[(size_t)i])
        if (P.len[(size_t)i] > 1) return i;
    return -1;
}

class AutSearch {
public:
    explicit AutSearch(const Graph& g) : g_(g), R_(g), mark_((size_t)g.n, 0), stamp_(0) {}

    Refiner& refiner() { return R_; }

    /* initial partition by vertex type; order[t] = position of type t in lab (swap: types 1 and 2 exchanged) */
    Part initial(const std::vector<int>& typeorder) {
        Part P;
        P.lab.reserve((size_t)g_.V);
        P.pos.assign((size_t)g_.V, 0);
        P.cell.assign((size_t)g_.V, 0);
        P.len.assign((size_t)g_.V + 1, 0);
        P.ncells = 0;
        for (size_t t = 0; t < typeorder.size(); t++) {
            const int s = (int)P.lab.size();
            for (int v = 0; v < g_.V; v++)
                if (g_.type[(size_t)v] == typeorder[t]) { P.pos[(size_t)v] = (int)P.lab.size(); P.cell[(size_t)v] = s; P.lab.push_back(v); }
            const int L = (int)P.lab.size() - s;
            if (L > 0) { P.len[(size_t)s] = L; P.ncells++; }
        }
        return P;
    }

    /* map every row of A's class onto the row of B it is mapped to (vertex map lab_A[i] -> lab_B[i]) */
    bool check_discrete(const Part& A, const Part& B, std::vector<int>& vmap) {
        vmap.assign((size_t)g_.V, -1);
        for (int i = 0; i < g_.V; i++) vmap[(size_t)A.lab[(size_t)i]] = B.lab[(size_t)i];
        for (int v = 0; v < g_.n; v++) if (vmap[(size_t)v] < 0 || vmap[(size_t)v] >= g_.n) return false;
        for (int r = g_.n; r < g_.V; r++) {
            const int rr = vmap[(size_t)r];
            if (rr < g_.n) return false;
            const uint32_t a = g_.start[(size_t)r], ae = g_.start[(size_t)r + 1];
            const uint32_t b = g_.start[(size_t)rr], be = g_.start[(size_t)rr + 1];
            if (ae - a != be - b) return false;
            ++stamp_;
            for (uint32_t t = b; t < be; t++) mark_[g_.adj[t]] = stamp_;
            for (uint32_t t = a; t < ae; t++) if (mark_[(size_t)vmap[g_.adj[t]]] != stamp_) return false;
        }
        return true;
    }

    /* 1: map found (qubit part in pi), 0: refuted, -1: work limit or depth limit */
    int search(Part& A, Part& B, std::vector<int>& pi, int depth) {
        if (!R_.refine(A, B)) return R_.out_of_work() ? -1 : 0;
        if (A.ncells == g_.V) {
            std::vector<int> vmap;
            if (!check_discrete(A, B, vmap)) return 0;
            pi.assign(vmap.begin(), vmap.begin() + g_.n);
            return 1;
        }
        if (depth >= 64) return -1;
        const int s = first_nonsingleton(A);
        const int a = A.lab[(size_t)s];
        const int L = A.len[(size_t)s];
        for (int j = 0; j < L; j++) {
            Part A2 = A, B2 = B;
            individualise(A2, s, a);
            individualise(B2, s, B.lab[(size_t)s + j]);
            push_individualised(R_, A2, s);
            const int r = search(A2, B2, pi, depth + 1);
            if (r != 0) return r;
        }
        return 0;
    }

private:
    const Graph& g_;
    Refiner R_;
    std::vector<uint64_t> mark_;
    uint64_t stamp_;
};

int uf_find_aut(std::vector<int>& par, int a) {
    while (par[(size_t)a] != a) { par[(size_t)a] = par[(size_t)par[(size_t)a]]; a = par[(size_t)a]; }
    return a;
}

} /* namespace */

bool rows_map_onto(int n, const std::vector<const SparseRows*>& classes, const std::vector<int>& pi, const std::vector<int>& map) {
    if ((int)pi.size() != n || map.size() != classes.size()) return false;
    std::vector<char> seen((size_t)n, 0);
    for (int q = 0; q < n; q++) {
        if (pi[(size_t)q] < 0 || pi[(size_t)q] >= n || seen[(size_t)pi[(size_t)q]]) return false;
        seen[(size_t)pi[(size_t)q]] = 1;
    }
    for (size_t c = 0; c < classes.size(); c++) {
        const SparseRows* dst = classes[(size_t)map[c]];
        std::set<std::vector<int> > target;
        for (size_t r = 0; r < dst->rows.size(); r++) {
            std::vector<int> s(dst->rows[r]);
            std::sort(s.begin(), s.end());
            s.erase(std::unique(s.begin(), s.end()), s.end());
            if (!s.empty()) target.insert(s);
        }
        for (size_t r = 0; r < classes[c]->rows.size(); r++) {
            std::vector<int> s;
            for (size_t t = 0; t < classes[c]->rows[r].size(); t++) s.push_back(pi[(size_t)classes[c]->rows[r][t]]);
            std::sort(s.begin(), s.end());
            s.erase(std::unique(s.begin(), s.end()), s.end());
            if (!s.empty() && !target.count(s)) return false;
        }
    }
    return true;
}

AutResult find_row_automorphisms(int n, const std::vector<const SparseRows*>& classes, bool want_swap, uint64_t work_limit) {
    AutResult res;
    if (work_limit == 0) work_limit = 400000000ULL;
    const uint64_t per_test = std::max<uint64_t>(work_limit / 64, 1000000ULL);
    Graph g;
    g.n = n;
    std::vector<std::vector<std::vector<int> > > rows(classes.size());
    g.type.assign((size_t)n, 0);
    for (size_t c = 0; c < classes.size(); c++) {
        for (size_t r = 0; r < classes[c]->rows.size(); r++) {
            std::vector<int> s(classes[c]->rows[r]);
            std::sort(s.begin(), s.end());
            s.erase(std::unique(s.begin(), s.end()), s.end());
            bool okr = !s.empty();
            for (size_t t = 0; t < s.size(); t++) if (s[t] < 0 || s[t] >= n) okr = false;
            if (!okr) continue;
            rows[c].push_back(s);
            g.type.push_back(1 + (int)c);
        }
    }
    g.V = (int)g.type.size();
    {   /* CSR adjacency */
        std::vector<std::vector<int> > adj((size_t)g.V);
        int v = n;
        for (size_t c = 0; c < rows.size(); c++)
            for (size_t r = 0; r < rows[c].size(); r++, v++)
                for (size_t t = 0; t < rows[c][r].size(); t++) { adj[(size_t)v].push_back(rows[c][r][t]); adj[(size_t)rows[c][r][t]].push_back(v); }
        g.start.assign((size_t)g.V + 1, 0);
        for (int u = 0; u < g.V; u++) g.start[(size_t)u + 1] = g.start[(size_t)u] + (uint32_t)adj[(size_t)u].size();
        g.adj.reserve(g.start[(size_t)g.V]);
        for (int u = 0; u < g.V; u++) for (size_t t = 0; t < adj[(size_t)u].size(); t++) g.adj.push_back((uint32_t)adj[(size_t)u][t]);
    }
    AutSearch S(g);
    Refiner& R = S.refiner();
    std::vector<int> order;
    for (int t = 0; t <= (int)classes.size(); t++) order.push_back(t);

    /* base: coarsest equitable refinement of the type partition */
    R.set_limit(work_limit);
    Part base = S.initial(order);
    {
        Part B = base;
        for (int i = 0; i < g.V; i += base.len[(size_t)i]) R.push(i);
        if (!R.refine(base, B)) {   /* only the work limit can stop the refinement of a partition against itself */
            res.work = R.work();
            res.orbits = n;
            return res;
        }
    }

    std::vector<int> par((size_t)n);
    for (int q = 0; q < n; q++) par[(size_t)q] = q;
    /* v0 = first vertex of the smallest non-singleton qubit cell */
    int c0 = -1;
    for (int i = 0; i < g.V; i += base.len[(size_t)i])
        if (base.lab[(size_t)i] < n && base.len[(size_t)i] > 1 && (c0 < 0 || base.len[(size_t)i] < base.len[(size_t)c0])) c0 = i;
    if (c0 < 0) {   /* every qubit is fixed by every automorphism */
        res.complete = true;
        res.stab_trivial = true;
    } else {
        const int v0 = base.lab[(size_t)c0];
        {   /* point stabiliser of v0 trivial iff refinement after individualising v0 is discrete */
            Part A = base, B = base;
            individualise(A, c0, v0);
            individualise(B, c0, v0);
            push_individualised(R, A, c0);
            if (R.refine(A, B)) res.stab_trivial = A.ncells == g.V;
        }
        bool decided = true;
        const int L0 = base.len[(size_t)c0];
        for (int j = 0; j < L0 && R.work() <= work_limit; j++) {
            const int w = base.lab[(size_t)c0 + j];
            if (w == v0 || uf_find_aut(par, w) == uf_find_aut(par, v0)) continue;
            res.tests++;
            Part A = base, B = base;
            individualise(A, c0, v0);
            individualise(B, c0, w);
            push_individualised(R, A, c0);
            R.set_limit(std::min(work_limit, R.work() + per_test));
            std::vector<int> pi;
            const int r = S.search(A, B, pi, 1);
            R.set_limit(work_limit);
            if (r == 1) {
                res.gens.push_back(pi);
                for (int q = 0; q < n; q++) {
                    const int a = uf_find_aut(par, q), b = uf_find_aut(par, pi[(size_t)q]);
                    if (a != b) par[(size_t)std::max(a, b)] = std::min(a, b);
                }
            } else if (r == 0) {
                res.refuted++;
            } else {
                res.undecided++;
                decided = false;
            }
        }
        if (R.work() > work_limit) decided = false;
        res.complete = decided && res.stab_trivial;
        if (!res.complete) {
            /* nontrivial (or undecided) point stabiliser: look for more generators between pairs of qubits of the
             * same base cell that are still in different orbits (each test bounded; the result stays a subgroup) */
            for (int i = 0; i < g.V && R.work() <= work_limit; i += base.len[(size_t)i]) {
                if (base.lab[(size_t)i] >= n || base.len[(size_t)i] < 2) continue;
                const int L = base.len[(size_t)i];
                for (int a = 0; a < L && R.work() <= work_limit; a++) {
                    const int v = base.lab[(size_t)i + a];
                    if (uf_find_aut(par, v) != v) continue;
                    for (int b = a + 1; b < L && R.work() <= work_limit; b++) {
                        const int w = base.lab[(size_t)i + b];
                        if (uf_find_aut(par, w) != w || uf_find_aut(par, v) == uf_find_aut(par, w)) continue;
                        res.tests++;
                        Part A = base, B = base;
                        individualise(A, i, v);
                        individualise(B, i, w);
                        push_individualised(R, A, i);
                        R.set_limit(std::min(work_limit, R.work() + per_test));
                        std::vector<int> pi;
                        const int r = S.search(A, B, pi, 1);
                        R.set_limit(work_limit);
                        if (r == 1) {
                            res.gens.push_back(pi);
                            for (int q = 0; q < n; q++) {
                                const int x = uf_find_aut(par, q), y = uf_find_aut(par, pi[(size_t)q]);
                                if (x != y) par[(size_t)std::max(x, y)] = std::min(x, y);
                            }
                        } else if (r == 0) {
                            res.refuted++;
                        } else {
                            res.undecided++;
                        }
                    }
                }
            }
        }
    }
    for (int q = 0; q < n; q++) if (uf_find_aut(par, q) == q) res.orbits++;

    /* class 0 <-> class 1 exchanging map */
    if (want_swap && classes.size() == 2 && rows[0].size() == rows[1].size() && !rows[0].empty() && R.work() <= work_limit) {
        std::vector<int> sw;
        sw.push_back(0); sw.push_back(2); sw.push_back(1);
        Part A = S.initial(order), B = S.initial(sw);
        R.set_limit(work_limit);
        for (int i = 0; i < g.V; i += A.len[(size_t)i]) R.push(i);
        bool ok = A.len == B.len && R.refine(A, B);
        if (!ok) {
            res.swap_state = R.out_of_work() ? 3 : 2;
        } else if (A.ncells == g.V) {
            res.tests++;
            Part A2 = A, B2 = B;
            std::vector<int> pi;
            const int r = S.search(A2, B2, pi, 1);
            res.swap_state = r == 1 ? 1 : r == 0 ? 2 : 3;
            if (r == 1) res.swap = pi;
        } else {
            int c = -1;
            for (int i = 0; i < g.V; i += A.len[(size_t)i])
                if (A.lab[(size_t)i] < n && A.len[(size_t)i] > 1 && (c < 0 || A.len[(size_t)i] < A.len[(size_t)c])) c = i;
            if (c < 0) c = first_nonsingleton(A);
            const int v0 = A.lab[(size_t)c];
            bool undecided = false;
            res.swap_state = 2;
            for (int j = 0; j < A.len[(size_t)c] && R.work() <= work_limit; j++) {
                res.tests++;
                Part A2 = A, B2 = B;
                individualise(A2, c, v0);
                individualise(B2, c, B.lab[(size_t)c + j]);
                push_individualised(R, A2, c);
                R.set_limit(std::min(work_limit, R.work() + per_test));
                std::vector<int> pi;
                const int r = S.search(A2, B2, pi, 1);
                R.set_limit(work_limit);
                if (r == 1) { res.swap = pi; res.swap_state = 1; break; }
                if (r < 0) { undecided = true; res.undecided++; } else res.refuted++;
            }
            if (res.swap_state != 1 && (undecided || R.work() > work_limit)) res.swap_state = 3;
        }
    }
    res.work = R.work();
    return res;
}

} /* namespace distcc */
