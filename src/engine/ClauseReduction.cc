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
 * DistQLDPC engine -- module ClauseReduction.cc
 *
 * Learnt-clause database reduction (reduceDB, reduceDB_Tier2, reduceDB_core), removal of
 * satisfied clauses, top-level simplify, clause splitting, removeLearntClauses.
 *
 * Restructured from MaxCDCL src/solver/Solver.cc by DistQLDPC (GH-95, stage 1): code moved
 * verbatim, search unchanged. The copyright and MIT permission notice above apply to the
 * MaxCDCL / Maple_CM / Maple_LCM / MiniSat code contained in this file (see src/solver/LICENSE).
 *
 * Modifications Copyright (C) 2025-2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>, part of DistQLDPC
 * (GPL-3.0-or-later when distributed as this project; see LICENSE, NOTICE, MODIFICATIONS.md).
 */

#ifndef DISTQLDPC_ENGINE_UNITY
#error "src/engine/ClauseReduction.cc is part of the engine unity build; compile src/engine/Engine.cc"
#endif
/*_________________________________________________________________________________________________
 |
 |  reduceDB : ()  ->  [void]
 |
 |  Description:
 |    Remove half of the learnt clauses, minus the clauses locked by the current assignment. Locked
 |    clauses are clauses that are reason to some assignment. Binary clauses are never removed.
 |________________________________________________________________________________________________@*/

void Solver::reduceDB()
{
    int     i, j;
    //if (local_learnts_dirty) cleanLearnts(learnts_local, LOCAL);
    //local_learnts_dirty = false;
    // printf("c caSize: %d, caWasted: %d (%4.3f), nbCORE: %d, nbTIER2: %d, conflicts: %llu, hardConfl: %llu\n",
    // 	   ca.size(), ca.wasted(), (float)ca.wasted()/ca.size(), learnts_core.size(), learnts_tier2.size(), conflicts, conflicts-softConflicts);

    // for (i = 0; i < learnts_local.size(); i++) {
    //   Clause& c = ca[learnts_local[i]];
    //   int nb=0;
    //   for(j=0; j<c.size(); j++) {
    // 	if (sign(c[j]) == polarity[var(c[j])]) 
    // 	  nb++;
    //   }
    //   c.touched() = nb;
    // }
    
    sort(learnts_local, reduceDB_lt(ca));
    
    int limit = learnts_local.size() / 2;
    int totalLocalSize=0, removedSize=0;
    for (i = j = 0; i < learnts_local.size(); i++){
        Clause& c = ca[learnts_local[i]];
	totalLocalSize += c.size();
        if (c.mark() == LOCAL)
	  if (c.removable() && !locked(c) && i < limit) {
	    removedSize += c.size();
	    removeClause(learnts_local[i]);
	  }
	  else{
	    if (!c.removable()) limit++;
	    c.removable(true);
	    learnts_local[j++] = learnts_local[i];
	  }
    }
    learnts_local.shrink(i - j);
    // printf("c removedSize: %d(%4.2f), over totalLocalSize: %d (%4.2f), NBremoved: %d, over nbLocalBefore: %d\n",
    // 	   removedSize, (float)removedSize/(i-j), totalLocalSize, (float)totalLocalSize/i, i-j, i);
    // printf("c %d ca size: %d, ca wasted: %d (%4.3f)\n\n",
    // 	   nbClauseReduce, ca.size(), ca.wasted(), (float)ca.wasted()/ca.size()); 
    checkGarbage();
}

// struct reduceTIER2_lt {
//     ClauseAllocator& ca;
//     reduceTIER2_lt(ClauseAllocator& ca_) : ca(ca_) {}
//   bool operator () (CRef x, CRef y) {
    
//     if (ca[x].touched() < ca[y].touched()) return true;
//     if (ca[x].touched() > ca[y].touched()) return false;

//     if(ca[x].lbd() > ca[y].lbd()) return true;
//     if(ca[x].lbd() < ca[y].lbd()) return false;    
    
//     // Finally we can use old activity or size, we choose the last one
    
//      return ca[x].size() > ca[y].size();
//     }
// };

