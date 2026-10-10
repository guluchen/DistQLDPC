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
 * DistQLDPC engine -- module Preprocessing.cc
 *
 * Soft-literal preprocessing: conflicting soft literals, partition into disjoint
 * inconsistent sets, initial conflict detection (with its simple LK helpers), hard clauses for soft clauses.
 *
 * Restructured from MaxCDCL src/solver/Solver.cc by DistQLDPC (GH-95, stage 1): code moved
 * verbatim, search unchanged. The copyright and MIT permission notice above apply to the
 * MaxCDCL / Maple_CM / Maple_LCM / MiniSat code contained in this file (see src/solver/LICENSE).
 *
 * Modifications Copyright (C) 2025-2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>, part of DistQLDPC
 * (GPL-3.0-or-later when distributed as this project; see LICENSE, NOTICE, MODIFICATIONS.md).
 */

#ifndef DISTQLDPC_ENGINE_UNITY
#error "src/engine/Preprocessing.cc is part of the engine unity build; compile src/engine/Engine.cc"
#endif

// for each soft clause of the form 1 2 3, create a new variable non decisional v and
// add a hard equivalence v <--> 1 2 3, meaning: add a hard clause -v 1 2 3
//    then add 3 hard clauses v -1, v -2, v -3
void Solver::addHardClausesForSoftClauses() {
  vec<Lit> lits;
  int nbUnitSoft=0, nbNonUnitSoft=0;
  hardSoftClauses.clear();
  nbOrignalVars = nVars();
  unitSoftLits.clear(); nonUnitSoftLits.clear(); allSoftLits.clear();
  for(int i=0; i<softClauses.size(); i++) {
    lits.clear();
   Clause& c=ca[softClauses[i]];
   int sat=0;
   for (int j=0; j<c.size(); j++) {
     if (value(c[j]) == l_Undef)
       lits.push(c[j]);
     else if (value(c[j]) == l_True)
       sat=1;
   }
   if (sat==0) {
     if (lits.size() == 0)
       solutionCost += 1;
     else if (lits.size() == 1 && softLits[var(lits[0])] == lit_Undef) {
       softLits[var(lits[0])] = lits[0]; nbUnitSoft++;
       unitSoftLits.push(lits[0]); allSoftLits.push(lits[0]);
     }
     else {
       nbNonUnitSoft++;
       Lit p=createHardClausesFromLits(lits);
       allSoftLits.push(p);
     }
   }
  }
  printf("c nb soft clauses: %d, of which %d unit, %d nonUnit and %llu empty\n", 
	 softClauses.size(), nbUnitSoft, nbNonUnitSoft, solutionCost);
  objForSearch = nbUnitSoft + nbNonUnitSoft;
  rebuildOrderHeap();
  allSoftLits.copyTo(allSoftLitsForCardC);

  for(int i=0; i<softClauses.size(); i++) {
    CRef cr=softClauses[i];
    ca[cr].mark(1);
    ca.free(cr);
  }
  softClauses.clear();
  checkGarbage();
}

//For a set of literals 1 2 3, create a new soft lit x and create
// hard clauses encoding x <-> 1 2 3 (-x 1 2 3, x -1, x -2, x -3)
Lit Solver::createHardClausesFromLits(vec<Lit>& lits) {
    Var vv=newVar(false, false);
    Lit pp = mkLit(vv);
    softLits[vv] = pp;
    nonUnitSoftLits.push(pp);
    lits.push(~pp);
    CRef cr = ca.alloc(lits, false);
    clauses.push(cr);
    attachClause(cr);
    //   hardSoftClauses.push(cr);
    
    lits.pop();
    vec<Lit> ps;   
    ps.clear();
    ps.push(pp);
    ps.push(); // leave a room for the second literal
    for (int ii=0; ii<lits.size(); ii++) {
	 	ps[1] = ~lits[ii];
	 	CRef cr = ca.alloc(ps, false);
	 	clauses.push(cr);
	 	attachClause(cr);
	 	imply[toInt(lits[ii])] = pp;
    }
    return pp;
}

struct unitSoftLits_lt {
    vec2<Lit, vec<Lit> >& conflictLits;
    unitSoftLits_lt(vec2<Lit, vec<Lit> >& conflictLits_) : conflictLits(conflictLits_) {}
  	bool operator () (Lit l1, Lit l2) {
  		return conflictLits[l1].size() < conflictLits[l2].size();
    }
};

