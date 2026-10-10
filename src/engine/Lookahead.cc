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
 * DistQLDPC engine -- module Lookahead.cc
 *
 * Lower-bound lookahead: LK propagation, lookback, inconsistent-set bookkeeping, auxiliary
 * variable heap and selection, lookahead, lookaheadForRestart, fixByLookahead.
 *
 * Restructured from MaxCDCL src/solver/Solver.cc by DistQLDPC (GH-95, stage 1): code moved
 * verbatim, search unchanged. The copyright and MIT permission notice above apply to the
 * MaxCDCL / Maple_CM / Maple_LCM / MiniSat code contained in this file (see src/solver/LICENSE).
 *
 * Modifications Copyright (C) 2025-2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>, part of DistQLDPC
 * (GPL-3.0-or-later when distributed as this project; see LICENSE, NOTICE, MODIFICATIONS.md).
 */

#ifndef DISTQLDPC_ENGINE_UNITY
#error "src/engine/Lookahead.cc is part of the engine unity build; compile src/engine/Engine.cc"
#endif

void Solver::simplelookback(CRef confl, Var falseVar, vec<Lit>& lits, vec<Lit>& out_learnt) {
  int pathC=0;
  out_learnt.clear(); lits.clear();
  if (confl == CRef_Bin) {
    assert(level(var(binConfl[0])) > decisionLevel());
    assert(level(var(binConfl[1])) > decisionLevel());
    seen[var(binConfl[0])] = 1; seen[var(binConfl[1])] = 1;  pathC = 2;
  }
  else {
    Clause& c = ca[confl];
    if (falseVar != var_Undef) {
      if (c.size() == 2 && value(c[0]) == l_False) {
	// Special case for binary clauses: the first one has to be SAT
	assert(value(c[1]) == l_True);
	Lit tmp = c[0];
	c[0] = c[1]; c[1]=tmp;
      }
      assert(!seen[falseVar] && level(falseVar) > decisionLevel());
      out_learnt.push(~softLits[falseVar]); lits.push(~softLits[falseVar]);
    }
    for(int i=(falseVar == var_Undef ? 0 : 1); i<c.size(); i++) {
      Lit q=c[i]; Var v = var(q);
      if (level(v) > 0 && !seen[v]) {
	seen[v]=1;
	if (level(v) > decisionLevel())
	  pathC++;
      }
    }
  }
  int index = trail.size() - 1;
  while (index >= trailRecord) {
    Lit p = trail[index--]; Var v = var(p);
    if (seen[v]) {
      seen[v] = 0; pathC--;
      confl = reason(v);
      if (pathC == 0 && falseVar == var_Undef && lits.size() == 0) {
	out_learnt.push(~p);
	for(index = trail.size() - 1; index >= trailRecord; index--) {
	  Lit q = trail[index]; Var vv = var(q);
	  assert(!seen[vv]);
	  assigns[vv] = l_Undef;
	  if (auxiVar(vv))
	    insertAuxiVarOrder(vv);
	}
	qhead = trailRecord;
	trail.shrink(trail.size() - trailRecord);
	return;
      }
      if (confl == CRef_Undef) {
	lits.push(~p); out_learnt.push(~p);
      }
      else {
	Clause& rc = ca[confl];
	// Special case for binary clauses: the first one has to be SAT
	if (rc.size() == 2 && value(rc[0]) == l_False) {
	  assert(value(rc[1]) == l_True);
	  Lit tmp = rc[0];
	  rc[0] = rc[1], rc[1] = tmp;
	}
	for (int j = 1; j < rc.size(); j++){
	  Lit q = rc[j]; Var vv=var(q);
	  if (level(vv) > 0 && !seen[vv]) {
	    seen[vv] = 1;
	    if (level(vv) > decisionLevel())
	      pathC++;
	  }
	}
      }
    }
  }
}