void Solver::reduceDB_Tier2() {
  sort(learnts_tier2, reduceTIER2_lt(ca));
  int i, j;
  int limit = learnts_tier2.size()/2;
  
  //  printf("\n conflicts: %llu, tier2: %d, \n", conflicts, learnts_tier2.size());
  for (i = j = 0; i < learnts_tier2.size(); i++){
    Clause& c = ca[learnts_tier2[i]];
    if (c.mark() == TIER2) {
      assert(c.lbd() > 2);
      if (i < limit){
	learnts_local.push(learnts_tier2[i]);
	c.mark(LOCAL);
	//c.removable(true);
	c.activity() = 0;
	claBumpActivity(c);
	
	//	printf("i: %d, lbd: %d, touched: %u \n ", i, c.lbd(), c.touched());
      }else
	learnts_tier2[j++] = learnts_tier2[i];
    }
  }
  learnts_tier2.shrink(i - j);
  
   // printf("\ntier2: %d, last: %u, lastlbd: %d, core_lbd_cut: %d, core: %d\n",
   // 	  learnts_tier2.size(), ca[learnts_tier2.last()].touched(),
   // 	  ca[learnts_tier2.last()].lbd(), core_lbd_cut, learnts_core.size());
}

struct reduceCORE_lt {
  ClauseAllocator& ca;
  reduceCORE_lt(ClauseAllocator& ca_) : ca(ca_) {}
  bool operator () (CRef x, CRef y) {
    if(ca[x].lbd() > ca[y].lbd()) return true;
    if(ca[x].lbd() < ca[y].lbd()) return false;    
    
    // Finally we can use old activity or size, we choose the last one
    
     return ca[x].size() > ca[y].size();
    }
};

void Solver::reduceDB_core()
{
    int     i, j;
    //if (local_learnts_dirty) cleanLearnts(learnts_local, LOCAL);
    //local_learnts_dirty = false;
    // printf("c caSize: %d, caWasted: %d (%4.3f), nbCORE: %d, nbTIER2: %d, conflicts: %llu, hardConfl: %llu\n",
    // 	   ca.size(), ca.wasted(), (float)ca.wasted()/ca.size(), learnts_core.size(), learnts_tier2.size(), conflicts, conflicts-softConflicts); 
    
    sort(learnts_core, reduceCORE_lt(ca));
 
    int limit = learnts_core.size() / 2;
    int totalLocalSize=0, removedSize=0;
    //int cut = (core_lbd_cut == 3) ? 3 : 4;

    // int meanSize;
    // for (i = 0; i < learnts_core.size(); i++){
    //   Clause& c = ca[learnts_core[i]];
    //   totalLocalSize += c.size();
    // }
    // if (i>0)
    //   meanSize = totalLocalSize/i;
    // else meanSize = 0;
    
    //  printf("\n conflicts: %llu, core: %d, \n", conflicts, learnts_core.size());
    for (i = j = 0; i < learnts_core.size(); i++){
        Clause& c = ca[learnts_core[i]];
	//	totalLocalSize += c.size();
        if (c.mark() == CORE)
	  if ( i < limit && c.lbd() > 2 && c.touched() + coreInactiveLimit < conflicts) {
	    learnts_tier2.push(learnts_core[i]);
	    c.mark(TIER2);
	    
	    //  printf("i: %d, lbd: %d, touched: %u\n", i, c.lbd(), c.touched());
	  }
	  else{
	    // if (!c.removable()) limit++;
	    //c.removable(true);
	    learnts_core[j++] = learnts_core[i];
	  }
    }
    learnts_core.shrink(i - j);
    // printf("c removedSize: %d(%4.2f), over totalCoreSize: %d (%4.2f), NBremoved: %d, over nbCoreBefore: %d\n",
    // 	   removedSize, (float)removedSize/(i-j> 0 ? i-j : 1), totalLocalSize, (float)totalLocalSize/i, i-j, i);
    // printf("c %d ca size: %d, ca wasted: %d (%4.3f)\n\n",
    // 	   nbClauseReduce, ca.size(), ca.wasted(), (float)ca.wasted()/ca.size());

       // printf("core: %d, last: %u, lastlbd: %d, core_lbd_cut: %d\n\n",
       // 	  learnts_core.size(), ca[learnts_core.last()].touched(),
       // 	      ca[learnts_core.last()].lbd(), core_lbd_cut);
}


void Solver::removeSatisfied(vec<CRef>& cs)
{
    int i, j;
    for (i = j = 0; i < cs.size(); i++){
        Clause& c = ca[cs[i]];
        if(c.mark()!=1){
            if (satisfied(c))
                removeClause(cs[i]);
            else
                cs[j++] = cs[i];
        }
    }
    cs.shrink(i - j);
}

void Solver::safeRemoveSatisfied(vec<CRef>& cs, unsigned valid_mark)
{
    int i, j;
    for (i = j = 0; i < cs.size(); i++){
        Clause& c = ca[cs[i]];
        if (c.mark() == valid_mark)
            if (satisfied(c))
                removeClause(cs[i]);
            else
                cs[j++] = cs[i];
    }
    cs.shrink(i - j);
}


