/***************************************************************************************[Solver.cc]
 MiniSat -- Copyright (c) 2003-2006, Niklas Een, Niklas Sorensson
 Copyright (c) 2007-2010, Niklas Sorensson
 
Chanseok Oh's MiniSat Patch Series -- Copyright (c) 2015, Chanseok Oh

Maple_LCM, Based on MapleCOMSPS_DRUP --Copyright (c) 2017, Mao Luo, Chu-Min LI, Fan Xiao: implementing a learnt clause minimisation approach
 Reference: M. Luo, C.-M. Li, F. Xiao, F. Manya, and Z. L. , “An effective learnt clause minimization approach for cdcl sat solvers,” in IJCAI-2017, 2017, pp.703-711.
 
Maple_CM, Based on Maple_LCM --Copyright (c) 2018, Chu-Min LI, Mao Luo, Fan Xiao: implementing a clause minimisation approach.

Copyright (c) 2021,Chu-Min Li (chu-min.li@u-picardie.fr)

A MaxSAT solver combining branch-and-bound and clause learning, implemented by Chu-Min Li with the help of Jordi Coll
Based on Maple_LCM

Reference: Chu-Min Li, Zhenxing Xu, Jordi Coll, Felip Manyà, Djamal Habet, Kun He, Combining Clause Learning and Branch and Bound for MaxSAT, in CP-2021, to appear


Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge, publish, distribute,
 sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
**************************************************************************************************/

/*
 * DistQLDPC engine -- module Cardinality.cc
 *
 * Dynamic auxiliary variables and cardinality encodings (Sinz sequential counter, MTO).
 *
 * Restructured from MaxCDCL src/solver/Solver.cc by DistQLDPC (GH-95, stage 1): code moved
 * verbatim, search unchanged. The copyright and MIT permission notice above apply to the
 * MaxCDCL / Maple_CM / Maple_LCM / MiniSat code contained in this file (see src/solver/LICENSE).
 *
 * Modifications Copyright (C) 2025-2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>, part of DistQLDPC
 * (GPL-3.0-or-later when distributed as this project; see LICENSE, NOTICE, MODIFICATIONS.md).
 */

#ifndef DISTQLDPC_ENGINE_UNITY
#error "src/engine/Cardinality.cc is part of the engine unity build; compile src/engine/Engine.cc"
#endif

void Solver::cleanClausesForNewVars(vec<CRef>& cs) {
  int i, j;
  for (i = j = 0; i < cs.size(); i++){
    CRef cr = cs[i];
    Clause& c = ca[cr];
    bool sat=false;
    if(c.mark()!=1){
      for (int ii = 0; ii < c.size(); ii++){
	Lit p=c[ii];
        if (value(p) == l_True || dynVar(var(p))) {
	  sat = true;
	  break;
        }
	// Lit p=c[ii];
        // if (value(p) == l_True){
	//   sat = true;
	//   break;
        // }
	//	else if (value(p) == l_Undef && dynVar(var(p)) && !seen[var(p)])
	// seen[var(p)] = 1;
      }
      if (sat)
        removeClause(cr);
      // else {
      // 	int li, lj;
      // 	for (li = lj = 0; li < c.size(); li++){
      // 	  Lit p=c[li];
      // 	  if (value(p) != l_False){
      // 	    c[lj++] = p;
      // 	    if (dynVar(var(p)) && !seen[var(p)])
      // 	      seen[var(p)] = 1;
      // 	  }
      // 	  else assert(li>1);
      // 	}
      // 	if (lj==2) {
      // 	  detachClause(cr, true);
      // 	  c.shrink(li - lj);
      // 	  attachClause(cr);
      // 	}
      // 	else {
      // 	  assert(lj>2);
      // 	  c.shrink(li - lj);
      // 	}
      else cs[j++] = cr;
      // }
    }
  }
  cs.shrink(i - j);
}

void Solver::collectDynVars() {
  cleanClausesForNewVars(learnts_core);
  cleanClausesForNewVars(learnts_tier2);
  cleanClausesForNewVars(learnts_local);
  cleanClausesForNewVars(hardens);
  checkGarbage();
  dynVars.clear();
  for(int i=nVars() - 1; i>=staticNbVars; i--) {
    //  decision[i] = true;
    if (seen[i])
      seen[i] = 0;
    else if (value(i) == l_Undef) {
      dynVars.push(i);
      decision[i]=false;
    }
  }
  // for(int i=0; i<nVars(); i++)
  //   if (value(i) == l_Undef || level(i) > 0)
  //     assert(!seen[i]);
}

