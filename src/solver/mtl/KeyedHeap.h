/*****************************************************************************************[KeyedHeap.h]
Copyright (c) 2003-2006, Niklas Een, Niklas Sorensson
Copyright (c) 2007-2010, Niklas Sorensson

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
 * DistQLDPC (GH-103): mtl/Heap.h specialised to a min-heap ordered by `act[x] < act[y]` on a
 * vec<double>, with each slot caching the key of its element. The algorithm (slot moves, child
 * rule, stop tests) is the one of Heap<Comp>; only the key loads differ. The cached key of an
 * element is (re)read from `act` in insert, decrease, increase, update and build, so callers must
 * follow every change of act[x] for an x in the heap by decrease(x)/increase(x)/update(x) before
 * the next heap operation -- which is what the MaxCDCL engine does for activityLB.
 *
 * Modifications Copyright (C) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>, part of DistQLDPC
 * (GPL-3.0-or-later when distributed as this project; see LICENSE, NOTICE, MODIFICATIONS.md).
 */

#ifndef Minisat_KeyedHeap_h
#define Minisat_KeyedHeap_h

#include "mtl/Vec.h"

namespace Minisat {

class KeyedActivityHeap {
    struct Slot { double key; int x; };

    const vec<double>& act;    // the key of element x is act[x]
    vec<Slot> heap;            // heap[i].key == act[heap[i].x] at every comparison
    vec<int>  indices;         // each element's position in the heap, -1 if absent

    static inline int left  (int i) { return i*2+1; }
    static inline int right (int i) { return (i+1)*2; }
    static inline int parent(int i) { return (i-1) >> 1; }

    void percolateUp(int i)
    {
        Slot s = heap[i];
        int  p = parent(i);

        while (i != 0 && s.key < heap[p].key){
            heap[i]            = heap[p];
            indices[heap[p].x] = i;
            i                  = p;
            p                  = parent(p);
        }
        heap   [i]   = s;
        indices[s.x] = i;
    }

    void percolateDown(int i)
    {
        Slot s = heap[i];
        while (left(i) < heap.size()){
            int child = right(i) < heap.size() && heap[right(i)].key < heap[left(i)].key ? right(i) : left(i);
            if (!(heap[child].key < s.key)) break;
            heap[i]            = heap[child];
            indices[heap[i].x] = i;
            i                  = child;
        }
        heap   [i]   = s;
        indices[s.x] = i;
    }

  public:
    KeyedActivityHeap(const vec<double>& a) : act(a) { }

    int  size      ()          const { return heap.size(); }
    bool empty     ()          const { return heap.size() == 0; }
    bool inHeap    (int n)     const { return n < indices.size() && indices[n] >= 0; }
    int  operator[](int index) const { assert(index < heap.size()); return heap[index].x; }

    void decrease  (int n) { assert(inHeap(n)); heap[indices[n]].key = act[n]; percolateUp  (indices[n]); }
    void increase  (int n) { assert(inHeap(n)); heap[indices[n]].key = act[n]; percolateDown(indices[n]); }

    void update(int n)
    {
        if (!inHeap(n))
            insert(n);
        else {
            heap[indices[n]].key = act[n];
            percolateUp(indices[n]);
            percolateDown(indices[n]); }
    }

    void insert(int n)
    {
        indices.growTo(n+1, -1);
        assert(!inHeap(n));

        indices[n] = heap.size();
        Slot s; s.key = act[n]; s.x = n;
        heap.push(s);
        percolateUp(indices[n]);
    }

    int  removeMin()
    {
        int x               = heap[0].x;
        heap[0]             = heap.last();
        indices[heap[0].x]  = 0;
        indices[x]          = -1;
        heap.pop();
        if (heap.size() > 1) percolateDown(0);
        return x;
    }

    void build(const vec<int>& ns) {
        for (int i = 0; i < heap.size(); i++)
            indices[heap[i].x] = -1;
        heap.clear();

        for (int i = 0; i < ns.size(); i++){
            indices[ns[i]] = i;
            Slot s; s.key = act[ns[i]]; s.x = ns[i];
            heap.push(s); }

        for (int i = heap.size() / 2 - 1; i >= 0; i--)
            percolateDown(i);
    }

    void clear(bool dealloc = false)
    {
        for (int i = 0; i < heap.size(); i++)
            indices[heap[i].x] = -1;
        heap.clear(dealloc);
    }
};

}

#endif
