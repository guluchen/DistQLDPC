// GH58 test-only normalized partition state; linked to actual candidate objects.
// Not a substitute for the mandatory original WCNF/parser regression.
#include "Solver.h"
#include <cstdio>
#include <cstdlib>
#include <vector>
using namespace Minisat;
static void need(bool x,const char* why) { if(!x){std::fprintf(stderr,"GH58_PARTITION_FAIL %s\n",why);std::exit(1);} }
class Probe:public Solver {
public:
 void test(int m,int units,int signs) {
  derivedCost=0;
  std::vector<Lit> old;
  for(int i=0;i<m;++i){Var v=newVar(false,(units>>i)&1);Lit p=mkLit(v,(signs>>i)&1);old.push_back(p);softLits[v]=p;allSoftLits.push(p);}
  Var vu=newVar(),vn=newVar(false,false);Lit su=mkLit(vu),sn=mkLit(vn);
  softLits[vu]=su;softLits[vn]=sn;allSoftLits.push(su);allSoftLits.push(sn);
  unitSoftLits.push(su);nonUnitSoftLits.push(sn);
  for(int i=0;i<m;++i) ((units>>i)&1?unitSoftLits:nonUnitSoftLits).push(old[i]);
  // Genuine pairwise hard exclusion premises, allocated/attached to the engine.
  for(int i=0;i<m;++i)for(int j=i+1;j<m;++j){
   vec<Lit> c;c.push(~old[i]);c.push(~old[j]);CRef cr=ca.alloc(c,false);clauses.push(cr);attachClause(cr);
   conflictLits[old[i]].push(old[j]);conflictLits[old[j]].push(old[i]);
  }
  rebuildOrderHeap();const int before=nVars();partition();
  need(nVars()==before+1,"exact one representative");Lit rep=mkLit(before);
  need(derivedCost==unsigned(m-1),"original derived cost retained");
  need(unitSoftLits.size()==1 && unitSoftLits[0]==su,"active unit order/preservation");
  need(nonUnitSoftLits.size()==2 && nonUnitSoftLits[0]==sn && nonUnitSoftLits[1]==rep,"active auxiliary/new representative order");
  need(softLits[before]==rep && imply.size()==2*nVars(),"active representative metadata");
  for(int i=0;i<m;++i){need(softLits[var(old[i])]==lit_Undef,"old mapping retired");need(!orderHeapAuxi.inHeap(var(old[i])),"stale auxiliary heap entry retired");need(imply[toInt(old[i])]==rep,"original implication map retained");}
  need(orderHeapAuxi.inHeap(vu)&&orderHeapAuxi.inHeap(vn)&&orderHeapAuxi.inHeap(before),"required actual heap rebuild");
  need(orderHeapAuxi.size()==3,"heap contains exactly active normalized soft vars");
  auto sat=[](Lit p,unsigned model){return bool((model>>var(p))&1)!=bool(sign(p));};
  unsigned checked=0;
  for(unsigned model=0;model<(1u<<nVars());++model){
   bool hard=true;for(int i=0;i<clauses.size();++i){const Clause& c=ca[clauses[i]];bool ok=false;for(int j=0;j<c.size();++j)ok|=sat(c[j],model);hard&=ok;}
   if(!hard)continue;++checked;
   unsigned orig=!sat(su,model)+!sat(sn,model);for(Lit p:old)orig+=!sat(p,model);
   unsigned now=derivedCost;for(int i=0;i<unitSoftLits.size();++i)now+=!sat(unitSoftLits[i],model);for(int i=0;i<nonUnitSoftLits.size();++i)now+=!sat(nonUnitSoftLits[i],model);
   need(orig==now,"all-hard-feasible objective identity");
  }
  need(checked>0,"nonvacuous generated hard equivalence");
 }
 void noConflict(){
  derivedCost=0;Var u=newVar(),n=newVar(false,false);Lit p=mkLit(u),q=mkLit(n);
  softLits[u]=p;softLits[n]=q;unitSoftLits.push(p);nonUnitSoftLits.push(q);allSoftLits.push(p);allSoftLits.push(q);rebuildOrderHeap();partition();
  need(nVars()==2&&derivedCost==0,"no replacement/cost change without conflict");
  need(unitSoftLits.size()==1&&unitSoftLits[0]==p&&nonUnitSoftLits.size()==1&&nonUnitSoftLits[0]==q,"no-removal lists preserved");
  need(orderHeapAuxi.size()==2&&orderHeapAuxi.inHeap(u)&&orderHeapAuxi.inHeap(n),"no-removal active heap preserved");
 }
};
int main(){unsigned count=0;for(int m=2;m<=3;++m)for(int units=0;units<(1<<m);++units)for(int signs=0;signs<(1<<m);++signs){Probe p;p.test(m,units,signs);++count;}Probe p;p.noConflict();std::printf("GH58_PARTITION_ORACLE_PASS cases=%u no_conflict=1\n",count);return 0;}