Var Solver::newAuxiVar(bool sign)
{
  if (dynVars.size() > 0) {
    int v=dynVars.last();
    dynVars.pop();
    Lit p = mkLit(v);
    watches_bin[p].clear();
    watches_bin[~p].clear();
    watches[p].clear();
    watches[~p].clear();
    imply[toInt(p)] = lit_Undef;
    imply[toInt(~p)] = lit_Undef;
    decision[v] = false;
    assigns[v] = l_Undef;
    return v;
  }
    int v = nVars();
    watches_bin.init(mkLit(v, false));
    watches_bin.init(mkLit(v, true ));
    watches  .init(mkLit(v, false));
    watches  .init(mkLit(v, true ));
    assigns  .push(l_Undef);
    vardata  .push(mkVarData(CRef_Undef, 0));
    activity_CHB  .push(0);
    activity_VSIDS.push(rnd_init_act ? drand(random_seed) * 0.00001 : 0);
    
    picked.push(0);
    conflicted.push(0);
    almost_conflicted.push(0);
#ifdef ANTI_EXPLORATION
    canceled.push(0);
#endif
    
    seen     .push(0);
    seen2    .push(0);
    seen2    .push(0);
    polarity .push(sign);
    decision .push(false);
    trail    .capacity(v+1);
    //  setDecisionVar(v, dvar);
    decision[v] = false;

    activity_distance.push(0);
    var_iLevel.push(0);
    var_iLevel_tmp.push(0);
    pathCs.push(0);

    // softWatches.init(mkLit(v, false));
    // softWatches.init(mkLit(v, true));

    // lookaheadCNT.push(0);

    imply.push(lit_Undef);
    imply.push(lit_Undef);

    activityLB.push(0);
    //  lastTested.push(0);
    softLits.push(lit_Undef);

    conflictLits.init(mkLit(v, false));
    conflictLits.init(mkLit(v, true));

    softVarLocked.push(0);
    inConflict.push(NON);
    unlockReason.push(var_Undef);

    inConflicts.push(NON);

    //  unlockReasonForLK.push(var_Undef);
    involved.push(0);
    
    return v;
}

// create cardinality clauses for a set of soft clauses such that the sum of these lits <= k
// using the Sequential Counter method of Sinz
// precondition: activeSoftLits.size() > k > 0
void Solver::addCardinalityConstraints(vec<Lit>& activeSoftLits, int k) {
  vec<Lit> ps, auxiLits1, auxiLits2;
  //auxiLits1 represent x1+x2+...+x_{i-1} and auxiLits2 x1+x2+...+x_i for i=2, ..., n
  // create clause ¬x1 v s11
  Var v = newAuxiVarForCardinality(); Lit s11 = mkLit(v);
  ps.clear(); ps.push(~activeSoftLits[0]); ps.push(s11);
  CRef cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr);
  ca[cr].mark(CORE);
  auxiLits1.clear(); auxiLits1.push(s11); // sum x1
  
  for(int i=1; i<activeSoftLits.size() - 1; i++) {
    auxiLits2.clear();
    for(int j=0; j<k && j<=i; j++) { // sij=0 for j>i
      v = newAuxiVarForCardinality(); Lit s = mkLit(v); auxiLits2.push(s);
    }
    //create clause ¬xi v si1
    ps.clear(); ps.push(~activeSoftLits[i]); ps.push(auxiLits2[0]);
    cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr);
    ca[cr].mark(CORE);
    //create clause ¬s_{i-1,1} v si1
    ps.clear(); ps.push(~auxiLits1[0]); ps.push(auxiLits2[0]);
    cr = ca.alloc(ps, true); cardinalityC.push(cr);  attachClause(cr);
    ca[cr].mark(CORE);
    if (k<=i) {
      //create clause ¬xi v ¬s_{i-1, k} for forbidding overflow
      // there is no overflow for k>=i because s_{i-1, k} is 0
      ps.clear(); ps.push(~activeSoftLits[i]); ps.push(~auxiLits1.last());
      cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr);
      ca[cr].mark(CORE);
    }
    
    for(int j=1; j<k && j<=i; j++) {
      //create clause ¬xi v ¬s_{i-1, j-1} v sij
      ps.clear(); ps.push(~activeSoftLits[i]); ps.push(~auxiLits1[j-1]); ps.push(auxiLits2[j]);
      cr = ca.alloc(ps, true);	cardinalityC.push(cr);	attachClause(cr);
      ca[cr].mark(CORE);
      if (j<i) {
	//create clause ¬s_{i-1, j} v sij
	ps.clear(); ps.push(~auxiLits1[j]); ps.push(auxiLits2[j]);
	cr = ca.alloc(ps, true);	cardinalityC.push(cr);	attachClause(cr);
	ca[cr].mark(CORE);
      }
    }
    auxiLits2.copyTo(auxiLits1);
  }
  //create clause ¬xn v ¬s_{n-1,k}
  ps.clear(); ps.push(~activeSoftLits.last()); ps.push(~auxiLits1.last());
  cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr);
  ca[cr].mark(CORE);
}

