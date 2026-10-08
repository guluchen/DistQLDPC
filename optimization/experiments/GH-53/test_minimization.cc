// GH53 test-only direct helper fixture. Not linked into production.
// SOURCE ONLY / UNCOMPILED: full weighted-caller coverage remains pending.
#include "solver/Solver.h"
#include <cstdio>
#include <cstdlib>
#include <vector>
using namespace Minisat;

static void require(bool ok, const char* message) {
    if (!ok) { std::fprintf(stderr, "GH53_FIXTURE_FAIL %s\n", message); std::exit(1); }
}

class Probe : public Solver {
public:
    int configuredMode() const { return ccmin_mode; }
    // Intentional test-only mode coverage; constructor default checked first.
    void testMode(int mode) { ccmin_mode = mode; }

    void run(int scenario, bool quasi, int signs) {
        for (int i=0; i<5; ++i) newVar();
        VSIDS = true; // caller activity policy held fixed, not production change
        const Lit a=mkLit(0, signs&1), x=mkLit(1, signs&2),
                  u=mkLit(2, signs&4), z=mkLit(3), y=mkLit(4);
        std::vector<std::vector<Lit> > formula;
        auto reasonClause = [&](std::vector<Lit> c) {
            formula.push_back(c);
            vec<Lit> actual; for (Lit p:c) actual.push(p);
            return ca.alloc(actual, false);
        };
        // Root unit is a genuine premise, never an assumption in entailment.
        formula.push_back({z}); uncheckedEnqueue(z);
        newDecisionLevel(); uncheckedEnqueue(a);
        if (scenario==0) {
            // x is a separate decision with no reason.
            newDecisionLevel(); uncheckedEnqueue(x);
        } else if (scenario==1) {
            uncheckedEnqueue(x, reasonClause({x, ~a}));
        } else if (scenario==2) {
            uncheckedEnqueue(x, reasonClause({x, ~a, ~z}));
        } else {
            uncheckedEnqueue(y, reasonClause({y, ~a}));
            uncheckedEnqueue(x, reasonClause({x, ~y}));
        }
        newDecisionLevel(); uncheckedEnqueue(u);
        // Original conflict clause is falsified by this legal implication trail.
        formula.push_back({~u, ~a, ~x});
        vec<Lit> learned; learned.push(~u); learned.push(~a); learned.push(~x);
        for (int i=0;i<learned.size();++i) seen[var(learned[i])]=1;
        std::vector<int> assignment, levels, reasons, trailBefore;
        for(int v=0;v<nVars();++v) {
            assignment.push_back(toInt(assigns[v]));
            levels.push_back(level(v)); reasons.push_back(reason(v));
        }
        for(int i=0;i<trail.size();++i) trailBefore.push_back(toInt(trail[i]));
        int bt=-1,lbd=-1;
        if(quasi) simplifyQuasiConflictClause(learned,bt,lbd);
        else simplifyConflictClause(learned,bt,lbd);
        const bool retained=scenario==0 || (scenario==3 && ccmin_mode==1);
        require(learned.size()==(retained?3:2), "literal retention/removal");
        require(learned[0]==~u && learned[1]==(scenario==0?~x:~a), "asserting/backtrack literal");
        require(bt==(scenario==0?2:1), "backtrack level");
        require(lbd==(scenario==0?3:2), "exact distinct nonzero levels");
        for(int v=0;v<nVars();++v) {
            require(!seen[v], "seen cleanup");
            require(assignment[v]==toInt(assigns[v]) && levels[v]==level(v)
                    && reasons[v]==int(reason(v)), "assignment/level/reason preserved");
        }
        require(trail.size()==int(trailBefore.size()), "trail size");
        for(int i=0;i<trail.size();++i) require(toInt(trail[i])==trailBefore[i], "trail preserved");
        auto satisfied=[](Lit p, unsigned model) {
            return bool((model>>var(p))&1) != bool(sign(p));
        };
        unsigned models=0;
        for(unsigned model=0;model<(1u<<nVars());++model) {
            bool hard=true;
            for(const auto& c:formula) {
                bool sat=false; for(Lit p:c) sat |= satisfied(p,model);
                hard &= sat;
            }
            if(!hard) continue;
            ++models;
            bool sat=false; for(int i=0;i<learned.size();++i) sat |= satisfied(learned[i],model);
            require(sat,"hard formula entails actual learned clause");
        }
        require(models>0,"nonvacuous formula oracle");
    }
};

int main(int argc,char** argv) {
    require(argc==2,"explicit expected constructor mode required");
    const int expected=std::atoi(argv[1]); require(expected==1 || expected==2,"expected mode1/2");
    unsigned cases=0;
    for(int mode=1;mode<=2;++mode)
        for(int scenario=0;scenario<4;++scenario)
            for(int quasi=0;quasi<2;++quasi)
                for(int signs=0;signs<8;++signs) {
                    Probe p; require(p.configuredMode()==expected,"actual constructor default");
                    p.testMode(mode); p.run(scenario,quasi,signs); ++cases;
                }
    std::printf("GH53_HELPER_IMPLICATION_PASS cases=%u default=%d\n",cases,expected);
    return 0;
}