void Solver::partition() {
  int nbIsets=0;
  vec<Lit> iset, workingSet, initWorkingSet;

  initConflLits.clear(); initConflLits.push(lit_Undef);
  conflLits.clear(); conflLits.push(lit_Undef);

  // FILE* fp1 = fopen("aaa", "w");
  
  initWorkingSet.clear();
  for(int i=0; i<allSoftLits.size(); i++) {
    Lit p=allSoftLits[i];
    if (value(p) == l_Undef && conflictLits[p].size() > 0) {
      conflicted[var(p)] = 0; picked[var(p)]=0;
      initWorkingSet.push(p);
      vec<Lit>& lits1 = conflictLits[p];
      initConflLits.push(p);
      for(int j=0; j<lits1.size(); j++)
	initConflLits.push(lits1[j]);
      initConflLits.push(lit_Undef);
      
     // for(int j=0; j<lits1.size(); j++)
     //   fprintf(fp1, "%d ", toInt(lits1[j]));
     // fprintf(fp1, "\n");
      
    }
  }
  // for(int i=0; i<initConflLits.size(); i++)
  //   printf("%d ", toInt(initConflLits[i]));
  // printf("\n");
  while (initWorkingSet.size() > 0) {
    workingSet.clear();
    int i, j;
    for(i=0, j=0; i<initWorkingSet.size(); i++) {
      Lit p=initWorkingSet[i];
      vec<Lit>& lits3 = conflictLits[p];
      if (lits3.size() > 0 && !picked[var(p)]) {
	int aa, bb;
	for(aa=0, bb=0; aa<lits3.size(); aa++) {
	  Lit pp = lits3[aa];
	  // eliminate the picked lits from  conflictLits[p]
	  if (!picked[var(pp)] && value(pp) == l_Undef)
	    lits3[bb++] = pp; 
	}
	lits3.shrink(aa-bb);
	if (bb>0) {
	  conflicted[var(p)]=0;
	  workingSet.push(p);
	  initWorkingSet[j++] = p;
	}
	else {
	  conflLits.push(p);
	  conflLits.push(lit_Undef);
	  nbIsets++;
	}
      }
    }
    initWorkingSet.shrink(i-j);
    iset.clear(); 
    while (workingSet.size() > 0) {
      Lit candidate=workingSet[0];
      int min=conflictLits[candidate].size();
      for(int k=1; k<workingSet.size(); k++) {
	Lit q=workingSet[k];
	if (conflictLits[q].size() < min) {
	  candidate=q; min = conflictLits[q].size();
	}
      }
      vec<Lit>& lits2 = conflictLits[candidate];
      for(int ii=0; ii<lits2.size(); ii++) {
	Lit q=lits2[ii];
	if (conflicted[var(q)]==iset.size()) {
	  assert(value(q) == l_Undef && !picked[var(q)]);
	  conflicted[var(q)]++;
	}
      }
      iset.push(candidate); picked[var(candidate)]=1;
      //eliminate lits not conflict with candidate
      int jj, ii;
      for(jj=0, ii=0; jj<workingSet.size(); jj++) {
	Lit q=workingSet[jj];
	if (conflicted[var(q)] < iset.size())
	  conflicted[var(q)]=0;
	else workingSet[ii++]=q;
      }
      workingSet.shrink(jj-ii);
    }
    for(int k=0; k<iset.size(); k++)
      conflLits.push(iset[k]);
    conflLits.push(lit_Undef);
    nbIsets++;
  }

  printf("c init nbIsets: %d\n", nbIsets);
  nbIsets=0;
  
  Lit q = lit_Undef;
  for(int i=0; i<initConflLits.size() - 1; i++) {
    Lit p = initConflLits[i];
    if (p == lit_Undef) {
      q = initConflLits[++i];
      conflictLits[q].clear();
    }
    else conflictLits[q].push(p);
  }

  initConflLits.shrink(initConflLits.size());
  initConflLits.push(lit_Undef);

  // FILE* fp2 = fopen("bbb", "w");
  // for(int i=0; i<unitSoftLits.size(); i++) {
  //   Lit p=unitSoftLits[i];
  //   vec<Lit>& lits6 = conflictLits[p];
  //   for(int j=0; j<lits6.size(); j++)
  //     fprintf(fp2, "%d ", toInt(lits6[j]));
  //   fprintf(fp2, "\n");
  // }

  int i, j;
  for(int pass=0; pass<2; pass++) {
    
  int m, n, debut=0;
  for(i=conflLits.size() - 1; i>=debut;) {
    if (conflLits[i] == lit_Undef) {
      for(j=0; j<conflLits.size(); j++)
	if (conflLits[j] != lit_Undef)
	  conflicted[var(conflLits[j])] = 0;
      iset.clear();
      i--;
    }
    else {
      for(j=i;  conflLits[j] != lit_Undef; j--) {
	Lit p = conflLits[j];
	iset.push(p);
	vec<Lit>& lits4=conflictLits[p];
	for(int a=0; a<lits4.size(); a++)
	  conflicted[var(lits4[a])]++;
      }
      for(m=j-1, n=j-1; m>=debut; m--) {
	Lit q = conflLits[m];
	if (q != lit_Undef && conflicted[var(q)] == iset.size()) {
	  iset.push(q);
	  vec<Lit>& lits5 = conflictLits[q];
	  for(int a=0; a<lits5.size(); a++)
	    conflicted[var(lits5[a])]++;
	}
	else conflLits[n--] = q;
      }
      debut = n+1;
      if (pass == 1 && iset.size() > 1) {
	createHardClausesFromLits(iset);
	for(int k=0; k<iset.size(); k++) 
	  softLits[var(iset[k])] = lit_Undef;
	derivedCost += iset.size() - 1;
	nbIsets++;
	// printf("==== iset : %d \n", iset.size());
	// for(int k=0; k<iset.size(); k++)
	//   // printf("%d ", conflicted[var(iset[k])]);
	//   printf("%d ", toInt(iset[k]));
	// printf("\n++++++\n\n");
	int a, b;
	for(int k=0; k<iset.size(); k++)
	  for(int k1=k+1; k1 <iset.size(); k1++) {
	    Lit p1 = iset[k], p2 = iset[k1];
	    vec<Lit>& lits7 = conflictLits[p1];
	    for(a=0; a<lits7.size(); a++)
	      if (lits7[a] == p2)
		break;
	    if (a == lits7.size())
	      printf("problem a\n");
	    
	    vec<Lit>& lits8 = conflictLits[p2];
	    for(b=0; b<lits8.size(); b++)
	      if (lits8[b] == p1)
		break;
	    
	    if ( b == lits8.size())
	      printf("problem b\n");
	  }
      }
      else {
	for(int k=0; k<iset.size(); k++)
	  initConflLits.push(iset[k]);
	initConflLits.push(lit_Undef);
	nbIsets++;
      }
      i=j;
      assert(conflLits[j] == lit_Undef);
    }
  }
  if (pass == 0) {
    printf("c nbIsets after pass 1: %d\n", nbIsets);
    nbIsets=0;
    conflLits.shrink(conflLits.size());
    
    for(int k=0; k<initConflLits.size(); k++)
      conflLits.push(initConflLits[k]);
  }
  }

  
  for(i=0, j=0; i<unitSoftLits.size(); i++)
    if (softLits[var(unitSoftLits[i])] != lit_Undef)
      unitSoftLits[j++] = unitSoftLits[i];
  unitSoftLits.shrink(i-j);
  bool removedSoftLits = i > j;
  // partition() has already replaced these members and accounted for their cost.
  // Retire inactive auxiliary soft literals as well as inactive unit literals.
  for(i=0, j=0; i<nonUnitSoftLits.size(); i++)
    if (softLits[var(nonUnitSoftLits[i])] != lit_Undef)
      nonUnitSoftLits[j++] = nonUnitSoftLits[i];
  nonUnitSoftLits.shrink(i-j);
  removedSoftLits = removedSoftLits || i > j;
  printf("c isets %d, derivedCost %llu\n", nbIsets, derivedCost);
  if (removedSoftLits)
    rebuildOrderHeap();
  
  for(i=0; i<allSoftLits.size(); i++) {
    Lit p=allSoftLits[i];
    conflicted[var(p)] = 0; picked[var(p)]=0;
  }
  conflLits.clear(); initConflLits.clear();
}

