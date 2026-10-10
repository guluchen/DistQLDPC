// GH-102 test (port of GH-94's tests/test_incremental_dualskip.cc to the dual-map bound-sharing path): the
// production CSS-split driver (min_distance_css_interleaved) of GH-102 (GH-76 persistent half solvers + GH-85
// per-half orbit clauses + GH-94's verified dual-map detection, both halves kept, proven lower bounds shared),
// end to end, against exhaustive enumeration of BOTH halves without any symmetry clause.
// src/core/distqldpc.cc is included verbatim (its main() renamed); each driver run happens in a forked child
// (as in production, solve_in_child_fork) and reports through the production bounds pipe protocol; the child's
// stdout (engine log, verb=1) goes to a temporary file that is scanned for the GH-102 driver lines.
// Instances (n = 4..18; half X: Hz v = 0, Gx v != 0; half Z: Hx v = 0, Gz v != 0; d = min(dX, dZ)), unchanged
// from GH-94:
//  * planted dual: Hz, Gx random (optionally closed under a planted GH-75 shift group, so the halves also get
//    orbit clauses), pi drawn from the production candidate_family(n, true) (identity included), Hx = row-
//    operations on pi(Hz) (+ optional redundant row), Gz = pi(Gx) plus row operations with Hx / Gz rows. Then
//    pi(rs Hz) = rs Hx and pi(rs[Hz;Gx]) = rs[Hx;Gz]: dX = dZ (checked by enumeration) and detection must
//    verify a dual map;
//  * planted dual with a random (non-family) pi: dX = dZ, detection may or may not find a map;
//  * near miss: planted dual with one bit of Hx or Gz flipped (dX != dZ possible; detection must not lie);
//  * independent halves (control).
// Every instance runs four configurations: sharing variant A (symbreak on; production default), variant B
// (-dualshare-b), variant A with symbreak off, and -no-dualshare (= GH-89). Checks per run: RESULT d OPTIMAL with
// d = min(dX, dZ) from enumeration; every emitted LB <= d <= every emitted UB; the driver reports sharing iff the
// production detection verifies a map. Whenever detection verifies a map, enumeration must give dX = dZ.
// Engine output goes to a temporary file; the verdict goes to stderr.
#define main distqldpc_main_unused
#include "../src/core/distqldpc.cc"
#undef main

#include <set>
#include <sys/wait.h>

static unsigned long long rng_state = 0x9e3779b97f4a7c15ULL;
static unsigned rnd(unsigned m) {
    rng_state ^= rng_state << 13; rng_state ^= rng_state >> 7; rng_state ^= rng_state << 17;
    return (unsigned)(rng_state % m);
}
static int fails = 0;
static void need(bool x, const char* why, int inst, int cfg) {
    if (!x) { fprintf(stderr, "GH102_DUALSHARE_FAIL inst=%d cfg=%d %s\n", inst, cfg, why); fails++; }
}

