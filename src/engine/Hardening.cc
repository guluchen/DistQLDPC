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
 * DistQLDPC engine -- module Hardening.cc
 *
 * Hardening (bound-driven fixing of soft literals): harden, reduceHardens, moreHarden,
 * hardenForRestart, hardenFromQuasiSoftConflict.
 *
 * Restructured from MaxCDCL src/solver/Solver.cc by DistQLDPC (GH-95, stage 1): code moved
 * verbatim, search unchanged. The copyright and MIT permission notice above apply to the
 * MaxCDCL / Maple_CM / Maple_LCM / MiniSat code contained in this file (see src/solver/LICENSE).
 *
 * Modifications Copyright (C) 2025-2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>, part of DistQLDPC
 * (GPL-3.0-or-later when distributed as this project; see LICENSE, NOTICE, MODIFICATIONS.md).
 */

#ifndef DISTQLDPC_ENGINE_UNITY
#error "src/engine/Hardening.cc is part of the engine unity build; compile src/engine/Engine.cc"
#endif

void Solver::hardenForRestart(int nbIsets, int trailRecord) {
  Var vv;
  printf("c harden from start...\n");
  hardenEnable = false;
  if (nbIsets == NON) {
    vv = simplePickAuxiVar();
    while (vv != var_Undef) {
      hardenEnable = true;
      uncheckedEnqueue(softLits[vv]);
      fixedByHardens++;
      vv = simplePickAuxiVar();
      //  printf("level 0: %d", level(vv));
    }
  }
  else {
    vec<Lit> toHarden;
    toHarden.clear();
    for(int i=trailRecord; i< trail.size(); i++) {
      Var v=var(trail[i]);
      assigns[v] = l_Undef;
      if (auxiVar(v)) {
	assert(v>=0 && v<activityLB.size());
	activityLB[v] = (1-stepSizeLB)*activityLB[v];
	insertAuxiVarOrder(v);
	orderHeapAuxi.decrease(v);
	if (inConflicts[v] == NON)
	  toHarden.push(trail[i]);
      }
    }
    trail.shrink(trail.size() - trailRecord);
    qhead = trailRecord;
    //   trail_lim.shrink(1);
    //   resetConflicts(nbIsets);
    bumpConflVars(); //the score of confl vars and non-confl vars is updated differently
    
    if (toHarden.size() == 0)
      return;
    hardenEnable = true;
    for(int i=0; i<toHarden.size(); i++) {
      Lit p = toHarden[i];
      uncheckedEnqueue(p);
      fixedByHardens++; fixedByQuasiConfl++;
    }
  }
}