inline Var Solver::newAuxiVarForCardinality() {
  // return newAuxiVar();
  Var v=newAuxiVar();
  // dynVarsForCardinality.push(v);
  activity_CHB[v] = 0;
  activity_VSIDS[v] = 0;
  // decision[v] = true;
  assigns[v] = l_Undef;
  assert(!auxiVar(v));
  setDecisionVar(v, true);
  // //  if (!order_heap_CHB.inHeap(v))
  //   order_heap_CHB.update(v);
  //   // if (!order_heap_VSIDS.inHeap(v))
  //   order_heap_VSIDS.update(v); 
  return v;
}

// create clauses for ¬x1 + ¬x2 + ... + ¬xn <= k
// Precondition: n>k>0
// Should be called only at the root of the search tree
void Solver::addCardinalityConstraints() {
  uint64_t& prevUB = card_prevUB;  // GH-73: was function-local static

  if (UB==1 || UB == prevUB)
    return;
  prevUB = UB;

  if (cardinalityEncMode == CARD_ENC_OFF) {
    if (verbosity >= 1)
      printf("\nc Cardinality: off (soft-conflict only), UB %llu\n", UB);
    return;
  }

  if (cardinalityC.size() > 0) {
    for(int i=0; i<cardinalityC.size(); i++)
      removeClause(cardinalityC[i]);
    cardinalityC.clear();
    
    collectDynVars();
    
    watches.cleanAll();
    watches_bin.cleanAll();
    checkGarbage();
  }
  
  // for(int i=0; i<dynVarsForCardinality.size(); i++)
  //   dynVars.push(dynVarsForCardinality[i]);
  // dynVarsForCardinality.clear();
  
  vec<Lit> activeSoftLits;
  activeSoftLits.clear();
  int nbFalse=0;
  
  for(int i=0; i<allSoftLitsForCardC.size(); i++) {
    if (value(allSoftLitsForCardC[i]) == l_Undef)
      activeSoftLits.push(~allSoftLitsForCardC[i]);
    else if (value(allSoftLitsForCardC[i]) == l_False)
      nbFalse++;
  }
  if (activeSoftLits.size() < 2 || UB - 1 - nbFalse < 1 || activeSoftLits.size() <= UB - 1 - nbFalse
      || activeSoftLits.size()*(UB - 1 - nbFalse) > 10000)
    return;
  int k = UB - 1 - nbFalse;
  bool useSinz = (cardinalityEncMode == CARD_ENC_SINZ)
      || (cardinalityEncMode == CARD_ENC_BOTH_FORCE)
      || (cardinalityEncMode == CARD_ENC_BOTH && activeSoftLits.size() <= 100);
  bool useMto = (cardinalityEncMode == CARD_ENC_MTO)
      || (cardinalityEncMode == CARD_ENC_BOTH)
      || (cardinalityEncMode == CARD_ENC_BOTH_FORCE);
  if (useSinz)
    addCardinalityConstraints(activeSoftLits, k);
  if (useMto)
    addCardinalityConstraintsMTO(activeSoftLits, k);
  const char* enc = "unknown";
  if (cardinalityEncMode == CARD_ENC_BOTH) enc = "Sinz+MTO";
  else if (cardinalityEncMode == CARD_ENC_BOTH_FORCE) enc = "Sinz+MTO forced";
  else if (cardinalityEncMode == CARD_ENC_SINZ) enc = "Sinz";
  else if (cardinalityEncMode == CARD_ENC_MTO) enc = "MTO";
  printf("\nc Cardinality: %d (%s) for UB %llu\n", cardinalityC.size(), enc, UB);

  rebuildOrderHeap();

  //  activeSoftLits.shrink_(activeSoftLits.size() - 9);
  // addCardinalityConstraintsbis(activeSoftLits, 4);
  
  // for(int i=0; i<activeSoftLits.size(); i++)
  //   printf("%d ", var(activeSoftLits[i]));
  // printf("\n\n");
  
  // for(int i=0; i<cardinalityC.size(); i++) {
  //   Clause& c=ca[cardinalityC[i]];
  //   for(int j=0; j<c.size(); j++) {
  //     if (toInt(c[j])%2 == 1)
  // 	printf("-%d ", var(c[j]));
  //     else printf("%d ", var(c[j]));
  //   }
  //   printf("0\n");
  // }
}

