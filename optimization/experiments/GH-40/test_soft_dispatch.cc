// Test-only soft-lock ternary dispatch fixture against actual production propagation.
// Neither this file nor its state setup is linked into scientific binaries.
#include <cstdio>
#include <cstdlib>
#include "Solver.h"
using namespace Minisat;
static void require(bool ok, const char* why) {
    if (!ok) { std::fprintf(stderr, "FAIL: %s\n", why); std::exit(2); }
}
struct Fixture : Solver {
    Fixture() {
        for (int v=0;v<12;++v) newVar(false,false);
        lk_propagations=0;
        softConflictFlag=false;
        UBconflictFlag=false;
    }
    void run(unsigned id, int kind, bool negative, int depth, bool cursor3,
             bool alias, bool emptyCore, bool initialUB) {
        UBconflictFlag=initialUB;
        for (int k=0;k<depth;++k) newDecisionLevel();
        uncheckedEnqueue(mkLit(11));
        const int oldTrail=trail.size(), oldHead=qhead;
        Lit p=mkLit(0,negative);
        if (kind!=0) softLits[0]=(kind==1 ? p : ~p);
        for (int v=1;v<=5;++v) {
            softLits[v]=mkLit(v);
            activityLB[v]=double(v)/10;
        }
        orderHeapAuxi.clear();
        insertAuxiVarOrder(4); // Already present; repeated insert must stay harmless.
        assigns[3]=l_True;
        vardata[3]=mkVarData(CRef_Undef,decisionLevel());
        finalIset.push(0); finalIset.push(0);
        isetLock.push(kind==4 ? 1 : kind==5 ? 2 : 0); isetLock.push(0);
        isets.init(1); isetsLits.init(1);
        if (!emptyCore) {
            isets[0].push(0); isets[0].push(1);
            isetsLits[0].push(mkLit(1)); isetsLits[0].push(mkLit(2));
            isetsLits[0].push(mkLit(3));
            isetsLits[1].push(mkLit(2)); isetsLits[1].push(mkLit(4));
            isetsLits[1].push(mkLit(5));
        }
        if (kind>=3) inConflicts[0]=alias ? 1 : 0;
        vec<Lit> reasonLits;
        assigns[6]=l_False; vardata[6]=mkVarData(CRef_Undef,decisionLevel());
        reasonLits.push(p); reasonLits.push(~mkLit(11)); reasonLits.push(mkLit(6));
        CRef reasonRef=ca.alloc(reasonLits,false); clauses.push(reasonRef); attachClause(reasonRef); ca[reasonRef].setLastPoint(cursor3 ? 3 : 2);
        const uint64_t oldLK=lk_propagations;
        const bool oldSoft=softConflictFlag, oldUB=UBconflictFlag;
        CRef propagated=propagateForLK();
        require(propagated==CRef_Undef,"soft dispatch returns no hard conflict");
        bool result=falseVar==var_Undef;
        require(falseVar==(kind==2 || kind==3 ? 0 : var_Undef),"soft dispatch falseVar");
        require(result==(kind!=2 && kind!=3),"original soft-violation return");
        require(value(p)==l_True,"assignment happens before possible false return");
        require(trail.size()==oldTrail+1 && trail.last()==p,"exact append order");
        require(vardata[0].reason==reasonRef,"exact reason");
        require(vardata[0].level==decisionLevel()+1,"lookahead level");
        require(qhead==trail.size() && lk_propagations==oldLK+(result ? 2 : 1),"propagation processes source and successful implication");
        require(softConflictFlag==oldSoft && UBconflictFlag==oldUB,"flags preserved");
        require(unLockedVars.size()==(kind>=4 ? 1 : 0),"only locked soft violation unlocks");
        if (kind>=4) require(unLockedVars[0]==0,"exact unlocked variable");
        require(isetLock[0]==(kind==5 ? 1 : 0),"lock decremented once only when locked");
        for (int v=1;v<=5;++v) {
            bool expected=v==4 || (kind==4 && !emptyCore && v!=3);
            require(orderHeapAuxi.inHeap(v)==expected,"zero-lock inserts undefined core members");
        }
        std::printf("case=%u result=%d head=%d flags=%d,%d lk=%llu trail=",id,int(result),qhead,
                    int(softConflictFlag),int(UBconflictFlag),(unsigned long long)lk_propagations);
        for (int k=0;k<trail.size();++k) std::printf("%d,",toInt(trail[k]));
        std::printf(" unlocked=");
        for (int k=0;k<unLockedVars.size();++k) std::printf("%d,",unLockedVars[k]);
        std::printf(" heap=");
        for (int k=0;k<orderHeapAuxi.size();++k) std::printf("%d,",orderHeapAuxi[k]);
        std::printf("\n");
        for (int v=0;v<nVars();++v)
            std::printf("v%d=%d reason=%u level=%d soft=%d conflict=%d\n",v,toInt(assigns[v]),
                        unsigned(vardata[v].reason),vardata[v].level,toInt(softLits[v]),inConflicts[v]);
        for (int k=0;k<finalIset.size();++k) {
            std::printf("core%d root=%d lock=%d members=",k,finalIset[k],isetLock[k]);
            for (int j=0;j<isets[k].size();++j) std::printf("%d,",isets[k][j]);
            std::printf(" lits=");
            for (int j=0;j<isetsLits[k].size();++j) std::printf("%d,",toInt(isetsLits[k][j]));
            std::printf("\n");
        }
    }
};
int main() {
    unsigned id=0;
    for (int kind=0;kind<6;++kind)
        for (int sign=0;sign<2;++sign)
            for (int depth=0;depth<3;++depth)
                for (int reason=0;reason<2;++reason)
                    for (int alias=0;alias<2;++alias)
                        for (int empty=0;empty<2;++empty) {
                            if (kind>=4 && empty) continue; // Do not invent an empty locked core.
                            for (int initialUB=0;initialUB<2;++initialUB) {
                                Fixture f;
                                f.run(id++,kind,sign!=0,depth,reason!=0,alias!=0,empty!=0,initialUB!=0);
                            }
                        }
    return 0;
}
