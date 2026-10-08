// GH-17 public production-path fixture. Not linked into application binaries.
#include <cstdio>
#include <cstdlib>
#include "mtl/Vec.h"
#include "mtl/Heap.h"
#include "mtl/Alg.h"
#include "utils/Options.h"
#include "SolverTypes.h"
#include "Solver.h"

using namespace Minisat;

class FixtureSolver : public Solver {
public:
    const vec<char>& seenFlags() const { return seen; }
};

static void require(bool condition, const char* message) {
    if (!condition) { std::fprintf(stderr, "FAIL: %s\n", message); std::exit(2); }
}

struct Fixture {
    FixtureSolver solver;
    int count;
    vec<int> scratch;
    Fixture() : count(0) {
        for (int i=0; i<12; ++i) {
            Var v=solver.newVar(false, false);
            solver.softLits[v]=mkLit(v);
        }
    }
    void add(unsigned mask) {
        solver.isetsLits.init(count);
        solver.isetsLits[count].clear();
        for (int v=0; v<8; ++v)
            if (mask & (1u<<v)) solver.isetsLits[count].push(mkLit(v));
#ifdef GH17_BASELINE
        solver.setConflict(count);
#else
        solver.setConflict(count, scratch);
#endif
    }
    void emit(unsigned fixture, unsigned step) {
        std::printf("%u:%u n=%d owners=", fixture, step, count);
        for (int v=0; v<solver.inConflicts.size(); ++v) std::printf("%d,", solver.inConflicts[v]);
        std::printf(" seen=");
        for (int v=0;v<solver.seenFlags().size();++v) std::printf("%d,",int(solver.seenFlags()[v]));
        std::printf(" unlocked=");
        for (int v=0;v<solver.unLockedVars.size();++v) std::printf("%d,",solver.unLockedVars[v]);
        for (int k=0; k<count; ++k) {
            std::printf(" core%d rep%d lock%d ids=",k,solver.finalIset[k],solver.isetLock[k]);
            // vec2 has no const operator[]; only inspect this test fixture here.
            Solver& s=solver;
            for (int j=0; j<s.isets[k].size(); ++j) std::printf("%d,",s.isets[k][j]);
            std::printf(" lits=");
            for (int j=0; j<s.isetsLits[k].size(); ++j) std::printf("%d,",toInt(s.isetsLits[k][j]));
        }
        std::printf("\n");
    }
};

int main() {
    {
        Fixture f;
        f.add(3); f.add(12); f.add(22); // {0,1}, {2,3}, {1,2,4}
        require(f.count==3,"three cores retained");
        require(f.solver.isetLock[2]==3,"two distinct core weights merged");
        require(f.solver.finalIset[0]==2 && f.solver.finalIset[1]==2,"both old roots remapped");
        require(f.solver.isets[2].size()==3,"new plus two old core identifiers");
        require(f.solver.isetsLits[2].size()==1 && var(f.solver.isetsLits[2][0])==4,"only new variable retained");
        f.add(41); // {0,3,5}: both old variables belong to the same merged core
        require(f.solver.isetLock[3]==4,"same component not counted twice");
        f.add(0); // oldset must clear after a nonempty merge
        require(f.solver.isets[4].size()==1 && f.solver.isetLock[4]==1,"empty core contains no stale scratch");
        f.add(64); // {6}, disjoint after empty call
        require(f.solver.isets[5].size()==1,"disjoint core remains disjoint");
        f.solver.unLockedVars.push(0);
        f.add(144); // {4,7}, unlock increment on old representative before merging
        require(f.solver.unLockedVars.size()==0 && f.solver.isetLock[6]==6,"unlock increment preserved");
        f.emit(99999,0);
        f.solver.resetConflicts(f.count); f.count=0;
        for (int v=0;v<8;++v) require(f.solver.inConflicts[v]==NON,"reset removed all owners");
        f.add(1); f.add(3);
        require(f.solver.isetLock[1]==2,"restart with reused scratch has fresh weight");
        f.emit(99999,1);
    }
    // All length-three sequences of four-variable cores, including empty cores.
    // Byte-compare traces against the ORIGINAL production method, not a copied
    // implementation. Manual assertions above give separate invariant checks.
    for (unsigned seq=0;seq<4096;++seq) {
        Fixture f;
        for (unsigned step=0;step<3;++step) {
            f.add((seq>>(4*step)) & 15u);
            f.emit(seq,step);
        }
    }
    return 0;
}