/*_________________________________________________________________________________________________
 |
 |  simplify : [void]  ->  [bool]
 |
 |  Description:
 |    Simplify the clause database according to the current top-level assigment. Currently, the only
 |    thing done here is the removal of satisfied clauses, but more things can be put here.
 |________________________________________________________________________________________________@*/
bool Solver::simplify(bool simplifyOriginal)
{
    assert(decisionLevel() == 0);
    
    if (!ok || propagate() != CRef_Undef)
        return ok = false;
    
    if (nAssigns() == simpDB_assigns || (simpDB_props > 0))
        return true;
    
    // Remove satisfied clauses:
    removeSatisfied(learnts_core); // Should clean core first.
    safeRemoveSatisfied(learnts_tier2, TIER2);
    safeRemoveSatisfied(learnts_local, LOCAL);
    if (simplifyOriginal)        // Can be turned off.
        removeSatisfied(clauses);
    //  removeSoftSatisfied(softClauses);
    checkGarbage();
    rebuildOrderHeap();
    
    simpDB_assigns = nAssigns();
    simpDB_props   = clauses_literals + learnts_literals;   // (shouldn't depend on stats really, but it will do for now)
    
    return true;
}

int Solver::setCounter(CRef cr) {
  int j, k;
  Clause& c=ca[cr];
  counter++;
  for(j=0, k=0; j<c.size(); j++) {
    if (value(c[j]) == l_Undef) {
      seen2[toInt(c[j])] = counter;
      c[k++] = c[j];
    }
  }
  c.shrink(j-k);
  return k;
}

// return the number of literals whose seen2 is equal to counter, i.e. in the previous intersection.
// The seen2 of these literals are incremented for the next iterations
// nb is the number of literals in the new intersection whose seen2 is equal tp the new counter
int Solver::countCommunLiterals(CRef cr) {
  int i, j, nb=0;
  Clause& c=ca[cr];
  for(i=0,j=0; i<c.size(); i++) {
    if (value(c[i]) == l_Undef) {
      if (seen2[toInt(c[i])] == counter) {
	seen2[toInt(c[i])]++;
	nb++;
      }
      c[j++] = c[i];
    }
    else assert(i>1);
  }
  c.shrink(i-j);
  counter++;
  return nb;
}


void Solver::splitClauses(vec<CRef>& cs) {
  vec<Lit> communLits;
  communLits.clear();
  CRef cr=cs[0];
  Clause& c=ca[cr];
  int lbd = c.lbd();
  for(int i=0; i<c.size(); i++) 
    if (seen2[toInt(c[i])] == counter) {
      communLits.push(c[i]);
    }
  Var v = newAuxiVar();
  Lit p = mkLit(v);

  int a, b, clauseType = LOCAL;
  bool toAttache;
  for(int i=0; i<cs.size(); i++) {
    CRef cr1=cs[i]; 
    Clause& c1 = ca[cr1];
    if (lbd > c1.lbd()) lbd = c1.lbd();
    assert(c1.mark() != 1);
    if (c1.mark() == CORE)
      clauseType = CORE;
    else if (c1.mark() == TIER2 && clauseType == LOCAL)
      clauseType = TIER2;
    
    if (seen2[toInt(c1[0])] == counter || seen2[toInt(c1[1])] == counter) {
      detachClause(cr1, true); toAttache=true;
    }
    else toAttache=false;
    
    //   detachClause(cr1, true);
    // int k=0;
    // for(a=0; a<c1.size(); a++) {
    //   if (seen2[toInt(c1[a])] == counter) 
    // 	k++;
    // }
    // if (communLits.size() != k) {
    //   for(int aa=0; aa<c1.size(); aa++)
    // 	if (seen2[toInt(c1[aa])] == counter)
    // 	  printf("%d %llu, ", toInt(c1[aa]), seen2[toInt(c1[aa])]);
    //   printf("\n");
    //   for(int aa=0; aa<communLits.size(); aa++)
    // 	printf("%d %llu, ", toInt(communLits[aa]), seen2[toInt(communLits[aa])]);
    //   printf("****%d %d %d %d, ****\n\n", communLits.size(), k, i, cs.size());
    // }
 
    int k=0;
    for(a=0, b=0; a<c1.size(); a++) {
      if (seen2[toInt(c1[a])] == counter) {
	k++;
      }
      else c1[b++] = c1[a];
    }
    assert(communLits.size() == k);
    assert(b<c1.size() && a>b && a == c1.size());
    
    c1[b++] = ~p;
    c1.shrink(a-b);
    if (b<=1)
      printf("%d, %d, %d, %d, %d\n", b, k, communLits.size(), cs.size(), i);
    assert(b>1);
    if (toAttache)
      attachClause(cr1);
  }

  communLits.push(p);
  CRef cr2 = ca.alloc(communLits, true);
  attachClause(cr2); ca[cr2].mark(clauseType); ca[cr2].set_lbd(lbd);
  if (clauseType == CORE) {
    learnts_core.push(cr2); ca[cr2].touched() = conflicts;
  }
  else if (clauseType == TIER2) {
    learnts_tier2.push(cr2);  ca[cr2].touched() = conflicts;
  }
  else {
    learnts_local.push(cr2); claBumpActivity(ca[cr2]);
  }
  watches.cleanAll();
  watches_bin.cleanAll();

  nbSavedLits += cs.size() * (communLits.size() - 1) - (communLits.size() + 1);
  // printf("communLits: %d, nbCls: %d\n", communLits.size()-1, cs.size());
}

