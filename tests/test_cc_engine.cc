// GH-124 S0 test: the CC level-search engine (src/cc) against exhaustive enumeration.
// src/core/distqldpc.cc is included verbatim (its main() renamed) so that the production orbit detection
// (find_half_symmetry, GH-85), dual-map detection (find_dual_maps, GH-87/GH-107) and the production CC wrapper
// (min_distance_css_cc) are the ones under test; driver runs happen in a forked child and report through the
// production bounds pipe protocol (TRY / LB / UB / RESULT).
//
// Part A (half level): random halves (H, G) with n = 4..18 (half X convention: F = {v : H v = 0, G v != 0}),
//   half of them closed under a planted GH-75 shift so that find_half_symmetry verifies nontrivial orbits.
//   Every subset of {excl, pack, orbf, mrv} and relabeling seeds 0..2: the level ladder 1..d_h must give EMPTY
//   below d_h and FOUND at d_h with a witness of weight d_h in F (no element: EMPTY at every level <= n).
// Part B (driver): random consistent CSS codes (Hx Hz^T = 0, Gx/Gz computed as quotient bases, n = 6..16),
//   planted shifts and self-dual codes (Hx = Hz, so the identity XZ-dual map is verified). Configurations:
//   default, -cc-dual=off, -ub-basis, -cc-seed 1/2, -cc-rules none / mrv. Each run: RESULT d OPTIMAL with
//   d = min(dX, dZ) from enumeration (dX: Hz x = 0, x not in rs Hx), every LB <= d <= every UB, LBs monotone.
// Part C (mutants, -cc-mutant=K): every mutant must change an answer. 1 (forbidden set not restored), 2 (packing
//   prune >=) and 3 (orbit seed rule off by one: O_1..O_i forbidden while r_i is searched, on instances with
//   verified orbits) must produce wrong half-level verdicts; 4 (stop rule without the other half's lower bound,
//   which forces the sequential schedule) must produce wrong driver answers, both when the schedule is requested
//   (-cc-schedule=sequential) and when it is not (default options, as the binary runs -cc-mutant=4). The
//   canonical driver must stay correct under the sequential schedule, where the other-half check is load-bearing.
#define main distqldpc_main_unused
#include "../src/core/distqldpc.cc"
#undef main

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

static const char* rules_name(int mask) {
    static char buf[64];
    distcc::Rules r; r.excl = mask & 1; r.pack = mask & 2; r.orbf = mask & 4; r.mrv = mask & 8;
    snprintf(buf, sizeof(buf), "%s", distcc::rules_string(r).c_str());
    return buf;
}