int Solver::lookaheadForRestart() {
  int lb = UB-falseLits.size();
  if (lb==0) {
    return NON;
  }
  if (lb == 1) {
    if (!orderHeapAuxi.empty())
      hardenForRestart(NON, trail.size());
    return 0;
  }
  if (stepSizeLB > 0.06) stepSizeLB -= 0.000001;
  
  //  int baseLevel = decisionLevel();
  int nbConfl=0;
  trailRecord = trail.size(); 
  UBconflictFlag=false; softConflictFlag=false; falseVar = var_Undef;
  //  newDecisionLevel();
  lastConflLits.clear();
  for(int i=conflLits.size()-1; i>=0; i--)
    if  (conflLits[i] != lit_Undef)
      lastConflLits.push(conflLits[i]);
  for(int i=initConflLits.size()-1; i>=0; i--) {
    Lit p=initConflLits[i];
    if (p != lit_Undef)
      lastConflLits.push(p);
  }
  int nbIsets=0;
  vec<Lit> out_learnt, ps;
#ifdef printTestedVar
  printf("\n\nc **********lookahead: %llu, lb: %d, NbFalseLits: %d, thres: %d, UB: %llu\n", LOOKAHEAD, lb, falseLits.size(), thres, UB);
#endif

  int i, j;
  for(i=0, j=0; i<isetClauses.size(); i++) {
    Clause& c=ca[isetClauses[i]];
    if (c.mark() == LOCAL)
      removeClause(isetClauses[i]);
    else if (c.mark() != 1)
      isetClauses[j++] = isetClauses[i];
  }
  isetClauses.shrink(i-j);

  while (1) {
    Var v = pickAuxiVar();
    if (v == var_Undef)
      break;
#ifdef printTestedVar
    printf("c %d %10.9lf ", v, activityLB[v]);
#endif
    uncheckedEnqueueForLK(softLits[v]);
    CRef confl = propagateForLK();
    if (confl != CRef_Undef || falseVar != var_Undef) {
      isetsLits.init(nbIsets); isetsLits[nbIsets].clear();
      if (confl == CRef_Undef) {
	confl = reason(falseVar); isetsLits[nbIsets].push(softLits[falseVar]);
      }
      simplelookback(confl, falseVar, ps, out_learnt);
      if (ps.size() == 0 && out_learnt.size() == 1) {
      	Lit p=out_learnt[0];
      	printf("c ****unit iset %d\n", var(p));
	
      	resetConflicts_(nbIsets);
	//	bumpConflVars();
	isetsLits[nbIsets].clear(); nbConfl=0; nbIsets=0;
      	uncheckedEnqueue(p);
      	if (propagate() != CRef_Undef  || softConflictFlag==true) {
      	  return NON;
      	}
      	trailRecord = trail.size(); lb = UB-falseLits.size();
      	UBconflictFlag=false; softConflictFlag=false; falseVar = var_Undef;
      	lastConflLits.clear();
      	for(int i=conflLits.size()-1; i>=0; i--)
      	  if  (conflLits[i] != lit_Undef)
      	    lastConflLits.push(conflLits[i]);
      	for(int i=initConflLits.size()-1; i>=0; i--) {
      	  Lit p=initConflLits[i];
      	  if (p != lit_Undef)
      	    lastConflLits.push(p);
      	}
      	continue;
      }
      int nbSeen = 0, csize;
      if (confl == CRef_Bin) {
	csize=2;
	counter++;
	seen2[toInt(binConfl[0])] = counter; seen2[toInt(binConfl[1])] = counter;
      }
      else {
	Clause& c = ca[confl]; csize=c.size();
	if (falseVar != var_Undef && csize <= ps.size()) {
	  counter++;
	  for(int i=0; i<c.size(); i++)
	    seen2[toInt(c[i])] = counter;
	}
      }
      for(int i=0; i<ps.size(); i++)
	if (seen2[toInt(ps[i])] == counter)
	  nbSeen++;
      if (nbSeen < csize) {
	assert(ps.size() > 1);
	CRef cr=ca.alloc(ps, true);
	isetClauses.push(cr);
	attachClause(cr);
      }
      //	  else printf("q\n");
      //	else printf("nnn old %d new %d\n", saved, lits.size());
      lookbackResetTrail(confl, falseVar, nbIsets, out_learnt); nbConfl++;
      setConflict(nbIsets);
      falseVar = var_Undef;
      if (lb==nbConfl) {
	printf("c softConfl at top...\n");
#ifdef printTestedVar
	printf("c ====== maxSuccLB: %d\n", maxSuccLB);
#endif
	UBconflictFlag = true; softConflictFlag = true;
	//	trail_lim.shrink(1);
	nbLKsuccess++; totalPrunedLB += lb; totalPrunedLB2 += lb*lb;
	resetConflicts(nbIsets);
	bumpConflVars();
	return NON; 
      }
    }
  }
  assert(nbIsets == nbConfl);
  if (nbConfl == lb - 1) {
    printf("c quasi softConfl at top...\n");
    quasiSoftConflicts++;
    hardenForRestart(nbIsets, trailRecord);
  }
  else {
    for(int i=trailRecord; i< trail.size(); i++) {
      Var v=var(trail[i]);
      assigns[v] = l_Undef;
      if (auxiVar(v)) {
	assert(v>=0 && v<activityLB.size());
	activityLB[v] = (1-stepSizeLB)*activityLB[v];
	insertAuxiVarOrder(v);
	orderHeapAuxi.decrease(v);
      }
    }
    trail.shrink(trail.size() - trailRecord);
    qhead = trailRecord;
    //   trail_lim.shrink(1);
    //   resetConflicts(nbIsets);
    bumpConflVars(); //the score of confl vars and non-confl vars is updated differently
  }
  for(int i=0; i<involvedLits.size(); i++) {
    involved[var(involvedLits[i])] = 0;
  }
  involvedLits.clear();
  return nbIsets;
}

