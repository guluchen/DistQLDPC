#include "cc_half.h"
#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <vector>

static bool halt(void*) { return true; }

int main() {
    unsigned levels = 0, cancelled = 0;
    uint64_t cuts = 0, nodes = 0, leaves = 0;
    for (int n = 4; n <= 10; ++n)
    for (int graph = 0; graph < 3; ++graph)
    for (int mode = 0; mode < 3; ++mode)
    for (int seed : {0, 31}) {
        distcc::SparseRows H, G;
        H.cols = G.cols = n;
        for (int q = 1; q < n; ++q) {
            int parent = graph == 0 ? q - 1 : graph == 1 ? 0 : (q - 1) / 2;
            H.rows.push_back({parent, q});
        }
        if (graph == 2) H.rows.push_back({0, n - 1});
        G.rows.push_back({n / 2});
        distcc::Rules rules;
        rules.erasure_gate = distcc::ERASURE_GATE_NONE;
        rules.mrv = mode == 1;
        if (mode == 2) rules.sparse = rules.sparseov = rules.sparsemrv = rules.erasure = false;
        distcc::HalfSearch search(H, G, {}, rules, seed, 0, nullptr,
                                  mode == 1 ? distcc::ROWORDER_BFS : distcc::ROWORDER_INDEX);
        for (int w = 1; w <= n; ++w) {
            const auto res = search.run_level(w);
            if (res.verdict != (w == n ? distcc::LEVEL_FOUND : distcc::LEVEL_EMPTY)) return 1;
            if (w == n) {
                auto witness = res.witness;
                std::sort(witness.begin(), witness.end());
                if (int(witness.size()) != n) return 2;
                for (int q = 0; q < n; ++q)
                    if (int(witness[q]) != q) return 3;
            }
            std::printf("%d %d %d %d %d %d %llu %llu %llu %llu\n", n, graph, mode, seed, w,
                        int(res.verdict), (unsigned long long)res.nodes, (unsigned long long)res.packprune,
                        (unsigned long long)res.nocand, (unsigned long long)res.leaf2);
            ++levels; cuts += res.packprune; nodes += res.nodes; leaves += res.leaf2;
        }
        search.set_poll(halt, nullptr, 0);
        if (search.run_level(n).verdict != distcc::LEVEL_ABORTED) return 4;
        search.set_poll(nullptr, nullptr);
        if (search.run_level(n).verdict != distcc::LEVEL_FOUND) return 5;
        ++cancelled;
    }
    if (!cuts || !leaves || !nodes || levels != 882 || cancelled != 126) return 6;
    std::printf("PASS %u levels, %u interrupted and resumed searches, %llu pack cuts, %llu nodes, %llu leaf2\n",
                levels, cancelled, (unsigned long long)cuts, (unsigned long long)nodes, (unsigned long long)leaves);
}
