// GH-124 S0 test: the CC level-search engine (src/cc) against exhaustive enumeration.
// src/core/distqldpc.cc is included verbatim (its main() renamed) so that the production orbit detection
// (find_half_symmetry, GH-85), dual-map detection (find_dual_maps, GH-87/GH-107) and the production CC wrapper
// (min_distance_css_cc) are the ones under test; driver runs happen in a forked child and report through the
// production bounds pipe protocol (TRY / LB / UB / RESULT).
//
// Part A (half level): random halves (H, G) with n = 4..18 (half X convention: F = {v : H v = 0, G v != 0}),
//   half of them closed under a planted GH-75 shift so that find_half_symmetry verifies nontrivial orbits, and a
//   third of them with all column weights made odd (GH-133: one extra row over the even-weight columns, invariant
//   under the planted shift) so that the parity rule is in force. Every subset of {excl, pack, orbf, mrv, parity,
//   leaf} and relabeling seeds 0..2: the level ladder 1..d_h must give EMPTY below d_h and FOUND at d_h with a
//   witness of weight d_h in F (no element: EMPTY at every level <= n); on an all-odd half d_h must be even.
// Part B (driver): random consistent CSS codes (Hx Hz^T = 0, Gx/Gz computed as quotient bases, n = 6..16),
//   planted shifts and self-dual codes (Hx = Hz, so the identity XZ-dual map is verified). Configurations:
//   default (GH-133 rules excl,pack,orbf,parity,leaf), -cc-dual=off, -ub-basis, -cc-seed 1/2, -cc-rules none / mrv,
//   the GH-124 rule set excl,pack,orbf ("oldrules"). Each run: RESULT d OPTIMAL with d = min(dX, dZ) from
//   enumeration (dX: Hz x = 0, x not in rs Hx), every LB <= d <= every UB, LBs monotone. A third of the codes get
//   all-odd column weights in Hz (fix-up row before Hx is drawn from ker Hz), so the X half qualifies for parity.
// Part C (mutants, -cc-mutant=K): every mutant must change an answer. 1 (forbidden set not restored), 2 (packing
//   prune >=) and 3 (orbit seed rule off by one: O_1..O_i forbidden while r_i is searched, on instances with
//   verified orbits) must produce wrong half-level verdicts; 4 (stop rule without the other half's lower bound,
//   which forces the sequential schedule) must produce wrong driver answers, both when the schedule is requested
//   (-cc-schedule=sequential) and when it is not (default options, as the binary runs -cc-mutant=4). The
//   canonical driver must stay correct under the sequential schedule, where the other-half check is load-bearing.
//   GH-133: 5 (parity rule forced although a column weight is even; instances with an even column weight), 6 (leaf
//   budget off by one) and 7 (leaf closure without the detector check) must produce wrong half-level verdicts.
//   GH-138: 8 (overlap limit off by one), 9 (parity checks H used as the stabilizer rows K) and 10 (even-|g| tie cut)
//   must produce wrong half-level verdicts.
// GH-138 (rule overlap): Part A gives every half a set K of stabilizer rows g with H g = 0 and G g = 0 (the elements
//   that make e + g an element of F): by instance, a basis of ker [H; G] in enumeration order, all its elements of
//   weight <= 6 (at most 60), or a few random elements; K is NOT closed under the planted shift, so the orbit seed
//   rule is tested with an arbitrary row set. Every subset of the 7 rules (128) x seeds 0..2. Part B runs the
//   driver, where K = the same-type stabilizer matrix (X half Hx, Z half Hz), with and without overlap.
// Part E (GH-140, -ub-search): on the Part B codes, (a) the randomized finder (UbFinder) of each half alone, 300
//   iterations with a falling target: every returned word is in ker H, detected by G (nontrivial), lighter than the
//   target and >= d_h from enumeration; a second finder with the same seed returns the same words (determinism); the
//   count of halves where it reaches d_h is reported (triples on for odd instances); with mutant 11 (no detector check)
//   some returned word must be trivial. (b) Driver runs with the finder: pre-pass capped at 10 ms, share 0.9 with a
//   poll at every node, the same with the first N polls skipped (the finder starts mid-ladder, so levels are
//   abandoned when U <= w; counted from -cc-trace ABORTED lines), dual off + seed 3,
//   sequential schedule, -ub-basis off, ub-only (RESULT -1 without trap, every UB >= d): RESULT d OPTIMAL = enumeration,
//   every UB >= d, LBs monotone <= d. (c) Mutants 11 (finder without the detector check: the driver's verification
//   must stop the run) and 12 (mutant 11 plus words reported without verification: wrong answers) must fail.
// Part D (GH-133, MaxSAT path): the production interleaved split driver (min_distance_css_interleaved, -no-card)
//   with -oddcap-skip on and off on the Part B codes: RESULT d OPTIMAL = enumeration, bounds within [1, d]. It runs
//   with the production defaults of the other flags (so also -stab-overlap=auto, the default since GH-148's adoption;
//   Parts F and G set -stab-overlap explicitly through PreCfg).
// Part F (GH-144, -ub-pre on the MaxSAT path): the same driver with the verified finder pre-pass on the Part B codes:
//   budget 1 s (converged pre-pass, U0 = d on almost every code), and pre-passes cut after 1, 2 or 3 finder iterations
//   (U0 > d on many codes, so Phase 1 FOUND, Phase 2a FOUND and Phase 2b OPT below a seeded U are exercised), with
//   -oddcap-skip off, -seed 5, -dualmode off, -dualmode skip, -no-symbreak and -card-mto: RESULT d OPTIMAL = enumeration,
//   every UB >= d, LBs monotone <= d, and the first UB (the pre-pass U0) >= d. Test mutants: 1 (finder without its
//   detector check: trivial words must be rejected by the verification; answers stay correct) and 2 (mutant 1 plus
//   words used without verification: some answer must be wrong, on the codes and on the rotated surface codes).
// GH-146 (-ub-isd collision mode of the same finder): Part E (a) is repeated with six collision configurations (Stern
//   p = 1, 2; Dumer p = 1, 2; window sizes automatic / 0 / 2 / 3; walk 0 / 1 / 8 / 32 Canteaut-Chabaud swaps; batch
//   1 / 2 / 3; refresh 0 / 5): every returned word is in ker H, detected by G, lighter than the target and >= d_h;
//   same seed, same words; the halves where d_h is reached are counted and must be >= 90 % per configuration; mutant 11
//   (no detector check) must return a trivial word. Part E (b): the CC driver with Stern / Dumer (pre-pass, late start,
//   finder-only), and mutants 11 / 12 in collision mode (12 = words reported without verification: some answer must be
//   wrong). Part F: the MaxSAT pre-pass in collision mode (budget 1 s, cut after 2 iterations) and its mutants 1 / 2
//   (2 must answer wrongly on the codes or on the rotated surface codes).
// GH-152 (-cc-aut=on, Tanner-graph automorphism candidates): Part G = half level on relabeled planted-shift halves (hidden
//   symmetry) with orbits from the Tanner generators under the GF(2) checks, all 128 rule subsets x seeds 0..2 vs brute force;
//   Part H = driver with -cc-aut=on on relabeled hypergraph products (hidden transpose XZ duality) and relabeled random codes;
//   mutants 13 (candidates and the cyclic shift i -> i+1 mod n kept without the GF(2) checks) and 14 (swap map / identity used as dual map
//   without the check) must fail. Usage: test_cc_engine [NA [NB [NG [NH]]]].
// Part G (GH-148, -stab-overlap on the MaxSAT path): (a) encoding check: on one row g of weight w = 1..14 with the
//   objective "maximize the true qubits" (soft clauses x_i), MaxCDCL's optimum must be w - floor(|g|/2) for the
//   binomial and the sequential-counter encodings and the native MaxCDCL propagator (at most floor(|g|/2) true, and that many reachable). (b) The MaxSAT
//   split driver with the overlap constraints on the Part B codes, in configurations without and with -ub-pre (cut
//   after one finder iteration), the four encodings (auto, bin, seq, native), the per-probe activation (auto ratio 2, ratio 1), -card-mto, -dualmode off/skip, -seed 3, -no-symbreak,
//   -oddcap-skip off: RESULT d OPTIMAL = enumeration, every UB >= d, LBs monotone <= d; and on rotated surface codes
//   d = 3..5 (weight-2 boundary stabilizers, the rule binds hard). Mutants (test-only g_stab_overlap_mutant): 1 = limit
//   floor(|g|/2) - 1 and 2 = the half's parity rows used as g without the GF(2) check must give wrong answers.
//   Also counted: codes where the constraints remove an element of F of weight <= d + 2 (the rule is not vacuous).
// GH-157 (rule charge): Part I (a) the bound function on random hitting-set instances (k <= 10 candidate sets over <= 14
//   qubits, a third of them with every qubit in <= 2 sets) against brute-force tau: charge (with and without the raise)
//   <= tau, local <= raised, and the early-exit contract (bound(r) > r iff exact bound > r, and then bound(r) <= exact
//   bound) for every r; mutant 15 must exceed tau somewhere. (b) On every Part A half: all 128 base rule subsets x three
//   charge configurations (lb-minr 1 / 2 / 3 with lb-gap unlimited / 0 / 1) x seeds 0..2 (seed 1: auto switch-off at
//   60 % after any level; seed 2: no raise): the ladder must match enumeration; mutant 15 (charge inflated by 1/D) must
//   give wrong half-level verdicts. The search hands a copy of the odd rows' candidate sets to the lb_charge tested in
//   (a). (c) Part B driver configurations with charge (minr 1 and 3, gap 0 / 1 / unlimited, with and without pack).
#define main distqldpc_main_unused
#include "../src/core/distqldpc.cc"
#undef main

#include <algorithm>
#include <set>
#include <sys/wait.h>

static unsigned long long rng_state = 0x243f6a8885a308d3ULL;
static unsigned rnd(unsigned m) {
    rng_state ^= rng_state << 13; rng_state ^= rng_state >> 7; rng_state ^= rng_state << 17;
    return (unsigned)(rng_state % m);
}

typedef unsigned Mask;
static int popc(Mask x) { return __builtin_popcount(x); }
static bool odd(Mask x) { return popc(x) & 1; }
static Mask perm_apply(const std::vector<int>& p, Mask v) {
    Mask w = 0;
    for (size_t i = 0; i < p.size(); i++) if ((v >> i) & 1) w |= 1u << p[i];
    return w;
}
static std::vector<int> blockshift(int n, int L) { std::vector<int> p(n); for (int i = 0; i < n; i++) p[i] = (i / L) * L + ((i % L) + 1) % L; return p; }
static std::vector<int> stridedshift(int n, int L) { const int B = n / L; std::vector<int> p(n); for (int i = 0; i < n; i++) p[i] = (((i / B) + 1) % L) * B + (i % B); return p; }
static std::vector<Mask> closure(std::vector<Mask> seeds, const std::vector<std::vector<int> >& gens, size_t cap) {
    std::set<Mask> seen; std::vector<Mask> out, todo(seeds);
    while (!todo.empty() && out.size() < cap) {
        Mask v = todo.back(); todo.pop_back();
        if (!v || seen.count(v)) continue;
        seen.insert(v); out.push_back(v);
        for (const auto& g : gens) todo.push_back(perm_apply(g, v));
    }
    return out;
}
static Mask rand_vec(int n, int wmin, int wmax) {
    Mask v = 0; int w = wmin + (int)rnd((unsigned)(wmax - wmin + 1));
    for (int j = 0; j < w; j++) v |= 1u << rnd(n);
    return v;
}
// GH-133: make every column weight of H odd by adding one row over the even-weight columns (if any)
static void make_columns_odd(std::vector<Mask>& H, int n) {
    Mask fix = 0;
    for (int c = 0; c < n; c++) { int w = 0; for (Mask h : H) w += (h >> c) & 1; if (!(w & 1)) fix |= 1u << c; }
    if (fix) H.push_back(fix);
}
static bool all_odd(const std::vector<Mask>& H, int n) {
    for (int c = 0; c < n; c++) { int w = 0; for (Mask h : H) w += (h >> c) & 1; if (!(w & 1)) return false; }
    return true;
}
static Matrix to_matrix(const std::vector<Mask>& rows, int n) {
    Matrix m; m.rows = (int)rows.size(); m.cols = n; m.data.assign((size_t)m.rows * n, 0);
    for (int r = 0; r < m.rows; r++) for (int c = 0; c < n; c++) m.data[(size_t)r * n + c] = (rows[r] >> c) & 1;
    return m;
}
static distcc::SparseRows to_rows(const std::vector<Mask>& rows, int n) {
    distcc::SparseRows R; R.cols = n;
    for (Mask v : rows) { std::vector<int> s; for (int c = 0; c < n; c++) if ((v >> c) & 1) s.push_back(c); R.rows.push_back(s); }
    return R;
}
// GF(2) span of masks (echelon by highest bit)
struct Span {
    std::vector<Mask> b;
    Mask red(Mask v) const { for (Mask r : b) if ((v ^ r) < v) v ^= r; return v; }
    bool add(Mask v) { v = red(v); if (!v) return false; b.push_back(v); std::sort(b.rbegin(), b.rend()); return true; }
    bool has(Mask v) const { return red(v) == 0; }
};
static bool in_kernel(const std::vector<Mask>& H, Mask v) { for (Mask h : H) if (odd(h & v)) return false; return true; }
static bool detected(const std::vector<Mask>& G, Mask v) { for (Mask g : G) if (odd(g & v)) return true; return false; }
// min weight of v in ker H with G v != 0 (-1: none)
static int half_opt(const std::vector<Mask>& H, const std::vector<Mask>& G, int n) {
    int opt = -1;
    for (Mask v = 1; v < (1u << n); v++) {
        if (!in_kernel(H, v) || !detected(G, v)) continue;
        int w = popc(v);
        if (opt < 0 || w < opt) opt = w;
    }
    return opt;
}
// min weight of v in ker H outside rs S (-1: none) -- the independent definition
static int half_opt_stab(const std::vector<Mask>& H, const std::vector<Mask>& S, int n) {
    Span sp; for (Mask s : S) sp.add(s);
    int opt = -1;
    for (Mask v = 1; v < (1u << n); v++) {
        if (!in_kernel(H, v) || sp.has(v)) continue;
        int w = popc(v);
        if (opt < 0 || w < opt) opt = w;
    }
    return opt;
}

