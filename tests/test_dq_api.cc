/*
 * DistQLDPC — native checks of the in-process library entry point (src/core/dq_api.h; web demo).
 *
 * Copyright (C) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 *   dq_api_test solve <prefix> [--compute-g] [flags...]
 *       dq_solve on <prefix>_{Hx,Hz,Gx,Gz}.txt (--compute-g: only Hx, Hz; Gx, Gz computed); the library's stdout is
 *       the CLI's stdout (compare with bin/distqldpc), every event goes to stderr as "E <line>".
 *   dq_api_test logicals <prefix>
 *       Gx, Gz computed from Hx, Hz against the bundled <prefix>_{Gx,Gz}.txt: same number of rows, computed rows in
 *       ker H, and rs[S; G_computed] = rs[S; G_bundled] (S = Hz for Gx, Hx for Gz). Prints one OK / FAIL line.
 *   dq_api_test cancel <prefix> <seconds> [flags...]
 *       dq_solve in a thread, dq_cancel() after <seconds>; the FINAL event must say CANCELLED (or finish earlier).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <string>
#include <thread>
#include <chrono>
#include <vector>

#include "../src/core/dq_api.h"

static std::string slurp(const std::string& path) {
    FILE* f = fopen(path.c_str(), "rb");
    if (!f) { fprintf(stderr, "cannot open %s\n", path.c_str()); exit(2); }
    std::string s;
    char buf[65536];
    size_t n;
    while ((n = fread(buf, 1, sizeof(buf), f)) > 0) s.append(buf, n);
    fclose(f);
    return s;
}

typedef std::vector<uint64_t> Bits;

static std::vector<Bits> rows_of(const std::string& txt, int& n) {
    std::vector<Bits> out;
    n = -1;
    size_t i = 0;
    while (i < txt.size()) {
        size_t j = txt.find('\n', i);
        if (j == std::string::npos) j = txt.size();
        std::string line = txt.substr(i, j - i);
        i = j + 1;
        size_t k = line.find_first_not_of(" \t\r");
        if (k == std::string::npos || line[k] == '#') continue;
        std::vector<int> v;
        for (char c : line) if (c == '0' || c == '1') v.push_back(c - '0');
        if (v.empty()) continue;
        if (n < 0) n = (int)v.size();
        Bits b((size_t)(n + 63) / 64, 0);
        for (int c = 0; c < n; c++) if (v[c]) b[(size_t)c >> 6] |= 1ULL << (c & 63);
        out.push_back(b);
    }
    return out;
}

static int rank_of(std::vector<Bits> m, int n) {
    int r = 0;
    for (int c = 0; c < n && r < (int)m.size(); c++) {
        int p = -1;
        for (int i = r; i < (int)m.size(); i++) if ((m[i][(size_t)c >> 6] >> (c & 63)) & 1) { p = i; break; }
        if (p < 0) continue;
        std::swap(m[r], m[p]);
        for (int i = 0; i < (int)m.size(); i++)
            if (i != r && ((m[i][(size_t)c >> 6] >> (c & 63)) & 1))
                for (size_t w = 0; w < m[i].size(); w++) m[i][w] ^= m[r][w];
        r++;
    }
    return r;
}

static bool in_kernel(const std::vector<Bits>& H, const Bits& v) {
    for (const Bits& h : H) {
        uint64_t acc = 0;
        for (size_t w = 0; w < h.size(); w++) acc ^= h[w] & v[w];
        if (__builtin_popcountll(acc) & 1) return false;
    }
    return true;
}

static void on_event(const char* line, void*) { fprintf(stderr, "E %s\n", line); fflush(stderr); }

static std::string join_flags(int argc, char** argv, int from, bool* compute_g) {
    std::string f;
    for (int i = from; i < argc; i++) {
        if (compute_g && !strcmp(argv[i], "--compute-g")) { *compute_g = true; continue; }
        if (!f.empty()) f += " ";
        f += argv[i];
    }
    return f;
}

int main(int argc, char** argv) {
    if (argc < 3) { fprintf(stderr, "usage: see tests/test_dq_api.cc\n"); return 2; }
    const std::string mode = argv[1], p = argv[2];
    if (mode == "solve") {
        bool cg = false;
        const std::string flags = join_flags(argc, argv, 3, &cg);
        const std::string hx = slurp(p + "_Hx.txt"), hz = slurp(p + "_Hz.txt");
        std::string gx, gz;
        if (!cg) { gx = slurp(p + "_Gx.txt"); gz = slurp(p + "_Gz.txt"); }
        int d = dq_solve(hx.c_str(), hz.c_str(), cg ? NULL : gx.c_str(), cg ? NULL : gz.c_str(), flags.c_str(), on_event, NULL);
        fprintf(stderr, "E RETURN %d\n", d);
        return d >= 0 ? 0 : 1;
    }
    if (mode == "logicals") {
        const std::string hx = slurp(p + "_Hx.txt"), hz = slurp(p + "_Hz.txt");
        char *gx = NULL, *gz = NULL;
        const auto t0 = std::chrono::steady_clock::now();
        const int k = dq_compute_logicals(hx.c_str(), hz.c_str(), &gx, &gz);
        const double secs = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
        int n = 0, n2 = 0;
        std::vector<Bits> Hx = rows_of(hx, n), Hz = rows_of(hz, n2);
        bool ok = true;
        std::string why;
        for (int half = 0; half < 2; half++) {   /* 0: Gx (ker Hx, mod Hz), 1: Gz (ker Hz, mod Hx) */
            int nn = 0;
            std::vector<Bits> Gc = rows_of(half == 0 ? gx : gz, nn);
            std::vector<Bits> Gb = rows_of(slurp(p + (half == 0 ? "_Gx.txt" : "_Gz.txt")), nn);
            const std::vector<Bits>& H = half == 0 ? Hx : Hz;
            const std::vector<Bits>& S = half == 0 ? Hz : Hx;
            if (Gc.size() != Gb.size()) { ok = false; why += " rows " + std::to_string(Gc.size()) + "!=" + std::to_string(Gb.size()); }
            for (const Bits& v : Gc) if (!in_kernel(H, v)) { ok = false; why += " computed row not in ker H"; break; }
            std::vector<Bits> A(S), B(S), C(S);
            A.insert(A.end(), Gc.begin(), Gc.end());
            B.insert(B.end(), Gb.begin(), Gb.end());
            C.insert(C.end(), Gc.begin(), Gc.end());
            C.insert(C.end(), Gb.begin(), Gb.end());
            const int ra = rank_of(A, n), rb = rank_of(B, n), rc = rank_of(C, n), rs = rank_of(S, n);
            if (!(ra == rb && rb == rc && ra - rs == (int)Gc.size())) {
                ok = false;
                why += std::string(" ") + (half == 0 ? "Gx" : "Gz") + " span mismatch (" + std::to_string(ra) + "," + std::to_string(rb) + "," +
                       std::to_string(rc) + ", rank S " + std::to_string(rs) + ")";
            }
        }
        printf("%s %s n %d k %d time %.3fs%s\n", ok ? "OK" : "FAIL", p.c_str(), n, k, secs, why.c_str());
        free(gx);
        free(gz);
        return ok ? 0 : 1;
    }
    if (mode == "cancel" && argc >= 4) {
        const double secs = atof(argv[3]);
        const std::string flags = join_flags(argc, argv, 4, NULL);
        const std::string hx = slurp(p + "_Hx.txt"), hz = slurp(p + "_Hz.txt"), gx = slurp(p + "_Gx.txt"), gz = slurp(p + "_Gz.txt");
        int d = -2;
        std::thread t([&]() { d = dq_solve(hx.c_str(), hz.c_str(), gx.c_str(), gz.c_str(), flags.c_str(), on_event, NULL); });
        std::this_thread::sleep_for(std::chrono::duration<double>(secs));
        dq_cancel();
        t.join();
        fprintf(stderr, "E RETURN %d\n", d);
        return 0;
    }
    fprintf(stderr, "unknown mode\n");
    return 2;
}
