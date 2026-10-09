// Test-only actual production propagation; never included in solver binaries.
#include <cstdio>
#include <cstdlib>
#include "Solver.h"
using namespace Minisat;
static void need(bool b, const char* s) {
    if (!b) { std::fprintf(stderr,"FAIL %s\n",s); std::exit(2); }
}
struct Probe : Solver {
    Probe() {
        for (int v=0;v<16;++v) newVar(false,false);
        softConflictFlag=false; UBconflictFlag=false; lk_propagations=0;
        newDecisionLevel();
    }
    void fact(int v, bool positive) { uncheckedEnqueue(mkLit(v,!positive)); }
    CRef add(int a,int b) {
        vec<Lit> x; x.push(mkLit(a)); x.push(~mkLit(0)); x.push(mkLit(b));
        CRef r=ca.alloc(x,false); ca[r].setLastPoint(2);
        clauses.push(r); attachClause(r); return r;
    }
    void setup(int action,int a,int b) {
        if (action==0) fact(a,true);
        if (action==1 || action==4) fact(a,false);
        if (action>=3) fact(b,false);
        if (action==5) softLits[a]=~mkLit(a);
    }
    void transcript(int id,CRef result) {
        std::printf("case=%d result=%u false=%d qhead=%d lk=%llu flags=%d,%d ca=%u,%u trail=",
          id,unsigned(result),falseVar,qhead,(unsigned long long)lk_propagations,
          int(softConflictFlag),int(UBconflictFlag),ca.size(),ca.wasted());
        for(int k=0;k<trail.size();++k) std::printf("%d,",toInt(trail[k]));
        std::printf("\n");
        for(int v=0;v<nVars();++v) {
            std::printf("v%d=%d/%u/%d seen=%d soft=%d lock=%d\n",v,toInt(assigns[v]),
              unsigned(vardata[v].reason),vardata[v].level,int(seen[v]),
              toInt(softLits[v]),inConflicts[v]);
            for(int sg=0;sg<2;++sg) {
                Lit p=mkLit(v,sg!=0); std::printf("w%d:",toInt(p));
                vec<Watcher>& w=watches[p];
                for(int j=0;j<w.size();++j) std::printf("%u/%d,",unsigned(w[j].cref),toInt(w[j].blocker));
                std::printf(" bin:");
                vec<Watcher>& bw=watches_bin[p];
                for(int j=0;j<bw.size();++j) std::printf("%u/%d,",unsigned(bw[j].cref),toInt(bw[j].blocker));
                std::printf("\n");
            }
        }
        for(int j=0;j<clauses.size();++j) {
            CRef r=clauses[j]; Clause& c=ca[r];
            std::printf("clause%u=%d",unsigned(r),int(c.mark()));
            if(c.mark()!=1) { std::printf("/%u:",c.lastPoint());
                for(int k=0;k<c.size();++k) std::printf("%d,",toInt(c[k])); }
            std::printf("\n");
        }
        std::printf("unlocked:");
        for(int j=0;j<unLockedVars.size();++j) std::printf("%d,",unLockedVars[j]);
        std::printf("\n");
    }
    void run(int id,int length,int a,int b,bool deleted,bool gc) {
        if(deleted) { CRef d=add(13,14); removeClause(d); }
        if(length>0) { setup(a,1,2); add(1,2); }
        if(length>1) { setup(b,3,4); add(3,4); }
        if(length>2) { fact(5,true); add(5,6); }
        CRef oldFirst=length ? clauses[deleted?1:0] : CRef_Undef;
        if(gc) {
            garbageCollect();
            need(ca.wasted()==0,"GC waste cleared");
            if(deleted && length) need(clauses[0]!=oldFirst,"actual live CRef relocation");
        }
        // Setup facts are valid queued assignments; only p is pending for this call.
        qhead=trail.size(); fact(0,true);
        const int baseTrail=trail.size();
        CRef expected=CRef_Undef; int expectedSoft=var_Undef, units=0;
        bool stopped=false;
        const int acts[]={a,b,0};
        const int count=length;
        for(int j=0;j<count;++j) {
            if(stopped) continue;
            int action=acts[j], v=1+2*j;
            // Independent residual formula: (v OR tail), since p=true.
            // true satisfies; undefined tail permits a moved watch;
            // false tail forces v, or contradicts false v.
            if(action==4) { expected=clauses[j+(deleted&&!gc?1:0)]; stopped=true; }
            if(action==3 || action==5) {
                ++units;
                if(action==5) { expectedSoft=v; stopped=true; }
            }
        }
        CRef result=propagateForLK();
        need(result==expected,"independent hard conflict");
        need(falseVar==expectedSoft,"independent soft failure");
        need(trail.size()==baseTrail+units,"exact implied trail growth");
        need(qhead==trail.size(),"all pending work consumed or stopped");
        need(lk_propagations==uint64_t(1+((stopped)?0:units)),"exact propagation count");
        stopped=false; int moved=0;
        for(int j=0;j<count;++j) {
            int action=acts[j], v=1+2*j;
            if(!stopped && (action==1 || action==2)) {
                ++moved;
                need(watches[~mkLit(v+1)].size()==1,"moved destination");
            }
            if(!stopped && (action==3 || action==5)) {
                need(value(mkLit(v))==l_True,"formula unit implication");
                need(vardata[v].reason==clauses[j+(deleted&&!gc?1:0)],"unit reason");
            }
            if(!stopped && (action==4 || action==5)) stopped=true;
        }
        need(watches[mkLit(0)].size()==count-moved,"retained watch count/dead cleanup");
        need(unLockedVars.size()==0,"unlocked list unchanged for unlocked soft failure");
        transcript(id,result);
    }
};
int main() {
    int id=0;
    for(int deleted=0;deleted<2;++deleted) for(int gc=0;gc<2;++gc) {
        { Probe p; p.run(id++,0,0,0,deleted!=0,gc!=0); }
        for(int a=0;a<6;++a) { Probe p; p.run(id++,1,a,0,deleted!=0,gc!=0); }
        for(int n=2;n<=3;++n) for(int a=0;a<6;++a) for(int b=0;b<6;++b) {
            Probe p; p.run(id++,n,a,b,deleted!=0,gc!=0);
        }
    }
    need(id==316,"preregistered case count");
    std::printf("PREFETCH_FIXTURE_COMPLETE cases=%d\n",id);
    return 0;
}
