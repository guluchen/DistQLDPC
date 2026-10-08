// GH26 test-only actual Solver snapshot reader. No production call site.
// Does not roll back engine state, set solver flags or learn any clause.
#ifndef GH26_ENGINE_SNAPSHOT_FIXTURE_H
#define GH26_ENGINE_SNAPSHOT_FIXTURE_H
#include "Solver.h"
#include "snapshot_fla.h"
#include <set>
#include <string>
#include <cstdint>
#include <limits>

namespace gh26 {
// Must be captured at actual normalization/root-cost transfer boundaries.
// The reader cannot reconstruct historical transfer identity from a scalar.
struct OffsetWitness {
    std::uint64_t initial_fixed_search_cost;
    std::vector<int> transferred_root_false;
    OffsetWitness() : initial_fixed_search_cost(0) {}
};
struct EngineSnapshot {
    Snapshot model;
    std::vector<int> conditional_nogood;
    std::uint64_t residual_ub, fixed_search_cost, derived_cost, relaxed_cost;
    int base_false, core_weight;
    bool exported;
    std::string decline;
    EngineSnapshot() : residual_ub(0), fixed_search_cost(0), derived_cost(0),
        relaxed_cost(0), base_false(0), core_weight(0), exported(false) {}
};

// Protected-state exposure by ordinary inheritance, not a production friend or
// private/public macro. Test fixture setup is added separately after review.
class EngineSnapshotFixture : public Minisat::Solver {
    bool verifyLiveList(const Minisat::vec<Minisat::CRef>& list,
                        const std::set<Minisat::CRef>& emitted, EngineSnapshot& out) {
        for (int i=0;i<list.size();++i) {
            Minisat::CRef cr=list[i];
            // Bounds are only a guard. Complete Clause-start provenance is a
            // caller precondition from real ca.alloc/attachClause/relocAll.
            if (cr>=ca.size()) { out.decline="live list reference"; return false; }
            const Minisat::Clause& clause=ca[cr];
            if (clause.mark()==1) continue;
            if (clause.reloced() || clause.size()<2 || emitted.count(cr)==0) {
                out.decline="live hard clause not attached"; return false;
            }
        }
        return true;
    }
    bool appendWatchedClauses(EngineSnapshot& out, bool binary,
                             std::set<Minisat::CRef>& emitted) {
        for (int v=0;v<nVars();++v) for (int s=0;s<2;++s) {
            Minisat::Lit key=Minisat::mkLit(v,s!=0);
            // operator[] is a raw accessor; lookup() would clean dirty watchers
            // and violate the read-only extraction contract.
            const Minisat::vec<Watcher>& list=binary ? watches_bin[key] : watches[key];
            for (int j=0;j<list.size();++j) {
                Minisat::CRef cr=list[j].cref;
                // cr<size does not prove this is an allocation boundary or
                // a complete Clause; actual watcher provenance is required.
                if (cr>=ca.size()) { out.decline="watcher allocator reference"; return false; }
                const Minisat::Clause& clause=ca[cr];
                if (clause.mark()==1) continue;
                if (clause.reloced()) { out.decline="unrelocated watcher"; return false; }
                if (!emitted.insert(cr).second) continue;
                if (clause.size()<2 || (binary && clause.size()!=2)) {
                    out.decline="watcher clause shape"; return false;
                }
                std::vector<int> lits;
                for (int k=0;k<clause.size();++k) {
                    int p=Minisat::toInt(clause[k]);
                    if (p<0 || p/2>=nVars()) { out.decline="clause literal"; return false; }
                    lits.push_back(p);
                }
                out.model.hard.push_back(lits);
            }
        }
        return true;
    }
public:
    EngineSnapshot extract(int record, int count_isets, int count_conflicts,
                           const OffsetWitness& offsets) {
        EngineSnapshot out;
        out.residual_ub=UB;
        out.fixed_search_cost=fixedCostBySearch;
        out.derived_cost=derivedCost;
        out.relaxed_cost=relaxedCost;
        out.model.variables=nVars();
        out.model.base.assign(nVars(),-1);
        if (record<0 || record>trail.size() || qhead<record || count_isets<0 ||
            count_conflicts<0 || count_isets>isets.size() || count_isets>isetsLits.size() ||
            count_isets>finalIset.size() || softLits.size()!=nVars()) {
            out.decline="snapshot dimensions"; return out;
        }
        // Rebuild alpha from its trail prefix, NOT assigns containing the
        // positive lookahead suffix. Record includes all current root facts.
        std::set<int> alpha_variables;
        for (int i=0;i<record;++i) {
            Minisat::Lit p=trail[i]; int v=Minisat::var(p);
            if (v<0 || v>=nVars() || !alpha_variables.insert(v).second || value(p)!=Minisat::lbool(static_cast<uint8_t>(0)) ||
                level(v)<0 || level(v)>decisionLevel()) {
                out.decline="base trail assignment"; return out;
            }
            out.model.base[v]=!Minisat::sign(p);
            if (level(v)>0) out.conditional_nogood.push_back(Minisat::toInt(~p));
        }
        std::set<int> false_literals;
        for (int i=0;i<falseLits.size();++i) {
            int p=Minisat::toInt(falseLits[i]),v=p/2;
            if (p<0 || v>=nVars() || !false_literals.insert(p).second ||
                out.model.base[v]<0 || out.model.base[v]!=(p&1)) {
                out.decline="current falseLits mapping"; return out;
            }
        }
        std::set<int> transferred;
        for (std::size_t i=0;i<offsets.transferred_root_false.size();++i) {
            int p=offsets.transferred_root_false[i],v=p/2;
            if (p<0 || v>=nVars() || !transferred.insert(p).second ||
                out.model.base[v]<0 || out.model.base[v]!=(p&1) || level(v)!=0 ||
                false_literals.count(p)!=0 || Minisat::toInt(softLits[v])!=p) {
                out.decline="transferred root witness"; return out;
            }
        }
        if (offsets.initial_fixed_search_cost>std::numeric_limits<std::uint64_t>::max()-transferred.size() ||
            offsets.initial_fixed_search_cost+transferred.size()!=fixedCostBySearch) {
            out.decline="fixed-search transfer delta"; return out;
        }
        std::vector<int> objective(nVars(),-1);
        std::set<int> all_objective_variables;
        for (int i=0;i<allSoftLits.size();++i) {
            int p=Minisat::toInt(allSoftLits[i]),v=p/2;
            if (p<0 || v>=nVars() || !all_objective_variables.insert(v).second ||
                softLits[v]!=allSoftLits[i]) {
                out.decline="normalized objective"; return out;
            }
            bool false_at_base=out.model.base[v]>=0 && out.model.base[v]==(p&1);
            // A root falsity already moved into fixedCostBySearch contributes
            // no residual cost, but remains a hard alpha fact above.
            if (false_at_base && false_literals.count(p)==0) {
                if (level(v)!=0 || transferred.count(p)==0) {
                    out.decline="uncertified uncounted falsity"; return out;
                }
                continue;
            }
            objective[v]=p;
            out.model.soft.push_back(p);
            if (false_at_base) ++out.base_false;
        }
        if (out.base_false!=falseLits.size()) {
            out.decline="residual false count"; return out;
        }
        for (std::set<int>::const_iterator i=transferred.begin();i!=transferred.end();++i)
            if (all_objective_variables.count(*i/2)==0) {
                out.decline="transfer outside normalized objective"; return out;
            }
        std::set<int> components, members;
        for (int root=0;root<count_isets;++root) {
            if (finalIset[root]<0 || finalIset[root]>=count_isets) {
                out.decline="core final pointer"; return out;
            }
            if (finalIset[root]!=root) continue;
            Core core;
            core.weight=isets[root].size(); // original component count, never remaining lock
            if (core.weight<=0) { out.decline="empty component list"; return out; }
            for (int j=0;j<isets[root].size();++j) {
                int component=isets[root][j];
                if (component<0 || component>=count_isets || finalIset[component]!=root ||
                    !components.insert(component).second) {
                    out.decline="component partition"; return out;
                }
                const Minisat::vec<Minisat::Lit>& literals=isetsLits[component];
                for (int k=0;k<literals.size();++k) {
                    int p=Minisat::toInt(literals[k]),v=p/2;
                    if (p<0 || v>=nVars() || objective[v]!=p || out.model.base[v]>=0 ||
                        !members.insert(v).second || inConflicts.size()<=v ||
                        inConflicts[v]!=component) {
                        out.decline="core objective/member partition"; return out;
                    }
                    core.members.push_back(p);
                }
            }
            if (core.weight>static_cast<int>(core.members.size())) {
                out.decline="core weight exceeds members"; return out;
            }
            out.core_weight+=core.weight;
            out.model.cores.push_back(core);
        }
        if (static_cast<int>(components.size())!=count_isets || out.core_weight!=count_conflicts ||
            UB<=static_cast<std::uint64_t>(out.base_false) ||
            UB-static_cast<std::uint64_t>(out.base_false)!=static_cast<std::uint64_t>(count_conflicts)+1) {
            out.decline="gap1/original weight"; return out;
        }
        std::set<Minisat::CRef> emitted;
        if (!appendWatchedClauses(out,true,emitted) || !appendWatchedClauses(out,false,emitted)) return out;
        if (!verifyLiveList(clauses,emitted,out) || !verifyLiveList(learnts_core,emitted,out) ||
            !verifyLiveList(learnts_tier2,emitted,out) || !verifyLiveList(learnts_local,emitted,out) ||
            !verifyLiveList(hardens,emitted,out) || !verifyLiveList(cardinalityC,emitted,out) ||
            !verifyLiveList(isetClauses,emitted,out) || !verifyLiveList(hardSoftClauses,emitted,out) ||
            !verifyLiveList(hardLearnts,emitted,out) || !verifyLiveList(softLearnts,emitted,out)) return out;
        out.exported=true;
        return out;
    }
};
} // namespace gh26
#endif