void Solver::moreHarden() {
  // if (UB==2) return;
  int nbfixed=0;
  Var vv;
  nbHardens++;
  if (decisionLevel() == 0) {
    vv = simplePickAuxiVar();
    while (vv != var_Undef) {
      hardenEnable = true;
      uncheckedEnqueue(softLits[vv]);
      fixedByHardens++;
      vv = simplePickAuxiVar();
      //  printf("level 0: %d", level(vv));
    }
    //  printf("\n");
  }
  else {
    vv = simplePickAuxiVar();
    if (vv == var_Undef)
      return;
    assert(!softVarLocked[vv]);
    hardenEnable = true;
    // if (falseLits.size() > 0 && level(var(falseLits.last())) < decisionLevel()) {
    //   printf("****\n");
    //   cancelUntil(level(var(falseLits.last())));
    // }
    vec<Lit> ps;
    ps.clear();
    ps.push();
    int nbFalseLits=falseLits.size();
    counter++;
    for(int i=nbFalseLits-1; i>=0; i--) {
      Var v=var(falseLits[i]);
      if (level(v) > 0) {
  	ps.push(falseLits[i]); seen2[v] = counter;
      }
    }
    for(int i=nbFalseLits-1; i>=0; i--) {
      Var v=var(falseLits[i]);
      if (level(v) > 0 && inConflict[v] != NON) {
    	Var u = unlockReason[v];
    	assert(u != var_Undef);
    	if (level(u) > 0 && seen2[u] < counter) {
    	  seen2[u] = counter;
    	  assert(value(softLits[u]) == l_False);
    	  ps.push(softLits[u]);
    	}
      }
    }
    do {
      CRef cr = CRef_Undef;
      ps[0] = softLits[vv];
      assert(inConflict[vv] != NON);
      //    if (inConflict[vv] != NON) {
      Var u = unlockReason[vv];
      assert(u != var_Undef);
      assert(value(softLits[u]) == l_False);
      if (level(u) > 0 && seen2[u] < counter) {
	if (ps.size() > 1) {
	  Lit p2=ps[1];
	  if (level(u) > level(var(p2))) {
	    ps[1] = softLits[u]; ps.push(p2);
	    cr =ca.alloc(ps, true);
	    ps[1] = p2;
	  }
	  else {ps.push(softLits[u]);  cr =ca.alloc(ps, true);}
	}
	else {ps.push(softLits[u]);  cr =ca.alloc(ps, true);}
	ps.shrink(1);
      }
      else cr =ca.alloc(ps, true);
      hardens.push(cr);
      attachClause(cr);
      uncheckedEnqueue(ps[0], cr);
      // if (level(var(ps[0])) != level(var(ps[1])))
      //   printf("%d %d, decLevel: %d, ps: %d, c: %d, c[3]level: %d\n", level(var(ps[0])), level(var(ps[1])), decisionLevel(), ps.size(), ca[cr].size(), level(var(ca[cr][2])));
      assert( level(var(ca[cr][0])) == level(var(ca[cr][1])));
      fixedByHardens++; nbfixed++;
      //    }
      vv = simplePickAuxiVar();
    } while (vv != var_Undef);
    // printf("\n %d %llu\n", decisionLevel(), conflicts);
  }
  // printf("harden level %d, fixes %d, UB: %llu, hardens: %d\n", hardenLevel, nbfixed, UB, hardens.size());
}

void Solver::hardenFromQuasiSoftConflict(int trailRecord, int nbIsets) {
  vec<Lit> toHarden;
  toHarden.clear();
  for(int i=trailRecord; i< trail.size(); i++) {
    Var v=var(trail[i]);
    assigns[v] = l_Undef;
    if (auxiVar(v)) {
      assert(v>=0 && v<activityLB.size());
      activityLB[v] = (1-stepSizeLB)*activityLB[v];
      insertAuxiVarOrder(v);
      orderHeapAuxi.decrease(v);
      if (inConflicts[v] == NON)
	toHarden.push(trail[i]);
    }
  }
  trail.shrink(trail.size() - trailRecord);
  qhead = trailRecord;
  // trail_lim.shrink(1);
  resetConflicts(nbIsets);
  bumpConflVars(); //the score of confl vars and non-confl vars is updated differently
  
  if (toHarden.size() == 0)
    return;
  hardenEnable = true;
  UBconflictFlag = true; softConflictFlag = true;
  
  vec<Lit> learnt_clause;
  int backtrack_level, lbd;
  learnt_clause.clear();
  analyzeQuasiSoftConflict(learnt_clause, backtrack_level, lbd);
  if (learnt_clause.size() > 0) {
    Lit p = learnt_clause[0];
    if (level(var(p)) < decisionLevel()) {
      cancelUntil(level(var(p)));
    }
    assert(level(var(p)) == decisionLevel());
  }
  else {
    cancelUntil(0);
  }
  UBconflictFlag = false; softConflictFlag = false;
  
  if (learnt_clause.size() == 0) 
    for(int i=0; i<toHarden.size(); i++) {
      Lit p = toHarden[i];
      uncheckedEnqueue(p);
      fixedByHardens++; fixedByQuasiConfl++;
    }
  else {
    reduceHardens();
    vec<Lit> ps;
    ps.clear();
    ps.push();
    counter++;
    for(int i=0; i<learnt_clause.size(); i++) {
      Lit p = learnt_clause[i];
      ps.push(p);
      seen2[var(p)] = counter;
    }
    
    for(int i=0; i<toHarden.size(); i++) {
      Lit p = toHarden[i];
      if (!softVarLocked[var(p)]) {
	ps[0] = p;
	CRef cr;
	cr =ca.alloc(ps, true);
	hardens.push(cr);
	attachClause(cr);
	uncheckedEnqueue(p, cr);
	fixedByHardens++; fixedByQuasiConfl++;
      }
    }
  }
}

