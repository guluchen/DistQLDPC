// Calls ORIGINAL/candidate production propagation; never linked into solver binaries.
#include <cstdio>
#include <cstdlib>
#include <type_traits>
#include "Solver.h"
using namespace Minisat;

static void require(bool good, const char* message) {
    if (!good) { std::fprintf(stderr, "FAIL: %s\n", message); std::exit(2); }
}

struct Fixture : Solver {
    Fixture() {
        static_assert(std::is_trivially_copy_assignable<Watcher>::value,
                      "Self-assignment must have no custom side effects");
        for (int v=0; v<80; ++v) newVar(false, false);
        softConflictFlag=false; UBconflictFlag=false; lk_propagations=0;
        newDecisionLevel();
    }
    void assigned(int v, bool truth) {
        assigns[v]=truth ? l_True : l_False;
        vardata[v]=mkVarData(CRef_Undef, decisionLevel());
    }
    CRef clause(int first, int third) {
        vec<Lit> literals;
        literals.push(mkLit(first)); literals.push(~mkLit(0));
        literals.push(mkLit(third));
        CRef cr=ca.alloc(literals, false);
        ca[cr].setLastPoint(2);
        clauses.push(cr); attachClause(cr);
        return cr;
    }
    void emit(unsigned id, CRef result) {
        std::printf("case=%u result=%u false=%d qhead=%d lk=%llu flags=%d,%d trail=",
                    id, unsigned(result), falseVar, qhead,
                    (unsigned long long)lk_propagations, int(softConflictFlag), int(UBconflictFlag));
        for (int i=0;i<trail.size();++i) std::printf("%d,",toInt(trail[i]));
        std::printf("\n");
        for (int v=0;v<nVars();++v) {
            std::printf("v%d=%d reason=%u level=%d\n",v,toInt(assigns[v]),
                        unsigned(vardata[v].reason),vardata[v].level);
            for (int signbit=0;signbit<2;++signbit) {
                Lit p=mkLit(v,signbit!=0);
                vec<Watcher>& ws=watches[p];
                std::printf("w%d:",toInt(p));
                for (int i=0;i<ws.size();++i)
                    std::printf("%u/%d,",unsigned(ws[i].cref),toInt(ws[i].blocker));
                vec<Watcher>& bins=watches_bin[p];
                std::printf(" bin:");
                for (int i=0;i<bins.size();++i)
                    std::printf("%u/%d,",unsigned(bins[i].cref),toInt(bins[i].blocker));
                std::printf("\n");
            }
        }
        for (int i=0;i<clauses.size();++i) {
            Clause& c=ca[clauses[i]];
            std::printf("clause%u mark=%d",unsigned(clauses[i]),int(c.mark()));
            if (c.mark()!=1) {
                std::printf(" point=%u:",c.lastPoint());
                for (int j=0;j<c.size();++j) std::printf("%d,",toInt(c[j]));
            }
            std::printf("\n");
        }
    }
    void scenario(unsigned id, bool soft, int moved, int kept, int tail, bool deleted) {
        // Every clause's second watch is ~p. All setup assignments precede p.
        if (deleted) { CRef dead=clause(70,71); removeClause(dead); }
        for (int i=0;i<moved;++i) {
            int v=3+2*i; assigned(v,false); clause(v,v+1);
        }
        for (int i=0;i<kept;++i) { assigned(10+i,true); clause(10+i,20+i); }
        assigned(2,false);
        if (soft) softLits[1]=~mkLit(1); else assigned(1,false);
        CRef conflict=clause(1,2);
        for (int i=0;i<tail;++i) clause(30+i,30+i+tail);
        const CRef old_conflict=conflict;
        garbageCollect();
        conflict=clauses[moved+kept];
        require(ca.wasted()==0,"GC discards deleted allocation");
        require(!deleted || conflict!=old_conflict,"deleted prefix forces actual CRef relocation");
        const uint64_t prior=lk_propagations;
        uncheckedEnqueue(mkLit(0));
        CRef result=propagateForLK();
        require(result==(soft ? CRef_Undef : conflict),"same conflict return");
        require(falseVar==(soft ? 1 : var_Undef),"same failed soft variable");
        require(qhead==trail.size(),"pending propagation ends at conflict");
        require(lk_propagations==prior+1,"one propagated queued literal");
        vec<Watcher>& retained=watches[mkLit(0)];
        require(retained.size()==kept+1+tail,"compaction retains exact suffix length");
        require(retained[kept].cref==conflict,"conflict watch remains before tail");
        for (int i=0;i<moved;++i)
            require(watches[~mkLit(4+2*i)].size()==1,"moved prefix watch kept in destination");
        require(!soft || value(mkLit(1))==l_True,"soft failure retains queued implication");
        garbageCollect();
        if (soft) require(vardata[1].reason==clauses[moved+kept],"GC relocates enqueued soft reason");
        emit(id,soft ? CRef_Undef : clauses[moved+kept]);
    }
};

int main() {
    const int tails[]={0,1,2,7,23};
    unsigned id=0;
    for (int soft=0;soft<2;++soft)
        for (int moved=0;moved<3;++moved)
            for (int kept=0;kept<2;++kept)
                for (int deleted=0;deleted<2;++deleted)
                    for (unsigned t=0;t<sizeof(tails)/sizeof(tails[0]);++t) {
                        Fixture f;
                        f.scenario(id++,soft!=0,moved,kept,tails[t],deleted!=0);
                    }
    return 0;
}
