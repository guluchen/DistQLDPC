// Test-only calls to production Solver functions; never linked into timed binaries.
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include "Solver.h"
using namespace Minisat;
#ifndef EXPECT_SYMMETRIC
#error Compile this test with EXPECT_SYMMETRIC=0 for baseline or =1 for candidate
#endif
static void require(bool good, const char* message) {
    if (!good) { std::fprintf(stderr,"FAIL: %s\n",message); std::exit(2); }
}
struct Fixture : Solver {
    void exercise(unsigned id, bool vsids, bool reverse, unsigned signs,
                  bool soft, bool last, double increment, int mode) {
        VSIDS=vsids; cardinalityEncMode=mode;
        for (int i=0;i<4;++i) newVar(false,false);
        var_inc=increment;
        double before[4];
        for (int i=0;i<4;++i) {
            before[i]=activity_VSIDS[i]=double(i)*0.25;
            order_heap_VSIDS.insert(i);
        }
        softConflictFlag=false; UBconflictFlag=false; lk_propagations=0;
        trailRecord=0; qhead=0; hardWeight=10;
        Lit p=mkLit(1,(signs&1)!=0), q=mkLit(2,(signs&2)!=0);
        vec<Lit> hard; hard.push(~p); hard.push(~q);
        require(addClause_(hard,10),"hard binary clause accepted");
        if (soft) { softLits[1]=p; softLits[2]=q; }
        require(uncheckedEnqueueForLK(reverse?q:p),"first lookahead enqueue");
        require(uncheckedEnqueueForLK(reverse?p:q),"second lookahead enqueue");
        CRef conflict=propagateForLK();
        require(conflict==CRef_Bin && falseVar==var_Undef,"actual binary hard conflict");
        int first=var(binConfl[0]), second=var(binConfl[1]);
        require(first!=second && (first==1 || first==2) && (second==1 || second==2),
                "two distinct conflicting variables");
        isetsLits.init(0); isetsLits[0].clear();
        vec<Lit> learnt;
        lookbackResetTrail(conflict,var_Undef,0,learnt,last);
        for (int i=0;i<4;++i) {
            double delta=0;
            if (vsids) {
                if (EXPECT_SYMMETRIC && mode==CARD_ENC_MTO) delta=(i==first || i==second)?increment*.1:0;
                else delta=(i==first)?increment*.2:0;
            }
            require(std::fabs(activity_VSIDS[i]-before[i]-delta)<1e-12,
                    "expected production activity delta");
            require(assigns[i]==l_Undef && !seen[i],"assignments and seen restored");
        }
        require(trail.size()==0 && qhead==0,"lookahead trail restored");
        require(isetsLits[0].size()==2 && learnt.size()==3,"two-assumption conflict explanation");
        require(isetsLits[0][0]==(reverse?p:q) && isetsLits[0][1]==(reverse?q:p),
                "explanation contains the two actual assumptions");
        require(learnt[1]==~isetsLits[0][0] && learnt[2]==~isetsLits[0][1],
                "explanation negates the two conflicting assumptions");
        require(clauses.size()==1 && ca[clauses[0]].size()==2,"hard clause preserved");
        double previous=1e10;
        for(int i=0;i<4;++i) {
            int v=order_heap_VSIDS.removeMin();
            require(activity_VSIDS[v]<=previous+1e-12,"activity heap order preserved");
            previous=activity_VSIDS[v];
        }
        // Exclude the intentionally different heuristic activities from state trace.
        std::printf("case=%u mode=%d vsids=%d first=%d second=%d trail=%d qhead=%d iset=",
                    id,mode,int(vsids),first,second,trail.size(),qhead);
        for(int i=0;i<isetsLits[0].size();++i) std::printf("%d,",toInt(isetsLits[0][i]));
        std::printf(" learnt=");
        // Slot0 is the reserved UIP placeholder, not an explanation literal
        // on this two-assumption path. Compare only populated explanation slots.
        for(int i=1;i<learnt.size();++i) std::printf("%d,",toInt(learnt[i]));
        std::printf("\n");
    }
};
int main() {
    unsigned id=0;
    for(int mode=0;mode<5;++mode)
    for(int vsids=0;vsids<2;++vsids) for(int reverse=0;reverse<2;++reverse)
    for(unsigned signs=0;signs<4;++signs) for(int soft=0;soft<2;++soft)
    for(int last=0;last<2;++last) for(int scale=0;scale<2;++scale) {
        Fixture fixture;
        fixture.exercise(id++,vsids,reverse,signs,soft,last,scale?2.5:1.0,mode);
    }
    require(id==640,"fixture count");
    std::puts("PASS: 640 production binary-conflict activity and rollback fixtures");
}