void Solver::addCardinalityConstraintsMTO(vec<Lit>& activeSoftLits, int k) {

    int k2 = k;
    int m = activeSoftLits.size(); //Number of variables
    int n = 0; //number of bits
    while (k2) {
        k2 >>= 1;
        ++n;
    }

    vec<Lit>  result(n,lit_Undef);
    nLevelsMTO(activeSoftLits,0,m,result);

    vec<Lit> ps;
    CRef cr;

    for(int i = n-1; i >= 0; i--){
        ps.push(~result[i]);
        if(!bitIsSet(k,i)){
            if(ps.size()==1)
                uncheckedEnqueue(ps[0]);
            else {
                cr = ca.alloc(ps, true);
                cardinalityC.push(cr);
                attachClause(cr); ca[cr].mark(CORE);
            }
            ps.pop();
        }
    }
}

void Solver::nLevelsMTO(vec<Lit> & x, int lIndex, int m, vec<Lit> & result){
    int n = result.size();

    //Base case, leaf
    if(m==1){
        result[0]=x[lIndex];
    }

    //Recursive case, branch in the binary tree
    else{
        vec<Lit> ps;
        CRef cr;

        vec<Lit> left(n,lit_Undef), right(n,lit_Undef);
        int lSize = m/2;
        int rSize = m - m/2;
        nLevelsMTO(x,lIndex, lSize, left);
        nLevelsMTO(x,lIndex+lSize, rSize, right);

        vec<Lit> c(n-1,lit_Undef); //carry

        int h = 0;
        Var v;
        while(h < n-1){

            v = newAuxiVarForCardinality(); c[h] = mkLit(v);
            v = newAuxiVarForCardinality(); result[h] = mkLit(v);

            //====When carry in is false====
            //left and not(carry) -> result
            if(left[h]!=lit_Undef) {
                ps.clear();
                ps.push(~left[h]); ps.push(c[h]); ps.push(result[h]);
                cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
            }

            //right and not(carry) -> result
            if(right[h]!=lit_Undef) {
                ps.clear();
                ps.push(~right[h]);ps.push(c[h]);ps.push(result[h]);
                cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
            }

            //left and right -> carry
            if(left[h]!=lit_Undef && right[h]!=lit_Undef) {
                ps.clear();
                ps.push(~left[h]);ps.push(~right[h]);ps.push(c[h]);
                cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
            }

            //====When carry in is true====
           if(h>0){
                //carryin and not(carry) -> result
                ps.clear();
                ps.push(~c[h-1]); ps.push(c[h]); ps.push(result[h]);
                cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);

                //carryin and left -> carry
                if(left[h]!=lit_Undef){
                    ps.clear();
                    ps.push(~c[h-1]); ps.push(~left[h]); ps.push(c[h]);
                    cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
                }

                //carryin and right -> carry
                if(right[h]!=lit_Undef){
                    ps.clear();
                    ps.push(~c[h-1]); ps.push(~right[h]); ps.push(c[h]);
                    cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
                }

                //carryin and left and right -> result
                if(left[h]!=lit_Undef && right[h]!=lit_Undef) {
                    ps.clear();
                    ps.push(~c[h-1]); ps.push(~left[h]); ps.push(~right[h]); ps.push(result[h]);
                    cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
                }
            }

            ++h;

            //If all bits processed, break
            if(right[h]==lit_Undef && right[h]==lit_Undef)
                break;
        }

        v = newAuxiVarForCardinality(); result[h] = mkLit(v);

        //====Clauses of the uppermost digits====
        // left -> result
        if(left[h]!=lit_Undef) {
            ps.clear();
            ps.push(~left[h]); ps.push(result[h]);
            cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
        }

        // right -> result
        if(right[h]!=lit_Undef) {
            ps.clear();
            ps.push(~right[h]); ps.push(result[h]);
            cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
        }

        // carryin -> result
        if(h>0) {
            ps.clear();
            ps.push(~c[h - 1]); ps.push(result[h]);
            cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
        }

        // not(left) or not(right)
        if(left[h]!=lit_Undef && right[h]!=lit_Undef) {
            ps.clear();
            ps.push(~left[h]); ps.push(~right[h]);
            cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
        }

        // not(left) or not(carryin)
        if(left[h]!=lit_Undef && h>0) {
            ps.clear();
            ps.push(~left[h]); ps.push(~c[h-1]);
            cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
        }

        // not(right) or not(carryin)
        if(right[h]!=lit_Undef && h>0) {
            ps.clear();
            ps.push(~right[h]); ps.push(~c[h-1]);
            cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
        }

    }
}