void Solver::reduceHardens() {
  //  sort(hardens, reduceDB_lt(ca));

  // int limit = hardens.size() / 2;
  int ii, jj;

  // for(ii=0, jj=0; ii<hardens.size(); ii++) {
  //   Clause& c = ca[hardens[ii]];
  //   if (!locked(c) &&  (ii < limit || c.activity() == 0))
  //     removeClause(hardens[ii]);
  //   else hardens[jj++] = hardens[ii];
  // }
  
  for(ii=0, jj=0; ii<hardens.size(); ii++) {
    Clause& c = ca[hardens[ii]];
    if (locked(c))
      hardens[jj++] = hardens[ii];
    else removeClause(hardens[ii]); 
  }
  hardens.shrink(ii-jj);
  checkGarbage();
}

void Solver::harden() {
  int nbfixed=0;
  nbHardens++;
  //  int saved = hardenLevel;
  hardenLevel = decisionLevel();
  if (falseLits.size() == 0 || level(var(falseLits.last())) == 0) {
    // if (decisionLevel() != 0) {
    //   int nbToHarden=0;
    //   for(int i=0; i<allSoftLits.size(); i++) {
    // 	Lit p = allSoftLits[i];
    // 	if (value(p) == l_Undef)
    // 	  nbToHarden++;
    //   }
    //   printf("falseLits %d, level %d, UB %llu, hardenL %d, confl %llu, starts %llu, toH %d\n",
    // 	     falseLits.size(), decisionLevel(), UB, saved, conflicts, starts, nbToHarden);
    // }
    //   assert(decisionLevel() == 0);
    // printf("nbSoftLits: %d\n", allSoftLits.size());
    for(int i=0; i<allSoftLits.size(); i++) {
      Lit p = allSoftLits[i];
      if (value(p) == l_Undef && !softVarLocked[var(p)]) {
	uncheckedEnqueue(p); fixedByHardens++;
      }
    }
  }
  else {
    // assert(level(var(falseLits.last())) == decisionLevel());
    assert(UB == falseLits.size() + 1);
    if (level(var(falseLits.last())) < decisionLevel())
      for(int i=0; i<allSoftLits.size(); i++) {
	Lit p = allSoftLits[i];
	if (value(p) == l_Undef && !softVarLocked[var(p)]) {
	  cancelUntil(level(var(falseLits.last())));
	  break;
	}
      }
    reduceHardens();
    vec<Lit> ps;
    ps.clear();
    ps.push();
    int nbFalseLits=falseLits.size();
    counter++;
    for(int i=nbFalseLits-1; i>=0; i--) {
      Var v=var(falseLits[i]);
      if (level(v) > 0) {
	ps.push(falseLits[i]); seen2[v] = counter;
      }
    }
    // for(int i=nbFalseLits-1; i>=0; i--) {
    //   Var v=var(falseLits[i]);
    //   if (level(v) > 0 && inConflict[v] != NON) {
    // 	Var u = unlockReason[v];
    // 	assert(u != var_Undef);
    // 	if (level(u) > 0 && seen2[u] < counter) {
    // 	  seen2[u] = counter;
    // 	  assert(value(softLits[u]) == l_False);
    // 	  ps.push(softLits[u]);
    // 	}
    //   }
    // }
    assert(ps.size() > 1);
   for(int i=0; i<allSoftLits.size(); i++) {
      Lit p = allSoftLits[i];
      if (value(p) == l_Undef && !softVarLocked[var(p)]) {
	ps[0] = p;
	CRef cr;
	// if (inConflict[var(p)] != NON) {
	//   Var u = unlockReason[var(p)];
	//   assert(u != var_Undef);
	//   if (level(u) > 0 && seen2[u] < counter) {
	//     assert(value(softLits[u]) == l_False);
	//     ps.push(softLits[u]);
	//     cr =ca.alloc(ps, true);
	//     ps.shrink(1);
	//   }
	//   else cr =ca.alloc(ps, true);
	// }
	// else
	  cr =ca.alloc(ps, true);
	hardens.push(cr);
	attachClause(cr);
	uncheckedEnqueue(p, cr);
	fixedByHardens++; nbfixed++;
      }
    }
  }
  // printf("harden level %d, fixes %d, UB: %llu, hardens: %d\n", hardenLevel, nbfixed, UB, hardens.size());
}
