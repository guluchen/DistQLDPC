// GH63 test only. Source prepared; UNCOMPILED. Never linked into production.
#include "solver/Solver.h"
#include <cstdio>
#include <cstdlib>
#include <limits>
using namespace Minisat;

static void need(bool ok, const char* label) {
    if (!ok) { std::fprintf(stderr, "GH63_STATE_FAIL %s\n", label); std::exit(1); }
}
class Probe : public Solver {
public:
    Probe() { for (int i=0;i<8;++i) newVar(); }
    void reset(uint64_t seed,int pattern,int a,int b) {
        counter=seed;
        for(int i=0;i<seen2.size();++i)
            seen2[i]=pattern==0 ? 0 : pattern==1 ? seed+uint64_t(1)
                : pattern==2 ? seed : (i%2 ? seed+uint64_t(1) : uint64_t(i));
        for(int i=0;i<vardata.size();++i) vardata[i].level=i%2 ? b : a;
    }
    template<class V> int actual(const V& c) { return computeLBD(c); }
    template<class V> int original(const V& c) {
        int lbd=0; counter++;
        for(int i=0;i<c.size();i++) {
            int l=level(var(c[i]));
            if(l!=0 && seen2[l]!=counter) { seen2[l]=counter; lbd++; }
        }
        return lbd;
    }
    void same(const Probe& r) const {
        need(counter==r.counter,"counter");
        need(seen2.size()==r.seen2.size(),"stamp-size");
        for(int i=0;i<seen2.size();++i) need(seen2[i]==r.seen2[i],"whole-stamp");
        need(vardata.size()==r.vardata.size(),"vardata-size");
        for(int i=0;i<vardata.size();++i) {
            need(vardata[i].level==r.vardata[i].level,"level");
            need(vardata[i].reason==r.vardata[i].reason,"reason");
        }
    }
    // Test-only shared-marker interleaving, NOT binRes entailment certification.
    void marker(int step) {
        counter++;
        seen2[step%seen2.size()]=counter;
        seen2[(step+1)%seen2.size()]=counter-uint64_t(1);
    }
};
int main() {
    const uint64_t top=std::numeric_limits<uint64_t>::max();
    const uint64_t seeds[]={0,1,17,top-2,top-1,top};
    const int sizes[]={2,0,1,4,2,1};
    Probe actual,reference;
    int calls=0;
    for(int seed=0;seed<6;++seed) for(int pattern=0;pattern<4;++pattern)
    for(int a=0;a<6;++a) for(int b=0;b<6;++b)
    for(int signs=0;signs<4;++signs) for(int container=0;container<2;++container) {
        actual.reset(seeds[seed],pattern,a,b);
        reference.reset(seeds[seed],pattern,a,b);
        for(int step=0;step<6;++step) {
            vec<Lit> literals;
            for(int i=0;i<sizes[step];++i) literals.push(mkLit(i, bool(signs&(1<<(i%2)))));
            int got,want;
            if(container==0) {
                got=actual.actual(literals); want=reference.original(literals);
            } else {
                ClauseAllocator allocator;
                CRef cr=allocator.alloc(literals,false);
                Clause& clause=allocator[cr];
                got=actual.actual(clause); want=reference.original(clause);
                need(clause.size()==literals.size(),"clause-size");
                for(int i=0;i<clause.size();++i) need(clause[i]==literals[i],"clause-literals");
            }
            need(got==want,"return"); actual.same(reference);
            need(literals.size()==sizes[step],"vec-size");
            for(int i=0;i<literals.size();++i)
                need(literals[i]==mkLit(i,bool(signs&(1<<(i%2)))),"vec-literals");
            actual.marker(step); reference.marker(step); actual.same(reference);
            ++calls;
        }
    }
    need(calls==41472,"finite-call-count");
    std::printf("GH63_LBD_STATE_PASS calls=%d containers=2 full_stamps=1\n",calls);
    return 0;
}