void Solver::addConflictLit(Lit p, Lit q) {
	int i;
	vec<Lit>& lits1=conflictLits[p];
	for(i=0; i<lits1.size(); i++)
		if (lits1[i] == q)
			break;
	if (i==lits1.size())
		lits1.push(q);
	vec<Lit>& lits2=conflictLits[q];
	for(i=0; i<lits2.size(); i++)
		if (lits2[i] == p)
			break;
	if (i==lits2.size())
		lits2.push(p);
}

bool Solver::findConflictSoftLits() {
  CRef confl;
  int initTrail = trail.size(), nbConflLits=0, nbFailedLits=0, nbConfLits2=0;
  int i, j;

  falseLits.clear();
  falseLitsRecord = 0; trailRecord = trail.size();  rootNbIsets = 0;
  UB = unitSoftLits.size()+nonUnitSoftLits.size() + 1;
  for(i=0; i<unitSoftLits.size(); i++) {
	conflictLits[unitSoftLits[i]].clear();
  }
  for(i=0; i<unitSoftLits.size(); i++) {
    Lit p=unitSoftLits[i];
    if (value(p) != l_Undef)
      continue;
    falseLits.clear();
    simpleUncheckEnqueue(p);
    confl = simplePropagate();
    if (confl != CRef_Undef || softConflictFlag){
      cancelUntilTrailRecord(); softConflictFlag=false;
      uncheckedEnqueue(~p);
      if (propagate() != CRef_Undef  || softConflictFlag==true){
	return false;
      }
      trailRecord = trail.size();
      nbFailedLits++;
    }
    else {
      if (falseLits.size() > 0) {
		nbConflLits += falseLits.size();
		for(j=0; j<falseLits.size(); j++)
	  	 addConflictLit(p, falseLits[j]);
      }
    /*  int savedTrailRecord=trailRecord;
      for(j=i+1; j<unitSoftLits.size(); j++) {
      	Lit q = unitSoftLits[j];
      	if (value(q) == l_Undef) {
      		trailRecord = trail.size();
      		falseLitsRecord=falseLits.size();
      		simpleUncheckEnqueue(q);
      		CRef confl1 = simplePropagate();
      		cancelUntilTrailRecord(); softConflictFlag=false;
      		if (confl1 != CRef_Undef || softConflictFlag) {
      			lits.push(q); nbConfLits2++;
      		}
      	}
      }
      trailRecord = savedTrailRecord; falseLitsRecord = 0; */
      cancelUntilTrailRecord();
    }
  }
  printf("c conflLits %d, conflLits2 %d, nbFailedLits %d, fixedVarsBypreproc %d, totalFixedVars %d\n", 
	 nbConflLits, nbConfLits2, nbFailedLits, trail.size()-initTrail, trail.size());
  if (nbConflLits > 0)
	partition();
  return true;
}

