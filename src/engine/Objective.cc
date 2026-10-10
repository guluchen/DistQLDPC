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
 * DistQLDPC engine -- module Objective.cc
 *
 * Objective and bound management (DistQLDPC hooks): bounds pipe (TRY/LB/UB), cost
 * bound accessors, incumbent tracking and printing, checkSolution.
 *
 * Restructured from MaxCDCL src/solver/Solver.cc by DistQLDPC (GH-95, stage 1): code moved
 * verbatim, search unchanged. The copyright and MIT permission notice above apply to the
 * MaxCDCL / Maple_CM / Maple_LCM / MiniSat code contained in this file (see src/solver/LICENSE).
 *
 * Modifications Copyright (C) 2025-2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>, part of DistQLDPC
 * (GPL-3.0-or-later when distributed as this project; see LICENSE, NOTICE, MODIFICATIONS.md).
 */

#ifndef DISTQLDPC_ENGINE_UNITY
#error "src/engine/Objective.cc is part of the engine unity build; compile src/engine/Engine.cc"
#endif

void Solver::setBoundsPipe(int write_fd) {
    bounds_pipe_w = write_fd;
}

uint64_t Solver::getCostLB() const {
    return solutionCost + infeasibleUB + fixedCostBySearch + derivedCost + relaxedCost;
}

uint64_t Solver::getCostUB() const {
    return solutionCost + bestSup + fixedCostBySearch + derivedCost + relaxedCost;
}

void Solver::emitBoundsUpdate() {
    if (bounds_pipe_w < 0)
        return;
    char buf[64];
    int n;
    if (infeasibleUB > 0 && !boundsHideLB) {
        uint64_t lbv = getCostLB(); if (lbv > boundsLbCap) lbv = boundsLbCap;
        n = snprintf(buf, sizeof(buf), "LB %llu\n",
                     (unsigned long long)lbv);
        if (n > 0)
            (void)write(bounds_pipe_w, buf, (size_t)n);
    }
    if (bestSolutionFound) {
        uint64_t ubv = getCostUB(); if (ubv > boundsUbCap) ubv = boundsUbCap;
        n = snprintf(buf, sizeof(buf), "UB %llu\n",
                     (unsigned long long)ubv);
        if (n > 0)
            (void)write(bounds_pipe_w, buf, (size_t)n);
    }
}

void Solver::emitTryUpdate(uint64_t try_val) {
    if (bounds_pipe_w < 0)
        return;
    char buf[64];
    int n = snprintf(buf, sizeof(buf), "TRY %llu\n", (unsigned long long)try_val);
    if (n > 0)
        (void)write(bounds_pipe_w, buf, (size_t)n);
}

void Solver::noteBestSolution(uint64_t unsatSoft) {
    if (!bestSolutionFound || unsatSoft < bestSup) {
        bestSolutionFound = true;
        bestSup = unsatSoft;
        emitBoundsUpdate();
    }
}

void Solver::printBestSolution() const {
    if (!bestSolutionFound) {
        printf("c TIMEOUT/INTERRUPT: no feasible solution found yet.\n");
        return;
    }
    uint64_t maxsat = objForSearch - bestSup + (uint64_t)nbSatLitsAtStart;
    uint64_t optimal = solutionCost + bestSup + fixedCostBySearch + derivedCost + relaxedCost;
    printf("c TIMEOUT/INTERRUPT: best solution so far:\n");
    printf("c   unsat soft clauses (search): %llu\n", bestSup);
    printf("c   satisfied soft clauses (maxsat): %llu\n", maxsat);
    printf("c   total weight cost: %llu\n", optimal);
    if (model.size() > 0) {
        printf("v ");
        int lim = nbOriVars > 0 ? nbOriVars : nVars();
        for (int i = 0; i < lim && i < model.size(); i++)
            if (model[i] != l_Undef)
                printf("%s%d ", (model[i] == l_True) ? "" : "-", i + 1);
        printf("0\n");
    }
}

void Solver::checkSolution() {
  int nbFalse=0;
  for(Var v=0; v<nVars(); v++)
    if (auxiVar(v) && value(softLits[v]) == l_False)
      nbFalse++;
  if (nbFalse != falseLits.size()+fixedCostBySearch + relaxedCost)
    printf("c **** error nb of false soft clauses real nbfalse: %d, recorded falseLits: %llu****\n",
	   nbFalse, falseLits.size()+fixedCostBySearch+relaxedCost);

  // printf("c there are %d hard clauses\n", clauses.size());
  for(int i=0; i<clauses.size(); i++)
    if (!satisfied(ca[clauses[i]])) {
      printf("c clause %d non-satisfied: ", i);
      Clause& c=ca[clauses[i]];
      for(int j=0; j<c.size(); j++)
	printf(" %d ", toInt(c[j]));
      printf("\n");
    }
}