static std::vector<int> orbits_of(const std::vector<Mask>& H, const std::vector<Mask>& G, int n) {
    HalfSymInfo info = find_half_symmetry(to_matrix(H, n), to_matrix(G, n));
    if ((int)info.reps.size() < info.n) return info.orbit_of;
    return std::vector<int>();
}

static distcc::Rules rules_of(int mask) {
    distcc::Rules r; r.excl = mask & 1; r.pack = mask & 2; r.orbf = mask & 4; r.mrv = mask & 8; r.parity = mask & 16; r.leaf = mask & 32;
    r.overlap = mask & 64; r.charge = mask & 128;   // GH-157
    return r;
}
static const int RM_CHG = 128;   // GH-157
static const int RM_DEF = 7 | 16 | 32 | 64 | 128;   // GH-157: the default rule set (excl,pack,orbf,parity,leaf,overlap,charge)
static const int RM_OLD = 7, RM_133 = 7 | 16 | 32, RM_NEW = 7 | 16 | 32 | 64, RM_ALL = 127, RM_NSUB = 128;
static const char* rules_name(int mask) {
    static char buf[64];
    distcc::Rules r = rules_of(mask);
    snprintf(buf, sizeof(buf), "%s", distcc::rules_string(r).c_str());
    return buf;
}

// ladder 1..dh for one configuration; returns true if every verdict matches; nodes summed into *nodes
static bool ladder_ok(const std::vector<Mask>& H, const std::vector<Mask>& G, const std::vector<Mask>& K, int n, int dh,
                      const std::vector<int>& orb, int rmask, uint64_t seed, int mutant, uint64_t* nodes, std::string& why,
                      int lbminr = 3, uint64_t* lbprunes = NULL, int lbgap = 1000) {
    distcc::Rules r = rules_of(rmask);
    const distcc::SparseRows Kr = to_rows(K, n);
    distcc::HalfSearch hs(to_rows(H, n), to_rows(G, n), orb, r, seed, mutant, &Kr);
    hs.set_lb_minr(lbminr);
    hs.set_lb_gap(lbgap);
    hs.set_lb_raise(seed != 2 || mutant != 0);   // GH-157: seed 2 ladders run the charge without the raise
    hs.set_lb_auto(seed == 1 && mutant == 0 ? 60 : 0, 1);   // GH-157: seed 1 ladders exercise the auto switch-off (any level)
    const int top = dh < 0 ? n : dh;
    char buf[160];
    for (int w = 1; w <= top; w++) {
        distcc::LevelResult res = hs.run_level(w);
        if (nodes) *nodes += res.nodes;
        if (lbprunes) *lbprunes += res.chgprune;
        const bool expect_found = (w == dh);
        if (res.verdict == distcc::LEVEL_INCONSISTENT) { snprintf(buf, sizeof(buf), "w=%d INCONSISTENT", w); why = buf; return false; }
        if ((res.verdict == distcc::LEVEL_FOUND) != expect_found) {
            snprintf(buf, sizeof(buf), "w=%d got %s expected %s (d_h=%d)", w, res.verdict == distcc::LEVEL_FOUND ? "FOUND" : "EMPTY",
                     expect_found ? "FOUND" : "EMPTY", dh);
            why = buf; return false;
        }
        if (res.verdict == distcc::LEVEL_FOUND) {
            Mask v = 0;
            for (int q : res.witness) v |= 1u << q;
            if (popc(v) != w || (int)res.witness.size() != w || !in_kernel(H, v) || !detected(G, v)) {
                snprintf(buf, sizeof(buf), "w=%d invalid witness", w); why = buf; return false;
            }
        }
    }
    return true;
}

struct RunOut { bool ok; int d; std::vector<long long> lbs, ubs; };

static RunOut run_driver(const Matrix& Hx, const Matrix& Hz, const Matrix& Gx, const Matrix& Gz,
                         const distcc::DriverOptions& opt, bool symbreak, bool dual_allowed) {
    RunOut r; r.ok = false; r.d = -2;
    int fd[2];
    if (pipe(fd) != 0) { perror("pipe"); exit(2); }
    fflush(stdout); fflush(stderr);
    pid_t pid = fork();
    if (pid == 0) {
        close(fd[0]);
        int devnull = open("/dev/null", O_WRONLY);
        if (devnull >= 0 && !getenv("CC_TEST_VERBOSE")) { dup2(devnull, 1); dup2(devnull, 2); }
        alarm(60);
        (void)min_distance_css_cc(Hx, Hz, Gx, Gz, 0, fd[1], opt, symbreak, dual_allowed);
        fflush(stdout);
        _exit(0);
    }
    close(fd[1]);
    std::string all; char buf[4096]; ssize_t k;
    while ((k = read(fd[0], buf, sizeof(buf))) > 0) all.append(buf, (size_t)k);
    close(fd[0]);
    int st = 0; waitpid(pid, &st, 0);
    size_t pos = 0;
    while (pos < all.size()) {
        size_t e = all.find('\n', pos); if (e == std::string::npos) e = all.size();
        std::string line = all.substr(pos, e - pos); pos = e + 1;
        unsigned long long v; int d;
        if (sscanf(line.c_str(), "LB %llu", &v) == 1) r.lbs.push_back((long long)v);
        else if (sscanf(line.c_str(), "UB %llu", &v) == 1) r.ubs.push_back((long long)v);
        else if (!strncmp(line.c_str(), "RESULT -1", 9)) r.d = -1;
        else if (sscanf(line.c_str(), "RESULT %d", &d) == 1 && strstr(line.c_str(), " OPTIMAL")) { r.d = d; r.ok = true; }
    }
    return r;
}

// GH-133 Part D: the production MaxSAT split driver (fresh solver per probe, -no-card) with -oddcap-skip off/on
struct PreCfg { const char* name; double pre; uint64_t iters; bool oddcap; uint64_t seed; int dualmode; bool symbreak; int card; int mutant;
                int ovl; int ovl_enc; int ovl_mutant; double ovl_ratio;   /* GH-148 (0 = -stab-overlap off) */
                int isd = 0; int isd_p = 2; };   // GH-146: collision mode of the pre-pass finder
static RunOut run_maxsat(const Matrix& Hx, const Matrix& Hz, const Matrix& Gx, const Matrix& Gz, bool oddcap, const PreCfg* pc = NULL) {
    RunOut r; r.ok = false; r.d = -2;
    int fd[2];
    if (pipe(fd) != 0) { perror("pipe"); exit(2); }
    fflush(stdout); fflush(stderr);
    pid_t pid = fork();
    if (pid == 0) {
        close(fd[0]);
        int devnull = open("/dev/null", O_WRONLY);
        if (devnull >= 0 && !getenv("CC_TEST_VERBOSE")) { dup2(devnull, 1); dup2(devnull, 2); }
        alarm(120);
        g_oddcap_skip = oddcap;
        if (pc) {   // GH-144 Part F
            g_ub_pre = pc->pre; g_ub_pre_max_iters = pc->iters; g_seed = pc->seed; g_ub_pre_mutant = pc->mutant;
            g_ub_isd.isd = pc->isd; g_ub_isd.isd_p = pc->isd_p;   // GH-146 (child process only)
            g_stab_overlap = pc->ovl != 0; g_stab_overlap_enc = pc->ovl_enc; g_stab_overlap_mutant = pc->ovl_mutant; g_stab_overlap_ratio = pc->ovl_ratio;   // GH-148
            (void)min_distance_css_interleaved(Hx, Hz, Gx, Gz, 0, fd[1], pc->card, pc->symbreak, pc->dualmode, false);
        } else
        (void)min_distance_css_interleaved(Hx, Hz, Gx, Gz, 0, fd[1], 0, true, DUALMODE_SHARE, false);
        fflush(stdout);
        _exit(0);
    }
    close(fd[1]);
    std::string all; char buf[4096]; ssize_t k;
    while ((k = read(fd[0], buf, sizeof(buf))) > 0) all.append(buf, (size_t)k);
    close(fd[0]);
    int st = 0; waitpid(pid, &st, 0);
    size_t pos = 0;
    while (pos < all.size()) {
        size_t e = all.find('\n', pos); if (e == std::string::npos) e = all.size();
        std::string line = all.substr(pos, e - pos); pos = e + 1;
        unsigned long long v; int d;
        if (sscanf(line.c_str(), "LB %llu", &v) == 1) r.lbs.push_back((long long)v);
        else if (sscanf(line.c_str(), "UB %llu", &v) == 1) r.ubs.push_back((long long)v);
        else if (!strncmp(line.c_str(), "RESULT -1", 9)) r.d = -1;
        else if (sscanf(line.c_str(), "RESULT %d", &d) == 1 && strstr(line.c_str(), " OPTIMAL")) { r.d = d; r.ok = true; }
    }
    return r;
}

static bool run_ok(const RunOut& r, int d) {
    if (!r.ok || r.d != d) return false;
    long long prev = 0;
    for (long long lb : r.lbs) { if (lb > d || lb < prev) return false; prev = lb; }
    for (long long ub : r.ubs) if (ub < d) return false;
    return true;
}

// GH-140: minimum weight of a nonzero element of rs(S) (n + 1 if rs(S) = 0)
static int min_span_weight(const std::vector<Mask>& S, int n) {
    Span sp; for (Mask v : S) sp.add(v);
    int best = n + 1;
    const size_t b = sp.b.size();
    for (unsigned long long c = 1; c < (1ULL << b); c++) {
        Mask v = 0;
        for (size_t i = 0; i < b; i++) if ((c >> i) & 1) v ^= sp.b[i];
        if (v && popc(v) < best) best = popc(v);
    }
    return best;
}

// quotient basis: elements of ker(A) not in rs(B) completing rs(B) to ker(A)
static std::vector<Mask> quotient_basis(const std::vector<Mask>& A, const std::vector<Mask>& B, int n) {
    Span sp; for (Mask b : B) sp.add(b);
    std::vector<Mask> out;
    for (Mask v = 1; v < (1u << n); v++) {
        if (!in_kernel(A, v)) continue;
        if (sp.add(v)) out.push_back(v);
    }
    return out;
}

// GH-157: brute-force minimum hitting set of k sets (bit masks over nq <= 14 qubits); -1 if a set is empty
static int brute_tau(const std::vector<Mask>& sets, int nq) {
    for (Mask s : sets) if (!s) return -1;
    int best = nq + 1;
    for (Mask x = 0; x < (1u << nq); x++) {
        if (popc(x) >= best) continue;
        bool ok = true;
        for (Mask s : sets) if (!(s & x)) { ok = false; break; }
        if (ok) best = popc(x);
    }
    return best;
}

