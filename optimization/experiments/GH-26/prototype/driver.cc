// Test-only model protocol: variables, clauses, softs, cores, base, clauses,
// soft literals, (weight, member-count, members) per core. No solver linkage.
#include <iostream>
#include "snapshot_fla.h"
int main() {
    int n, c, s, k;
    while (std::cin >> n >> c >> s >> k) {
        if (n<0 || c<0 || s<0 || k<0) return 2;
        gh26::Snapshot input;
        input.variables=n; input.base.resize(n); input.hard.resize(c);
        input.soft.resize(s); input.cores.resize(k);
        for (int i=0;i<n;++i) std::cin >> input.base[i];
        for (int i=0;i<c;++i) {
            int length; std::cin >> length;
            if (length<0) return 2;
            input.hard[i].resize(length);
            for (int j=0;j<length;++j) std::cin >> input.hard[i][j];
        }
        for (int i=0;i<s;++i) std::cin >> input.soft[i];
        for (int i=0;i<k;++i) {
            int length; std::cin >> input.cores[i].weight >> length;
            if (length<0) return 2;
            input.cores[i].members.resize(length);
            for (int j=0;j<length;++j) std::cin >> input.cores[i].members[j];
        }
        if (!std::cin) return 2;
        gh26::Stats stats;
        bool strengthened=gh26::strengthenOne(input,stats);
        std::cout << strengthened << ' ' << stats.candidates << ' ' << stats.branches
                  << ' ' << stats.covered << ' ' << stats.assumptions << ' '
                  << stats.implications << '\n';
    }
    return 0;
}
