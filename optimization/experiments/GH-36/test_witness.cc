// Test-only inclusion exercises the actual application helper, not a copy.
#define main distqldpc_application_main
#include "../../../src/core/distqldpc.cc"
#undef main
#include <stdexcept>

static void require(bool p, const char* text) {
    if (!p) throw std::runtime_error(text);
}
static Matrix one_row(int n, unsigned bits) {
    Matrix m; m.rows=1; m.cols=n;
    for (int i=0;i<n;++i) m.data.push_back((bits>>i)&1);
    return m;
}
// Independent truth-table oracle enumerates all Pauli assignments and retains
// exactly those equal to an original pure logical row. Full encoded predicates
// and OR Pauli weight are evaluated on that assignment.
static int oracle(const Matrix& hx,const Matrix& hz,const Matrix& gx,const Matrix& gz) {
    int best=INT32_MAX,n=hx.cols;
    for (unsigned p=1;p<(1u<<(2*n));++p) {
        unsigned x=p&((1u<<n)-1),z=p>>n;
        bool supplied=false;
        const Matrix* bases[2]={&gz,&gx};
        for (int kind=0;kind<2;++kind) for (int r=0;r<bases[kind]->rows;++r) {
            unsigned row=0;
            for(int i=0;i<n;++i) row|=unsigned(getm(*bases[kind],r,i))<<i;
            supplied|=kind==0 ? (x==row && z==0) : (z==row && x==0);
        }
        if (!supplied) continue;
        bool valid=true,nontrivial=false;
        const Matrix* checks[4]={&hx,&hz,&gx,&gz};
        unsigned components[4]={z,x,x,z};
        for(int k=0;k<4;++k) for(int r=0;r<checks[k]->rows;++r) {
            int parity=0;
            for(int i=0;i<n;++i) parity^=getm(*checks[k],r,i)*((components[k]>>i)&1);
            if(k<2) valid&=parity==0; else nontrivial|=parity!=0;
        }
        int weight=0;
        for(int i=0;i<n;++i) weight+=((x|z)>>i)&1;
        if(valid && nontrivial && weight<best) best=weight;
    }
    return best;
}
int main() {
    try {
        int count=0;
        for(int n=1;n<=3;++n) {
            unsigned limit=1u<<n;
            for(unsigned a=0;a<limit;++a) for(unsigned b=0;b<limit;++b)
            for(unsigned c=0;c<limit;++c) for(unsigned d=0;d<limit;++d) {
                Matrix hx=one_row(n,a),hz=one_row(n,b),gx=one_row(n,c),gz=one_row(n,d);
                int expected=oracle(hx,hz,gx,gz);
                require(verified_logical_row_bound(hx,hz,gx,gz)==expected,"witness truth table mismatch");
                ++count;
            }
        }
        Matrix zero=one_row(3,0), gx=one_row(3,3),gz=one_row(3,1);
        gz.data.insert(gz.data.end(),{1,1,1}); ++gz.rows;
        gx.data.insert(gx.data.end(),{0,1,1}); ++gx.rows;
        require(verified_logical_row_bound(zero,zero,gx,gz)==oracle(zero,zero,gx,gz),"multirow minimum mismatch");
        // Exercise the actual assignment in the application builder. All five
        // original encoding modes can receive the same verified inclusive scalar;
        // a cap alone must not make hasCostUB true before search.
        for (int mode=0;mode<5;++mode) {
            SimpSolver solver; StabilizerInstance meta; std::vector<Var> aux;
            Matrix h=one_row(1,0), g=one_row(1,1);
            require(build_stabilizer_instance(solver,aux,meta,h,h,g,g,0,mode,-1),"valid builder failed");
            require(solver.initUB==INT32_MAX,"shared builder unexpectedly changed");
            solver.initUB=verified_logical_row_bound(h,h,g,g);
            require(solver.initUB==1,"verified scalar mismatch");
            require(!solver.hasCostUB(),"input cap fabricated a solver model");
        }
        printf("WITNESS_ORACLE_PASS cases=%d plus_multirow\n",count);
        return 0;
    } catch(const std::exception& e) {fprintf(stderr,"%s\n",e.what()); return 1;}
}
