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
    void scenario(unsigned id, int size, int point, int firstState,
                  int tailState, bool reverse, bool staleBlocker,
                  bool negativeTail, bool deleted, bool gc, bool soft) {
        if (deleted) { CRef dead=clause(70,71); removeClause(dead); }
        assigned(9,false);
        if (firstState!=2) assigned(1,firstState==1);
        if (tailState!=2) assigned(2,(tailState==1)!=negativeTail);
        // Additional generic-clause candidates are false; size3 has only c[2].
        for (int v=3;v<size;++v) assigned(v,false);
        if (soft && firstState==2) softLits[1]=~mkLit(1);
        vec<Lit> lits;
        lits.push(reverse ? ~mkLit(0) : mkLit(1));
        lits.push(reverse ? mkLit(1) : ~mkLit(0));
        lits.push(mkLit(2,negativeTail));
        for (int v=3;v<size;++v) lits.push(mkLit(v));
        CRef cr=ca.alloc(lits,false); clauses.push(cr); attachClause(cr);
        ca[cr].setLastPoint(point);
        if (staleBlocker) {
            vec<Watcher>& ws=watches[mkLit(0)];
            int targets=0;
            for(int wi=0;wi<ws.size();++wi) if(ws[wi].cref==cr) {
                ws[wi].blocker=mkLit(9); ++targets;
            }
            require(targets==1,"one live target watcher among possibly dirty dead entries");
        }
        if (gc) { garbageCollect(); cr=clauses[0]; }
        uncheckedEnqueue(mkLit(0));
        CRef result=propagateForLK();
        const bool conflict=firstState==0 && tailState==0;
        const bool softFail=soft && firstState==2 && tailState==0;
        require(result==(conflict ? cr : CRef_Undef),"independent conflict oracle");
        require(falseVar==(softFail ? 1 : var_Undef),"independent soft-failure oracle");
        if (firstState!=1 && tailState==2) {
            require(ca[cr][1]==mkLit(2,negativeTail),"undefined tail is new watch");
            require(ca[cr].lastPoint()==3,"undefined index2 advances point3");
        }
        if (firstState!=1 && tailState==1)
            require(ca[cr].lastPoint()==2,"true index2 retains point2");
        if (firstState!=1 && tailState==0)
            require(ca[cr].lastPoint()==unsigned(point>size ? 2 : point),
                    "false tail preserves normalized point");
        // Pending literal0 always processed; implication1 adds one propagation
        // except genuine failed-soft or hard conflict which terminates it.
        require(qhead==trail.size(),"all queued propagation processed or aborted");
        require(lk_propagations==uint64_t(firstState==2 && tailState==0 && !soft ? 2 : 1),
                "independent propagated-literal count");
        emit(id,result);
    }
};
int main() {
    unsigned id=0;
    for (int size=3;size<=5;++size)
      for (int pi=0;pi<3;++pi)
       for (int first=0;first<3;++first)
        for (int tail=0;tail<3;++tail)
         for (int flags=0;flags<64;++flags) {
          Fixture f;
          f.scenario(id++,size,pi==2 ? size+1 : pi+2,first,tail,
                     flags&1,flags&2,flags&4,flags&8,flags&16,flags&32);
         }
    require(id==5184,"fixed exhaustive fixture count");
    return 0;
}