void Solver::simpleuncheckedEnqueueForLK(Lit p, CRef from){
    assert(value(p) == l_Undef);
    Var v = var(p);
    assigns[v] = lbool(!sign(p)); // this makes a lbool object whose value is sign(p)
    // vardata[x] = mkVarData(from, decisionLevel());
    vardata[v].reason = from;
    vardata[v].level = decisionLevel() + 1;
    trail.push_(p);
}

CRef Solver::simplepropagateForLK() {
  falseVar = var_Undef;
  CRef    confl = CRef_Undef;
  int     num_props = 0;
  watches.cleanAll();
  watches_bin.cleanAll();
  while (qhead < trail.size()) {
    Lit            p = trail[qhead++];     // 'p' is enqueued fact to propagate.
    vec<Watcher>&  ws = watches[p];
    Watcher        *i, *j, *end;
    num_props++;
    // First, Propagate binary clauses
    vec<Watcher>&  wbin = watches_bin[p];
    
    for (int k = 0; k<wbin.size(); k++) {
      Lit imp = wbin[k].blocker;
      if (value(imp) == l_False) {
	binConfl[0] = ~p; binConfl[1]=imp;
	return CRef_Bin;
	//	return wbin[k].cref;
      }   
      if (value(imp) == l_Undef) {
	simpleuncheckedEnqueueForLK(imp, wbin[k].cref);
	if (auxiVar(var(imp)) && value(softLits[var(imp)]) == l_False && !softVarLocked[var(imp)]) {
	  falseVar = var(imp);
	  return CRef_Undef;
	}
      }
    }
    if (xorCount > 0 && xorPropagate<3>(var(p), confl) != 0) {   // GH-98: XOR watches of var(p)
      qhead = trail.size();
      continue;
    }
    for (i = j = (Watcher*)ws, end = i + ws.size(); i != end;) {
	// Try to avoid inspecting the clause:
	Lit blocker = i->blocker;
	if (value(blocker) == l_True) {
	  *j++ = *i++; continue;
	}
	// Make sure the false literal is data[1]:
	CRef     cr = i->cref;
	Clause&  c = ca[cr];
	Lit      false_lit = ~p;
	if (c[0] == false_lit)
	  c[0] = c[1], c[1] = false_lit;
	assert(c[1] == false_lit);
	// If 0th watch is true, then clause is already satisfied.
	// However, 0th watch is not the blocker, make it blocker using a new watcher w
	// why not simply do i->blocker=first in this case?
	Lit     first = c[0];
	//  Watcher w     = Watcher(cr, first);
	if (first != blocker && value(first) == l_True){
	  i->blocker = first;
	  *j++ = *i++; continue;
	}
	assert(c.lastPoint() >=2);
	if (c.lastPoint() > c.size())
	  c.setLastPoint(2);
	for (int k = c.lastPoint(); k < c.size(); k++) {
	  if (value(c[k]) != l_False) {
	    // watcher i is abandonned using i++, because cr watches now ~c[k] instead of p
	    // the blocker is first in the watcher. However,
	    // the blocker in the corresponding watcher in ~first is not c[1]
	    Watcher w = Watcher(cr, first); i++;
	    c[1] = c[k]; c[k] = false_lit;
	    watches[~c[1]].push(w);
	    c.setLastPoint(k+1);
	    goto NextClause;
	  }
	}
	for (int k = 2; k < c.lastPoint(); k++) {
	  if (value(c[k]) != l_False) {
	    // watcher i is abandonned using i++, because cr watches now ~c[k] instead of p
	    // the blocker is first in the watcher. However,
	    // the blocker in the corresponding watcher in ~first is not c[1]
	    Watcher w = Watcher(cr, first); i++;
	    c[1] = c[k]; c[k] = false_lit;
	    watches[~c[1]].push(w);
	    c.setLastPoint(k+1);
	    goto NextClause;
	  }
	}
	// Did not find watch -- clause is unit under assignment:
	i->blocker = first;
	*j++ = *i++;
	if (value(first) == l_False) {
	  confl = cr;
	  qhead = trail.size();
	  // Copy the remaining watches:
	  while (i < end)
	    *j++ = *i++;
	}
	else {
	  simpleuncheckedEnqueueForLK(first, cr);
	  if (auxiVar(var(first)) && value(softLits[var(first)]) == l_False 
	      && !softVarLocked[var(first)]) {
	    qhead = trail.size();
	    // Copy the remaining watches:
	    while (i < end)
	      *j++ = *i++;
	    falseVar = var(first);
	  }
	}
    NextClause:;
    }
    ws.shrink(i - j);
    // if (confl == CRef_Undef)
    // 	if (shortenSoftClauses(p))
    // 	  break;
  }
  lk_propagations += num_props;
#ifdef XOR_SELFCHECK
  if (confl == CRef_Undef && falseVar == var_Undef && xorCount > 0) xorCheckFixpoint("simplepropagateForLK");
#endif
  return confl;
}

