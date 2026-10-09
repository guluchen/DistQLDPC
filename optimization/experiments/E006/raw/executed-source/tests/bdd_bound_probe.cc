// DistQLDPC independent projection/lifetime checks for the actual BDD encoder.
// SPDX-License-Identifier: GPL-3.0-or-later
#include "Solver.h"
#include "UnitBoundBDD.h"
#include <assert.h>
#include <cmath>
#include <algorithm>
#include <set>
#include <tuple>
#include <vector>
using namespace Minisat;
using CNF=std::vector<std::vector<int> >;
class Probe : public Solver {
public:
    Probe(int n) {
        hardWeight=1000;UB=1000;instanceType=1;phase_saving=0;
        for(int i=0;i<n;++i) newVar();
        staticNbVars=n;
    }
    CNF snapshot() const {
        CNF clauses;
        for(int i=0;i<cardinalityC.size();++i) {
            const Clause& c=ca[cardinalityC[i]];
            std::vector<int> row;
            for(int j=0;j<c.size();++j) row.push_back((sign(c[j])?-1:1)*(var(c[j])+1));
            clauses.push_back(row);
        }
        for(int i=0;i<trail.size();++i)
            clauses.push_back({(sign(trail[i])?-1:1)*(var(trail[i])+1)});
        return clauses;
    }
    void relax_and_remove() {
        cancelUntilBeginning(0);
        for(int i=0;i<cardinalityC.size();++i) removeClause(cardinalityC[i]);
        cardinalityC.clear();collectDynVars();
        watches.cleanAll();watches_bin.cleanAll();checkGarbage();
    }
    void tighten_remove() {
        for(int i=0;i<cardinalityC.size();++i) removeClause(cardinalityC[i]);
        cardinalityC.clear();collectDynVars();
        watches.cleanAll();watches_bin.cleanAll();checkGarbage();
    }
    bool unit_propagate() {return propagate()==CRef_Undef;}
};
// Independent SAT extension checker: original/auxiliary variables are ordinary
// Boolean variables; no use of the tested graph to evaluate CNF satisfaction.
static bool sat(const CNF& cnf,std::vector<int> a) {
    bool changed=true;
    while(changed) {
        changed=false;
        for(const auto& c:cnf) {
            bool satisfied=false;int unknown=0,last=0;
            for(int lit:c) {
                int v=abs(lit);
                if(a[v]<0) {++unknown;last=lit;}
                else satisfied|=a[v]==(lit>0);
            }
            if(satisfied)continue;
            if(!unknown)return false;
            if(unknown==1) {a[abs(last)]=last>0;changed=true;}
        }
    }
    int variable=0;
    for(const auto& c:cnf) {
        bool satisfied=false;
        for(int lit:c) if(a[abs(lit)]>=0 && a[abs(lit)]==(lit>0))satisfied=true;
        if(!satisfied)for(int lit:c) if(a[abs(lit)]<0) {variable=abs(lit);break;}
        if(variable)break;
    }
    if(!variable)return true;
    a[variable]=0;if(sat(cnf,a))return true;
    a[variable]=1;return sat(cnf,a);
}
static int count(int assignment,int n,int pattern) {
    int total=0;
    for(int i=0;i<n;++i)total+=bool(assignment&(1<<i)) != (pattern==2 || (pattern==1 && i%2));
    return total;
}
static void project(Probe& s,int n,int k,int pattern) {
    CNF cnf=s.snapshot();
    for(int x=0;x<(1<<n);++x) {
        std::vector<int> a(s.nVars()+1,-1);
        for(int i=0;i<n;++i)a[i+1]=(x>>i)&1;
        assert(sat(cnf,a)==(count(x,n,pattern)<=k));
    }
}
static vec<Lit>* literals(int n,int pattern) {
    vec<Lit>* xs=new vec<Lit>();
    for(int i=0;i<n;++i)xs->push(mkLit(i,pattern==2 || (pattern==1 && i%2)));
    return xs;
}
int main() {
    unsigned checks=0;
    for(int n=0;n<=8;++n)for(int k=-1;k<=n+1;++k) {
        DistQLDPCBDD::Graph g(n,k);
        std::set<std::tuple<int,int,int> > unique;
        for(size_t i=2;i<g.nodes.size();++i) {
            const auto& node=g.nodes[i];
            assert(node.low!=node.high && node.low<int(i) && node.high<int(i));
            assert(unique.insert(std::make_tuple(node.input,node.low,node.high)).second);
        }
        for(int x=0;x<(1<<n);++x) {
            int id=g.root;
            while(id>=2) {const auto& node=g.nodes[id];id=(x&(1<<node.input))?node.high:node.low;}
            assert(bool(id)==(__builtin_popcount(unsigned(x))<=k));++checks;
        }
        if(k>=0 && k<n)for(int pattern=0;pattern<3;++pattern) {
            Probe s(n);auto xs=literals(n,pattern);s.addCardinalityConstraintsBDD(*xs,k);
            project(s,n,k,pattern);
            if(n<=5)for(int partial=0;partial<int(pow(3,n));++partial) {
                int code=partial;std::vector<int> a(s.nVars()+1,-1);
                for(int i=0;i<n;++i){int b=code%3;code/=3;a[i+1]=b==2?-1:b;}
                bool possible=false;
                for(int x=0;x<(1<<n);++x) {
                    bool agrees=true;for(int i=0;i<n;++i)agrees &= a[i+1]<0 || a[i+1]==((x>>i)&1);
                    possible |= agrees && count(x,n,pattern)<=k;
                }
                assert(sat(s.snapshot(),a)==possible);++checks;
            }
            delete xs;
        }
    }
    // Actual root propagation, relaxation/reset/removal, recycling and relocation.
    for(int pattern=0;pattern<3;++pattern) {
        Probe s(6);auto xs=literals(6,pattern);
        for(int k : {0,4,1,5,2,0,3}) {
            s.addCardinalityConstraintsBDD(*xs,k);assert(s.unit_propagate());
            s.garbageCollect();project(s,6,k,pattern);
            s.relax_and_remove();assert(s.snapshot().empty());
            for(int v=0;v<s.nVars();++v)assert(s.value(v)==l_Undef);
        }
        s.addCardinalityConstraintsBDD(*xs,4);assert(s.unit_propagate());
        s.tighten_remove();s.addCardinalityConstraintsBDD(*xs,1);
        assert(s.unit_propagate());s.garbageCollect();project(s,6,1,pattern);
        s.relax_and_remove();delete xs;
    }
    printf("BDD_PROBE_PASS: %u graph/partial checks, production full signed CNF projections, root reset/tighten/relax/recycle/garbage\n",checks);
}
