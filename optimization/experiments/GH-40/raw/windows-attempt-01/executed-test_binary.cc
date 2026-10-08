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
    void scenario(unsigned id,int state,bool soft) {
        if(state!=2) assigned(1,state==1);
        if(soft && state==2) softLits[1]=~mkLit(1);
        vec<Lit> lits;lits.push(~mkLit(0));lits.push(mkLit(1));
        CRef cr=ca.alloc(lits,false);clauses.push(cr);attachClause(cr);
        uncheckedEnqueue(mkLit(0));
        CRef result=propagateForLK();
        require(result==(state==0 ? CRef_Bin : CRef_Undef),"binary independent conflict oracle");
        require(falseVar==(soft && state==2 ? 1 : var_Undef),"binary soft falseVar oracle");
        require(lk_propagations==uint64_t(state==0 || (soft && state==2) ? 0 : state==2 ? 2 : 1),"unchanged early binary return counter");
        if(result==CRef_Bin) std::printf("bin=%d,%d\n",toInt(binConfl[0]),toInt(binConfl[1]));
        emit(id,result);
    }
};
int main() {
    unsigned id=0;
    for(int state=0;state<3;++state)for(int soft=0;soft<2;++soft){
        Fixture f;f.scenario(id++,state,soft!=0);
    }
    require(id==6,"fixed binary fixture count");return 0;
}