void Solver::simplelookbackResetTrail(CRef confl, bool fromFalseVar) {
  if (confl == CRef_Bin) {
    assert(level(var(binConfl[0])) > decisionLevel());
    assert(level(var(binConfl[1])) > decisionLevel());
    seen[var(binConfl[0])] = 1; seen[var(binConfl[1])] = 1;
  }
  else {
    Clause& c = ca[confl];
    // if (!c.involved()) {
    //   involvedClauses.push(confl);
    //   c.setInvolved(1);
    // }
    if (fromFalseVar && c.size() == 2 && value(c[0]) == l_False) {
      // Special case for binary clauses: the first one has to be SAT
      assert(value(c[1]) == l_True);
      Lit tmp = c[0];
      c[0] = c[1]; c[1]=tmp;
    }  
    for(int i=(fromFalseVar ? 1 : 0); i<c.size(); i++) {
      Lit q=c[i]; Var v = var(q);
      if (!seen[v] && level(v) > decisionLevel())
	seen[v]=1;
    }
  }
  int index = trail.size() - 1;
  while (index >= trailRecord) {
    Lit p = trail[index--];
    Var v = var(p);
    if (seen[v]) {
      seen[v] = 0;
      confl = reason(v);
      if (confl == CRef_Undef) {
	conflLits.push(p);      softVarLocked[v]=1;
      }
      else {
	if (auxiVar(v))
	  insertAuxiVarOrder(v);
	Clause& rc = ca[confl];
	// if (!rc.involved()) {
	//   involvedClauses.push(confl);
	//   rc.setInvolved(1);
	// }
	// Special case for binary clauses: the first one has to be SAT
	if (rc.size() == 2 && value(rc[0]) == l_False) {
	  assert(value(rc[1]) == l_True);
	  Lit tmp = rc[0];
	  rc[0] = rc[1], rc[1] = tmp;
	}
	for (int j = 1; j < rc.size(); j++){
	  Lit q = rc[j]; Var vv=var(q);
	  if (!seen[vv] && level(vv) > decisionLevel()){
	    seen[vv] = 1;
	  }
	}
      }
    }
    else if (auxiVar(v))
      insertAuxiVarOrder(v);
    assigns[v] = l_Undef;
  }
  qhead = trailRecord;
  trail.shrink(trail.size() - trailRecord);
}

