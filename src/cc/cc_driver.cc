/*
 * DistQLDPC — CC engine driver (GH-124, experimental; selected with -engine=cc).
 *
 * Copyright (C) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * See cc_driver.h for the bound algebra, the verification and the traps. Clean-room code.
 */
#include "cc_driver.h"

#include <limits.h>
#include <stdio.h>
#include <string.h>
#include <algorithm>
#include <chrono>
#include <functional>
#include <memory>

namespace distcc {

namespace {

typedef std::vector<uint64_t> Bits;

Bits to_bits(const std::vector<int>& sup, int n) {
    Bits b((size_t)((n + 63) / 64), 0);
    for (size_t t = 0; t < sup.size(); t++) b[(size_t)sup[t] >> 6] ^= 1ULL << (sup[t] & 63);
    return b;
}

bool odd_overlap(const Bits& a, const Bits& b) {
    uint64_t acc = 0;
    for (size_t i = 0; i < a.size(); i++) acc ^= a[i] & b[i];
    return __builtin_popcountll(acc) & 1;
}

/* Row echelon basis over GF(2): each inserted row is reduced by the earlier rows (in insertion order)
 * and keeps its lowest set bit as pivot; reducing v by all rows in insertion order clears every pivot
 * bit of v, so v is in the span iff it reduces to zero. (Independent of src/core's Gf2Basis.) */
class Echelon {
public:
    explicit Echelon(int n) : words_((n + 63) / 64) {}
    bool reduce(Bits& v) const {
        for (size_t k = 0; k < rows_.size(); k++) {
            const int p = piv_[k];
            if ((v[(size_t)p >> 6] >> (p & 63)) & 1) {
                const Bits& r = rows_[k];
                for (int w = 0; w < words_; w++) v[w] ^= r[w];
            }
        }
        for (int w = 0; w < words_; w++)
            if (v[w]) return false;
        return true;
    }
    bool insert(Bits v) {
        if (reduce(v)) return false;
        int p = -1;
        for (int w = 0; w < words_ && p < 0; w++)
            if (v[w]) p = w * 64 + __builtin_ctzll(v[w]);
        rows_.push_back(v);
        piv_.push_back(p);
        return true;
    }
    int rank() const { return (int)rows_.size(); }

private:
    int words_;
    std::vector<Bits> rows_;
    std::vector<int> piv_;
};

double now_seconds() {
    return std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
}

bool support_ok(const std::vector<int>& e, int n, std::string& why) {
    std::vector<int> s(e);
    std::sort(s.begin(), s.end());
    if (s.empty()) { why = "empty support"; return false; }
    if (s.front() < 0 || s.back() >= n) { why = "qubit index out of range"; return false; }
    if (std::adjacent_find(s.begin(), s.end()) != s.end()) { why = "repeated qubit"; return false; }
    return true;
}

struct Half {
    const char* tag;
    const SparseRows* H;   /* parity checks of the half */
    const SparseRows* G;   /* detector rows */
    const SparseRows* S;   /* same-type stabilizers (trivial logicals = rs S) */
    const SparseRows* B;   /* logical basis rows of this half's type (for -ub-basis) */
    bool exists, searched;
    bool par;              /* GH-133: parity rule in force (all column weights odd): odd levels skipped */
    int rankH, rankHG, rankS;
    int lb, ub;
    uint64_t last_nodes, total_nodes;
    double total_time;
    std::vector<Bits> hbits;
    std::unique_ptr<Echelon> sbasis;
    std::unique_ptr<HalfSearch> search;
    Half() : tag(""), H(NULL), G(NULL), S(NULL), B(NULL), exists(false), searched(false), par(false), rankH(0), rankHG(0),
             rankS(0), lb(INT_MAX), ub(INT_MAX), last_nodes(0), total_nodes(0), total_time(0) {}
};

/* Start-up check of the half: (a) every same-type stabilizer row has even overlap with every parity
 * check and every detector row (so rs S lies in ker [H; G]); (b) rank [H; G] + rank S = n, so
 * ker [H; G] = rs S: an element of ker H is trivial iff all detectors are even (complete detectors). */
bool detector_check(Half& h, int n, std::string& why) {
    std::vector<Bits> sb, gb;
    for (size_t r = 0; r < h.S->rows.size(); r++) sb.push_back(to_bits(h.S->rows[r], n));
    for (size_t r = 0; r < h.H->rows.size(); r++) h.hbits.push_back(to_bits(h.H->rows[r], n));
    for (size_t r = 0; r < h.G->rows.size(); r++) gb.push_back(to_bits(h.G->rows[r], n));
    char buf[256];
    for (size_t s = 0; s < sb.size(); s++) {
        for (size_t r = 0; r < h.hbits.size(); r++)
            if (odd_overlap(sb[s], h.hbits[r])) {
                snprintf(buf, sizeof(buf), "%s half: stabilizer row %zu has odd overlap with parity row %zu", h.tag, s, r);
                why = buf;
                return false;
            }
        for (size_t r = 0; r < gb.size(); r++)
            if (odd_overlap(sb[s], gb[r])) {
                snprintf(buf, sizeof(buf), "%s half: stabilizer row %zu has odd overlap with detector row %zu", h.tag, s, r);
                why = buf;
                return false;
            }
    }
    Echelon eh(n);
    for (size_t r = 0; r < h.hbits.size(); r++) eh.insert(h.hbits[r]);
    h.rankH = eh.rank();
    for (size_t r = 0; r < gb.size(); r++) eh.insert(gb[r]);
    h.rankHG = eh.rank();
    h.sbasis.reset(new Echelon(n));
    for (size_t s = 0; s < sb.size(); s++) h.sbasis->insert(sb[s]);
    h.rankS = h.sbasis->rank();
    if (h.rankHG + h.rankS != n) {
        snprintf(buf, sizeof(buf), "%s half: detectors incomplete (rank[H;G] %d + rank S %d != n %d)",
                 h.tag, h.rankHG, h.rankS, n);
        why = buf;
        return false;
    }
    return true;
}

/* Verification of a witness of half h: H e = 0 and e not in rs S (independent GF(2) rank test). */
bool verify_in_half(const Half& h, const std::vector<int>& e, int n, std::string& why) {
    if (!support_ok(e, n, why)) return false;
    const Bits v = to_bits(e, n);
    for (size_t r = 0; r < h.hbits.size(); r++)
        if (odd_overlap(v, h.hbits[r])) {
            char buf[96];
            snprintf(buf, sizeof(buf), "parity row %zu violated", r);
            why = buf;
            return false;
        }
    Bits t(v);
    if (h.sbasis->reduce(t)) {
        why = "in the row space of the same-type stabilizers (trivial)";
        return false;
    }
    return true;
}

/* Driver-side check of the XZ-dual map pi (X-half qubit i -> Z-half qubit pi[i]), independent of the caller's
 * detection: pi(rs Hz) is contained in rs Hx, pi(rs Hx) in rs Hz, and rank Hz = rank Hx. A permutation preserves
 * orthogonality, so then pi(ker Hz) = (pi rs Hz)^perp = (rs Hx)^perp = ker Hx and pi(rs Hx) = rs Hz: pi maps
 * F_X = ker Hz \ rs Hx onto F_Z = ker Hx \ rs Hz and preserves weight, so dX = dZ. Needs detector_check first
 * (hbits and sbasis: X half H = Hz, S = Hx; Z half H = Hx, S = Hz). */
bool dual_map_check(const Half hs[2], const std::vector<int>& perm, int n, std::string& why) {
    if (hs[0].rankS != hs[1].rankS) { why = "rank Hx != rank Hz"; return false; }
    for (int k = 0; k < 2; k++) {   /* k = 0: pi(rows of Hz) in rs Hx; k = 1: pi(rows of Hx) in rs Hz */
        for (size_t r = 0; r < hs[k].hbits.size(); r++) {
            const Bits& v = hs[k].hbits[r];
            Bits img(v.size(), 0);
            for (int q = 0; q < n; q++)
                if ((v[(size_t)q >> 6] >> (q & 63)) & 1) img[(size_t)perm[q] >> 6] ^= 1ULL << (perm[q] & 63);
            if (!hs[k].sbasis->reduce(img)) {
                char buf[96];
                snprintf(buf, sizeof(buf), "image of %s row %zu is not in rs %s", k == 0 ? "Hz" : "Hx", r, k == 0 ? "Hx" : "Hz");
                why = buf;
                return false;
            }
        }
    }
    return true;
}

std::string support_string(const std::vector<int>& e) {
    std::string s;
    char buf[16];
    for (size_t i = 0; i < e.size(); i++) {
        snprintf(buf, sizeof(buf), i ? " %d" : "%d", e[i]);
        s += buf;
    }
    return s;
}

} /* namespace */

bool verify_logical(const SparseRows& Hpar, const SparseRows& Sstab, const std::vector<int>& e, std::string& why) {
    const int n = Hpar.cols;
    if (!support_ok(e, n, why)) return false;
    const Bits v = to_bits(e, n);
    for (size_t r = 0; r < Hpar.rows.size(); r++)
        if (odd_overlap(v, to_bits(Hpar.rows[r], n))) {
            why = "parity check violated";
            return false;
        }
    Echelon S(n);
    for (size_t r = 0; r < Sstab.rows.size(); r++) S.insert(to_bits(Sstab.rows[r], n));
    Bits t(v);
    if (S.reduce(t)) {
        why = "in the row space of the stabilizers (trivial)";
        return false;
    }
    return true;
}

bool parse_rules(const char* s, Rules& out) {
    Rules r;
    r.excl = r.pack = r.orbf = r.mrv = r.parity = r.leaf = r.overlap = r.charge = r.ecover = false;
    std::string all(s ? s : "");
    size_t pos = 0;
    while (pos <= all.size()) {
        size_t e = all.find(',', pos);
        if (e == std::string::npos) e = all.size();
        const std::string tok = all.substr(pos, e - pos);
        if (tok == "excl") r.excl = true;
        else if (tok == "pack") r.pack = true;
        else if (tok == "orbf") r.orbf = true;
        else if (tok == "mrv") r.mrv = true;
        else if (tok == "parity") r.parity = true;
        else if (tok == "leaf") r.leaf = true;
        else if (tok == "overlap") r.overlap = true;
        else if (tok == "charge") r.charge = true;   /* GH-157 */
        else if (tok == "ecover") r.ecover = true;   /* GH-157 */
        else if (tok == "none") { /* nothing */ }
        else return false;
        pos = e + 1;
    }
    out = r;
    return true;
}

std::string rules_string(const Rules& r) {
    std::string s;
    if (r.excl) s += ",excl";
    if (r.pack) s += ",pack";
    if (r.orbf) s += ",orbf";
    if (r.parity) s += ",parity";
    if (r.leaf) s += ",leaf";
    if (r.overlap) s += ",overlap";
    if (r.mrv) s += ",mrv";
    if (r.charge) s += ",charge";
    if (r.ecover) s += ",ecover";
    return s.empty() ? std::string("none") : s.substr(1);
}

int min_distance_cc(const DriverInput& in, const DriverOptions& opt, const BoundSink& sink) {
    const int n = in.Hx.cols;
    const int INF = INT_MAX;
    FILE* trace = NULL;
    const int verb = opt.verb;
    auto fail = [&](const std::string& msg) -> int {
        fprintf(stderr, "error: cc: %s: no answer\n", msg.c_str());
        if (verb > 0) printf("c cc: TRAP: %s: no answer\n", msg.c_str());
        fflush(stdout);
        if (trace) { fprintf(trace, "# TRAP %s\n", msg.c_str()); fclose(trace); trace = NULL; }
        if (sink.trap) sink.trap(sink.ctx);   /* withdraw the bounds already sent */
        else sink.result(sink.ctx, -1, false);
        return -1;
    };
    if (n <= 0 || in.Hz.cols != n || in.Gx.cols != n || in.Gz.cols != n) return fail("matrix column mismatch");
    if (opt.mutant != 0)
        fprintf(stderr, "warning: cc: test mutant %d active (deliberately broken; results are unreliable)\n", opt.mutant);
    /* mutant 4 runs under the sequential schedule, where the other-half check of the stop rule matters */
    const bool sequential = opt.sequential || opt.mutant == 4;

    Half hs[2];
    hs[0].tag = "X"; hs[0].H = &in.Hz; hs[0].G = &in.Gx; hs[0].S = &in.Hx; hs[0].B = &in.Gz;
    hs[1].tag = "Z"; hs[1].H = &in.Hx; hs[1].G = &in.Gz; hs[1].S = &in.Hz; hs[1].B = &in.Gx;
    for (int k = 0; k < 2; k++) {
        std::string why;
        if (!detector_check(hs[k], n, why)) return fail("detector check failed: " + why);
        hs[k].exists = hs[k].rankHG > hs[k].rankH;
        if (verb > 0)
            printf("c cc: %s half: n %d, rank H %d, rank [H;G] %d, rank S %d: detectors complete, %d logical(s)\n",
                   hs[k].tag, n, hs[k].rankH, hs[k].rankHG, hs[k].rankS, hs[k].rankHG - hs[k].rankH);
    }
    if (!hs[0].exists && !hs[1].exists) return fail("no nontrivial logical operator in either half");

    bool dual = false;
    if (opt.dual && !in.dual_perm.empty() && hs[0].exists && hs[1].exists) {
        if ((int)in.dual_perm.size() != n) return fail("dual map has the wrong length");
        std::vector<char> hit((size_t)n, 0);
        for (int i = 0; i < n; i++) {
            const int j = in.dual_perm[i];
            if (j < 0 || j >= n || hit[j]) return fail("dual map is not a permutation");
            hit[j] = 1;
        }
        std::string why;
        if (!dual_map_check(hs, in.dual_perm, n, why)) return fail("dual map failed the driver's check: " + why);
        dual = true;
    }
    hs[0].searched = hs[0].exists;
    hs[1].searched = hs[1].exists && !dual;
    for (int k = 0; k < 2; k++) hs[k].lb = hs[k].exists ? 1 : INF;
    if (verb > 0) {
        printf("c cc: rules %s, cc-seed %llu, dual %s, ub-basis %s%s\n", rules_string(opt.rules).c_str(),
               (unsigned long long)opt.seed,
               dual ? "on (verified map in use)" : opt.dual ? "on (no verified map: both halves)" : "off",
               opt.ub_basis ? "on" : "off",
               sequential ? ", schedule sequential (test)" : "");
        if (opt.rules.charge || opt.rules.ecover)   /* GH-157 */
            printf("c cc: node lower bounds%s%s at remaining budget >= %d and budget - packing <= %d, auto off below %d %% (GH-157)\n",
                   opt.rules.charge ? (opt.lb_raise ? " charge" : " charge(no raise)") : "", opt.rules.ecover ? " ecover" : "",
                   opt.lb_minr, opt.lb_gap, opt.lb_auto);
        if (dual)
            printf("c cc: dual map '%s' verified: dX = dZ, searching the X half only (Z bounds mirrored)\n",
                   in.dual_desc.c_str());
    }

    int U = INF;
    if (opt.ub_basis) {
        for (int k = 0; k < 2; k++) {
            if (!hs[k].exists) continue;
            for (size_t r = 0; r < hs[k].B->rows.size(); r++) {
                const std::vector<int>& b = hs[k].B->rows[r];
                std::string why;
                if (b.empty() || !verify_in_half(hs[k], b, n, why)) {
                    if (verb > 0) printf("c cc: basis row %zu of the %s half not used (%s)\n", r, hs[k].tag,
                                         b.empty() ? "empty" : why.c_str());
                    continue;
                }
                if ((int)b.size() < hs[k].ub) hs[k].ub = (int)b.size();
            }
        }
        if (dual) hs[0].ub = hs[1].ub = std::min(hs[0].ub, hs[1].ub);
        U = std::min(hs[0].ub, hs[1].ub);
        if (verb > 0) {
            if (U < INF) printf("c cc: ub-basis: verified basis rows give UB %d (X %d, Z %d)\n", U,
                                hs[0].ub == INF ? -1 : hs[0].ub, hs[1].ub == INF ? -1 : hs[1].ub);
            else printf("c cc: ub-basis: no verified basis row\n");
        }
        if (U < INF) sink.bound(sink.ctx, "UB", (uint64_t)U);
    }

    for (int k = 0; k < 2; k++) {
        if (!hs[k].searched) continue;
        /* GH-138: the half's stabilizer rows S (X half Hx, Z half Hz; verified by detector_check) feed rule overlap */
        hs[k].search.reset(new HalfSearch(*hs[k].H, *hs[k].G, in.orbit_of[k], opt.rules, opt.seed, opt.mutant, hs[k].S));
        hs[k].search->set_lb_minr(opt.lb_minr);   /* GH-157 */
        hs[k].search->set_lb_gap(opt.lb_gap);
        hs[k].search->set_lb_raise(opt.lb_raise);
        hs[k].search->set_lb_auto(opt.lb_auto);
        hs[k].par = hs[k].search->parity_active();
        if (verb > 0) {
            printf("c cc: %s half search: %d seeds (%s)\n", hs[k].tag, hs[k].search->num_seeds(),
                   hs[k].search->orbit_seeds() ? "orbit representatives" : "index rule");
            const HalfSearch& S = *hs[k].search;
            if (!opt.rules.parity)
                printf("c cc: %s half parity: rule off (column weights %d..%d)\n", hs[k].tag, S.min_col_weight(), S.max_col_weight());
            else if (S.all_odd_columns())
                printf("c cc: %s half parity: on (column weights %d..%d, all odd): every logical has even weight, odd levels skipped\n",
                       hs[k].tag, S.min_col_weight(), S.max_col_weight());
            else if (hs[k].par)
                printf("c cc: %s half parity: FORCED by test mutant 5 (column weights %d..%d, an even weight present)\n",
                       hs[k].tag, S.min_col_weight(), S.max_col_weight());
            else
                printf("c cc: %s half parity: off (column weights %d..%d, an even weight present)\n",
                       hs[k].tag, S.min_col_weight(), S.max_col_weight());
            if (!opt.rules.overlap)
                printf("c cc: %s half overlap: rule off\n", hs[k].tag);
            else if (S.overlap_active())
                printf("c cc: %s half overlap: on (%s%d stabilizer rows of %s, weights %d..%d, %d forbidden from the start)\n",
                       hs[k].tag, opt.mutant == 9 ? "TEST MUTANT 9: parity checks used, " : "", S.overlap_rows(),
                       opt.mutant == 9 ? (k == 0 ? "Hz" : "Hx") : (k == 0 ? "Hx" : "Hz"), S.overlap_min_weight(),
                       S.overlap_max_weight(), S.overlap_zero_rows());
            else
                printf("c cc: %s half overlap: idle (no stabilizer row)\n", hs[k].tag);
        }
    }
    /* GH-133 parity: level 1 of a qualifying half is empty (every element has even weight) */
    for (int k = 0; k < 2; k++)
        if (hs[k].searched && hs[k].par && (hs[k].lb & 1)) hs[k].lb++;
    if (dual) hs[1].lb = hs[0].lb;
    fflush(stdout);
    if (!opt.trace_path.empty()) {
        trace = fopen(opt.trace_path.c_str(), "w");
        if (!trace) return fail("cannot open trace file " + opt.trace_path);
        fprintf(trace, "# DistQLDPC cc-trace v1: half level verdict nodes seconds [witness support]\n");
        fprintf(trace, "# n %d rules %s cc-seed %llu dual %s mutant %d parity X %s Z %s\n", n, rules_string(opt.rules).c_str(),
                (unsigned long long)opt.seed, dual ? in.dual_desc.c_str() : "off", opt.mutant,
                hs[0].searched ? (hs[0].par ? "on" : "off") : "-", hs[1].searched ? (hs[1].par ? "on" : "off") : "-");
        fflush(trace);
    }

    /* GH-140 -ub-search: one finder per searched half (with a verified dual map: the X half only) */
    const double t_start = now_seconds();
    const bool ubs = opt.ub_search || opt.ub_only;
    std::unique_ptr<UbFinder> uf[2];
    double ub_spent = 0;
    std::string ub_trap;
    int ub_curw = 0;   /* level in progress (0: none) */
    if (ubs) {
        UbParams up = opt.ub;
        up.mutant = (opt.mutant == 11 || opt.mutant == 12) ? 11 : 0;
        for (int k = 0; k < 2; k++) {
            if (!hs[k].searched) continue;
            const uint64_t fs = opt.seed * 0x9e3779b97f4a7c15ULL + 0x6a09e667f3bcc909ULL + (uint64_t)k;
            uf[k].reset(new UbFinder(*hs[k].H, *hs[k].G, *hs[k].S, fs, up));
            if (verb > 0)
                printf("c cc: %s half ub-search: rank H %d, information set %d, triples %s, slack %d, li-cap %d%s\n", hs[k].tag,
                       uf[k]->rank(), uf[k]->dim(), uf[k]->dim() <= up.triples_max_k ? "on" : "off", up.slack, up.li_cap,
                       isd_desc(up, *uf[k]).c_str());
        }
        if (verb > 0) {
            if (opt.ub_only) printf("c cc: ub-search only (diagnostic): %.3fs finder budget, no level ladder\n", opt.ub_cap);
            else printf("c cc: ub-search: pre-pass %.3fs, share %.3f of wall time (/16 after %d re-hits of U or a plateau), cap %s\n",
                        opt.ub_cap >= 0 ? std::min(opt.ub_pre, opt.ub_cap) : opt.ub_pre, opt.ub_share, opt.ub_hits,
                        opt.ub_cap >= 0 ? (std::to_string(opt.ub_cap) + "s").c_str() : "none");
        }
        fflush(stdout);
    }
    int ub_rehits = 0;          /* finder iterations that re-hit U since U last changed */
    uint64_t ub_iters = 0, ub_iter_last = 0;   /* finder iterations (both halves); count at the last improvement */
    bool ub_conv = false;       /* ub_rehits reached opt.ub_hits: share / 16 from now on */
    auto ub_due = [&]() -> bool {
        if (!ubs) return false;
        if (opt.ub_cap >= 0 && ub_spent >= opt.ub_cap) return false;
        if (opt.ub_only) return true;
        const double pre = opt.ub_cap >= 0 ? std::min(opt.ub_pre, opt.ub_cap) : opt.ub_pre;
        return ub_spent < pre + (ub_conv ? opt.ub_share / 16 : opt.ub_share) * (now_seconds() - t_start);
    };
    /* one finder iteration on the half with the least finder time; a word is verified (mutant 12: not) before it
     * lowers ub_h / U and is reported; a failure or lb_h > ub_h sets ub_trap */
    auto ub_step = [&]() {
        int k = -1;
        for (int t = 0; t < 2; t++)
            if (uf[t] && (k < 0 || uf[t]->stats().seconds < uf[k]->stats().seconds)) k = t;
        if (k < 0) return;
        const int target = U < INF ? U : n + 1;
        std::vector<int> e;
        ub_iters++;
        if (!uf[k]->iterate(target, e)) {
            if (uf[k]->last_hit() && target == U) ub_rehits++;
            const uint64_t plateau = std::max<uint64_t>(64, 4 * ub_iter_last);
            if (!ub_conv && opt.ub_hits > 0 && (ub_rehits >= opt.ub_hits || ub_iters - ub_iter_last >= plateau)) {
                ub_conv = true;
                if (verb > 0) printf("c cc: ub-search: U %d %s: finder share %.4f from now on (iteration %llu, wall %.3fs)\n", U,
                                     ub_rehits >= opt.ub_hits ? "re-hit without improvement" : "not improved on a plateau",
                                     opt.ub_share / 16, (unsigned long long)ub_iters, now_seconds() - t_start);
                if (trace) { fprintf(trace, "# ub-search converged at U %d, wall %.6f\n", U, now_seconds() - t_start); fflush(trace); }
            }
            return;
        }
        Half& h = hs[k];
        const int w = (int)e.size();
        std::string why;
        if (opt.mutant != 12 && (w >= target || !verify_in_half(h, e, n, why))) {
            ub_trap = std::string(h.tag) + " half ub-search word failed verification: " + (w >= target ? "not below the target" : why);
            return;
        }
        if (verb > 0) {
            printf("c cc: ub-search: %s half word of weight %d (iteration %llu, wall %.3fs)\n", h.tag, w,
                   (unsigned long long)uf[k]->stats().iterations, now_seconds() - t_start);
            printf("c witness %s (ub-search): %s\n", h.tag, support_string(e).c_str());
        }
        if (trace) {
            fprintf(trace, "%s %d UB-SEARCH %llu %.6f %s\n", h.tag, w, (unsigned long long)uf[k]->stats().iterations,
                    now_seconds() - t_start, support_string(e).c_str());
            fflush(trace);
        }
        if (dual) {
            std::vector<int> img;
            for (size_t t = 0; t < e.size(); t++) img.push_back(in.dual_perm[e[t]]);
            std::sort(img.begin(), img.end());
            if (opt.mutant != 12 && !verify_in_half(hs[1], img, n, why)) {
                ub_trap = "dual image of the X ub-search word failed verification in the Z half: " + why;
                return;
            }
            hs[1].ub = std::min(hs[1].ub, w);
        }
        h.ub = std::min(h.ub, w);
        if (w < U) {
            U = w;
            sink.bound(sink.ctx, "UB", (uint64_t)U);
            ub_rehits = 0;
            ub_conv = false;
            ub_iter_last = ub_iters;
        }
        fflush(stdout);
        for (int t = 0; t < 2; t++)
            if (hs[t].exists && hs[t].lb > hs[t].ub && !opt.ub_only) {
                char buf[160];
                snprintf(buf, sizeof(buf), "%s half lower bound %d exceeds its verified (ub-search) upper bound %d",
                         hs[t].tag, hs[t].lb, hs[t].ub);
                ub_trap = buf;
            }
    };
    /* runs the finder while it is due; true: abandon the level in progress (U <= its weight) or a trap */
    uint64_t ub_skip = opt.ub_skip_polls;
    auto ub_poll = [&]() -> bool {   /* all time spent in here counts as finder time (so a share < 1 always ends) */
        if (ub_skip > 0) { ub_skip--; return false; }
        double t0 = now_seconds();
        while (ub_trap.empty() && ub_due()) {
            ub_step();
            const double t1 = now_seconds();
            ub_spent += t1 - t0;
            t0 = t1;
            if (ub_curw > 0 && U <= ub_curw) break;
        }
        return !ub_trap.empty() || (ub_curw > 0 && U <= ub_curw);
    };
    struct PollThunk { std::function<bool()> f; } thunk;
    thunk.f = ub_poll;
    auto ub_report = [&]() {
        if (!ubs || !(verb > 0 || opt.stats)) return;
        for (int k = 0; k < 2; k++) {
            if (!uf[k]) continue;
            const UbStats& st = uf[k]->stats();
            printf("c cc%s: ub-search %s: iterations %llu, finder time %.3fs, kept %llu, nontrivial %llu, li-gain %llu, "
                   "improvements %llu, rank %d, K %d, ub %d\n", opt.stats ? "-stats" : "", hs[k].tag,
                   (unsigned long long)st.iterations, st.seconds, (unsigned long long)st.kept,
                   (unsigned long long)st.nontrivial, (unsigned long long)st.li_gain, (unsigned long long)st.found,
                   uf[k]->rank(), uf[k]->dim(), hs[k].ub == INF ? -1 : hs[k].ub);
            if (opt.ub.isd)   /* GH-146 */
                printf("c cc%s: ub-search %s collision: rounds %llu, colliding pairs %llu (nontrivial %llu)\n", opt.stats ? "-stats" : "",
                       hs[k].tag, (unsigned long long)st.rounds, (unsigned long long)st.collisions, (unsigned long long)st.coll_nt);
        }
        fflush(stdout);
    };
    if (opt.ub_only) {   /* diagnostic: the finder alone for the budget; RESULT -1 (no answer) */
        ub_poll();
        if (!ub_trap.empty()) return fail(ub_trap);
        ub_report();
        if (verb > 0) printf("c cc: ub-search only: U %d after %.3fs (no lower-bound search)\n", U == INF ? -1 : U, ub_spent);
        fflush(stdout);
        if (trace) { fprintf(trace, "# ub-only U %d\n", U == INF ? -1 : U); fclose(trace); trace = NULL; }
        sink.result(sink.ctx, -1, false);
        return -1;
    }
    if (ubs)
        for (int k = 0; k < 2; k++)
            if (hs[k].search) hs[k].search->set_poll([](void* c) { return ((PollThunk*)c)->f(); }, &thunk, opt.ub_poll_mask);

    int lastLB = 1, lastTry = 0, d = -1;   /* the trivial bound 1 is not emitted */
    {   /* parity: the certified bound 2 of a qualifying half is emitted before the first level */
        int glb0 = INF;
        for (int k = 0; k < 2; k++)
            if (hs[k].exists && hs[k].lb < glb0) glb0 = hs[k].lb;
        if (glb0 > lastLB && glb0 < U) {
            sink.bound(sink.ctx, "LB", (uint64_t)glb0);
            lastLB = glb0;
        }
    }
    for (;;) {
        if (ubs) {   /* GH-140: finder slices due between levels (the pre-pass happens here on the first pass) */
            ub_curw = 0;
            ub_poll();
            if (!ub_trap.empty()) return fail(ub_trap);
        }
        int glb = INF;
        for (int k = 0; k < 2; k++)
            if (hs[k].exists && hs[k].lb < glb) glb = hs[k].lb;
        if (glb > U) return fail("global lower bound exceeds the verified upper bound");
        if (glb >= U) { d = U; break; }
        /* next level: lockstep (lowest lb; tie: half that was cheaper at its previous level, then X),
         * or, in the test-only sequential schedule, the first half still below U */
        int pick = -1;
        for (int k = 0; k < 2; k++) {
            if (!hs[k].searched || hs[k].lb >= U) continue;
            if (pick < 0) pick = k;
            else if (!sequential &&
                     (hs[k].lb < hs[pick].lb || (hs[k].lb == hs[pick].lb && hs[k].last_nodes < hs[pick].last_nodes)))
                pick = k;
        }
        if (pick < 0) return fail("no searchable half below the upper bound");
        Half& h = hs[pick];
        const int w = h.lb;   /* contiguous levels: the level-w precondition is lb_h = w */
        if (w > n) return fail(std::string(h.tag) + " half: rank shows a nontrivial logical but no level <= n found one");
        if (w > lastTry) { sink.bound(sink.ctx, "TRY", (uint64_t)w); lastTry = w; }
        const double t0 = now_seconds();
        ub_curw = w;
        LevelResult r = h.search->run_level(w);
        ub_curw = 0;
        const double dt = now_seconds() - t0;
        if (!ub_trap.empty()) return fail(ub_trap);
        h.last_nodes = r.nodes;
        h.total_nodes += r.nodes;
        h.total_time += dt;
        const char* vs = r.verdict == LEVEL_FOUND ? "FOUND" : r.verdict == LEVEL_EMPTY ? "EMPTY" :
                         r.verdict == LEVEL_ABORTED ? "ABORTED" : "INCONSISTENT";
        if (trace) {
            fprintf(trace, "%s %d %s %llu %.6f%s%s\n", h.tag, w, vs, (unsigned long long)r.nodes, dt,
                    r.witness.empty() ? "" : " ", support_string(r.witness).c_str());
            fflush(trace);
        }
        if (verb > 0)
            printf("c cc: %s half level %d %s nodes %llu seeds %llu time %.3fs\n", h.tag, w, vs,
                   (unsigned long long)r.nodes, (unsigned long long)r.seeds, dt);
        if (r.lbswitchoff && (verb > 0 || opt.stats))   /* GH-157 -cc-lb-auto (only with charge/ecover on) */
            printf("c cc: %s half node lower bounds switched off after level %d (%llu of %llu evaluations pruned, below %d %%)\n",
                   h.tag, w, (unsigned long long)(r.chgprune + r.ecprune), (unsigned long long)r.lbeval, opt.lb_auto);
        if (opt.stats) {
            printf("c cc-stats: %s level %d %s nodes %llu seeds %llu closed %llu nocand %llu packprune %llu parprune %llu "
                   "leaf1 %llu leaf2 %llu ovtight %llu ovforbid %llu time %.6fs\n",
                   h.tag, w, vs, (unsigned long long)r.nodes, (unsigned long long)r.seeds,
                   (unsigned long long)r.closed, (unsigned long long)r.nocand, (unsigned long long)r.packprune,
                   (unsigned long long)r.parprune, (unsigned long long)r.leaf1, (unsigned long long)r.leaf2,
                   (unsigned long long)r.ovtight, (unsigned long long)r.ovforbid, dt);
            if (!r.by_budget.empty()) {   /* nodes by remaining budget w - |S|, budget 0 (full clusters) first */
                printf("c cc-stats: %s level %d nodes-by-budget", h.tag, w);
                for (size_t b = 0; b < r.by_budget.size(); b++) printf(" %llu", (unsigned long long)r.by_budget[b]);
                printf("\n");
            }
            if (opt.rules.charge || opt.rules.ecover) {   /* GH-157: printed only with the new rules (identity otherwise) */
                printf("c cc-stats: %s level %d lb lbeval %llu chgprune %llu ecprune %llu ecexact %llu lbdead %llu\n", h.tag, w,
                       (unsigned long long)r.lbeval, (unsigned long long)r.chgprune, (unsigned long long)r.ecprune,
                       (unsigned long long)r.ecexact, (unsigned long long)r.lbdead);
                if (!r.lbprune_by_budget.empty()) {
                    printf("c cc-stats: %s level %d lbprune-by-budget", h.tag, w);
                    for (size_t b = 0; b < r.lbprune_by_budget.size(); b++) printf(" %llu", (unsigned long long)r.lbprune_by_budget[b]);
                    printf("\n");
                }
            }
        }
        fflush(stdout);
        if (r.verdict == LEVEL_INCONSISTENT) {
            char buf[160];
            snprintf(buf, sizeof(buf), "%s half: nontrivial syndrome-free cluster of weight %zu below level %d (precondition violated)",
                     h.tag, r.witness.size(), w);
            return fail(buf);
        }
        if (r.verdict == LEVEL_ABORTED) {   /* GH-140: U <= w (ub-search); lb unchanged, the stop rule decides next */
            if (verb > 0) printf("c cc: %s half level %d abandoned: ub-search upper bound %d <= %d\n", h.tag, w, U, w);
            fflush(stdout);
            continue;
        }
        bool stop = false;
        if (r.verdict == LEVEL_EMPTY) {
            h.lb = w + 1;
            if (h.par && (h.lb & 1)) {   /* GH-133 parity: an EMPTY even level 2t certifies 2t+2 */
                h.lb++;
                if (trace) { fprintf(trace, "%s %d SKIPPED 0 0.000000\n", h.tag, w + 1); fflush(trace); }
                if (verb > 0) printf("c cc: %s half level %d skipped (parity: every logical has even weight)\n", h.tag, w + 1);
            }
            if (dual) hs[1].lb = hs[0].lb;
        } else {
            std::string why;
            if ((int)r.witness.size() != w || !verify_in_half(h, r.witness, n, why))
                return fail(std::string(h.tag) + " half witness failed verification: " + why);
            if (verb > 0) printf("c witness %s: %s\n", h.tag, support_string(r.witness).c_str());
            if (dual) {
                std::vector<int> img;
                for (size_t t = 0; t < r.witness.size(); t++) img.push_back(in.dual_perm[r.witness[t]]);
                std::sort(img.begin(), img.end());
                if (!verify_in_half(hs[1], img, n, why))
                    return fail("dual image of the X witness failed verification in the Z half: " + why);
                if (verb > 0) printf("c witness Z (dual image): %s\n", support_string(img).c_str());
                hs[1].ub = std::min(hs[1].ub, w);
            }
            h.ub = std::min(h.ub, w);
            if (w < U) {
                U = w;
                sink.bound(sink.ctx, "UB", (uint64_t)U);
            }
            /* stop rule: d = w once the other half's lower bound is >= w. Under lockstep this always holds
             * at a hit (the picked half has the lowest lb; a mirrored dual half has lb = w); under the
             * sequential schedule it is load-bearing. Mutant 4 (which forces sequential) skips the check. */
            const Half& o = hs[1 - pick];
            const int olb = o.exists ? o.lb : INF;
            if (opt.mutant == 4 || olb >= w) {
                stop = true;
                d = w;
            }
        }
        for (int k = 0; k < 2; k++)
            if (hs[k].exists && hs[k].lb > hs[k].ub) {
                char buf[128];
                snprintf(buf, sizeof(buf), "%s half lower bound %d exceeds its verified upper bound %d",
                         hs[k].tag, hs[k].lb, hs[k].ub);
                return fail(buf);
            }
        if (stop) break;
        glb = INF;
        for (int k = 0; k < 2; k++)
            if (hs[k].exists && hs[k].lb < glb) glb = hs[k].lb;
        if (glb > U) return fail("global lower bound exceeds the verified upper bound");
        if (glb > lastLB && glb < U) {
            sink.bound(sink.ctx, "LB", (uint64_t)glb);
            lastLB = glb;
        }
    }
    ub_report();
    if (verb > 0 || opt.stats) {
        printf("c cc%s: total nodes X %llu Z %llu, search time X %.3fs Z %.3fs, wall %.3fs\n", opt.stats ? "-stats" : "",
               (unsigned long long)hs[0].total_nodes, (unsigned long long)hs[1].total_nodes, hs[0].total_time,
               hs[1].total_time, now_seconds() - t_start);
        if (verb > 0) printf("c cc: d = %d\n", d);
        fflush(stdout);
    }
    if (trace) {
        fprintf(trace, "# d %d\n", d);
        fclose(trace);
    }
    sink.bound(sink.ctx, "LB", (uint64_t)d);
    sink.result(sink.ctx, d, true);
    return d;
}

} /* namespace distcc */