// GH-148 Part G (a): optimum of "maximize true qubits" under one overlap row of weight w (forked child; -1 on failure)
static long long ovl_encoding_opt(int w, int enc) {
    int fd[2];
    if (pipe(fd) != 0) { perror("pipe"); exit(2); }
    fflush(stdout); fflush(stderr);
    pid_t pid = fork();
    if (pid == 0) {
        close(fd[0]);
        int devnull = open("/dev/null", O_WRONLY);
        if (devnull >= 0 && !getenv("CC_TEST_VERBOSE")) { dup2(devnull, 1); dup2(devnull, 2); }
        alarm(60);
        g_stab_overlap_enc = enc;
        SimpSolver S;
        S.setBoundsPipe(-1);
        S.parsing = true; S.verbosity = 0; S.instanceType = 1;
        S.hardWeight = (unsigned)(w + 64); S.UB = S.hardWeight; S.initUB = INT32_MAX; S.nbOriVars = w;
        while (S.nVars() < w) S.newVar();
        std::vector<Var> aux;
        OvlRows rows(1);
        for (int i = 0; i < w; i++) rows[0].push_back(i);
        long long res = -1;
        if (enc == 3 || add_overlap_constraints(S, aux, rows)) {
            bool ok = true;
            for (int i = 0; ok && i < w; i++) { std::vector<Lit> c(1, mkLit(i)); ok = add_clause_soft_fail(S, c, 1); }
            if (ok) {
                S.parsing = false; S.setFrozenVars(); S.eliminate(true);
                if (enc == 3) S.setOverlapRows(rows, std::vector<int>(1, w / 2), w);   // GH-148 native propagator
                if (S.okay()) {
                    vec<Lit> dummy;
                    S.solveLimited(dummy);
                    uint64_t opt = S.getLastOptimalCost();
                    if (opt != UINT64_MAX) res = (long long)opt;
                }
            }
        }
        char buf[32]; int len = snprintf(buf, sizeof(buf), "%lld\n", res);
        if (write(fd[1], buf, (size_t)len) < 0) {}
        _exit(0);
    }
    close(fd[1]);
    char buf[64] = {0}; ssize_t k = read(fd[0], buf, sizeof(buf) - 1); close(fd[0]);
    int st = 0; waitpid(pid, &st, 0);
    return k > 0 ? atoll(buf) : -1;
}

// GH-148: does the overlap rule (rows S, limit floor(|g|/2)) remove some element of F = {H v = 0, G v != 0} of weight <= wmax?
static bool ovl_removes(const std::vector<Mask>& H, const std::vector<Mask>& G, const std::vector<Mask>& S, int n, int wmax) {
    for (Mask v = 1; v < (1u << n); v++) {
        if (popc(v) > wmax || !in_kernel(H, v) || !detected(G, v)) continue;
        for (Mask g : S) if (g && popc(g & v) > popc(g) / 2) return true;
    }
    return false;
}