bool Solver::uncheckedEnqueueForLK(Lit p, CRef from){
    assert(value(p) == l_Undef);
    Var v = var(p);
    assigns[v] = lbool(!sign(p)); // this makes a lbool object whose value is sign(p)
    // vardata[x] = mkVarData(from, decisionLevel());
    vardata[v].reason = from;
    vardata[v].level = decisionLevel() + 1;
    trail.push_(p);

    // GH-103 C4: softLits[v] is lit_Undef or a literal of v (softLits[var(l)] = l), and p is now
    // true, so "auxiVar(v) && value(softLits[v]) == l_False" is exactly "softLits[v] == ~p".
    if (softLits[v] == ~p) // a soft clause is falsified
      return falsifiedSoftVarForLK(v);
    return true;
}

__attribute__((noinline)) bool Solver::falsifiedSoftVarForLK(Var v){
    assert(auxiVar(v) && value(softLits[v]) == l_False);
    {
      if (unLockedSoftVarForLK(v))
	return false;
      else {
	int iset = getLockedVarIsetForLK(v);
	decrmentIsetLock(iset);
	unLockedVars.push(v);
	if (getIsetLock(iset)==0) {
	  vec<int>& confls = isets[iset];
	  assert(iset == finalIset[iset]);
	  assert(iset < isets.size() && iset >=0 );
	  for(int j=0; j<confls.size(); j++) {
	    vec<Lit>& lits = isetsLits[confls[j]];
	    for(int i=0; i<lits.size(); i++) {
	       if (value(lits[i]) == l_Undef)
		insertAuxiVarOrder(var(lits[i]));
	    }
	  }
	}
      }
    }
    return true;
}

