// GH26 test-only, independent FLA model. Not connected to DistQLDPC production.
// Written from CP2026 Algorithms 1-3 and the local conservative proof.
// No upstream implementation was copied. Distributed under root project license.
#ifndef DISTQLDPC_GH26_SNAPSHOT_FLA_H
#define DISTQLDPC_GH26_SNAPSHOT_FLA_H
#include <vector>
#include <cstddef>

namespace gh26 {
// Literal representation: 2*variable + sign; sign 1 negates the variable.
struct Core { std::vector<int> members; int weight; };
struct Snapshot {
    int variables;
    std::vector<std::vector<int> > hard;
    std::vector<int> soft; // Exactly one active literal per objective variable.
    std::vector<int> base; // -1 unassigned, 0 false, 1 true.
    std::vector<Core> cores; // Disjoint, certified under base by the caller.
};
struct Stats {
    unsigned candidates, branches, covered, assumptions, implications;
    Stats() : candidates(0), branches(0), covered(0), assumptions(0), implications(0) {}
};

class Probe {
    const Snapshot& input;
    const std::vector<std::vector<int> >& occurs;
    const std::vector<int>& objective;
    const std::vector<int>& membership;
    Stats& stats;
    std::vector<int> values, remaining, falsified, units;
    std::vector<unsigned char> satisfied;
    std::size_t cursor;
    bool extra, contradiction;

    int value(int p) const {
        int v=values[p/2];
        return v < 0 ? -1 : (v != (p&1) ? 1 : 0);
    }
    void set(int p, bool assumption) {
        if (extra || contradiction) return;
        int old=value(p);
        if (old == 1) return;
        if (old == 0) { contradiction=true; return; }
        int v=p/2;
        values[v]=1-(p&1);
        if (assumption) ++stats.assumptions; else ++stats.implications;
        // BEFORE increment: reaching the old core weight merely unlocks it.
        if (objective[v] >= 0 && value(objective[v]) == 0) {
            int k=membership[v];
            if (k < 0 || falsified[k] >= input.cores[k].weight) extra=true;
            if (k >= 0) ++falsified[k];
        }
        const std::vector<int>& positive=occurs[p];
        for (std::size_t i=0;i<positive.size();++i) satisfied[positive[i]]=1;
        const std::vector<int>& negative=occurs[p^1];
        for (std::size_t i=0;i<negative.size();++i) {
            int c=negative[i];
            if (satisfied[c]) continue;
            --remaining[c];
            if (remaining[c] == 0) contradiction=true;
            else if (remaining[c] == 1) units.push_back(c);
        }
    }
    void propagate() {
        while (cursor < units.size() && !extra && !contradiction) {
            int c=units[cursor++];
            if (satisfied[c]) continue;
            int only=-1;
            const std::vector<int>& lits=input.hard[c];
            for (std::size_t i=0;i<lits.size();++i) {
                int val=value(lits[i]);
                if (val == 1) { satisfied[c]=1; break; }
                if (val < 0) only=lits[i];
            }
            if (satisfied[c]) continue;
            if (remaining[c] == 0 || only < 0) contradiction=true;
            else set(only, false);
        }
    }
public:
    Probe(const Snapshot& source, const std::vector<std::vector<int> >& occurrences,
          const std::vector<int>& obj, const std::vector<int>& member, Stats& counters)
        : input(source), occurs(occurrences), objective(obj), membership(member), stats(counters),
          values(source.base), remaining(source.hard.size(),0), falsified(source.cores.size(),0),
          satisfied(source.hard.size(),0), cursor(0), extra(false), contradiction(false) {
        for (std::size_t c=0;c<input.hard.size();++c) {
            const std::vector<int>& lits=input.hard[c];
            for (std::size_t j=0;j<lits.size();++j) {
                int val=value(lits[j]);
                if (val == 1) satisfied[c]=1;
                else if (val < 0) ++remaining[c];
            }
            if (!satisfied[c]) {
                if (remaining[c] == 0) contradiction=true;
                else if (remaining[c] == 1) units.push_back(static_cast<int>(c));
            }
        }
    }
    bool covered(int member) {
        // Selected false member is an unlocking premise, not a positive A.
        set(member^1, false);
        propagate();
        while (!extra && !contradiction) {
            int next=-1;
            // Fixed deterministic variable order. No search/threshold learning.
            for (int v=0;v<input.variables;++v) {
                if (objective[v] < 0 || values[v] >= 0) continue;
                int k=membership[v];
                if (k < 0 || falsified[k] >= input.cores[k].weight) {
                    next=objective[v]; break;
                }
            }
            if (next < 0) return false;
            set(next, true);
            propagate();
        }
        return extra || contradiction;
    }
};

// True certifies active-cost >= base-false + sum(core weights) + 1,
// GIVEN valid old cores. It does not prove the validity of caller-provided K.
// Input is never mutated, including on declined or uncovered probes.
inline bool strengthenOne(const Snapshot& input, Stats& stats) {
    if (input.variables < 0 || static_cast<int>(input.base.size()) != input.variables) return false;
    std::vector<int> objective(input.variables,-1), membership(input.variables,-1);
    std::vector<std::vector<int> > occurs(2*input.variables);
    for (int v=0;v<input.variables;++v)
        if (input.base[v] < -1 || input.base[v] > 1) return false;
    for (std::size_t i=0;i<input.soft.size();++i) {
        int p=input.soft[i];
        if (p < 0 || p/2 >= input.variables || objective[p/2] >= 0) return false;
        objective[p/2]=p;
    }
    for (std::size_t k=0;k<input.cores.size();++k) {
        const Core& core=input.cores[k];
        if (core.weight <= 0 || core.weight > static_cast<int>(core.members.size())) return false;
        for (std::size_t j=0;j<core.members.size();++j) {
            int p=core.members[j];
            if (p < 0 || p/2 >= input.variables || objective[p/2] != p ||
                membership[p/2] >= 0 || input.base[p/2] >= 0) return false;
            membership[p/2]=static_cast<int>(k);
        }
    }
    for (std::size_t c=0;c<input.hard.size();++c) {
        const std::vector<int>& lits=input.hard[c];
        for (std::size_t j=0;j<lits.size();++j) {
            int p=lits[j];
            if (p < 0 || p/2 >= input.variables) return false;
            occurs[p].push_back(static_cast<int>(c));
        }
    }
    for (std::size_t k=0;k<input.cores.size();++k) {
        const Core& core=input.cores[k];
        if (core.weight != 1 || core.members.size() > 2) continue;
        ++stats.candidates;
        bool all=true;
        for (std::size_t j=0;j<core.members.size();++j) {
            ++stats.branches;
            Probe probe(input, occurs, objective, membership, stats);
            if (!probe.covered(core.members[j])) { all=false; break; }
            ++stats.covered;
        }
        if (all) return true;
    }
    return false;
}
} // namespace gh26
#endif
