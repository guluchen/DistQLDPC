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
 * DistQLDPC engine -- EngineInternal.h: file-scope helpers shared by several engine modules.
 *
 * Clause-ordering comparators and tuning macros that were file-scope in Solver.cc and are used
 * by more than one module. Included once by Engine.cc, before the modules.
 *
 * Restructured from MaxCDCL src/solver/Solver.cc by DistQLDPC (GH-95, stage 1): code moved
 * verbatim, search unchanged. The copyright and MIT permission notice above apply to the
 * MaxCDCL / Maple_CM / Maple_LCM / MiniSat code contained in this file (see src/solver/LICENSE).
 *
 * Modifications Copyright (C) 2025-2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>, part of DistQLDPC
 * (GPL-3.0-or-later when distributed as this project; see LICENSE, NOTICE, MODIFICATIONS.md).
 */

#ifndef DISTQLDPC_ENGINE_INTERNAL_H
#define DISTQLDPC_ENGINE_INTERNAL_H

#ifndef DISTQLDPC_ENGINE_UNITY
#error "src/engine/EngineInternal.h is part of the engine unity build; compile src/engine/Engine.cc"
#endif

struct reduceTIER2_lt {
    ClauseAllocator& ca;
    reduceTIER2_lt(ClauseAllocator& ca_) : ca(ca_) {}
  bool operator () (CRef x, CRef y) {
    
    if (ca[x].touched() < ca[y].touched()) return true;
    if (ca[x].touched() > ca[y].touched()) return false;

    if(ca[x].lbd() > ca[y].lbd()) return true;
    if(ca[x].lbd() < ca[y].lbd()) return false;    
    
    // Finally we can use old activity or size, we choose the last one
    
     return ca[x].size() > ca[y].size();
    }
};

#define lbdLimitForOriCls 20

struct reduceDB_lt {
    ClauseAllocator& ca;
    reduceDB_lt(ClauseAllocator& ca_) : ca(ca_) {}
  bool operator () (CRef x, CRef y) {
    // if (ca[x].touched() > ca[y].touched()) return true;
    // if (ca[x].touched() < ca[y].touched()) return false;
    
    if (ca[x].activity() < ca[y].activity()) return true;
    if (ca[x].activity() > ca[y].activity()) return false;

    if(ca[x].lbd() > ca[y].lbd()) return true;
    if(ca[x].lbd() < ca[y].lbd()) return false;    
    
    // Finally we can use old activity or size, we choose the last one
    
     return ca[x].size() > ca[y].size();
    }
};

#define splitClauseSize 20
#define limitOfNbClausesToSplit 4

#endif
