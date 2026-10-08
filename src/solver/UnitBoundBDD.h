/* DistQLDPC experimental singleton unit-coefficient bound BDD.
 * Copyright (c) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
 * SPDX-License-Identifier: MIT
 * Newly authored; existing engine attribution and MIT notices remain intact.
 */
#ifndef DISTQLDPC_UNIT_BOUND_BDD_H
#define DISTQLDPC_UNIT_BOUND_BDD_H
#include <algorithm>
#include <vector>
namespace DistQLDPCBDD {
struct Node { int input, low, high; };
struct Graph {
    std::vector<Node> nodes;
    int root;
    Graph(int n, int k) : root(0) {
        nodes.push_back(Node{-1,0,0}); // false terminal
        nodes.push_back(Node{-1,1,1}); // true terminal
        if (k < 0) return;
        if (k >= n) { root = 1; return; }
        std::vector<int> suffix(k+1,1), current(k+1,1);
        for (int i=n-1; i>=0; --i) {
            // Only budgets reachable after i prefix decisions are constructed.
            for (int r=std::max(0,k-i); r<=k; ++r) {
                if (r>=n-i) { current[r]=1; continue; }
                int low=suffix[r], high=r ? suffix[r-1] : 0;
                if (low==high) current[r]=low;
                else {
                    current[r]=int(nodes.size());
                    nodes.push_back(Node{i,low,high});
                }
            }
            current.swap(suffix);
        }
        root=suffix[k];
        // At a fixed input, distinct nonterminal unit budgets represent distinct
        // thresholds, so state memoization also makes the graph reduced/unique.
    }
};
}
#endif