int main(int argc, char** argv) {
    const int NA = argc > 1 ? atoi(argv[1]) : 300;   // part A instances
    const int NB = argc > 2 ? atoi(argv[2]) : 200;   // part B instances
    int fails = 0;

    // ---------------- Part I (a), GH-157: bound functions vs brute force ----------------
    long pi_inst = 0, pi_bad = 0, pi_tight_c = 0, pi_gain_c = 0, pi_m15 = 0;
    {
        distcc::LbWork lw;
        lw.reset(16, 16);
        for (int inst = 0; inst < 20000; inst++) {
            const int nq = 3 + (int)rnd(12), k = 1 + (int)rnd(10);
            const bool deg2 = inst % 3 == 0;
            std::vector<Mask> sets;
            std::vector<int> deg((size_t)nq, 0);
            for (int i = 0; i < k; i++) {
                Mask s = 0;
                const int sz = 1 + (int)rnd(5);
                for (int t = 0; t < 3 * sz && popc(s) < sz; t++) {
                    const int j = (int)rnd((unsigned)nq);
                    if (deg2 && !(s >> j & 1) && deg[j] >= 2) continue;
                    if (!(s >> j & 1)) { s |= 1u << j; deg[j]++; }
                }
                if (!s && rnd(8)) { i--; continue; }   // empty sets are rare (dead-node path)
                sets.push_back(s);
            }
            const int kk = (int)sets.size();
            std::vector<uint32_t> rs(1, 0), rq;
            for (Mask s : sets) { for (int j = 0; j < nq; j++) if (s >> j & 1) rq.push_back((uint32_t)j); rs.push_back((uint32_t)rq.size()); }
            rq.push_back(0);
            const int tau = brute_tau(sets, nq);
            int p = 0;   // greedy disjoint packing in index order (the pack rule)
            { Mask m = 0; for (Mask s : sets) if (s && !(s & m)) { p++; m |= s; } }
            pi_inst++;
            const int bc = distcc::lb_charge(&rs[0], &rq[0], kk, -1, lw, 0);
            const int bl = distcc::lb_charge(&rs[0], &rq[0], kk, -1, lw, 0, false);   // local-degree only
            bool bad = false;
            if (tau < 0) bad = bc != distcc::LB_DEAD || bl != distcc::LB_DEAD;
            else {
                if (bc > tau || p > tau || bl > bc) bad = true;
                if (bc == tau) pi_tight_c++;
                if (bc > p) pi_gain_c++;
                for (int r = 0; r <= kk + 1; r++) {   // early-exit contract
                    const int c2 = distcc::lb_charge(&rs[0], &rq[0], kk, r, lw, 0);
                    if ((c2 > r) != (bc > r) || (c2 > r && c2 > bc)) bad = true;
                }
                if (distcc::lb_charge(&rs[0], &rq[0], kk, -1, lw, 15) > tau) pi_m15++;
            }
            if (bad) { pi_bad++; fails++; if (pi_bad <= 10) fprintf(stderr, "CC_FAIL partI(a) inst=%d nq=%d k=%d tau=%d pack=%d charge=%d local=%d\n", inst, nq, kk, tau, p, bc, bl); }
        }
    }
    printf("partI(a) (GH-157 charge): %ld hitting-set instances, %ld bad (charge = tau on %ld; charge > pack on %ld)\n",
           pi_inst, pi_bad, pi_tight_c, pi_gain_c);
    printf("partI(a) mutant 15 (charge + 1/D) exceeds tau on %ld instances\n", pi_m15);
    if (pi_m15 == 0 || pi_gain_c == 0) { fprintf(stderr, "CC_FAIL GH-157 bound expectations not met\n"); fails++; }
    long ib_runs = 0, ib_bad = 0, ib_prunes = 0, ib_m15_runs = 0, ib_m15_bad = 0;

    // ---------------- Part A: half level ----------------
    long a_inst = 0, a_orb = 0, a_none = 0, a_odd = 0, a_runs = 0, a_bad = 0;
    long mut_bad[13] = {0}, mut_runs[13] = {0};
    long a_kbasis = 0, a_klow = 0, a_krand = 0, a_ktight = 0;
    for (int inst = 0; inst < NA; inst++) {
        const int n = 4 + (int)rnd(15);
        std::vector<std::vector<int> > gens;
        if (rnd(2)) {
            std::vector<int> divs;
            for (int L = 2; L <= n; L++) if (n % L == 0) divs.push_back(L);
            if (!divs.empty()) { int L = divs[rnd((unsigned)divs.size())]; gens.push_back(rnd(2) ? stridedshift(n, L) : blockshift(n, L)); }
        }
        std::vector<Mask> h0, g0;
        int nh = 1 + (int)rnd((unsigned)(n / 2 + 2)), ng = 1 + (int)rnd(3);
        for (int k = 0; k < nh; k++) h0.push_back(rand_vec(n, 2, 5));
        for (int k = 0; k < ng; k++) g0.push_back(rand_vec(n, 1, n));
        std::vector<Mask> H = closure(h0, gens, 20), G = closure(g0, gens, 12);
        if (G.empty()) G.push_back(1u << rnd(n));
        if (inst % 3 == 0) make_columns_odd(H, n);   // GH-133: parity rule in force on these halves
        const int dh = half_opt(H, G, n);
        // GH-138: stabilizer rows K inside ker [H; G] (e + g stays in F for every e in F)
        std::vector<Mask> kerHG, K;
        {
            Span sp;
            std::vector<Mask> basis;
            for (Mask v = 1; v < (1u << n); v++) {
                if (!in_kernel(H, v) || detected(G, v)) continue;
                kerHG.push_back(v);
                if (sp.add(v)) basis.push_back(v);
            }
            const int kind = inst % 3;
            if (kind == 0) { K = basis; a_kbasis++; }
            else if (kind == 1) { for (Mask v : kerHG) if (popc(v) <= 6 && K.size() < 60) K.push_back(v); a_klow++; }
            else if (!basis.empty()) {
                for (int t = 0, T = 1 + (int)rnd(8); t < T; t++) {
                    Mask v = 0;
                    for (Mask b : basis) if (rnd(2)) v ^= b;
                    if (v) K.push_back(v);
                }
                a_krand++;
            }
            // does some minimum element of F meet a row of K in exactly floor(|g|/2) qubits (the rule can bind)?
            bool tight = false;
            if (dh > 0)
                for (Mask v = 1; v < (1u << n) && !tight; v++)
                    if (popc(v) == dh && in_kernel(H, v) && detected(G, v))
                        for (Mask g : K) if (popc(g & v) == popc(g) / 2 && popc(g) >= 2) { tight = true; break; }
            if (tight) a_ktight++;
        }
        std::vector<int> orb = orbits_of(H, G, n);
        const bool allodd = all_odd(H, n);
        a_inst++; if (!orb.empty()) a_orb++; if (dh < 0) a_none++; if (allodd) a_odd++;
        if (allodd && dh > 0 && (dh & 1)) { fails++; a_bad++; fprintf(stderr, "CC_FAIL partA inst=%d: all-odd half with odd d_h=%d\n", inst, dh); }
        for (int rm = 0; rm < RM_NSUB; rm++)
            for (uint64_t seed = 0; seed < 3; seed++) {
                std::string why;
                a_runs++;
                if (!ladder_ok(H, G, K, n, dh, orb, rm, seed, 0, NULL, why)) {
                    a_bad++; fails++;
                    if (a_bad <= 10) fprintf(stderr, "CC_FAIL partA inst=%d n=%d rules=%s seed=%llu: %s\n", inst, n, rules_name(rm),
                                             (unsigned long long)seed, why.c_str());
                }
            }
        // mutants 1-3 and 5-10 on the configurations where they apply
        for (int mt = 1; mt <= 10; mt++)
            for (int rm = 0; rm < RM_NSUB; rm++) {
                if (mt == 4) break;
                if (mt == 1 && !(rm & 1)) continue;
                if (mt == 2 && !(rm & 2)) continue;
                if (mt == 3 && (!(rm & 4) || orb.empty())) continue;
                if (mt == 5 && (!(rm & 16) || allodd)) continue;   // parity forced where a column weight is even
                if ((mt == 6 || mt == 7) && !(rm & 32)) continue;
                if (mt >= 8 && !(rm & 64)) continue;
                std::string why;
                mut_runs[mt]++;
                if (!ladder_ok(H, G, K, n, dh, orb, rm, 0, mt, NULL, why)) mut_bad[mt]++;
            }
        // Part I (b), GH-157: charge on top of every base subset, three gate configurations; mutant 15
        for (int rm = 0; rm < RM_NSUB; rm++)
            for (int lb = 1; lb <= 3; lb++) {
                const int rmx = rm | RM_CHG;
                static const int gaps[4] = {0, 1000, 0, 1};
                for (uint64_t seed = 0; seed < 3; seed++) {
                    std::string why;
                    uint64_t pr = 0;
                    ib_runs++;
                    if (!ladder_ok(H, G, K, n, dh, orb, rmx, seed, 0, NULL, why, lb, &pr, gaps[lb])) {
                        ib_bad++; fails++;
                        if (ib_bad <= 10) fprintf(stderr, "CC_FAIL partI(b) inst=%d n=%d rules=%s seed=%llu: %s\n", inst, n, rules_name(rmx),
                                                  (unsigned long long)seed, why.c_str());
                    }
                    ib_prunes += (long)pr;
                }
                std::string why;
                if (lb == 1) { ib_m15_runs++; if (!ladder_ok(H, G, K, n, dh, orb, rmx, 0, 15, NULL, why, 1)) ib_m15_bad++; }
            }
    }
    printf("partI(b) (GH-157 charge on the Part A halves): %ld ladder runs (128 base subsets x 3 configurations x seeds 0..2), %ld bad, %ld charge prunes\n",
           ib_runs, ib_bad, ib_prunes);
    printf("mutant 15 (charge inflated by 1/D): %ld/%ld half ladders wrong\n", ib_m15_bad, ib_m15_runs);
    if (ib_prunes == 0 || ib_m15_bad == 0) { fprintf(stderr, "CC_FAIL GH-157 mutant/prune expectations not met\n"); fails++; }
    printf("partA: %ld half instances (%ld with verified orbits, %ld with all column weights odd, %ld without any nontrivial element), %ld ladder runs over %d rule subsets x 3 seeds, %ld bad\n",
           a_inst, a_orb, a_odd, a_none, a_runs, RM_NSUB, a_bad);
    printf("partA K (GH-138): %ld basis, %ld low-weight sets, %ld random sets; %ld instances where a minimum element meets a row of K in floor(|g|/2) qubits\n",
           a_kbasis, a_klow, a_krand, a_ktight);

    // ---------------- Part B: driver through the forked pipe ----------------
    long b_inst = 0, b_runs = 0, b_bad = 0, b_dual = 0, b_xorb = 0, b_dxdz = 0, b_odd = 0, b_seqbad4 = 0, b_seq = 0, b_lock4bad = 0, b_lock4 = 0;
    long b_traps = 0, d_runs = 0, d_bad = 0, d_odd = 0;
    long f_runs = 0, f_bad = 0, f_above = 0, f_exact = 0, f_m1_runs = 0, f_m1_bad = 0, f_m2_runs = 0, f_m2_wrong = 0;
    long g_runs = 0, g_bad = 0, g_codes_removing = 0, g_m_runs[3] = {0, 0, 0}, g_m_wrong[3] = {0, 0, 0}, g_m_failed[3] = {0, 0, 0}, g_m_wrong_nat[3] = {0, 0, 0};
    long e_halves = 0, e_bad = 0, e_reach = 0, e_nondet = 0, e_mut11_unit = 0, e_runs = 0, e_dbad = 0, e_aborted = 0, e_mut12_wrong = 0, e_mut_halves = 0;
    // GH-146 collision mode
    static const struct ICfg { const char* name; int isd, p, l, walk, batch, refresh; } icfgs[] = {
        {"stern2", 1, 2, -1, 8, 1, 0}, {"stern1", 1, 1, -1, 8, 1, 0}, {"dumer2", 2, 2, -1, 8, 1, 0},
        {"stern2-l0-fresh", 1, 2, 0, 0, 1, 0}, {"dumer1-l2-w1-b3-r5", 2, 1, 2, 1, 3, 5}, {"stern2-l3-w32-b2", 1, 2, 3, 32, 2, 0},
    };
    const int NI = (int)(sizeof(icfgs) / sizeof(icfgs[0]));
    long i_halves[8] = {0}, i_bad[8] = {0}, i_nondet[8] = {0}, i_reach[8] = {0}, i_mut_halves = 0, i_mut_trivial = 0;
    long i_runs = 0, i_dbad = 0, i_m11_runs = 0, i_m11_bad = 0, i_m12_runs = 0, i_m12_bad = 0, i_m12_wrong = 0;
    long f_isd_runs = 0, f_isd_bad = 0, f_isd_m1_runs = 0, f_isd_m1_bad = 0, f_isd_m2_runs = 0, f_isd_m2_wrong = 0;
    for (int inst = 0; inst < NB; inst++) {
        const int n = 6 + (int)rnd(11);
        std::vector<std::vector<int> > gens;
        if (rnd(2)) {
            std::vector<int> divs;
            for (int L = 2; L <= n; L++) if (n % L == 0) divs.push_back(L);
            int L = divs[rnd((unsigned)divs.size())];
            gens.push_back(rnd(2) ? stridedshift(n, L) : blockshift(n, L));
        }
        const bool selfdual = rnd(4) == 0;
        std::vector<Mask> Hx, Hz;
        if (selfdual) {
            // self-orthogonal rows: even weight and pairwise even overlap; Hx = Hz
            std::vector<Mask> H;
            int want = 1 + (int)rnd((unsigned)(n / 3 + 1));
            for (int tries = 0; tries < 400 && (int)H.size() < want; tries++) {
                Mask v = rand_vec(n, 2, 6);
                if (!v || odd(v) || !in_kernel(H, v)) continue;
                std::vector<Mask> c = closure(std::vector<Mask>(1, v), gens, 16);
                std::vector<Mask> t(H); t.insert(t.end(), c.begin(), c.end());
                bool ok = true;
                for (size_t a = 0; a < t.size() && ok; a++) for (size_t b = a; b < t.size() && ok; b++) if (odd(t[a] & t[b])) ok = false;
                if (ok) H = t;
            }
            Hx = Hz = H;
        } else {
            std::vector<Mask> z0;
            int mz = 1 + (int)rnd((unsigned)(n / 3 + 1));
            for (int k = 0; k < mz; k++) z0.push_back(rand_vec(n, 2, 5));
            Hz = closure(z0, gens, 12);
            if (inst % 3 == 0) make_columns_odd(Hz, n);   // GH-133: the X half (Hz) qualifies for parity / odd-cap skip
            std::vector<Mask> ker;
            for (Mask v = 1; v < (1u << n); v++) if (popc(v) <= 6 && in_kernel(Hz, v)) ker.push_back(v);
            int mx = 1 + (int)rnd((unsigned)(n / 3 + 1));
            std::vector<Mask> x0;
            for (int k = 0; k < mx && !ker.empty(); k++) x0.push_back(ker[rnd((unsigned)ker.size())]);
            Hx = closure(x0, gens, 12);
            // a truncated closure of Hz need not be shift-invariant: keep only images that commute with Hz
            std::vector<Mask> keep;
            for (Mask v : Hx) if (in_kernel(Hz, v)) keep.push_back(v);
            Hx = keep;
        }
        if (Hx.empty() || Hz.empty()) { inst--; continue; }
        std::vector<Mask> Gx = quotient_basis(Hx, Hz, n);   // Z-type logicals: ker(Hx) / rs(Hz)
        std::vector<Mask> Gz = quotient_basis(Hz, Hx, n);   // X-type logicals: ker(Hz) / rs(Hx)
        if (Gx.empty() || Gz.empty() || Gx.size() != Gz.size()) { inst--; continue; }
        if (selfdual) Gz = Gx;
        // disguise the detector rows: add stabilizer rows and other logical rows
        for (int t = 0, T = (int)rnd(4); t < T; t++) {
            int a = (int)rnd((unsigned)Gx.size());
            Mask nv = Gx[a] ^ (rnd(2) ? Hz[rnd((unsigned)Hz.size())] : Gx[rnd((unsigned)Gx.size())]);
            if (nv && !selfdual) Gx[a] = nv;
        }
        const int dX = half_opt(Hz, Gx, n), dZ = half_opt(Hx, Gz, n);
        const int dX2 = half_opt_stab(Hz, Hx, n), dZ2 = half_opt_stab(Hx, Hz, n);
        if (dX != dX2 || dZ != dZ2) { fprintf(stderr, "CC_FAIL generator: detectors incomplete inst=%d\n", inst); fails++; continue; }
        const int d = std::min(dX, dZ);
        if (dX != dZ) b_dxdz++;
        if (all_odd(Hz, n)) { b_odd++; if (dX & 1) { fprintf(stderr, "CC_FAIL generator: all-odd Hz with odd dX inst=%d\n", inst); fails++; } }
        Matrix mHx = to_matrix(Hx, n), mHz = to_matrix(Hz, n), mGx = to_matrix(Gx, n), mGz = to_matrix(Gz, n);
        DualMapInfo dm = find_dual_maps(mHx, mHz, mGx, mGz, false);
        if (!dm.maps.empty()) b_dual++;
        if (!orbits_of(Hz, Gx, n).empty()) b_xorb++;
        b_inst++;
        struct Cfg { const char* name; int rmask; bool dual; bool ubb; uint64_t seed; bool symbreak; int lbminr; int lbgap; };
        const Cfg cfgs[] = {
            {"default", RM_DEF, true, false, 0, true}, {"dual-off", RM_DEF, false, false, 0, true}, {"ub-basis", RM_DEF, true, true, 0, true},
            {"seed1", RM_DEF, true, false, 1, true}, {"seed2", RM_DEF, false, true, 2, true}, {"none", 0, true, false, 0, true},
            {"mrv", RM_ALL | RM_CHG, true, false, 0, true}, {"no-symbreak", RM_DEF, true, false, 0, false}, {"gh152rules", RM_NEW, true, false, 0, true},
            {"oldrules", RM_OLD, true, false, 0, true}, {"oldrules-seed1", RM_OLD, false, false, 1, true},
            {"gh133rules", RM_133, true, false, 0, true}, {"overlap-only", 64, true, false, 0, true},
            {"overlap-index", 1 | 2 | 64, true, true, 2, false},
            {"charge", RM_NEW | RM_CHG, true, false, 0, true, 3, 0}, {"charge-minr1-gapinf", RM_NEW | RM_CHG, false, true, 1, true, 1, 1000},
            {"charge-minr1", RM_NEW | RM_CHG, true, false, 2, false, 1, 1}, {"charge-nopack-minr1", 1 | 4 | 16 | 32 | 64 | RM_CHG, true, false, 0, true, 1, 0},
        };
        for (const Cfg& c : cfgs) {
            distcc::DriverOptions o;
            o.ub_search = false;   // Part B tests the ladder; -ub-search is on by default since 2026-10-23 (Part E/F test it)
            o.rules = rules_of(c.rmask);
            o.dual = c.dual; o.ub_basis = c.ubb; o.seed = c.seed;
            if (c.lbminr) { o.lb_minr = c.lbminr; o.lb_gap = c.lbgap; }   // GH-157
            RunOut r = run_driver(mHx, mHz, mGx, mGz, o, c.symbreak, true);
            b_runs++;
            if (r.d == -1) b_traps++;
            if (!run_ok(r, d)) {
                b_bad++; fails++;
                if (b_bad <= 10) fprintf(stderr, "CC_FAIL partB inst=%d n=%d cfg=%s: d=%d (dX %d dZ %d) got %d\n", inst, n, c.name, d, dX, dZ, r.d);
            }
        }
        {   // test-only sequential schedule: canonical must pass; mutant 4 (forces sequential) must be caught when dZ < dX.
            // -ub-basis off (GH-133): with the basis upper bound the X half may stop at U before its own hit, which made
            // the detection of mutant 4 depend on the instance stream (1/200 in GH-124); without it the X half always
            // runs to its own distance under the sequential schedule and the other-half check decides the answer.
            distcc::DriverOptions o; o.sequential = true; o.ub_basis = false; o.ub_search = false;
            RunOut r = run_driver(mHx, mHz, mGx, mGz, o, true, false);
            b_runs++; b_seq++;
            if (!run_ok(r, d)) { b_bad++; fails++; fprintf(stderr, "CC_FAIL partB sequential inst=%d d=%d got %d\n", inst, d, r.d); }
            o.mutant = 4;
            mut_runs[4]++;
            RunOut r4 = run_driver(mHx, mHz, mGx, mGz, o, true, false);
            if (!run_ok(r4, d)) { mut_bad[4]++; b_seqbad4++; }
            distcc::DriverOptions l; l.mutant = 4; l.ub_basis = false; l.ub_search = false;   // schedule not requested: mutant 4 must switch to sequential itself
            RunOut l4 = run_driver(mHx, mHz, mGx, mGz, l, true, true);
            b_lock4++; mut_runs[4]++;
            if (!run_ok(l4, d)) { mut_bad[4]++; b_lock4bad++; }
        }
        {   // Part E (GH-140): finder alone (a), driver with the finder (b), mutants 11/12 (c)
            for (int half = 0; half < 2; half++) {
                const std::vector<Mask>& H = half ? Hx : Hz;
                const std::vector<Mask>& G = half ? Gz : Gx;
                const std::vector<Mask>& S = half ? Hz : Hx;
                const int dh = half ? dZ : dX;
                distcc::UbParams up;
                up.isd = 0;   // Part E tests the GH-140 enumeration (-ub-isd=off); stern is the default since 2026-10-23
                if (inst & 1) up.triples_max_k = 64;
                const uint64_t fseed = 1000 + (uint64_t)inst * 2 + (uint64_t)half;
                distcc::UbFinder f(to_rows(H, n), to_rows(G, n), to_rows(S, n), fseed, up);
                distcc::UbFinder f2(to_rows(H, n), to_rows(G, n), to_rows(S, n), fseed, up);
                int target = n + 1;
                bool bad = false;
                for (int it = 0; it < 300 && !bad; it++) {
                    std::vector<int> e1, e2;
                    const bool g1 = f.iterate(target, e1), g2 = f2.iterate(target, e2);
                    if (g1 != g2 || e1 != e2) { bad = true; e_nondet++; break; }
                    if (!g1) continue;
                    Mask v = 0;
                    for (int q : e1) v |= 1u << q;
                    if (popc(v) != (int)e1.size() || !in_kernel(H, v) || !detected(G, v) || (int)e1.size() >= target ||
                        (int)e1.size() < dh) bad = true;
                    else target = (int)e1.size();
                }
                e_halves++;
                if (bad) { e_bad++; fails++; if (e_bad <= 10) fprintf(stderr, "CC_FAIL partE finder inst=%d half=%d d_h=%d\n", inst, half, dh); }
                else if (target == dh) e_reach++;
                if (min_span_weight(S, n) >= dh) continue;   // mutant 11 can only show where a trivial word is lighter than d_h
                e_mut_halves++;
                distcc::UbParams um = up;
                um.mutant = 11;
                distcc::UbFinder fm(to_rows(H, n), to_rows(G, n), to_rows(S, n), fseed, um);
                bool trivial = false;
                for (int it = 0, tg = n + 1; it < 50 && !trivial; it++) {
                    std::vector<int> e;
                    if (!fm.iterate(tg, e)) continue;
                    Mask v = 0;
                    for (int q : e) v |= 1u << q;
                    if (!detected(G, v)) trivial = true;
                    else tg = (int)e.size();
                }
                mut_runs[11]++;
                if (trivial) e_mut11_unit++;
            }
            for (int half = 0; half < 2; half++) {   // GH-146: the finder alone in collision mode
                const std::vector<Mask>& H = half ? Hx : Hz;
                const std::vector<Mask>& G = half ? Gz : Gx;
                const std::vector<Mask>& S = half ? Hz : Hx;
                const int dh = half ? dZ : dX;
                const uint64_t fseed = 5000 + (uint64_t)inst * 2 + (uint64_t)half;
                for (int ci = 0; ci < NI; ci++) {
                    const ICfg& ic = icfgs[ci];
                    distcc::UbParams up;
                    up.isd = ic.isd; up.isd_p = ic.p; up.isd_l = ic.l; up.isd_walk = ic.walk; up.isd_batch = ic.batch; up.isd_refresh = ic.refresh;
                    distcc::UbFinder f(to_rows(H, n), to_rows(G, n), to_rows(S, n), fseed + 77 * (uint64_t)ci, up);
                    distcc::UbFinder f2(to_rows(H, n), to_rows(G, n), to_rows(S, n), fseed + 77 * (uint64_t)ci, up);
                    int target = n + 1;
                    bool bad = false;
                    for (int it = 0; it < 300 && !bad; it++) {
                        std::vector<int> e1, e2;
                        const bool g1 = f.iterate(target, e1), g2 = f2.iterate(target, e2);
                        if (g1 != g2 || e1 != e2) { bad = true; i_nondet[ci]++; break; }
                        if (!g1) continue;
                        Mask v = 0;
                        for (int q : e1) v |= 1u << q;
                        if (popc(v) != (int)e1.size() || !in_kernel(H, v) || !detected(G, v) || (int)e1.size() >= target ||
                            (int)e1.size() < dh) bad = true;
                        else target = (int)e1.size();
                    }
                    i_halves[ci]++;
                    if (bad) { i_bad[ci]++; fails++; if (i_bad[ci] <= 5) fprintf(stderr, "CC_FAIL GH-146 finder %s inst=%d half=%d d_h=%d\n", ic.name, inst, half, dh); }
                    else if (target == dh) i_reach[ci]++;
                }
                if (min_span_weight(S, n) >= dh) continue;   // mutant 11 can only show where a trivial word is lighter than d_h
                distcc::UbParams um;
                um.isd = 1 + (inst & 1); um.isd_p = 2; um.mutant = 11;
                distcc::UbFinder fm(to_rows(H, n), to_rows(G, n), to_rows(S, n), fseed, um);
                bool trivial = false;
                for (int it = 0, tg = n + 1; it < 50 && !trivial; it++) {
                    std::vector<int> e;
                    if (!fm.iterate(tg, e)) continue;
                    Mask v = 0;
                    for (int q : e) v |= 1u << q;
                    if (!detected(G, v)) trivial = true;
                    else tg = (int)e.size();
                }
                i_mut_halves++;
                if (trivial) i_mut_trivial++;
            }
            {   // GH-146: the CC driver with the finder in collision mode (canonical configurations and mutants 11 / 12)
                const uint64_t sk = rnd(40);
                for (int cfg = 0; cfg < 5; cfg++) {
                    distcc::DriverOptions o;
                    o.ub_search = true;
                    o.ub.isd = (cfg & 1) ? 2 : 1; o.ub.isd_p = cfg == 2 ? 1 : 2;
                    if (cfg == 0) { o.ub_pre = 1.0; o.ub_cap = 0.01; }                                   // pre-pass
                    if (cfg == 1) { o.ub_share = 0.9; o.ub_poll_mask = 0; o.ub_skip_polls = sk; o.ub_hits = 0; o.ub_basis = false; }   // late start
                    if (cfg == 2) { o.ub_cap = 0.005; o.ub_only = true; }                               // finder only
                    if (cfg == 3) { o.ub_pre = 1.0; o.ub_cap = 0.005; o.mutant = 11; }
                    if (cfg == 4) { o.ub_pre = 1.0; o.ub_cap = 0.005; o.mutant = 12; }
                    RunOut r = run_driver(mHx, mHz, mGx, mGz, o, true, true);
                    if (cfg >= 3) {
                        if (!(min_span_weight(Hx, n) < dX && dX == d) && !(min_span_weight(Hz, n) < dZ && dZ == d)) continue;
                        if (cfg == 3) { i_m11_runs++; if (!run_ok(r, d)) i_m11_bad++; }
                        else { i_m12_runs++; if (!run_ok(r, d)) i_m12_bad++; if (r.ok && r.d != d) i_m12_wrong++; }
                        continue;
                    }
                    i_runs++;
                    bool ok;
                    if (o.ub_only) { ok = r.d == -1 && r.lbs.empty(); for (long long ub : r.ubs) if (ub < d) ok = false; }
                    else ok = run_ok(r, d);
                    if (!ok) { i_dbad++; fails++; if (i_dbad <= 10) fprintf(stderr, "CC_FAIL GH-146 driver inst=%d cfg=%d: d=%d got %d\n", inst, cfg, d, r.d); }
                }
            }
            struct UCfg { const char* name; double pre, cap, share; uint64_t mask, skip; bool dual, ubb, seq, only; uint64_t seed; int mutant; };
            const uint64_t sk1 = rnd(40), sk2 = rnd(150), sk3 = rnd(40);
            const UCfg ucfgs[] = {
                {"ub-pre", 1.0, 0.01, 0.1, 0x3FFF, 0, true, true, false, false, 0, 0},
                {"ub-share-poll", 0.0, -1, 0.9, 0, 0, true, true, false, false, 0, 0},
                {"ub-late-start", 0.0, -1, 0.9, 0, sk1, true, false, false, false, 0, 0},
                {"ub-late-start2", 0.0, -1, 0.9, 0, sk2, false, true, false, false, 1, 0},
                {"ub-dualoff-seed3", 1.0, 0.005, 0.5, 0, 0, false, true, false, false, 3, 0},
                {"ub-sequential", 0.0, 0.02, 0.9, 0, sk3, true, false, true, false, 1, 0},
                {"ub-no-ubbasis", 1.0, 0.005, 0.5, 0, 0, true, false, false, false, 2, 0},
                {"ub-only", 0.0, 0.005, 0.1, 0x3FFF, 0, true, true, false, true, 0, 0},
                {"mutant11", 1.0, 0.005, 0.1, 0x3FFF, 0, true, true, false, false, 0, 11},
                {"mutant12", 1.0, 0.005, 0.1, 0x3FFF, 0, true, true, false, false, 0, 12},
            };
            for (const UCfg& c : ucfgs) {
                distcc::DriverOptions o;
                o.ub_search = true; o.ub_pre = c.pre; o.ub_cap = c.cap; o.ub_share = c.share; o.ub_poll_mask = c.mask; o.ub_skip_polls = c.skip;
                if (c.skip) o.ub_hits = 0;   // late start: keep the finder at its full share
                o.dual = c.dual; o.ub_basis = c.ubb; o.sequential = c.seq; o.ub_only = c.only; o.seed = c.seed; o.mutant = c.mutant;
                o.trace_path = "build/test_cc_ub_trace.txt";
                remove(o.trace_path.c_str());
                RunOut r = run_driver(mHx, mHz, mGx, mGz, o, true, true);
                if (FILE* tf = fopen(o.trace_path.c_str(), "r")) {
                    char line[4096];
                    while (fgets(line, sizeof(line), tf)) if (strstr(line, " ABORTED ")) e_aborted++;
                    fclose(tf);
                }
                if (c.mutant) {
                    if (!(min_span_weight(Hx, n) < dX && dX == d) && !(min_span_weight(Hz, n) < dZ && dZ == d)) continue;
                    mut_runs[c.mutant]++;
                    if (!run_ok(r, d)) mut_bad[c.mutant]++;
                    if (c.mutant == 12 && r.ok && r.d != d) e_mut12_wrong++;
                    continue;
                }
                e_runs++;
                bool ok;
                if (c.only) {
                    ok = r.d == -1 && r.lbs.empty();
                    for (long long ub : r.ubs) if (ub < d) ok = false;
                } else ok = run_ok(r, d);
                if (!ok) {
                    e_dbad++; fails++;
                    if (e_dbad <= 10) fprintf(stderr, "CC_FAIL partE inst=%d n=%d cfg=%s: d=%d got %d\n", inst, n, c.name, d, r.d);
                }
            }
        }
        {   // Part D (GH-133): the MaxSAT split driver with -oddcap-skip off (main) and on, -no-card
            if (all_odd(Hz, n) || all_odd(Hx, n)) d_odd++;
            for (int oc = 0; oc < 2; oc++) {
                RunOut r = run_maxsat(mHx, mHz, mGx, mGz, oc == 1);
                d_runs++;
                if (!run_ok(r, d)) { d_bad++; fails++; if (d_bad <= 10) fprintf(stderr, "CC_FAIL partD inst=%d oddcap=%d: d=%d got %d\n", inst, oc, d, r.d); }
            }
        }
        {   // Part F (GH-144): -ub-pre on the MaxSAT split driver
            static const PreCfg fcfg[] = {
                {"pre1s", 1.0, 0, true, 0, DUALMODE_SHARE, true, 0, 0},
                {"iter1", 1.0, 1, true, 0, DUALMODE_SHARE, true, 0, 0},
                {"iter2-oddcap-off", 1.0, 2, false, 0, DUALMODE_SHARE, true, 0, 0},
                {"iter3-seed5", 1.0, 3, true, 5, DUALMODE_SHARE, true, 0, 0},
                {"iter1-dual-off", 1.0, 1, true, 0, DUALMODE_OFF, true, 0, 0},
                {"iter2-dual-skip", 1.0, 2, true, 0, DUALMODE_SKIP, true, 0, 0},
                {"iter1-nosymbreak-seed2", 1.0, 1, true, 2, DUALMODE_SHARE, false, 0, 0},
                {"pre1s-mto", 1.0, 0, true, 0, DUALMODE_SHARE, true, 3, 0},
                {"mutant1", 1.0, 0, true, 0, DUALMODE_SHARE, true, 0, 1},
                {"mutant2", 1.0, 0, true, 0, DUALMODE_SHARE, true, 0, 2},
            };
            for (const PreCfg& c : fcfg) {
                RunOut r = run_maxsat(mHx, mHz, mGx, mGz, c.oddcap, &c);
                bool ok = run_ok(r, d) && !r.ubs.empty();
                if (c.mutant == 2) { f_m2_runs++; if (r.ok && r.d != d) f_m2_wrong++; continue; }
                if (c.mutant == 1) { f_m1_runs++; if (!run_ok(r, d)) { f_m1_bad++; fails++; fprintf(stderr, "CC_FAIL partF mutant1 inst=%d: d=%d got %d\n", inst, d, r.d); } continue; }
                f_runs++;
                if (ok) { if (r.ubs[0] > d) f_above++; else f_exact++; }
                if (!ok) { f_bad++; fails++; if (f_bad <= 10) fprintf(stderr, "CC_FAIL partF inst=%d n=%d cfg=%s: d=%d got %d (ubs %zu)\n", inst, n, c.name, d, r.d, r.ubs.size()); }
            }
            for (int ic = 0; ic < 4; ic++) {   // GH-146: the pre-pass finder in collision mode, and mutants 1 / 2
                PreCfg c = {"isd", 1.0, ic == 1 ? (uint64_t)2 : 0, true, (uint64_t)(inst % 3), DUALMODE_SHARE, true, 0, ic >= 2 ? ic - 1 : 0};
                c.isd = 1 + (ic & 1); c.isd_p = 1 + ((inst >> 1) & 1);
                RunOut r = run_maxsat(mHx, mHz, mGx, mGz, true, &c);
                if (ic == 3) { f_isd_m2_runs++; if (r.ok && r.d != d) f_isd_m2_wrong++; continue; }
                const bool ok = run_ok(r, d) && !r.ubs.empty();
                if (ic == 2) { f_isd_m1_runs++; if (!run_ok(r, d)) { f_isd_m1_bad++; fails++; fprintf(stderr, "CC_FAIL GH-146 partF mutant1 inst=%d: d=%d got %d\n", inst, d, r.d); } continue; }
                f_isd_runs++;
                if (!ok) { f_isd_bad++; fails++; if (f_isd_bad <= 10) fprintf(stderr, "CC_FAIL GH-146 partF inst=%d n=%d cfg=%d: d=%d got %d\n", inst, n, ic, d, r.d); }
            }
        }
        {   // Part G (GH-148): -stab-overlap on the MaxSAT split driver
            if (ovl_removes(Hz, Gx, Hx, n, dX + 2) || ovl_removes(Hx, Gz, Hz, n, dZ + 2)) g_codes_removing++;
            static const PreCfg gcfg[] = {
                {"ovl", -1.0, 0, true, 0, DUALMODE_SHARE, true, 0, 0, 1, 0, 0},
                {"ovl-bin", -1.0, 0, true, 0, DUALMODE_SHARE, true, 0, 0, 1, 1, 0},
                {"ovl-seq", -1.0, 0, true, 0, DUALMODE_SHARE, true, 0, 0, 1, 2, 0},
                {"ovl-mto", -1.0, 0, true, 0, DUALMODE_SHARE, true, 3, 0, 1, 0, 0},
                {"ovl-seq-mto-seed3", -1.0, 0, true, 3, DUALMODE_SHARE, true, 3, 0, 1, 2, 0},
                {"ovl-dual-off", -1.0, 0, true, 0, DUALMODE_OFF, true, 0, 0, 1, 0, 0},
                {"ovl-dual-skip", -1.0, 0, true, 0, DUALMODE_SKIP, true, 0, 0, 1, 2, 0},
                {"ovl-nosymbreak", -1.0, 0, true, 0, DUALMODE_SHARE, false, 0, 0, 1, 0, 0},
                {"ovl-oddcap-off", -1.0, 0, false, 0, DUALMODE_SHARE, true, 0, 0, 1, 1, 0},
                {"ovl-pre-iter1", 1.0, 1, true, 0, DUALMODE_SHARE, true, 0, 0, 1, 0, 0},
                {"ovl-pre1s-seq", 1.0, 0, true, 2, DUALMODE_SHARE, true, 0, 0, 1, 2, 0},
                {"ovl-auto", -1.0, 0, true, 0, DUALMODE_SHARE, true, 0, 0, 1, 0, 0, 2.0},
                {"ovl-native", -1.0, 0, true, 0, DUALMODE_SHARE, true, 0, 0, 1, 3, 0},
                {"ovl-native-mto-seed4", -1.0, 0, true, 4, DUALMODE_SHARE, true, 3, 0, 1, 3, 0},
                {"ovl-native-dual-off-nosymbreak", -1.0, 0, false, 1, DUALMODE_OFF, false, 0, 0, 1, 3, 0},
                {"ovl-native-auto-pre-iter1", 1.0, 1, true, 0, DUALMODE_SHARE, true, 0, 0, 1, 3, 0, 2.0},
                {"ovl-native-pre1s-ratio1", 1.0, 0, true, 2, DUALMODE_SKIP, true, 0, 0, 1, 3, 0, 1.0},
                {"ovl-native-mutant1", -1.0, 0, true, 0, DUALMODE_SHARE, true, 0, 0, 1, 3, 1},
                {"ovl-native-mutant2", -1.0, 0, true, 0, DUALMODE_SHARE, true, 0, 0, 1, 3, 2},
                {"ovl-ratio1-pre-iter1-mto", 1.0, 1, true, 1, DUALMODE_SHARE, true, 3, 0, 1, 0, 0, 1.0},
                {"ovl-mutant1", -1.0, 0, true, 0, DUALMODE_SHARE, true, 0, 0, 1, 0, 1},
                {"ovl-mutant2", -1.0, 0, true, 0, DUALMODE_SHARE, true, 0, 0, 1, 0, 2},
            };
            for (const PreCfg& c : gcfg) {
                RunOut r = run_maxsat(mHx, mHz, mGx, mGz, c.oddcap, &c);
                if (c.ovl_mutant) {
                    g_m_runs[c.ovl_mutant]++;
                    if (!run_ok(r, d)) g_m_failed[c.ovl_mutant]++;
                    if (r.ok && r.d != d) { g_m_wrong[c.ovl_mutant]++; if (c.ovl_enc == 3) g_m_wrong_nat[c.ovl_mutant]++; }
                    continue;
                }
                g_runs++;
                if (!run_ok(r, d)) { g_bad++; fails++; if (g_bad <= 10) fprintf(stderr, "CC_FAIL partG inst=%d n=%d cfg=%s: d=%d got %d\n", inst, n, c.name, d, r.d); }
            }
        }
    }
    // (Part G per-code block is inside the Part B loop above)
    // Part E on rotated surface codes [[d^2, 1, d]] (d = 3, 4; also with X and Z swapped): weight-2 boundary stabilizers
    // are lighter than d, so mutants 11 and 12 must show here; the canonical driver with the finder must stay correct.
    long e_surf = 0, e_surf_bad = 0;
    for (int dd = 3; dd <= 4; dd++)
        for (int swap = 0; swap < 2; swap++) {
            const int n = dd * dd;
            auto qb = [dd](int a, int b) { return a * dd + b; };
            std::vector<Mask> SX, SZ;
            for (int a = -1; a <= dd - 1; a++)
                for (int b = -1; b <= dd - 1; b++) {
                    Mask v = 0;
                    for (int da = 0; da < 2; da++)
                        for (int db = 0; db < 2; db++) {
                            const int x = a + da, y = b + db;
                            if (x >= 0 && x < dd && y >= 0 && y < dd) v |= 1u << qb(x, y);
                        }
                    const bool xtype = ((a + b) & 1) == 0;
                    const bool interior = a >= 0 && b >= 0 && a <= dd - 2 && b <= dd - 2;
                    const bool tb = (a == -1 || a == dd - 1) && b >= 0 && b <= dd - 2;   // top/bottom: X type only
                    const bool lr = (b == -1 || b == dd - 1) && a >= 0 && a <= dd - 2;   // left/right: Z type only
                    if (interior) (xtype ? SX : SZ).push_back(v);
                    else if (tb && xtype) SX.push_back(v);
                    else if (lr && !xtype) SZ.push_back(v);
                }
            std::vector<Mask> Hx = swap ? SZ : SX, Hz = swap ? SX : SZ;
            bool comm = true;
            for (Mask x : Hx) for (Mask z : Hz) if (odd(x & z)) comm = false;
            std::vector<Mask> Gx = quotient_basis(Hx, Hz, n), Gz = quotient_basis(Hz, Hx, n);
            if (!comm || Gx.size() != 1 || Gz.size() != 1) { fprintf(stderr, "CC_FAIL generator: surface code d=%d invalid\n", dd); fails++; continue; }
            const int dX = half_opt(Hz, Gx, n), dZ = half_opt(Hx, Gz, n), d = std::min(dX, dZ);
            if (d != dd) { fprintf(stderr, "CC_FAIL generator: surface code d=%d has d=%d\n", dd, d); fails++; continue; }
            Matrix mHx = to_matrix(Hx, n), mHz = to_matrix(Hz, n), mGx = to_matrix(Gx, n), mGz = to_matrix(Gz, n);
            for (int half = 0; half < 2; half++) {   // finder alone: canonical correct, mutant 11 returns a trivial word
                const std::vector<Mask>& H = half ? Hx : Hz;
                const std::vector<Mask>& G = half ? Gz : Gx;
                const std::vector<Mask>& S = half ? Hz : Hx;
                for (int mi = 0; mi < 6; mi++) {   // GH-146: mi 2..5 = collision mode (Stern, Dumer)
                    const int mt = (mi & 1) ? 11 : 0;
                    distcc::UbParams up; up.mutant = mt; up.isd = 0;   // mi 0..1: GH-140 enumeration (-ub-isd=off)
                    if (mi >= 2) { up.isd = mi < 4 ? 1 : 2; up.isd_p = 2; }
                    distcc::UbFinder f(to_rows(H, n), to_rows(G, n), to_rows(S, n), 77 + (uint64_t)half, up);
                    bool trivial = false, bad = false;
                    for (int it = 0, tg = n + 1; it < 100; it++) {
                        std::vector<int> e;
                        if (!f.iterate(tg, e)) continue;
                        Mask v = 0;
                        for (int q : e) v |= 1u << q;
                        if (!detected(G, v)) trivial = true;
                        if (!in_kernel(H, v) || (int)e.size() >= tg) bad = true;
                        tg = (int)e.size();
                    }
                    if (mt == 0) { e_surf++; if (trivial || bad) { e_surf_bad++; fails++; } }
                    else if (mi >= 2) { i_mut_halves++; if (trivial) i_mut_trivial++; }
                    else { mut_runs[11]++; e_mut_halves++; if (trivial) e_mut11_unit++; }
                }
            }
            for (int cfg = 0; cfg < 8; cfg++) {   // canonical, mutant 11, mutant 12, canonical with a late start; 4-7: the same in collision mode (GH-146)
                distcc::DriverOptions o;
                o.ub_search = true; o.ub_pre = 1.0; o.ub_cap = 0.01;
                o.ub.isd = 0;   // cfg 0..3: GH-140 enumeration (-ub-isd=off)
                if (cfg >= 4) { o.ub.isd = 1 + (cfg & 1); o.ub.isd_p = 2; }
                const int cb = cfg & 3;
                if (cb == 1) o.mutant = 11;
                if (cb == 2) o.mutant = 12;
                if (cb == 3) { o.ub_cap = -1; o.ub_pre = 0; o.ub_share = 0.9; o.ub_poll_mask = 0; o.ub_skip_polls = 3; }
                RunOut r = run_driver(mHx, mHz, mGx, mGz, o, true, true);
                if (cfg >= 4 && cb == 2) { i_m12_runs++; if (!run_ok(r, d)) i_m12_bad++; if (r.ok && r.d != d) i_m12_wrong++; continue; }
                if (cfg >= 4 && cb == 1) { i_m11_runs++; if (!run_ok(r, d)) i_m11_bad++; continue; }
                if (cb == 0 || cb == 3) { e_surf++; if (!run_ok(r, d)) { e_surf_bad++; fails++; fprintf(stderr, "CC_FAIL partE surface d=%d swap=%d cfg=%d got %d\n", dd, swap, cfg, r.d); } }
                else {
                    mut_runs[o.mutant]++;
                    if (!run_ok(r, d)) mut_bad[o.mutant]++;
                    if (o.mutant == 12 && r.ok && r.d != d) e_mut12_wrong++;
                }
            }
        }
    printf("partE (rotated surface codes d = 3, 4, X/Z swapped): %ld canonical checks, %ld bad\n", e_surf, e_surf_bad);
    long f_surf = 0, f_surf_bad = 0, f_surf_m2 = 0, f_surf_m2_wrong = 0;
    long g_surf = 0, g_surf_bad = 0, g_surf_mwrong[3] = {0, 0, 0};
    for (int dd = 3; dd <= 5; dd++) {   // GH-144 Part F on rotated surface codes (weight-2 stabilizers lighter than d)
        const int n = dd * dd;
        if (n > 31) break;
        std::vector<Mask> SX, SZ;
        for (int a = -1; a <= dd - 1; a++)
            for (int b = -1; b <= dd - 1; b++) {
                Mask v = 0;
                for (int da = 0; da < 2; da++)
                    for (int db = 0; db < 2; db++) {
                        const int x = a + da, y = b + db;
                        if (x >= 0 && x < dd && y >= 0 && y < dd) v |= 1u << (x * dd + y);
                    }
                const bool xtype = ((a + b) & 1) == 0;
                const bool interior = a >= 0 && b >= 0 && a <= dd - 2 && b <= dd - 2;
                const bool tb = (a == -1 || a == dd - 1) && b >= 0 && b <= dd - 2;
                const bool lr = (b == -1 || b == dd - 1) && a >= 0 && a <= dd - 2;
                if (interior) (xtype ? SX : SZ).push_back(v);
                else if (tb && xtype) SX.push_back(v);
                else if (lr && !xtype) SZ.push_back(v);
            }
        std::vector<Mask> Gx = quotient_basis(SX, SZ, n), Gz = quotient_basis(SZ, SX, n);
        const int d = std::min(half_opt(SZ, Gx, n), half_opt(SX, Gz, n));
        if (d != dd || Gx.size() != 1) { fprintf(stderr, "CC_FAIL generator: partF surface d=%d\n", dd); fails++; continue; }
        Matrix mHx = to_matrix(SX, n), mHz = to_matrix(SZ, n), mGx = to_matrix(Gx, n), mGz = to_matrix(Gz, n);
        for (int mt = 0; mt <= 2; mt++)
            for (uint64_t sd = 0; sd < 6; sd++) {   // sd 3..5: collision mode (GH-146)
                PreCfg c = {"surface", 1.0, 0, true, sd % 3, DUALMODE_SHARE, true, 0, mt};
                if (sd >= 3) { c.isd = 1 + (int)(sd & 1); c.isd_p = 2; }
                RunOut r = run_maxsat(mHx, mHz, mGx, mGz, true, &c);
                if (mt < 2) { f_surf++; if (!run_ok(r, d)) { f_surf_bad++; fails++; fprintf(stderr, "CC_FAIL partF surface d=%d mutant=%d seed=%llu got %d\n", dd, mt, (unsigned long long)sd, r.d); } }
                else if (sd >= 3) { f_isd_m2_runs++; if (r.ok && r.d != d) f_isd_m2_wrong++; }
                else { f_surf_m2++; if (r.ok && r.d != d) f_surf_m2_wrong++; }
            }
        for (int mt = 0; mt <= 2; mt++)   // GH-148 Part G on the same surface codes
            for (int enc = 0; enc <= 3; enc++)
                for (uint64_t sd = 0; sd < 2; sd++) {
                    PreCfg c = {"surface-ovl", sd ? 1.0 : -1.0, sd ? 1u : 0u, true, sd, DUALMODE_SHARE, true, enc == 2 ? 3 : 0, 0, 1, enc, mt};
                    RunOut r = run_maxsat(mHx, mHz, mGx, mGz, true, &c);
                    if (mt == 0) { g_surf++; if (!run_ok(r, d)) { g_surf_bad++; fails++; fprintf(stderr, "CC_FAIL partG surface d=%d enc=%d seed=%llu got %d\n", dd, enc, (unsigned long long)sd, r.d); } }
                    else { g_m_runs[mt]++; if (!run_ok(r, d)) g_m_failed[mt]++; if (r.ok && r.d != d) { g_m_wrong[mt]++; g_surf_mwrong[mt]++; } }
                }
    }
    printf("partF (MaxSAT -ub-pre): %ld runs on %ld codes, %ld bad (first UB = d on %ld runs, > d on %ld runs); "
           "mutant 1 %ld runs, %ld bad; surface codes d = 3..5: %ld canonical/mutant-1 runs, %ld bad\n",
           f_runs, b_inst, f_bad, f_exact, f_above, f_m1_runs, f_m1_bad, f_surf, f_surf_bad);
    printf("partF mutant 2 (finder without detector check, words unverified): %ld/%ld code runs and %ld/%ld surface runs wrong\n",
           f_m2_wrong, f_m2_runs, f_surf_m2_wrong, f_surf_m2);
    if (f_above == 0) { fprintf(stderr, "CC_FAIL GH-144 seeded U0 > d never exercised\n"); fails++; }
    if (f_surf_m2_wrong == 0) { fprintf(stderr, "CC_FAIL GH-144 mutant 2 expectations not met\n"); fails++; }

    {   // GH-148 Part G (a): encoding check, and the summary of Part G
        long enc_runs = 0, enc_bad = 0;
        for (int w = 1; w <= 14; w++)
            for (int enc = 1; enc <= 3; enc++) {
                long long opt = ovl_encoding_opt(w, enc);
                enc_runs++;
                if (opt != w - w / 2) { enc_bad++; fails++; fprintf(stderr, "CC_FAIL partG encoding w=%d enc=%d: optimum %lld, want %d\n", w, enc, opt, w - w / 2); }
            }
        printf("partG (a) encodings (binomial, sequential counter, native propagator; w = 1..14): %ld checks, %ld bad\n", enc_runs, enc_bad);
        printf("partG (b) MaxSAT -stab-overlap: %ld runs on %ld codes (%ld codes where the rule removes an element of F of weight <= d + 2), %ld bad; "
               "surface codes d = 3..5: %ld runs, %ld bad\n", g_runs, b_inst, g_codes_removing, g_bad, g_surf, g_surf_bad);
        printf("partG mutant 1 (limit floor(|g|/2) - 1): %ld/%ld runs failed, %ld with a wrong RESULT d OPTIMAL (%ld on surface codes, %ld with the native propagator)\n",
               g_m_failed[1], g_m_runs[1], g_m_wrong[1], g_surf_mwrong[1], g_m_wrong_nat[1]);
        printf("partG mutant 2 (parity rows of the half as g, unverified): %ld/%ld runs failed, %ld with a wrong RESULT d OPTIMAL (%ld on surface codes)\n",
               g_m_failed[2], g_m_runs[2], g_m_wrong[2], g_surf_mwrong[2]);
        if (g_codes_removing == 0 || g_m_wrong[1] == 0 || g_m_wrong[2] == 0 || g_m_wrong_nat[1] == 0) { fprintf(stderr, "CC_FAIL GH-148 mutant/coverage expectations not met\n"); fails++; }
    }
    printf("partB: %ld CSS codes (%ld with a verified dual map, %ld with X-half orbits, %ld with dX != dZ, %ld with all-odd Hz), %ld driver runs, %ld bad, %ld RESULT -1\n",
           b_inst, b_dual, b_xorb, b_dxdz, b_odd, b_runs, b_bad, b_traps);
    printf("partD (MaxSAT split, -oddcap-skip off/on): %ld runs on %ld codes (%ld with an all-odd half), %ld bad\n", d_runs, b_inst, d_odd, d_bad);
    printf("partE (ub-search finder): %ld halves x 300 iterations, %ld bad, %ld nondeterministic, reached d_h on %ld/%ld halves\n",
           e_halves, e_bad, e_nondet, e_reach, e_halves);
    printf("partE (driver with ub-search): %ld runs, %ld bad, %ld levels abandoned (U <= w)\n", e_runs, e_dbad, e_aborted);

    for (int ci = 0; ci < NI; ci++) {
        printf("GH-146 finder %-20s: %ld halves x 300 iterations, %ld bad, %ld nondeterministic, reached d_h on %ld/%ld halves\n",
               icfgs[ci].name, i_halves[ci], i_bad[ci], i_nondet[ci], i_reach[ci], i_halves[ci]);
        if (i_halves[ci] > 0 && i_reach[ci] * 10 < i_halves[ci] * 9) { fprintf(stderr, "CC_FAIL GH-146 finder %s reaches d_h on < 90 %% of the halves\n", icfgs[ci].name); fails++; }
    }
    printf("GH-146 finder mutant 11 (collision mode, no detector check): trivial word returned on %ld/%ld halves\n", i_mut_trivial, i_mut_halves);
    printf("GH-146 CC driver in collision mode: %ld runs, %ld bad; mutant 11 %ld/%ld runs stopped or wrong; mutant 12 %ld/%ld failed, %ld with a wrong RESULT d OPTIMAL\n",
           i_runs, i_dbad, i_m11_bad, i_m11_runs, i_m12_bad, i_m12_runs, i_m12_wrong);
    printf("GH-146 MaxSAT pre-pass in collision mode: %ld runs, %ld bad; mutant 1 %ld runs, %ld bad; mutant 2 %ld/%ld runs wrong (codes + surface)\n",
           f_isd_runs, f_isd_bad, f_isd_m1_runs, f_isd_m1_bad, f_isd_m2_wrong, f_isd_m2_runs);
    if (i_mut_trivial == 0 || i_m11_bad == 0 || i_m12_wrong == 0 || f_isd_m2_wrong == 0) { fprintf(stderr, "CC_FAIL GH-146 mutant expectations not met\n"); fails++; }

    // ---------------- GH-152 Part G: half level with hidden symmetry (-cc-aut candidates) ----------------
    // Random halves as in Part A, closed under a planted shift, then RELABELED by a random permutation rho, so that the
    // planted map rho g rho^-1 is (in general) not in the GH-75 index family. Orbits come from find_half_symmetry with
    // the Tanner-graph generators of (H, G) (find_row_automorphisms) as extra candidates under the GF(2) checks. Every
    // generator must map each row class onto itself (independent set check, rows_map_onto); when the planted map
    // preserves both row sets and the finder reports a complete group, the planted orbits must lie inside the found
    // ones. Ladders for all 128 rule subsets x seeds 0..2 vs brute force. Mutant 13 at half level: the generators plus
    // the cyclic shift i -> i+1 mod n, kept without the GF(2) checks, must give wrong ladders on some instance.
    const int NG = argc > 3 ? atoi(argv[3]) : 300;
    const int NH = argc > 4 ? atoi(argv[4]) : 150;
    long g_inst = 0, g_coarser = 0, aut_g_runs = 0, aut_g_bad = 0, g_badgen = 0, g_inv = 0, g_inv_complete = 0, g_miss = 0;
    long g_m13_runs = 0, g_m13_bad = 0, g_gens = 0, g_complete = 0;
    const std::vector<int> idmap = {0, 1}, swapmap = {1, 0};
    for (int inst = 0; inst < NG; inst++) {
        const int n = 4 + (int)rnd(15);
        std::vector<std::vector<int> > gens;
        {
            std::vector<int> divs;
            for (int L = 2; L <= n; L++) if (n % L == 0) divs.push_back(L);
            const int L = divs[rnd((unsigned)divs.size())];
            gens.push_back(rnd(2) ? stridedshift(n, L) : blockshift(n, L));
        }
        std::vector<Mask> h0, g0;
        const int nh = 1 + (int)rnd((unsigned)(n / 2 + 2)), ng = 1 + (int)rnd(3);
        for (int k = 0; k < nh; k++) h0.push_back(rand_vec(n, 2, 5));
        for (int k = 0; k < ng; k++) g0.push_back(rand_vec(n, 1, n));
        std::vector<Mask> H = closure(h0, gens, 64), G = closure(g0, gens, 32);
        if (G.empty()) G.push_back(1u << rnd(n));
        if (inst % 3 == 0) make_columns_odd(H, n);
        std::vector<int> rho(n);
        for (int i = 0; i < n; i++) rho[i] = i;
        for (int i = n - 1; i > 0; i--) std::swap(rho[i], rho[rnd((unsigned)(i + 1))]);
        for (Mask& v : H) v = perm_apply(rho, v);
        for (Mask& v : G) v = perm_apply(rho, v);
        std::vector<int> plant(n);
        for (int q = 0; q < n; q++) plant[rho[q]] = rho[gens[0][q]];
        const int dh = half_opt(H, G, n);
        std::vector<Mask> K;
        {
            Span sp;
            for (Mask v = 1; v < (1u << n); v++) {
                if (!in_kernel(H, v) || detected(G, v)) continue;
                if (inst % 2 == 0) { if (sp.add(v)) K.push_back(v); }
                else if (popc(v) <= 6 && K.size() < 60) K.push_back(v);
            }
        }
        const distcc::SparseRows Hr = to_rows(H, n), Gr = to_rows(G, n);
        const std::vector<const distcc::SparseRows*> cls = {&Hr, &Gr};
        const distcc::AutResult ar = distcc::find_row_automorphisms(n, cls, false);
        g_inst++; g_gens += (long)ar.gens.size(); if (ar.complete) g_complete++;
        for (const auto& p : ar.gens)
            if (!distcc::rows_map_onto(n, cls, p, idmap)) {
                g_badgen++; fails++;
                if (g_badgen <= 5) fprintf(stderr, "CC_FAIL GH-152 partG inst=%d: a generator does not preserve the row classes\n", inst);
            }
        if (distcc::rows_map_onto(n, cls, plant, idmap)) {
            g_inv++;
            if (ar.complete) {
                g_inv_complete++;
                std::vector<int> par(n);
                for (int q = 0; q < n; q++) par[q] = q;
                for (const auto& p : ar.gens)
                    for (int q = 0; q < n; q++) { int a = uf_find(par, q), b = uf_find(par, p[q]); if (a != b) par[std::max(a, b)] = std::min(a, b); }
                for (int q = 0; q < n; q++)
                    if (uf_find(par, q) != uf_find(par, plant[q])) {
                        g_miss++; fails++;
                        fprintf(stderr, "CC_FAIL GH-152 partG inst=%d: complete group misses the planted automorphism\n", inst);
                        break;
                    }
            }
        }
        const Matrix mH = to_matrix(H, n), mG = to_matrix(G, n);
        const HalfSymInfo fam = find_half_symmetry(mH, mG);
        const HalfSymInfo ext = find_half_symmetry(mH, mG, &ar.gens);
        if (ext.reps.size() < fam.reps.size()) g_coarser++;
        const std::vector<int> orb = (int)ext.reps.size() < n ? ext.orbit_of : std::vector<int>();
        for (int rm = 0; rm < RM_NSUB; rm++)
            for (uint64_t seed = 0; seed < 3; seed++) {
                std::string why;
                aut_g_runs++;
                if (!ladder_ok(H, G, K, n, dh, orb, rm, seed, 0, NULL, why)) {
                    aut_g_bad++; fails++;
                    if (aut_g_bad <= 10) fprintf(stderr, "CC_FAIL GH-152 partG inst=%d n=%d rules=%s seed=%llu: %s\n", inst, n, rules_name(rm),
                                             (unsigned long long)seed, why.c_str());
                }
            }
        if (n >= 2) {   // mutant 13 at half level
            std::vector<std::vector<int> > bad(ar.gens);
            std::vector<int> t(n);
            for (int i = 0; i < n; i++) t[i] = (i + 1) % n;
            bad.push_back(t);
            const HalfSymInfo m = find_half_symmetry(mH, mG, &bad, true);
            const std::vector<int> orbm = (int)m.reps.size() < n ? m.orbit_of : std::vector<int>();
            for (int rm = 0; rm < RM_NSUB; rm++) {
                if (!(rm & 4)) continue;
                std::string why;
                g_m13_runs++;
                if (!ladder_ok(H, G, K, n, dh, orbm, rm, 0, 0, NULL, why)) g_m13_bad++;
            }
        }
    }
    printf("GH-152 partG: %ld relabeled half instances, %ld Tanner generators (%ld complete groups), %ld instances with coarser orbits than the GH-75 family, "
           "%ld ladder runs (128 rule subsets x 3 seeds), %ld bad; generators violating the row classes %ld; planted map preserved the row sets on %ld "
           "(%ld with a complete group), missed %ld\n", g_inst, g_gens, g_complete, g_coarser, aut_g_runs, aut_g_bad, g_badgen, g_inv, g_inv_complete, g_miss);
    if (g_coarser == 0) { fprintf(stderr, "CC_FAIL GH-152 partG: no instance with a hidden symmetry recovered\n"); fails++; }

    // ---------------- GH-152 Part H: driver with -cc-aut=on ----------------
    // Codes: (a) relabeled hypergraph products HGP(M, M) of a random 2x2 .. 3x3 matrix M (n = 8, 13, 18): the transpose
    // map exchanges Hx and Hz, hidden by the relabeling; (b) relabeled Part-B-style random CSS codes with a planted
    // shift. Configurations with -cc-aut=on over rule sets, seeds, dual off, index seeds; RESULT d OPTIMAL = enumeration,
    // LBs monotone <= d <= UBs. Mutants 13 (generators and the cyclic shift i -> i+1 mod n kept without the GF(2) checks) and
    // 14 (swap map, or the identity, used as dual map without the check) must give wrong answers or stop the run.
    long h_inst = 0, h_hgp = 0, h_newdual = 0, h_coarser = 0, h_runs = 0, h_bad = 0, h_dxdz = 0;
    long h_m13_runs = 0, h_m13_bad = 0, h_m14_runs = 0, h_m14_bad = 0, h_badswap = 0;
    for (int inst = 0; inst < NH; inst++) {
        const bool hgp = inst % 3 != 2;
        int n = 0;
        std::vector<Mask> Hx, Hz;
        if (hgp) {
            const int a = 2 + (int)rnd(2), b = 2 + (int)rnd(2);
            int M[3][3];
            for (int i = 0; i < a; i++) for (int j = 0; j < b; j++) M[i][j] = (int)rnd(2);
            n = b * b + a * a;
            for (int k = 0; k < a; k++)
                for (int j = 0; j < b; j++) {   // Hx row (k, j)
                    Mask v = 0;
                    for (int i = 0; i < b; i++) if (M[k][i]) v |= 1u << (i * b + j);
                    for (int l = 0; l < a; l++) if (M[l][j]) v |= 1u << (b * b + k * a + l);
                    if (v) Hx.push_back(v);
                }
            for (int i = 0; i < b; i++)
                for (int l = 0; l < a; l++) {   // Hz row (i, l)
                    Mask v = 0;
                    for (int j = 0; j < b; j++) if (M[l][j]) v |= 1u << (i * b + j);
                    for (int k = 0; k < a; k++) if (M[k][i]) v |= 1u << (b * b + k * a + l);
                    if (v) Hz.push_back(v);
                }
        } else {
            n = 6 + (int)rnd(11);
            std::vector<std::vector<int> > gens;
            std::vector<int> divs;
            for (int L = 2; L <= n; L++) if (n % L == 0) divs.push_back(L);
            const int L = divs[rnd((unsigned)divs.size())];
            gens.push_back(rnd(2) ? stridedshift(n, L) : blockshift(n, L));
            std::vector<Mask> z0;
            const int mz = 1 + (int)rnd((unsigned)(n / 3 + 1));
            for (int k = 0; k < mz; k++) z0.push_back(rand_vec(n, 2, 5));
            Hz = closure(z0, gens, 48);
            std::vector<Mask> ker;
            for (Mask v = 1; v < (1u << n); v++) if (popc(v) <= 6 && in_kernel(Hz, v)) ker.push_back(v);
            const int mx = 1 + (int)rnd((unsigned)(n / 3 + 1));
            std::vector<Mask> x0;
            for (int k = 0; k < mx && !ker.empty(); k++) x0.push_back(ker[rnd((unsigned)ker.size())]);
            Hx = closure(x0, gens, 48);
            std::vector<Mask> keep;
            for (Mask v : Hx) if (in_kernel(Hz, v)) keep.push_back(v);
            Hx = keep;
        }
        if (Hx.empty() || Hz.empty()) { inst--; continue; }
        std::vector<int> rho(n);
        for (int i = 0; i < n; i++) rho[i] = i;
        for (int i = n - 1; i > 0; i--) std::swap(rho[i], rho[rnd((unsigned)(i + 1))]);
        for (Mask& v : Hx) v = perm_apply(rho, v);
        for (Mask& v : Hz) v = perm_apply(rho, v);
        std::vector<Mask> Gx = quotient_basis(Hx, Hz, n), Gz = quotient_basis(Hz, Hx, n);
        if (Gx.empty() || Gz.empty() || Gx.size() != Gz.size()) { inst--; continue; }
        const int dX = half_opt(Hz, Gx, n), dZ = half_opt(Hx, Gz, n);
        const int d = std::min(dX, dZ);
        if (dX != dZ) h_dxdz++;
        h_inst++; if (hgp) h_hgp++;
        const Matrix mHx = to_matrix(Hx, n), mHz = to_matrix(Hz, n), mGx = to_matrix(Gx, n), mGz = to_matrix(Gz, n);
        {   // diagnostics: new dual maps and coarser orbits that -cc-aut brings on this code
            const distcc::SparseRows rx = to_rows(Hx, n), rz = to_rows(Hz, n);
            const std::vector<const distcc::SparseRows*> cls = {&rx, &rz};
            const distcc::AutResult ar = distcc::find_row_automorphisms(n, cls, true);
            if (!ar.swap.empty() && !distcc::rows_map_onto(n, cls, ar.swap, swapmap)) {
                h_badswap++; fails++; fprintf(stderr, "CC_FAIL GH-152 partH inst=%d: swap map does not exchange the row classes\n", inst);
            }
            const DualMapInfo fdm = find_dual_maps(mHx, mHz, mGx, mGz, false);
            if (fdm.maps.empty() && !ar.swap.empty() && verify_dual_perm(mHx, mHz, mGx, mGz, ar.swap, fdm))
                h_newdual++;
            if (find_half_symmetry(mHz, mGx, &ar.gens).reps.size() < find_half_symmetry(mHz, mGx).reps.size()) h_coarser++;
        }
        struct HCfg { const char* name; int rmask; bool dual; bool ubb; uint64_t seed; bool symbreak; int mutant; };
        const HCfg cfgs[] = {
            {"aut", RM_DEF, true, false, 0, true, 0}, {"aut-seed1", RM_NEW, true, false, 1, true, 0}, {"aut-charge-seed2", RM_DEF, false, false, 2, true, 0},
            {"aut-dual-off", RM_NEW, false, false, 0, true, 0}, {"aut-no-symbreak", RM_NEW, true, false, 0, false, 0},
            {"aut-oldrules", RM_OLD, true, false, 0, true, 0}, {"aut-133-seed2", RM_133, false, true, 2, true, 0},
            {"aut-mrv", RM_ALL, true, false, 0, true, 0}, {"aut-overlap-only", 64, true, false, 0, true, 0},
            {"aut-orbf-only", 4, true, true, 3, true, 0}, {"aut-excl-orbf", 1 | 4, false, false, 0, true, 0},
            {"mutant13", RM_NEW, false, false, 0, true, 13}, {"mutant13-orbf", 1 | 4, false, false, 0, true, 13},
            {"mutant14", RM_NEW, true, false, 0, true, 14},
        };
        for (const HCfg& c : cfgs) {
            distcc::DriverOptions o;
            o.ub_search = false;
            o.aut = true;
            o.rules = rules_of(c.rmask);
            o.dual = c.dual; o.ub_basis = c.ubb; o.seed = c.seed; o.mutant = c.mutant;
            RunOut r = run_driver(mHx, mHz, mGx, mGz, o, c.symbreak, true);
            const bool ok = run_ok(r, d);
            if (c.mutant == 13) { h_m13_runs++; if (!ok) h_m13_bad++; continue; }
            if (c.mutant == 14) { h_m14_runs++; if (!ok) h_m14_bad++; continue; }
            h_runs++;
            if (!ok) {
                h_bad++; fails++;
                if (h_bad <= 10) fprintf(stderr, "CC_FAIL GH-152 partH inst=%d n=%d cfg=%s: d=%d (dX %d dZ %d) got %d\n", inst, n, c.name, d, dX, dZ, r.d);
            }
        }
    }
    printf("GH-152 partH: %ld relabeled codes (%ld hypergraph products, %ld with dX != dZ), %ld gain a verified dual map only through -cc-aut, "
           "%ld gain coarser X-half orbits; %ld driver runs with -cc-aut=on, %ld bad; swap maps violating the classes %ld\n",
           h_inst, h_hgp, h_dxdz, h_newdual, h_coarser, h_runs, h_bad, h_badswap);
    printf("mutant 13 (Tanner candidates and the cyclic shift i -> i+1 mod n kept without the GF(2) checks): half level %ld/%ld ladders wrong; driver %ld/%ld runs wrong or stopped\n",
           g_m13_bad, g_m13_runs, h_m13_bad, h_m13_runs);
    printf("mutant 14 (Tanner swap map, or the identity, used as dual map without the GF(2) check): driver %ld/%ld runs wrong or stopped\n",
           h_m14_bad, h_m14_runs);
    if (h_newdual == 0 || h_coarser == 0) { fprintf(stderr, "CC_FAIL GH-152 partH: the new dual-map / orbit paths were not exercised\n"); fails++; }
    if (g_m13_bad == 0 || h_m13_bad == 0 || h_m14_bad == 0) { fprintf(stderr, "CC_FAIL GH-152 mutant expectations not met\n"); fails++; }

    // ---------------- Part C: mutants ----------------
    printf("mutant 1 (forbidden set not restored): %ld/%ld half ladders wrong\n", mut_bad[1], mut_runs[1]);
    printf("mutant 2 (packing prune >=): %ld/%ld half ladders wrong\n", mut_bad[2], mut_runs[2]);
    printf("mutant 3 (orbit seed rule off by one, instances with orbits): %ld/%ld half ladders wrong\n", mut_bad[3], mut_runs[3]);
    printf("mutant 4 (stop rule without other half's lb, forces sequential): schedule requested %ld/%ld runs wrong; default options %ld/%ld wrong\n",
           b_seqbad4, b_seq, b_lock4bad, b_lock4);
    printf("mutant 5 (parity rule forced on halves with an even column weight): %ld/%ld half ladders wrong\n", mut_bad[5], mut_runs[5]);
    printf("mutant 6 (leaf budget off by one): %ld/%ld half ladders wrong\n", mut_bad[6], mut_runs[6]);
    printf("mutant 7 (leaf closure without the detector check): %ld/%ld half ladders wrong\n", mut_bad[7], mut_runs[7]);
    printf("mutant 8 (overlap limit off by one): %ld/%ld half ladders wrong\n", mut_bad[8], mut_runs[8]);
    printf("mutant 9 (overlap with the parity checks H as K): %ld/%ld half ladders wrong\n", mut_bad[9], mut_runs[9]);
    printf("mutant 10 (overlap even-|g| tie cut): %ld/%ld half ladders wrong\n", mut_bad[10], mut_runs[10]);
    printf("mutant 11 (ub-search without the detector check; halves/codes where a trivial word is lighter than d): finder returned a trivial word on %ld/%ld halves; driver %ld/%ld runs stopped or wrong\n",
           e_mut11_unit, e_mut_halves, mut_bad[11], mut_runs[11] - e_mut_halves);
    printf("mutant 12 (mutant 11 + words reported without verification): %ld/%ld driver runs failed, %ld of them with a wrong RESULT d OPTIMAL\n",
           mut_bad[12], mut_runs[12], e_mut12_wrong);
    if (e_mut11_unit == 0 || mut_bad[11] == 0 || mut_bad[12] == 0 || e_mut12_wrong == 0) { fprintf(stderr, "CC_FAIL GH-140 mutant expectations not met\n"); fails++; }
    if (e_aborted == 0) { fprintf(stderr, "CC_FAIL GH-140 abort path never exercised\n"); fails++; }
    bool mut_ok = mut_bad[1] > 0 && mut_bad[2] > 0 && mut_bad[3] > 0 && b_seqbad4 > 0 && b_lock4bad > 0 &&
                  mut_bad[5] > 0 && mut_bad[6] > 0 && mut_bad[7] > 0 && mut_bad[8] > 0 && mut_bad[9] > 0 && mut_bad[10] > 0;
    if (!mut_ok) { fprintf(stderr, "CC_FAIL mutant expectations not met\n"); fails++; }
    printf(fails ? "CC_ENGINE_TESTS FAIL (%d)\n" : "CC_ENGINE_TESTS PASS\n", fails);
    return fails ? 1 : 0;
}