CRef Solver::propagateForLK() {
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
      }
      if (value(imp) == l_Undef) {
	if (!uncheckedEnqueueForLK(imp, wbin[k].cref)) {
	  falseVar = var(imp);
	  return CRef_Undef;
	}
      }
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
	if (first != blocker) {
	  i->blocker = first;
	  if (value(first) == l_True){
	    *j++ = *i++; continue;
	  }
	}
	assert(c.lastPoint() >=2);
	if (c.lastPoint() > c.size())
	  c.setLastPoint(2);
	for (int k = c.lastPoint(); k < c.size(); k++) {
	  if (value(c[k]) == l_Undef) {
	    // watcher i is abandonned using i++, because cr watches now ~c[k] instead of p
	    // the blocker is first in the watcher. However,
	    // the blocker in the corresponding watcher in ~first is not c[1]
	    //  Watcher w = Watcher(cr, first); i++;
	    c[1] = c[k]; c[k] = false_lit;
	    watches[~c[1]].push(*i++);
	    c.setLastPoint(k+1);
	    goto NextClause;
	  }
	  else if (value(c[k]) == l_True) {
	    i->blocker = c[k];  *j++ = *i++;
	    c.setLastPoint(k);
	    goto NextClause;
	  }
	}
	for (int k = 2; k < c.lastPoint(); k++) {
	  if (value(c[k]) ==  l_Undef) {
	    // watcher i is abandonned using i++, because cr watches now ~c[k] instead of p
	    // the blocker is first in the watcher. However,
	    // the blocker in the corresponding watcher in ~first is not c[1]
	    //   Watcher w = Watcher(cr, first); i++;
	    c[1] = c[k]; c[k] = false_lit;
	    watches[~c[1]].push(*i++);
	    c.setLastPoint(k+1);
	    goto NextClause;
	  }
	  else if (value(c[k]) == l_True) {
	    i->blocker = c[k];  *j++ = *i++;
	    c.setLastPoint(k);
	    goto NextClause;
	  }
	}
	// Did not find watch -- clause is unit under assignment:
	//	i->blocker = first;
	*j++ = *i++;
	if (value(first) == l_False) {
	  confl = cr;
	  qhead = trail.size();
	  // Copy the remaining watches:
	  while (i < end)
	    *j++ = *i++;
	}
	else {
	  if (!uncheckedEnqueueForLK(first, cr)) {
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
  return confl;
}

int Solver::seeUnlockLits(int iset, int falseVar) {
  vec<int>& myInconfls = isets[iset];
  int nbfalse=0;
  for(int i=0; i<myInconfls.size(); i++) {
    vec<Lit>& lits = isetsLits[myInconfls[i]];
    for(int j=0; j<lits.size(); j++) {
      Var v=var(lits[j]);
      if (value(lits[j]) == l_False && level(v) > decisionLevel()
	  && falseVar != v && !seen[v]) {
	nbfalse++;
	seen[v] = 1;
      }
    }
  }
  // assert(nbfalse == myInconfls.size());
  return nbfalse;
}

void Solver::lookbackResetTrail(CRef confl, Var falseVar, int nbIsets, vec<Lit>& out_learnt, bool last) {
  int pathC=0;
  // GH-103 C6: loop invariants kept in locals (stores to char-typed seen/assigns would force reloads)
  const int dl = decisionLevel(); const bool vsids = VSIDS; const int tr = trailRecord;
  Lit* const trl = trail;
  out_learnt.clear();
  out_learnt.push();
  if (confl == CRef_Bin) {
    assert(level(var(binConfl[0])) > decisionLevel());
    assert(level(var(binConfl[1])) > decisionLevel());
    seen[var(binConfl[0])] = 1; seen[var(binConfl[1])] = 1;  pathC = 2;
    if (vsids) {
      varBumpActivity(var(binConfl[0]), .1);
      varBumpActivity(var(binConfl[0]), .1);
    }
  }
  else {
    Clause& c = ca[confl];
    // if (!c.involved()) {
    //   involvedClauses.push(confl);
    //   c.setInvolved(1);
    // }
    if (falseVar != var_Undef) {
      if (c.size() == 2 && value(c[0]) == l_False) {
	// Special case for binary clauses: the first one has to be SAT
	assert(value(c[1]) == l_True);
	Lit tmp = c[0];
	c[0] = c[1]; c[1]=tmp;
      }
      if (inConflicts[falseVar] != NON)
	pathC += seeUnlockLits(getLockedVarIsetForLK(falseVar), falseVar);
      assert(!seen[falseVar] && level(falseVar) > decisionLevel());
      out_learnt.push(softLits[falseVar]);
    }
    for(int i=(falseVar == var_Undef ? 0 : 1); i<c.size(); i++) {
      Lit q=c[i]; Var v = var(q);
      if (level(v) > 0) {
	if (!seen[v]) {
	  seen[v]=1;
	  if (level(v) > dl)
	    pathC++;
	  else {
	    out_learnt.push(q);
	    if (!involved[var(q)]) {
	      involved[var(q)] = 1;
	      involvedLits.push(q);
	    }
	  }
	  if (vsids)
	    varBumpActivity(v, .1);
	}
      } 
    }
  }
  int index = trail.size() - 1;
  while (index >= tr) {
    Lit p = trl[index--];
    Var v = var(p);
    if (seen[v]) {
      seen[v] = 0; pathC--;
      confl = reason(v);
      if (pathC == 0 && falseVar == var_Undef && isetsLits[nbIsets].size() == 0
	  && (!last || (auxiVar(var(p)) && inConflicts[var(p)] == NON && p == softLits[v]))) {
	//printf("y %u %d %d\n", confl, (auxiVar(v) ? toInt(value(softLits[v])) : -7), out_learnt.size());
	out_learnt[0] = ~p; assigns[v] = l_Undef;
	if (last && auxiVar(v) && inConflicts[v] == NON && p == softLits[v])
	  isetsLits[nbIsets].push(p);
	insertAuxiVarOrder(v);
	for(; index >= tr; index--) {
	  Lit q = trl[index];
	  Var vv = var(q);
	  assert(!seen[vv]);
	  assigns[vv] = l_Undef;
	  insertAuxiVarOrder(vv);
	}
	break;
      }
      if (confl == CRef_Undef) {
	isetsLits[nbIsets].push(p); out_learnt.push(~p);
	if (inConflicts[v] != NON)
	  pathC += seeUnlockLits(getLockedVarIsetForLK(v), falseVar);
      }
      else {
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
	int nbSeen=0;
	int resolventSize=pathC + out_learnt.size();
	for (int j = 1; j < rc.size(); j++){
	  Lit q = rc[j]; Var vv=var(q);
	  if (level(vv) > 0) {
	    if (seen[vv])
	      nbSeen++;
	    else {
	      seen[vv] = 1;
	      if (level(vv) > dl)
		pathC++;
	      else {
		out_learnt.push(q);
		if (!involved[var(q)]) {
		  involved[var(q)] = 1;
		  involvedLits.push(q);
		}
	      }
	      if (vsids)
		varBumpActivity(vv, .1);
	    }
	  }
	}
	if (nbSeen >= resolventSize) {
	  assert(falseVar==var_Undef);
	  reduceClause(confl, pathC);
	  //  printf("x\n");
	}
      }
    }
    else
      insertAuxiVarOrder(v); // GH-103 C3: insertAuxiVarOrder tests auxiVar(v) itself
    assigns[v] = l_Undef;
  }
  qhead = trailRecord;
  trail.shrink(trail.size() - trailRecord);
  //  if (isetsLits[nbIsets].size() > 0)
    for(int i=0; i<out_learnt.size(); i++)
      seen[var(out_learnt[i])] = 0;
}

void Solver::bumpConflVars() {
  for(int i=0; i<conflLits.size(); i++) {
    if (conflLits[i] != lit_Undef) {
      Var v = var(conflLits[i]);
      assert(v>=0 && v<activityLB.size());
      double oldAct = activityLB[v];
      // the two equations are equivalent, but the practical precision is different
      // activityLB[v] = stepSizeLB + (1-stepSizeLB)*oldAct;
      activityLB[v] = oldAct + (1-oldAct)*stepSizeLB; 
      insertAuxiVarOrder(v);
      assert(activityLB[v] >= oldAct);
      orderHeapAuxi.increase(v);
    }
  }
}

Var Solver::pickAuxiVar() {
  Var v = var_Undef;
  while(lastConflLits.size() > 0) {
    Lit p=lastConflLits[lastConflLits.size()-1];
    lastConflLits.shrink_(1);
    assert(auxiVar(var(p)));
    if (value(p) == l_Undef && unLockedSoftVarForLK(var(p)))
      return var(p);
  }
  while (v == var_Undef || value(v) != l_Undef || !unLockedSoftVarForLK(v)) {
    if (orderHeapAuxi.empty())
      return var_Undef;
    else {
      v = orderHeapAuxi.removeMin();
      assert(auxiVar(v));
    }
  }
  return v;
}

void Solver::setConflict(int& nbIsets) {
 for(int c = unLockedVars.size()-1; c >= 0; c--) {
    Var x = unLockedVars[c];
    incrementIsetLock(inConflicts[x]);
 }
 unLockedVars.shrink(unLockedVars.size());
  
  vec<int> oldset;
  int i, j, newlock = 1;
  oldset.clear();
  isets.init(nbIsets); isets[nbIsets].clear(); isets[nbIsets].push(nbIsets);
  for(i=0; i<=nbIsets; i++) seen[i]=0;
  finalIset.growTo(nbIsets+1); finalIset[nbIsets] = nbIsets;
  vec<Lit>& newlits = isetsLits[nbIsets]; // new inconsistent set of soft lits
  for(i=0, j=0; i<newlits.size(); i++) {
    Lit p = newlits[i];
    if (inConflicts[var(p)] == NON) {
      newlits[j++] = p; // we only keep the new involved lits in the set
      inConflicts[var(p)] = nbIsets;
    }
    else {
      int iset=getLockedVarIsetForLK(var(p));
      assert(iset<nbIsets && iset>=0);
      if (!seen[iset]) {
	newlock += getIsetLock(iset);
	vec<int>& myInconfls = isets[iset];
	assert(myInconfls.size() > 0);
	for(int k=0; k<myInconfls.size(); k++) {
	  int subIset=myInconfls[k];
	  assert(!seen[subIset]);
	  seen[subIset] = 1;
	  oldset.push(subIset);
	}
	assert(seen[iset]);
      }
    }
  }
  newlits.shrink(i-j);
  
  if (oldset.size() > 0) {
    vec<int>& myInconfls2 = isets[nbIsets];
    for(i=0; i<oldset.size(); i++) {
      int subIset = oldset[i];
      assert(seen[subIset]);
      myInconfls2.push(subIset);
      finalIset[subIset] = nbIsets;
      seen[subIset] = 0;
    }
    for(i=0; i<nbIsets; i++) assert(!seen[i]);
  }
  isetLock.growTo(nbIsets+1);  setIsetLock(nbIsets, newlock);
  nbIsets++;
}

void Solver::resetConflicts(int nbIsets) {
  unLockedVars.shrink(unLockedVars.size());

  conflLits.clear();
  for(int i=0; i<nbIsets; i++) {
    isetLock[i] = 0; finalIset[i] = NON;
    vec<Lit>& lits = isetsLits[i];
    for(int k=0; k<lits.size(); k++) {
      Lit p = lits[k];
      inConflicts[var(p)] = NON; 
      softVarLocked[var(p)] = 0;
      //  unlockReasonForLK[var(p)] = var_Undef;
      conflLits.push(p);
      insertAuxiVarOrder(var(p));
    }
  }
}

void Solver::resetConflicts_(int nbIsets) {
  unLockedVars.shrink(unLockedVars.size());

  for(int i=0; i<nbIsets; i++) {
    isetLock[i] = 0; finalIset[i] = NON;
    vec<Lit>& lits = isetsLits[i];
    for(int k=0; k<lits.size(); k++) {
      Lit p = lits[k];
      inConflicts[var(p)] = NON; 
      softVarLocked[var(p)] = 0;
      //  unlockReasonForLK[var(p)] = var_Undef;
      insertAuxiVarOrder(var(p));
    }
  }
}

Var Solver::simplePickAuxiVar() {
  Var v = var_Undef;
  while (v == var_Undef || value(v) != l_Undef ){ 
    if (orderHeapAuxi.empty())
      return var_Undef;
    else {
      v = orderHeapAuxi.removeMin();
      assert(auxiVar(v));
    }
  }
  return v;
}

void Solver::fixByLookahead(vec<Lit>& out_learnt) {
  int btlevel, lbd;
  nbFixedByLH++;
  for(int i=1; i<out_learnt.size(); i++)
    seen[var(out_learnt[i])]=1;
  simplifyQuasiConflictClause(out_learnt, btlevel, lbd);
  cancelUntil(btlevel);
  if (out_learnt.size() == 1)
    uncheckedEnqueue(out_learnt[0]);
  else {
    CRef cr = ca.alloc(out_learnt, true);
    if (out_learnt.size() > splitClauseSize && lbd<=tier2_lbd_cut)
      hardLearnts.push(cr);
    ca[cr].set_lbd(lbd);
    if (lbd <= core_lbd_cut){
      learnts_core.push(cr);
      ca[cr].mark(CORE);
      ca[cr].touched() = conflicts;
    }else if (lbd <= tier2_lbd_cut){
      learnts_tier2.push(cr);
      ca[cr].mark(TIER2);
      ca[cr].touched() = conflicts;
    }else{
      learnts_local.push(cr); }
    claBumpActivity(ca[cr]);
    attachClause(cr);
    uncheckedEnqueue(out_learnt[0], cr);
  }
}

//#define printTestedVar

// The involvedClauses stack stores the hard clauses that make disjoint conflicting soft clauses.
// If Ub is reached, the stack (together with the involved flag of each involved clauses) is cleared 
// when analyzing the soft conflict
// Otherwise, it is cleared here before returning true.
bool Solver::lookahead() {
  // GH-73: former function-local statics, now per-instance members
  int& thres = lk_thres;
  int& prevConflicts = lk_prevConflicts;
  int& maxSuccLB = lk_maxSuccLB;
  uint64_t& prevUB = lk_prevUB;
  int& nbSample = lk_nbSample;
  double& sumLB = lk_sumLB;
  double& sumSQLB = lk_sumSQLB;
  double& coef = lk_coef;
  int& myLH = lk_myLH;
  int& mySucc = lk_mySucc;

  hardenEnable = false; LHconfl = CRef_Undef;
  // return true;
  if (UB != prevUB) {
    prevUB = UB; nbSample=0; sumLB=0; sumSQLB=0;
  }

  assert(involvedLits.size() == 0);
  // for(int i=0; i<nVars(); i++)
  //   assert(!involved[i]);
  // if (UB < prevUB) {
  //   maxSuccLB = 0;
  //   // maxSuccLB -= prevUB - UB;
  //   // if (maxSuccLB < 0)
  //   //   maxSuccLB=0;
  //   // printf("c maxSuccLB: %d, UB: %llu \n", maxSuccLB, UB);
  //   prevUB = UB;
  // }

  int lb = UB-falseLits.size();
  if (lb==0) {
    UBconflictFlag = false; softConflictFlag = true;
    return false;
  }
  if (lb == 1) {
    if (!orderHeapAuxi.empty())
      moreHarden();
    return true;
  }
  int sampled=0;
  if (conflicts > prevConflicts) {
    if (drand(random_seed) < 0.01) {
      thres = lb;
      sampled=1;
    }
    else thres = maxSuccLB;
    // if (thres > UB/2)
    //   printf("c %d %llu\n", thres, UB/2);
    //  assert(thres <= UB/2);
    prevConflicts = conflicts;
  }
  if (LOOKAHEAD == nbLKsuccess)
    thres = UB;
  if (lb > thres)
    return true;

  if (stepSizeLB > 0.06) stepSizeLB -= 0.000001;
  
  // int baseLevel = decisionLevel();
  int nbConfl=0;
  trailRecord = trail.size(); 
  UBconflictFlag=false; softConflictFlag=false; falseVar = var_Undef;
  LOOKAHEAD++; //newDecisionLevel();
  lastConflLits.clear();
  for(int i=conflLits.size()-1; i>=0; i--)
    if  (conflLits[i] != lit_Undef)
      lastConflLits.push(conflLits[i]);
  // printf("c %d ", lastConflLits.size());
  for(int i=initConflLits.size()-1; i>=0; i--) {
    Lit p=initConflLits[i];
    if (p != lit_Undef)
      lastConflLits.push(p);
    // else printf("fdf ");
  }
  int nbIsets=0;
  vec<Lit> out_learnt;
#ifdef printTestedVar
  printf("\n\nc **********lookahead: %llu, lb: %d, NbFalseLits: %d, thres: %d, UB: %llu\n", LOOKAHEAD, lb, falseLits.size(), thres, UB);
#endif

  if (!sampled)
    myLH+=2;
  //  printf("\n");
  while (1) {
    Var v = pickAuxiVar();
    if (v == var_Undef)
      break;
#ifdef printTestedVar
    printf("c %d %10.9lf ", v, activityLB[v]);
#endif
    // testedVars.push(v);
    // lastTested[v]=LOOKAHEAD;
    //  Lit p=mkLit(v);
    uncheckedEnqueueForLK(softLits[v]);
    CRef confl = propagateForLK();
    if (confl != CRef_Undef) {  // printf("\n");
      isetsLits.init(nbIsets); isetsLits[nbIsets].clear();
      nbConfl++;
      lookbackResetTrail(confl, var_Undef, nbIsets, out_learnt, nbConfl==lb); 
      if (lb > nbConfl) {
	if (isetsLits[nbIsets].size() == 0) {
	  resetConflicts_(nbIsets);
	  for(int i=0; i<involvedLits.size(); i++) {
	    involved[var(involvedLits[i])] = 0;
	  }
	  involvedLits.clear();
	  UBconflictFlag=false; softConflictFlag=false; falseVar = var_Undef;
	  isetsLits[nbIsets].clear(); nbConfl=0;   nbIsets=0; 
	  fixByLookahead(out_learnt);
	  CRef confl=propagate();
	  if (confl != CRef_Undef  || softConflictFlag==true) {
	    if (confl != CRef_Undef)
	      LHconfl = confl;
	    return false;
	  }
	  trailRecord = trail.size(); lb = UB-falseLits.size();
	  UBconflictFlag=false; softConflictFlag=false; falseVar = var_Undef;
	  lastConflLits.clear();
	  for(int i=conflLits.size()-1; i>=0; i--)
	    if  (conflLits[i] != lit_Undef)
	      lastConflLits.push(conflLits[i]);
	  for(int i=initConflLits.size()-1; i>=0; i--) {
	    Lit p=initConflLits[i];
	    if (p != lit_Undef)
	      lastConflLits.push(p);
	  }
	  continue;
	}
	setConflict(nbIsets);
      }
#ifdef printTestedVar
      printf("£ %d\n", nbConfl);
#endif
      //	indexL=0; indexS=0;
    }
    else if (falseVar != var_Undef) {   //printf("\n");
      isetsLits.init(nbIsets); isetsLits[nbIsets].clear();
      lookbackResetTrail(reason(falseVar), falseVar, nbIsets, out_learnt); nbConfl++;
#ifdef printTestedVar
      printf("$ %d %d\n", falseVar, nbConfl);
#endif
      //	indexL=0; indexS=0;
      // lastTested[falseVar]=LOOKAHEAD;
      // testedVars.push(falseVar);
      if (lb > nbConfl) {
	isetsLits[nbIsets].push(softLits[falseVar]);
	setConflict(nbIsets);
      }
      falseVar = var_Undef;
    }
    if (lb==nbConfl) {
#ifdef printTestedVar
      printf("c ====== maxSuccLB: %d\n", maxSuccLB);
#endif
      if (sampled) {
	nbSample++;
	sumLB += nbConfl; sumSQLB += nbConfl*nbConfl;
	double meanLB = ((double)sumLB)/nbSample;
	double meanSQLB = ((double)sumSQLB)/nbSample;
	double stddev = sqrt(meanSQLB - meanLB*meanLB);
	if (myLH > 0) {
	  int rate = (mySucc * 100)/myLH;
	  if (rate > 75 && (meanLB + coef*stddev) < UB)
	    coef += 0.1;
	  else if (rate <= 60 && (meanLB + coef*stddev) > 1)
	    coef -= 0.1;
	  // if ((meanLB + coef*stddev) > UB+1)
	  //   coef = (UB+1 - meanLB)/stddev;
	  //  printf("rate : %d, coef: %2.1lf, UB: %llu, new thres: %d, mean: %4.2lf, stddev: %4.2lf\n", rate, coef, UB, (int)(meanLB + coef*stddev), meanLB, stddev);
	}
	else {
	  if (coef < 2)
	    coef = 2;
	  //	  printf("no LH\n");
	}
	maxSuccLB = (int) (meanLB + coef*stddev);
	myLH=0; mySucc = 0;
      }
      else { mySucc+=2; }
      // if (lb > maxSuccLB && maxSuccLB<UB/2) {
      // 	// printf("c conflicts: %llu, maxSuccLB: %d, lb: %d, UB: %llu, thres: %d\n", 
      // 	//        conflicts, maxSuccLB, lb, UB, thres);
      // 	maxSuccLB = lb;
      // }
      //The UB is reached, the soft conflict will be analyzed 
      // and the involvedClauses stack will be cleared together with the involved flag
      UBconflictFlag = true; softConflictFlag = true;
      //  trail_lim.shrink(1);
      //  lastConflLits.shrink(lastConflLits.size() - savedConflLits);
      nbLKsuccess++; totalPrunedLB += lb; totalPrunedLB2 += lb*lb;

      // double curMeanLB = (double)totalPrunedLB/(nbLKsuccess-savednbLKsuccess);
      // double curDev = sqrt((float)totalPrunedLB2/(nbLKsuccess-savednbLKsuccess) - curMeanLB*curMeanLB);
      // printf(" %d, %d\n", maxSuccLB, (int)(curMeanLB+2*curDev));
      resetConflicts(nbIsets);
      for(int i=0; i<isetsLits[nbIsets].size(); i++) {
	Lit p=isetsLits[nbIsets][i];
	conflLits.push(p);
	insertAuxiVarOrder(var(p));
      }
      bumpConflVars();
      return false; 
    }
  }

    if (nbConfl == lb - 1) {
      if (!sampled)
	mySucc+=1;
    quasiSoftConflicts++;
    hardenFromQuasiSoftConflict(trailRecord, nbIsets);
    
    // LHsuccQueue.push(1); lastSuccess = 1;
    // if (LHsuccQueue.full() && LHsuccQueue.getsum() > 35 && thres < UB) {
    //   thres++;
    // }
    
  }
  else {
    for(int i=trailRecord; i< trail.size(); i++) {
      Var v=var(trail[i]);
      assigns[v] = l_Undef;
      if (auxiVar(v)) {
	assert(v>=0 && v<activityLB.size());
	activityLB[v] = (1-stepSizeLB)*activityLB[v];
	insertAuxiVarOrder(v);
	orderHeapAuxi.decrease(v);
      }
    }
    trail.shrink(trail.size() - trailRecord);
    qhead = trailRecord;
    //  trail_lim.shrink(1);
    resetConflicts(nbIsets);
    bumpConflVars(); //the score of confl vars and non-confl vars is updated differently
  }
    // printf("c meanLB: %4.2lf, meanSQLB: %4.2lf, stddev: %4.2lf, nbSample: %d, maxSuccLB: %d, UB: %llu, thres: %d\n", 
    //        meanLB, meanSQLB, stddev, nbSample, maxSuccLB, UB, thres);
    // printf("c conflicts: %llu, maxSuccLB: %d, lb: %d, UB: %llu, thres: %d\n", 
    //        conflicts, maxSuccLB, lb, UB, thres);
#ifdef printTestedVar
  printf("\nc @@@@ lb: %d, thres: %d, new thres: %d, @@@@\n", lb, thres, (lb+nbConfl+1)/2);
#endif

  thres = lb-1; //(lb+nbConfl)/2;
  prevConflicts = conflicts;
  // lastConflLits.shrink(lastConflLits.size() - savedConflLits);
  for(int i=0; i<involvedLits.size(); i++) {
    involved[var(involvedLits[i])] = 0;
  }
  involvedLits.clear();
  return true;
}

void Solver::insertAuxiVarOrder(Var x) {
  // GH-103 C3: same test as "!inHeap(x) && auxiVar(x)", one branch, no bound check (indices sized per var)
  if (orderHeapAuxi.absent(x) & auxiVar(x)) orderHeapAuxi.insertAbsent(x);
}