// ladder 1..dh for one configuration; returns true if every verdict matches; nodes summed into *nodes
static bool ladder_ok(const std::vector<Mask>& H, const std::vector<Mask>& G, int n, int dh, const std::vector<int>& orb,
                      int rmask, uint64_t seed, int mutant, uint64_t* nodes, std::string& why) {
    distcc::Rules r; r.excl = rmask & 1; r.pack = rmask & 2; r.orbf = rmask & 4; r.mrv = rmask & 8;
    distcc::HalfSearch hs(to_rows(H, n), to_rows(G, n), orb, r, seed, mutant);
    const int top = dh < 0 ? n : dh;
    char buf[160];
    for (int w = 1; w <= top; w++) {
        distcc::LevelResult res = hs.run_level(w);
        if (nodes) *nodes += res.nodes;
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

static bool run_ok(const RunOut& r, int d) {
    if (!r.ok || r.d != d) return false;
    long long prev = 0;
    for (long long lb : r.lbs) { if (lb > d || lb < prev) return false; prev = lb; }
    for (long long ub : r.ubs) if (ub < d) return false;
    return true;
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

int main(int argc, char** argv) {
    const int NA = argc > 1 ? atoi(argv[1]) : 300;   // part A instances
    const int NB = argc > 2 ? atoi(argv[2]) : 200;   // part B instances
    int fails = 0;

    // ---------------- Part A: half level ----------------
    long a_inst = 0, a_orb = 0, a_none = 0, a_runs = 0, a_bad = 0;
    long mut_bad[5] = {0, 0, 0, 0, 0}, mut_runs[5] = {0, 0, 0, 0, 0};
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
        const int dh = half_opt(H, G, n);
        std::vector<int> orb = orbits_of(H, G, n);
        a_inst++; if (!orb.empty()) a_orb++; if (dh < 0) a_none++;
        for (int rm = 0; rm < 16; rm++)
            for (uint64_t seed = 0; seed < 3; seed++) {
                std::string why;
                a_runs++;
                if (!ladder_ok(H, G, n, dh, orb, rm, seed, 0, NULL, why)) {
                    a_bad++; fails++;
                    if (a_bad <= 10) fprintf(stderr, "CC_FAIL partA inst=%d n=%d rules=%s seed=%llu: %s\n", inst, n, rules_name(rm),
                                             (unsigned long long)seed, why.c_str());
                }
            }
        // mutants 1-3 on the configurations where they apply
        for (int mt = 1; mt <= 3; mt++)
            for (int rm = 0; rm < 16; rm++) {
                if (mt == 1 && !(rm & 1)) continue;
                if (mt == 2 && !(rm & 2)) continue;
                if (mt == 3 && (!(rm & 4) || orb.empty())) continue;
                std::string why;
                mut_runs[mt]++;
                if (!ladder_ok(H, G, n, dh, orb, rm, 0, mt, NULL, why)) mut_bad[mt]++;
            }
    }
    printf("partA: %ld half instances (%ld with verified orbits, %ld without any nontrivial element), %ld ladder runs over 16 rule subsets x 3 seeds, %ld bad\n",
           a_inst, a_orb, a_none, a_runs, a_bad);

    // ---------------- Part B: driver through the forked pipe ----------------
    long b_inst = 0, b_runs = 0, b_bad = 0, b_dual = 0, b_xorb = 0, b_dxdz = 0, b_seqbad4 = 0, b_seq = 0, b_lock4bad = 0, b_lock4 = 0;
    long b_traps = 0;
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
        Matrix mHx = to_matrix(Hx, n), mHz = to_matrix(Hz, n), mGx = to_matrix(Gx, n), mGz = to_matrix(Gz, n);
        DualMapInfo dm = find_dual_maps(mHx, mHz, mGx, mGz, false);
        if (!dm.maps.empty()) b_dual++;
        if (!orbits_of(Hz, Gx, n).empty()) b_xorb++;
        b_inst++;
        struct Cfg { const char* name; int rmask; bool dual; bool ubb; uint64_t seed; bool symbreak; };
        const Cfg cfgs[] = {
            {"default", 7, true, false, 0, true}, {"dual-off", 7, false, false, 0, true}, {"ub-basis", 7, true, true, 0, true},
            {"seed1", 7, true, false, 1, true}, {"seed2", 7, false, true, 2, true}, {"none", 0, true, false, 0, true},
            {"mrv", 15, true, false, 0, true}, {"no-symbreak", 7, true, false, 0, false},
        };
        for (const Cfg& c : cfgs) {
            distcc::DriverOptions o;
            o.rules.excl = c.rmask & 1; o.rules.pack = c.rmask & 2; o.rules.orbf = c.rmask & 4; o.rules.mrv = c.rmask & 8;
            o.dual = c.dual; o.ub_basis = c.ubb; o.seed = c.seed;
            RunOut r = run_driver(mHx, mHz, mGx, mGz, o, c.symbreak, true);
            b_runs++;
            if (r.d == -1) b_traps++;
            if (!run_ok(r, d)) {
                b_bad++; fails++;
                if (b_bad <= 10) fprintf(stderr, "CC_FAIL partB inst=%d n=%d cfg=%s: d=%d (dX %d dZ %d) got %d\n", inst, n, c.name, d, dX, dZ, r.d);
            }
        }
        {   // test-only sequential schedule: canonical must pass; mutant 4 (forces sequential) must be caught when dZ < dX
            distcc::DriverOptions o; o.sequential = true;
            RunOut r = run_driver(mHx, mHz, mGx, mGz, o, true, false);
            b_runs++; b_seq++;
            if (!run_ok(r, d)) { b_bad++; fails++; fprintf(stderr, "CC_FAIL partB sequential inst=%d d=%d got %d\n", inst, d, r.d); }
            o.mutant = 4;
            mut_runs[4]++;
            RunOut r4 = run_driver(mHx, mHz, mGx, mGz, o, true, false);
            if (!run_ok(r4, d)) { mut_bad[4]++; b_seqbad4++; }
            distcc::DriverOptions l; l.mutant = 4;   // schedule not requested: mutant 4 must switch to sequential itself
            RunOut l4 = run_driver(mHx, mHz, mGx, mGz, l, true, true);
            b_lock4++; mut_runs[4]++;
            if (!run_ok(l4, d)) { mut_bad[4]++; b_lock4bad++; }
        }
    }
    printf("partB: %ld CSS codes (%ld with a verified dual map, %ld with X-half orbits, %ld with dX != dZ), %ld driver runs, %ld bad, %ld RESULT -1\n",
           b_inst, b_dual, b_xorb, b_dxdz, b_runs, b_bad, b_traps);

    // ---------------- Part C: mutants ----------------
    printf("mutant 1 (forbidden set not restored): %ld/%ld half ladders wrong\n", mut_bad[1], mut_runs[1]);
    printf("mutant 2 (packing prune >=): %ld/%ld half ladders wrong\n", mut_bad[2], mut_runs[2]);
    printf("mutant 3 (orbit seed rule off by one, instances with orbits): %ld/%ld half ladders wrong\n", mut_bad[3], mut_runs[3]);
    printf("mutant 4 (stop rule without other half's lb, forces sequential): schedule requested %ld/%ld runs wrong; default options %ld/%ld wrong\n",
           b_seqbad4, b_seq, b_lock4bad, b_lock4);
    bool mut_ok = mut_bad[1] > 0 && mut_bad[2] > 0 && mut_bad[3] > 0 && b_seqbad4 > 0 && b_lock4bad > 0;
    if (!mut_ok) { fprintf(stderr, "CC_FAIL mutant expectations not met\n"); fails++; }
    printf(fails ? "CC_ENGINE_TESTS FAIL (%d)\n" : "CC_ENGINE_TESTS PASS\n", fails);
    return fails ? 1 : 0;
}
