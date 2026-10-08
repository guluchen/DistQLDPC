// Test-only check of the observer against the ACTUAL original Vec implementation.
// Not a replacement for Solver lifetime/scientific checks or timing evidence.
#include "mtl/Vec.h"
#include "GH46AllocationDiagnostic.h"
#include <cstdio>
#include <cstdlib>
using namespace Minisat;
static void require(bool ok,const char* message) {
    if(!ok) { std::fprintf(stderr,"FAIL: %s\n",message); std::exit(2); }
}
static void check(const int* sizes,int count) {
    GH46AllocationCounts local,retained;
    vec<int> reuse;
    for(int call=0;call<count;++call) {
        {
            vec<int> fresh;
            GH46AllocationScope observe(local,&fresh);
            for(int i=0;i<sizes[call];++i) fresh.push(i);
        }
        reuse.clear();
        {
            GH46AllocationScope observe(retained,&reuse);
            for(int i=0;i<sizes[call];++i) reuse.push(i);
        }
    }
    require(local.predicted_growths==retained.growths,"predicted count equals actual retained growth");
    require(local.predicted_capacity==reuse.capacity(),"predicted capacity equals actual retained Vec");
    require(local.predicted_requested_bytes==retained.requested_bytes,"predicted bytes equal actual retained requests");
    require(local.calls==uint64_t(count) && retained.calls==uint64_t(count),"call count");
    require(!gh46_active_allocation,"RAII active pointer restored");
}
int main() {
    const int boundary[]={5,7,0,3,12,1};check(boundary,6);
    // Exhaust all three-call sizes 0..15; includes growth boundaries, shrink/clear,
    // and empty calls. Both sides use original Vec; only the first is simulated.
    for(int a=0;a<16;++a) for(int b=0;b<16;++b) for(int c=0;c<16;++c) {
        int sizes[]={a,b,c};check(sizes,3);
    }
    std::puts("PASS: 4097 exact Vec allocation predictions including within-capacity transitions");
}