void Solver::identifyClausesToSplit(vec<CRef>& cs) {
  int i=0, j;
  vec<CRef> toSplit;

  removeSatisfied(cs); 

  while (i<cs.size()) {
    CRef cr=cs[i];
    if (ca[cr].size() < splitClauseSize) {
      i++;
      continue;
    }
    toSplit.clear();
    int nbCommunLits = setCounter(cr), minSize=ca[cr].size();
    toSplit.push(cr);
    for(j=i+1; j<cs.size() && 2*nbCommunLits >= UB; j++) {
      CRef cr1 = cs[j];
      int oldMinSize = minSize, oldnbCommunLits = nbCommunLits;
      if (ca[cr1].size() < splitClauseSize)
	continue;
      if (ca[cr1].size() < minSize)
	minSize = ca[cr1].size();
      // intersection
      nbCommunLits = countCommunLiterals(cr1);
      if (nbCommunLits == ca[cr1].size()) {
	//	printf("removed %d clauses\n", toSplit.size());
	for(int a=0; a<toSplit.size(); a++)
	  removeClause(toSplit[a]);
	toSplit.clear();
	break;
      }
      else if (nbCommunLits == ca[cr].size()) {
	removeClause(cr1);
	continue;
      }
      if ( 2*nbCommunLits >= minSize )
	toSplit.push(cr1);
      else {
	//remove the last intersection 
	Clause& c=ca[cr1];
	for(int a=0; a<c.size(); a++) {
	  if (seen2[toInt(c[a])] == counter)
	    seen2[toInt(c[a])]--;
	}
	counter--;
	minSize = oldMinSize; nbCommunLits = oldnbCommunLits;
	break;
      }
    }
    i=j;
    //|| (toSplit.size()>1 && nbCommunLits +1 == minSize))
    if (toSplit.size()>limitOfNbClausesToSplit)
      splitClauses(toSplit);
    // printf("communLits: %d, nbCls: %d, minSize: %d, Leanrts %d\n",
    //	   nbCommunLits, toSplit.size(), minSize, cs.size());
  }
  // printf(" ----------------- starts: %llu, UB: %llu\n", starts, UB);
}

void Solver::removeLearntClauses() {
  for(int i=0; i<involvedLits.size(); i++) {
    involved[var(involvedLits[i])] = 0;
  }
  involvedLits.clear();
  for (int i=0; i < learnts_local.size(); i++)
     removeClause(learnts_local[i]);
  learnts_local.clear();
  for (int i=0; i < learnts_tier2.size(); i++)
     removeClause(learnts_tier2[i]);
  learnts_tier2.clear();
  for (int i=0; i < learnts_core.size(); i++)
     removeClause(learnts_core[i]);

  for(int i=0; i<hardens.size(); i++)
    removeClause(hardens[i]);
  hardens.clear();

  for(int i=0; i<cardinalityC.size(); i++)
    removeClause(cardinalityC[i]);
  cardinalityC.clear();

  for(int i=0; i<isetClauses.size(); i++)
    removeClause(isetClauses[i]);
  isetClauses.clear();
    
  learnts_core.clear();
  watches.cleanAll();
  watches_bin.cleanAll();
  checkGarbage();

  dynVars.clear();
  for(int i=nVars() - 1; i>=staticNbVars; i--) {
    decision[i] = false;
    dynVars.push(i);
  }
}
