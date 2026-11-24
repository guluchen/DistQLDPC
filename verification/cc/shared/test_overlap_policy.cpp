/* Copyright (C) 2026 Yu-Fang Chen. SPDX-License-Identifier: GPL-3.0-or-later */
#include "cc_half.h"
#include <algorithm>
#include <cstdio>
#include <vector>

static bool stop(void*) { return true; }

int main() {
    unsigned levels = 0, interrupted = 0;
    unsigned long long tight = 0, forbidden = 0;
    for (int length = 4; length <= 10; ++length) {
        distcc::SparseRows H, G, K;
        H.cols = G.cols = K.cols = 2 * length;
        G.rows.push_back({0, 1});
        std::vector<int> pairs;
        for (int i = 0; i < length; ++i) {
            const int q = 2 * i, next = 2 * ((i + 1) % length);
            pairs.push_back(i);
            pairs.push_back(i);
            K.rows.push_back({q, q + 1});
            if (i % 2 == 0) K.rows.push_back({q, q + 1, next, next + 1});
            H.rows.push_back({q, q + 1, next, next + 1});
        }
        for (int mode = 0; mode < 8; ++mode)
            for (const int seed : {0, 31}) {
                distcc::Rules rules;
                rules.tiebreak = (mode & 1) != 0;
                rules.sparseov = (mode & 2) != 0;
                rules.erasure_gate = distcc::ERASURE_GATE_NONE;
                distcc::HalfSearch search(H, G, mode & 4 ? pairs : std::vector<int>{},
                                          rules, seed, 0, &K);
                for (int w = 1; w <= length; ++w) {
                    const auto r = search.run_level(w);
                    if (r.verdict != (w == length ? distcc::LEVEL_FOUND : distcc::LEVEL_EMPTY)) return 1;
                    if (w == length) {
                        std::vector<int> cells(length, 0);
                        for (const auto q : r.witness) {
                            if (q >= 2u * length) return 2;
                            ++cells[q / 2];
                        }
                        if (!std::all_of(cells.begin(), cells.end(), [](int c){ return c == 1; })) return 3;
                    }
                    std::printf("%d %d %d %d %d %llu %llu %llu %llu", length, mode, seed, w,
                                int(r.verdict), (unsigned long long)r.nodes, (unsigned long long)r.ovtight,
                                (unsigned long long)r.ovtightx, (unsigned long long)r.ovforbid);
                    for (const auto q : r.witness) std::printf(" %u", unsigned(q));
                    std::puts("");
                    tight += r.ovtight;
                    forbidden += r.ovforbid;
                    ++levels;
                }
                search.set_poll(stop, nullptr, 0);
                if (search.run_level(length).verdict != distcc::LEVEL_ABORTED) return 4;
                search.set_poll(nullptr, nullptr);
                if (search.run_level(length).verdict != distcc::LEVEL_FOUND) return 5;
                ++interrupted;
            }
    }
    if (!tight || !forbidden || levels != 784 || interrupted != 112) return 6;
    std::printf("PASS %u levels, %u poll/retry, %llu tight, %llu newly blocked\n",
                levels, interrupted, tight, forbidden);
}
