// Independent exhaustive checks for the one-call warm-start experiment.
// SPDX-License-Identifier: GPL-3.0-or-later
#define main distqldpc_application_main
#include "../src/core/distqldpc.cc"
#undef main
#include <assert.h>

static std::vector<uint8_t> bits(int value, int n) {
    std::vector<uint8_t> a(n);
    for (int i=0;i<n;++i) a[i]=(value>>i)&1;
    return a;
}
static int oracle(const DistWarm::Formula& f, const std::vector<uint8_t>& a) {
    int cost=0;
    for (size_t i=0;i<f.clauses.size();++i) {
        bool sat=false;
        for (size_t j=0;j<f.clauses[i].lits.size();++j) {
            int l=f.clauses[i].lits[j];
            sat |= l>0 ? a[l-1]!=0 : a[-l-1]==0;
        }
        if (!sat && f.clauses[i].hard) return -1;
        cost += !sat;
    }
    return cost;
}
static Matrix matrix(int n, const std::vector<int>& rows) {
    Matrix m; m.cols=n; m.rows=int(rows.size());
    for (size_t r=0;r<rows.size();++r)
        for (int i=0;i<n;++i) m.data.push_back((rows[r]>>i)&1);
    return m;
}
int main() {
    // Kept active even though production engine objects use -DNDEBUG.
    DistWarm::Rng rng(173);
    int witnesses=0;
    for (int t=0;t<250;++t) {
        DistWarm::Formula f; f.vars=4; f.hard_score=6;
        for (int c=0;c<8;++c) {
            DistWarm::Clause clause; clause.hard=c<5;
            int len=rng.next()%4;
            for (int j=0;j<len;++j) {
                int v=int(rng.next()%4)+1;
                clause.lits.push_back(rng.next()%2 ? v : -v);
            }
            f.clauses.push_back(clause); // duplicates, tautologies, empty clauses included
        }
        int optimum=100;
        for (int x=0;x<16;++x) {
            auto a=bits(x,4); int cost=oracle(f,a);
            assert(DistWarm::verified_cost(f,a)==cost);
            if (cost>=0) optimum=std::min(optimum,cost);
        }
        auto result=DistWarm::run(f,128,1), again=DistWarm::run(f,128,1);
        assert(result.cost==again.cost && result.assignment==again.assignment && result.flips==again.flips);
        assert(result.flips<=128);
        if (result.cost>=0) {
            assert(oracle(f,result.assignment)==result.cost && result.cost>=optimum); ++witnesses;
        } else assert(result.assignment.empty());
    }
    assert(witnesses>0);
    for (int n : {1,4,5}) {
        Matrix hx=matrix(n,{n==4 ? 15 : n==5 ? 3 : 0}), hz=hx;
        Matrix gx=matrix(n,n==4 ? std::vector<int>{3,5} : n==5 ? std::vector<int>{12,24,28} : std::vector<int>{1}), gz=gx;
        int exact=100;
        for (int x=0;x<(1<<n);++x) for (int z=0;z<(1<<n);++z) {
            std::vector<uint8_t> a(3*n);
            int weight=0; bool feasible=(x|z)!=0, logical=false;
            for(int i=0;i<n;++i) { a[i]=(x>>i)&1; a[n+i]=(z>>i)&1; a[2*n+i]=a[i]|a[n+i]; weight+=a[2*n+i]; }
            for(int r=0;r<hx.rows;++r) {
                int px=0,pz=0; for(int i=0;i<n;++i) {px^=getm(hz,r,i)*a[i];pz^=getm(hx,r,i)*a[n+i];}
                feasible &= px==0 && pz==0;
            }
            for(int r=0;r<gx.rows;++r) {
                int p=0,q=0;for(int i=0;i<n;++i) {p^=getm(gx,r,i)*a[i];q^=getm(gz,r,i)*a[n+i];}
                logical |= p||q;
            }
            feasible &= logical;
            assert(verified_pauli_weight(hx,hz,gx,gz,a)==(feasible?weight:-1));
            if(feasible) exact=std::min(exact,weight);
            a[2*n]^=1; assert(verified_pauli_weight(hx,hz,gx,gz,a)==-1);
        }
        assert(exact==(n==4 ? 2 : 1));
        // Inclusive original-cost cap at the optimum and above it; n=1 has fixed cost.
        for (int cap=exact;cap<=n;++cap) for (int mode : {0,3}) {
            SimpSolver s; std::vector<Var> aux; StabilizerInstance meta;
            assert(build_stabilizer_instance(s,aux,meta,hx,hz,gx,gz,0,mode,-1));
            s.initUB=cap; vec<Lit> assumptions; s.solveLimited(assumptions);
            assert(s.getLastOptimalCost()==uint64_t(exact));
        }
    }
    printf("SLS_PROBE_PASS: 250 exhaustive small CNFs, deterministic budget, original CSS witnesses, inclusive caps and fixed-cost endpoint\n");
}
