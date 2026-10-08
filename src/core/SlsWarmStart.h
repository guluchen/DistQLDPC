/* DistQLDPC bounded original-instance local search.
 * Copyright (C) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Newly authored WalkSAT-style experiment; not imported MaxCDCL/Loandra code.
 */
#ifndef DISTQLDPC_SLS_WARM_START_H
#define DISTQLDPC_SLS_WARM_START_H
#include <algorithm>
#include <stdint.h>
#include <vector>

namespace DistWarm {
struct Clause { std::vector<int> lits; bool hard; };
struct Formula { int vars; int hard_score; std::vector<Clause> clauses; };
struct Result {
    int cost, flips, final_hard_unsat;
    std::vector<uint8_t> assignment;
    Result() : cost(-1), flips(0), final_hard_unsat(0) {}
};
struct Rng {
    uint32_t state;
    explicit Rng(uint32_t seed) : state(seed ? seed : 1) {}
    uint32_t next() {
        state ^= state << 13; state ^= state >> 17; state ^= state << 5;
        return state;
    }
};
inline int variable(int lit) { return (lit > 0 ? lit : -lit) - 1; }
inline bool truth(int lit, const std::vector<uint8_t>& a) {
    return bool(a[variable(lit)]) != (lit < 0);
}
// Independent full scan, deliberately not based on the search's cached counts.
inline int verified_cost(const Formula& f, const std::vector<uint8_t>& a) {
    if (a.size() != size_t(f.vars)) return -1;
    for (size_t i = 0; i < a.size(); ++i) if (a[i] > 1) return -1;
    int cost = 0;
    for (size_t i = 0; i < f.clauses.size(); ++i) {
        bool sat = false;
        for (size_t j = 0; j < f.clauses[i].lits.size(); ++j) {
            const int lit = f.clauses[i].lits[j];
            if (!lit || variable(lit) >= f.vars) return -1;
            sat |= truth(lit, a);
        }
        if (!sat && f.clauses[i].hard) return -1;
        if (!sat) ++cost; // original application soft clauses all have weight one
    }
    return cost;
}

class Search {
    const Formula& f;
    Rng rng;
    std::vector<uint8_t> a;
    std::vector<std::vector<int> > occurs;
    std::vector<int> counts, position, hard_unsat, soft_unsat;
    int count_after(int ci, int flip) const {
        int count = 0;
        const Clause& c = f.clauses[ci];
        for (size_t j = 0; j < c.lits.size(); ++j)
            count += truth(c.lits[j], a) != (variable(c.lits[j]) == flip);
        return count;
    }
    void set_unsat(int ci, bool unsat) {
        std::vector<int>& list = f.clauses[ci].hard ? hard_unsat : soft_unsat;
        if (unsat && position[ci] < 0) {
            position[ci] = int(list.size()); list.push_back(ci);
        } else if (!unsat && position[ci] >= 0) {
            const int p = position[ci], last = list.back();
            list[p] = last; position[last] = p;
            list.pop_back(); position[ci] = -1;
        }
    }
    int delta(int v) const {
        int d = 0;
        for (size_t j = 0; j < occurs[v].size(); ++j) {
            const int ci = occurs[v][j];
            const int weight = f.clauses[ci].hard ? f.hard_score : 1;
            d += weight * (int(count_after(ci, v) == 0) - int(counts[ci] == 0));
        }
        return d;
    }
    void flip(int v) {
        for (size_t j = 0; j < occurs[v].size(); ++j) {
            int ci = occurs[v][j];
            counts[ci] = count_after(ci, v);
            set_unsat(ci, counts[ci] == 0);
        }
        a[v] ^= 1;
    }
public:
    explicit Search(const Formula& formula, uint32_t seed)
        : f(formula), rng(seed), a(f.vars), occurs(f.vars),
          counts(f.clauses.size()), position(f.clauses.size(), -1) {
        for (int v = 0; v < f.vars; ++v) a[v] = rng.next() & 1;
        for (size_t ci = 0; ci < f.clauses.size(); ++ci) {
            std::vector<int> vars;
            for (size_t j = 0; j < f.clauses[ci].lits.size(); ++j)
                vars.push_back(variable(f.clauses[ci].lits[j]));
            std::sort(vars.begin(), vars.end());
            vars.erase(std::unique(vars.begin(), vars.end()), vars.end());
            for (size_t j = 0; j < vars.size(); ++j) occurs[vars[j]].push_back(int(ci));
            counts[ci] = count_after(int(ci), -1);
            set_unsat(int(ci), counts[ci] == 0);
        }
    }
    Result run(int budget) {
        Result best;
        for (int step = 0; step <= budget; ++step) {
            if (hard_unsat.empty() && (best.cost < 0 || int(soft_unsat.size()) < best.cost)) {
                best.cost = int(soft_unsat.size()); best.assignment = a;
            }
            if (step == budget || (hard_unsat.empty() && soft_unsat.empty())) break;
            const std::vector<int>& unsat = hard_unsat.empty() ? soft_unsat : hard_unsat;
            const Clause& clause = f.clauses[unsat[rng.next() % unsat.size()]];
            if (clause.lits.empty()) break; // hard UNSAT; no witness, exact path retained
            int v = variable(clause.lits[rng.next() % clause.lits.size()]);
            if (rng.next() % 4 != 0) {
                int best_delta = 0, ties = 0;
                for (size_t j = 0; j < clause.lits.size(); ++j) {
                    const int candidate = variable(clause.lits[j]), d = delta(candidate);
                    if (!ties || d < best_delta) { best_delta = d; v = candidate; ties = 1; }
                    else if (d == best_delta && rng.next() % ++ties == 0) v = candidate;
                }
            }
            flip(v); ++best.flips;
        }
        best.final_hard_unsat = int(hard_unsat.size());
        return best;
    }
};
inline Result run(const Formula& f, int budget = 10000, uint32_t seed = 1) {
    return Search(f, seed).run(budget);
}
}
#endif
