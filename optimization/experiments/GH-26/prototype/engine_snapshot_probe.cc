// GH26 read-only adapter fixture. No production hook/rollback/learning claim.
#include "engine_snapshot_fixture.h"
#include <iostream>
#include <sstream>
#include <iomanip>
#include <stdexcept>

using namespace Minisat;
static void require(bool condition,const char* message) {
    if (!condition) throw std::runtime_error(message);
}
class Fixture : public gh26::EngineSnapshotFixture {
public:
    std::vector<std::vector<int> > original_hard;
    std::vector<int> original_soft;
    gh26::OffsetWitness offsets;
    void setup(int signs,bool covered,int root_mode) {
        for (int i=0;i<4;++i) newVar();
        UB=100; UBconflictFlag=false; softConflictFlag=false; falseVar=var_Undef;
        LHconfl=CRef_Undef; hardenEnable=false;
        LOOKAHEAD=lk_propagations=nbLKsuccess=totalPrunedLB=totalPrunedLB2=0;
        fixedCostBySearch=0; derivedCost=0; relaxedCost=0;
        for (int i=0;i<4;++i) {
            Lit p=mkLit(i,i<3 && (signs&(1<<i))!=0);
            softLits[i]=p; allSoftLits.push(p); original_soft.push_back(toInt(p));
        }
        int pairs[3][2]={{0,1},{0,2},{1,2}};
        for (int i=0;i<(covered?3:2);++i) {
            vec<Lit> ps; ps.push(~softLits[pairs[i][0]]); ps.push(~softLits[pairs[i][1]]);
            CRef cr=ca.alloc(ps,false); clauses.push(cr); attachClause(cr);
            original_hard.push_back(std::vector<int>{toInt(ps[0]),toInt(ps[1])});
        }
        if (root_mode!=0) {
            uncheckedEnqueue(root_mode==3 ? softLits[3] : ~softLits[3]);
            qhead=trail.size();
            if (root_mode==2) {
                // Capture the literal identities BEFORE the same scalar cost
                // transfer/clear operations used by the baseline success path.
                offsets.initial_fixed_search_cost=fixedCostBySearch;
                for (int i=0;i<falseLits.size();++i) offsets.transferred_root_false.push_back(toInt(falseLits[i]));
                fixedCostBySearch+=falseLits.size(); falseLits.clear();
            }
        }
        trailRecord=trail.size();
        isets.init(0); isets[0].push(0);
        isetsLits.init(0); isetsLits[0].push(softLits[0]); isetsLits[0].push(softLits[1]);
        finalIset.push(0); isetLock.push(1);
        inConflicts[0]=inConflicts[1]=0;
        UB=falseLits.size()+2;
    }
    std::string fingerprint() {
        std::ostringstream s;
        s<<std::setprecision(17);
        s<<qhead<<','<<trailRecord<<','<<UB<<','<<fixedCostBySearch<<','<<derivedCost<<','<<relaxedCost;
        s<<" flags"<<ok<<','<<UBconflictFlag<<','<<softConflictFlag<<','<<falseVar<<','<<hardenEnable<<','<<LHconfl;
        s<<" counters"<<solves<<','<<starts<<','<<decisions<<','<<propagations<<','<<conflicts
         <<','<<clauses_literals<<','<<learnts_literals<<','<<LOOKAHEAD<<','<<lk_propagations
         <<','<<nbLKsuccess<<','<<totalPrunedLB<<','<<totalPrunedLB2<<','<<counter;
        s<<" allocator"<<ca.size()<<','<<ca.wasted();
        for (int v=0;v<nVars();++v)
            s<<';'<<toInt(assigns[v])<<','<<vardata[v].reason<<','<<vardata[v].level
             <<','<<seen[v]<<','<<involved[v]<<','<<inConflict[v]<<','<<inConflicts[v]
             <<','<<softVarLocked[v]<<','<<unlockReason[v]<<','<<orderHeapAuxi.inHeap(v)
             <<','<<order_heap_VSIDS.inHeap(v)<<','<<order_heap_CHB.inHeap(v)
             <<','<<activityLB[v]<<','<<activity_VSIDS[v]<<','<<activity_CHB[v]
             <<','<<seen2[v]<<','<<toInt(softLits[v]);
        for (int i=0;i<orderHeapAuxi.size();++i) s<<" H"<<orderHeapAuxi[i];
        for (int i=0;i<order_heap_VSIDS.size();++i) s<<" V"<<order_heap_VSIDS[i];
        for (int i=0;i<order_heap_CHB.size();++i) s<<" B"<<order_heap_CHB[i];
        for (int i=0;i<involvedLits.size();++i) s<<" I"<<toInt(involvedLits[i]);
        for (int i=0;i<allSoftLits.size();++i) s<<" S"<<toInt(allSoftLits[i]);
        for (int i=0;i<trail.size();++i) s<<" t"<<toInt(trail[i]);
        for (int i=0;i<trail_lim.size();++i) s<<" l"<<trail_lim[i];
        for (int i=0;i<falseLits.size();++i) s<<" f"<<toInt(falseLits[i]);
        for (int i=0;i<falseLits_lim.size();++i) s<<" F"<<falseLits_lim[i];
        for (int i=0;i<unLockedVars.size();++i) s<<" u"<<unLockedVars[i];
        for (int i=0;i<finalIset.size();++i) s<<" k"<<finalIset[i]<<','<<isetLock[i];
        for (int i=0;i<isets.size();++i) {
            for (int j=0;j<isets[i].size();++j) s<<" c"<<isets[i][j];
            for (int j=0;j<isetsLits[i].size();++j) s<<" p"<<toInt(isetsLits[i][j]);
        }
        for (int v=0;v<nVars();++v) for (int signbit=0;signbit<2;++signbit) {
            Lit key=mkLit(v,signbit!=0);
            for (int kind=0;kind<2;++kind) {
                const vec<Watcher>& list=kind ? watches[key] : watches_bin[key];
                for (int j=0;j<list.size();++j) s<<" w"<<kind<<','<<toInt(key)<<','<<list[j].cref<<','<<toInt(list[j].blocker);
            }
        }
        for (int i=0;i<clauses.size();++i) {
            const Clause& c=ca[clauses[i]];
            s<<" C"<<clauses[i]<<','<<c.mark()<<','<<c.lastPoint();
            for (int j=0;j<c.size();++j) s<<','<<toInt(c[j]);
        }
        return s.str();
    }
    gh26::EngineSnapshot read() {return extract(trailRecord,1,1,offsets);}
};
static bool literal(int p,int assignment) { return bool(assignment&(1<<(p/2)))!=bool(p&1); }
int main() {
    try {
        int cases=0;
        for (int signs=0;signs<8;++signs) for (int covered=0;covered<2;++covered) for (int root=0;root<4;++root) {
            Fixture solver; solver.setup(signs,covered!=0,root);
            std::string before=solver.fingerprint();
            gh26::EngineSnapshot snapshot=solver.read();
            require(snapshot.exported,"adapter unexpectedly declined");
            require(before==solver.fingerprint(),"adapter mutated actual engine state");
            gh26::Stats stats;
            bool strengthened=gh26::strengthenOne(snapshot.model,stats);
            require(strengthened==(covered!=0),"adapter targeted strengthening mismatch");
            int exact=100,models=0;
            for (int a=0;a<16;++a) {
                bool valid=true;
                for (int v=0;v<4;++v) if (snapshot.model.base[v]>=0 && bool(a&(1<<v))!=bool(snapshot.model.base[v])) valid=false;
                for (std::size_t c=0;c<solver.original_hard.size();++c) {
                    bool satisfied=false;
                    for (std::size_t j=0;j<solver.original_hard[c].size();++j) satisfied|=literal(solver.original_hard[c][j],a);
                    valid&=satisfied;
                }
                if (!valid) continue;
                ++models; int original=0,residual=0;
                for (std::size_t j=0;j<solver.original_soft.size();++j) original+=!literal(solver.original_soft[j],a);
                for (std::size_t j=0;j<snapshot.model.soft.size();++j) residual+=!literal(snapshot.model.soft[j],a);
                require(original==residual+snapshot.fixed_search_cost,"adapter fixed root offset mismatch");
                int oldcost=0;
                for (std::size_t j=0;j<snapshot.model.cores[0].members.size();++j) oldcost+=!literal(snapshot.model.cores[0].members[j],a);
                require(oldcost>=snapshot.model.cores[0].weight,"invalid fixture old certificate");
                if (original<exact) exact=original;
            }
            require(models>0,"fixture has no feasible original models");
            int lower=snapshot.base_false+snapshot.core_weight+int(strengthened)+snapshot.fixed_search_cost;
            require(lower<=exact,"scientific adapter LB exceeds original objective");
            require(snapshot.conditional_nogood.empty(),"root fixture produced nonroot nogood");
            // Repeat extraction proves stability without restoring hidden state.
            require(solver.read().exported && before==solver.fingerprint(),"repeated extraction state mismatch");
            std::cout<<"case="<<cases++<<" signs="<<signs<<" covered="<<covered<<" root="<<root
                     <<" strengthened="<<strengthened<<" original_exact="<<exact<<" lower="<<lower<<'\n';
        }
        require(cases==64,"fixture count");
        std::cout<<"READONLY_ADAPTER_64_PASS productionTier0=NOT_RUN learning=NOT_RUN rollback=NOT_RUN\n";
    } catch (const std::exception& e) {
        std::cerr<<e.what()<<'\n'; return 2;
    }
    return 0;
}