bool Solver::detectInitConflicts() {
  vec<Lit> ps;
  //  int baseLevel = decisionLevel();
  int nbConfl=0, nbLits=0;
  trailRecord = trail.size(); 
  UBconflictFlag=false; softConflictFlag=false; falseVar = var_Undef;
  LOOKAHEAD++; //newDecisionLevel();
  lastConflLits.clear(); conflLits.clear();
  int i, point=0;
  bool flag=true;
  do {
    if (flag)
      for (i=0; i< nonUnitSoftLits.size(); i++) {
	Lit p = nonUnitSoftLits[i];
	if (value(p) == l_Undef && !softVarLocked[var(p)])
	  simpleuncheckedEnqueueForLK(softLits[var(p)]);
      }
    flag=false;      conflLits.clear();
    for(i=point; i<unitSoftLits.size(); i++) {
      Lit p=unitSoftLits[i];
      if (value(p) == l_Undef && !softVarLocked[var(p)]) {
	simpleuncheckedEnqueueForLK(softLits[var(p)]);
	CRef confl = simplepropagateForLK();
	if (confl != CRef_Undef) {
	  simplelookbackResetTrail(confl, false); nbConfl++;
	  flag=true; point = i;
	  break;
	}
	else if (falseVar != var_Undef) {
	  simplelookbackResetTrail(reason(falseVar), true); nbConfl++;
	  softVarLocked[falseVar]=1;
	  conflLits.push(softLits[falseVar]);
	  falseVar = var_Undef;
	  flag=true; point = i;
	  break;
	}
      }
    }
    if (flag) {
      ps.clear();
      for(int i=0; i<conflLits.size(); i++) {
	Lit p = conflLits[i];
	softVarLocked[var(p)] = 0;
	ps.push(~p);
      }
      if (ps.size() == 1) {
	uncheckedEnqueue(ps[0]);
	if (propagate() != CRef_Undef  || softConflictFlag==true)
	  return false;
      }
      else {
	CRef cr=ca.alloc(ps, false);
	clauses.push(cr);
	attachClause(cr);
      }
      softVarLocked[var(conflLits[0])] = 1; lastConflLits.push(conflLits[0]);
      nbLits += ps.size();
    }
    if (i == unitSoftLits.size() && point > 0)
      point = 0;
  } while (point > 0 || i < unitSoftLits.size());

  for(int i=0; i<lastConflLits.size(); i++)
    softVarLocked[var(lastConflLits[i])] = 0;
  lastConflLits.clear();
  assert(involvedLits.size() == 0);
  // for(int i=0; i<involvedClauses.size(); i++) {
  //   Clause& c = ca[involvedClauses[i]];
  //   c.setInvolved(0);
  // }
  // involvedClauses.clear();
  for(int i=trailRecord; i< trail.size(); i++) {
    Var v=var(trail[i]);
    assigns[v] = l_Undef;
  }
  trail.shrink(trail.size() - trailRecord);
  qhead = trailRecord;
  // trail_lim.shrink(1);
  printf("c %d conflict sets found with length %d\n", nbConfl, nbLits);
  return true;
}