typedef unsigned Mask;
static Mask perm_apply(const std::vector<int>& p, Mask v) {
    Mask w = 0;
    for (size_t i = 0; i < p.size(); i++) if ((v >> i) & 1) w |= 1u << p[i];
    return w;
}
static Matrix to_matrix(const std::vector<Mask>& rows, int n) {
    Matrix m; m.rows = (int)rows.size(); m.cols = n; m.data.assign((size_t)m.rows * n, 0);
    for (int r = 0; r < m.rows; r++) for (int c = 0; c < n; c++) m.data[(size_t)r * n + c] = (rows[r] >> c) & 1;
    return m;
}
static bool odd(Mask x) { return __builtin_popcount(x) & 1; }
static int half_opt(const std::vector<Mask>& H, const std::vector<Mask>& G, int n) {
    int opt = -1;
    for (Mask v = 1; v < (1u << n); v++) {
        bool ok = true;
        for (Mask h : H) if (odd(h & v)) { ok = false; break; }
        if (!ok) continue;
        bool nt = false;
        for (Mask g : G) if (odd(g & v)) { nt = true; break; }
        if (!nt) continue;
        int w = __builtin_popcount(v);
        if (opt < 0 || w < opt) opt = w;
    }
    return opt;
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

struct RunOut { bool ok; int d; std::vector<long long> lbs, ubs; int status; bool shared; int skips; int follower; };

static RunOut run_driver(const Matrix& Hx, const Matrix& Hz, const Matrix& Gx, const Matrix& Gz,
                         int card, bool symbreak, int mode) {
    RunOut r; r.ok = false; r.d = -2; r.status = 0; r.shared = false; r.skips = 0; r.follower = 0;
    char logname[] = "/tmp/gh102_dualshare_XXXXXX";
    int logfd = mkstemp(logname);
    if (logfd < 0) { perror("mkstemp"); exit(2); }
    int fd[2];
    if (pipe(fd) != 0) { perror("pipe"); exit(2); }
    fflush(stdout); fflush(stderr);
    pid_t pid = fork();
    if (pid == 0) {
        close(fd[0]);
        dup2(logfd, 1);
        alarm(60);
        (void)min_distance_css_interleaved(Hx, Hz, Gx, Gz, 1, fd[1], card, symbreak, mode, false);
        fflush(stdout);
        _exit(0);
    }
    close(fd[1]);
    std::string all; char buf[4096]; ssize_t k;
    while ((k = read(fd[0], buf, sizeof(buf))) > 0) all.append(buf, (size_t)k);
    close(fd[0]);
    int st = 0; waitpid(pid, &st, 0); r.status = st;
    FILE* lf = fdopen(logfd, "r");
    if (lf) {
        rewind(lf);
        char line[1024];
        while (fgets(line, sizeof(line), lf)) {
            if (!strncmp(line, "c dualshare: dual map", 21)) r.shared = true;
            else if (!strncmp(line, "c dualshare: ", 13) && strstr(line, "skipped")) r.skips++;
            else if (r.shared && mode == DUALSHARE_B && strstr(line, "c CSS incremental: Z half cap") && strstr(line, "feasibility")) r.follower++;
        }
        fclose(lf);
    } else close(logfd);
    unlink(logname);
    size_t pos = 0;
    while (pos < all.size()) {
        size_t e = all.find('\n', pos); if (e == std::string::npos) e = all.size();
        std::string line = all.substr(pos, e - pos); pos = e + 1;
        unsigned long long v; int d;
        if (sscanf(line.c_str(), "LB %llu", &v) == 1) r.lbs.push_back((long long)v);
        else if (sscanf(line.c_str(), "UB %llu", &v) == 1) r.ubs.push_back((long long)v);
        else if (!strncmp(line.c_str(), "RESULT -1", 9)) { r.d = -1; }   // UNKNOWN (no answer)
        else if (sscanf(line.c_str(), "RESULT %d", &d) == 1 && strstr(line.c_str(), " OPTIMAL")) { r.d = d; r.ok = true; }
    }
    return r;
}

int main(int argc, char** argv) {
    const int N = argc > 1 ? atoi(argv[1]) : 1000;
    // mutation analysis only: GH102_SEMANTIC_ONLY=1 drops the bookkeeping check (sharing reported iff verified),
    // so that a mutant must be caught by the semantic checks (d, LB, UB) alone
    const bool report_check = !getenv("GH102_SEMANTIC_ONLY");
    long runs = 0, detected = 0, planted_family = 0, planted_random = 0, near_miss = 0, indep = 0, skipped = 0;
    long xsym = 0, dx_ne_dz = 0, near_detected = 0, descents = 0, d_ge3 = 0;
    long shared_runs = 0, runs_with_skips = 0, total_skips = 0, b_follower_probes = 0, both_sym = 0;
    for (int inst = 0; inst < N; inst++) {
        const int n = 4 + (int)rnd(15);
        const int card = (int)rnd(4);
        const unsigned kind = rnd(8);   // 0-3 planted family pi, 4 random pi, 5-6 near miss, 7 independent
        std::vector<std::vector<int> > gens;
        if (rnd(2)) {   // planted X-half symmetry (orbit clauses on the solved half)
            std::vector<int> divs;
            for (int L = 2; L <= n; L++) if (n % L == 0) divs.push_back(L);
            int L = divs[rnd((unsigned)divs.size())];
            gens.push_back(rnd(2) ? stridedshift(n, L) : blockshift(n, L));
        }
        std::vector<Mask> hz0, gx0;
        int nh = (int)rnd((unsigned)(n / 2 + 2)), ng = 1 + (int)rnd(2);   // more checks -> larger distances
        for (int k = 0; k < nh; k++) hz0.push_back(rand_vec(n, 2, 5));
        for (int k = 0; k < ng; k++) gx0.push_back(rand_vec(n, 1, n));
        std::vector<Mask> Hz = closure(hz0, gens, 16), Gx = closure(gx0, gens, 12);
        if (Gx.empty()) Gx.push_back(1u << rnd(n));
        std::vector<Mask> Hx, Gz;
        std::vector<int> pi(n);
        if (kind <= 6) {
            if (kind == 4) {
                for (int i = 0; i < n; i++) pi[i] = i;
                for (int i = n - 1; i > 0; i--) { int j = (int)rnd((unsigned)(i + 1)); std::swap(pi[i], pi[j]); }
            } else {
                std::vector<SymCandidate> fam = candidate_family(n, true);
                pi = fam[rnd((unsigned)fam.size())].perm;
            }
            for (Mask h : Hz) Hx.push_back(perm_apply(pi, h));
            for (int t = 0, T = (int)rnd(4); t < T && Hx.size() > 1; t++) {   // row operations keep rs
                int a = (int)rnd((unsigned)Hx.size()), b = (int)rnd((unsigned)Hx.size());
                if (a != b) Hx[a] ^= Hx[b];
            }
            if (Hx.size() > 1 && rnd(3) == 0) Hx.push_back(Hx[0] ^ Hx[1]);   // redundant row
            for (Mask g : Gx) Gz.push_back(perm_apply(pi, g));
            for (int t = 0, T = (int)rnd(4); t < T; t++) {
                // row operations keep rs[Hx;Gz]; an operation that would zero a Gz row is skipped (otherwise
                // a logical row lying in rs Hx could vanish entirely and the zero-row filter below would
                // replace an emptied Gz by a random row, which is not a row operation)
                int a = (int)rnd((unsigned)Gz.size());
                Mask nv = Gz[a];
                if (!Hx.empty() && rnd(2)) nv ^= Hx[rnd((unsigned)Hx.size())];
                else { int b = (int)rnd((unsigned)Gz.size()); if (a != b) nv ^= Gz[b]; }
                if (nv) Gz[a] = nv;
            }
            if (kind == 5 || kind == 6) {   // near miss: flip one bit of Hx or Gz
                if (!Hx.empty() && rnd(2)) Hx[rnd((unsigned)Hx.size())] ^= 1u << rnd(n);
                else Gz[rnd((unsigned)Gz.size())] ^= 1u << rnd(n);
            }
        } else {
            int mh = (int)rnd((unsigned)(n / 2 + 2)), mg = 1 + (int)rnd(2);
            for (int k = 0; k < mh; k++) Hx.push_back(rand_vec(n, 2, 5));
            for (int k = 0; k < mg; k++) Gz.push_back(rand_vec(n, 1, n));
        }
        // drop all-zero rows of Gz (only a near-miss bit flip can create one; a zero logical row is
        // semantically void); if Gz would become empty, a random unit row replaces it (near miss only)
        std::vector<Mask> Gz2; for (Mask g : Gz) if (g) Gz2.push_back(g);
        if (Gz2.empty()) Gz2.push_back(1u << rnd(n));
        Gz = Gz2;
        const int dX = half_opt(Hz, Gx, n), dZ = half_opt(Hx, Gz, n);
        if (dX < 0 && dZ < 0) { skipped++; continue; }   // the driver dies: no logical in either half
        const int d = dX < 0 ? dZ : dZ < 0 ? dX : std::min(dX, dZ);
        if (kind <= 4) need(dX == dZ, "planted dual instance with dX != dZ (test construction)", inst, -1);
        if (dX != dZ) dx_ne_dz++;
        if (d >= 3) d_ge3++;
        const Matrix mHx = to_matrix(Hx, n), mHz = to_matrix(Hz, n), mGx = to_matrix(Gx, n), mGz = to_matrix(Gz, n);
        DualMapInfo dm = find_dual_maps(mHx, mHz, mGx, mGz, false);
        const bool det = !dm.maps.empty();
        if (det) { detected++; need(dX == dZ, "dual map verified but dX != dZ", inst, -1); }
        if (kind <= 3) { planted_family++; need(det, "planted family dual map not detected", inst, -1); }
        else if (kind == 4) planted_random++;
        else if (kind <= 6) { near_miss++; if (det) near_detected++; }
        else indep++;
        if (det && dX >= 0) {
            HalfSymInfo si = find_half_symmetry(mHz, mGx);
            HalfSymInfo sz = find_half_symmetry(mHx, mGz);
            if ((int)si.reps.size() < si.n) xsym++;
            if ((int)si.reps.size() < si.n && (int)sz.reps.size() < sz.n) both_sym++;
        }
        for (int cfg = 0; cfg < 4; cfg++) {
            // cfg 0: variant A (default), 1: variant B, 2: variant A without symbreak, 3: -no-dualshare (GH-89)
            const bool sb = cfg != 2;
            const int mode = cfg == 1 ? DUALSHARE_B : cfg == 3 ? DUALSHARE_OFF : DUALSHARE_A;
            RunOut r = run_driver(mHx, mHz, mGx, mGz, card, sb, mode);
            runs++;
            need(WIFEXITED(r.status) && WEXITSTATUS(r.status) == 0, "driver child did not exit cleanly", inst, cfg);
            need(r.ok, "no RESULT d OPTIMAL", inst, cfg);
            need(r.d == d, "d != min(dX, dZ) by enumeration", inst, cfg);
            for (long long lb : r.lbs) need(lb <= d, "emitted LB > d", inst, cfg);
            for (long long ub : r.ubs) need(ub >= d, "emitted UB < d", inst, cfg);
            const bool both = dX >= 0 && dZ >= 0;
            if (report_check) need(r.shared == (mode != DUALSHARE_OFF && det && both), "sharing reported iff a dual map is verified", inst, cfg);
            if (r.shared) { shared_runs++; total_skips += r.skips; if (r.skips) runs_with_skips++; b_follower_probes += r.follower; }
            // shared descent exercised: the first incumbent was not optimal (phase 2 had to improve or prove)
            if (cfg == 0 && r.shared && !r.ubs.empty() && r.ubs[0] > d) descents++;
            if (fails > 20) { fprintf(stderr, "too many failures, stopping\n"); goto out; }
        }
    }
out:
    fprintf(stderr, "GH102_DUALSHARE_%s instances=%d skipped=%ld runs=%ld planted_family=%ld planted_random=%ld near_miss=%ld independent=%ld detected=%ld near_miss_detected=%ld dX!=dZ=%ld detected_with_xhalf_orbits=%ld detected_with_both_half_orbits=%ld d>=3=%ld shared_runs=%ld shared_runs_with_implied_skips=%ld implied_skips=%ld b_follower_probes=%ld shared_descents=%ld failures=%d\n",
            fails ? "FAIL" : "PASS", N, skipped, runs, planted_family, planted_random, near_miss, indep, detected,
            near_detected, dx_ne_dz, xsym, both_sym, d_ge3, shared_runs, runs_with_skips, total_skips, b_follower_probes,
            descents, fails);
    return fails ? 1 : 0;
}
