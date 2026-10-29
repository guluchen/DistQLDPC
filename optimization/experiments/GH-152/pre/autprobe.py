#!/usr/bin/env python3
"""Measurement probe: automorphisms of the colored Tanner graph (qubits, Hx rows, Hz rows) by
individualization-refinement. Prints qubit orbits of the group found and whether an X<->Z swapping
map exists. Pure Python, research probe only."""
import sys, time

def load(path):
    rows = []
    with open(path) as f:
        for line in f:
            t = line.split()
            if not t: continue
            rows.append([i for i, x in enumerate(t) if x == '1'])
    return rows

def build(hx, hz, n, swap=False):
    # vertices: 0..n-1 qubits, then Hx rows, then Hz rows
    adj = [[] for _ in range(n + len(hx) + len(hz))]
    col = [0] * n + [1] * len(hx) + [2] * len(hz)
    for i, r in enumerate(hx):
        v = n + i
        for q in r: adj[v].append(q); adj[q].append(v)
    for i, r in enumerate(hz):
        v = n + len(hx) + i
        for q in r: adj[v].append(q); adj[q].append(v)
    return adj, col

def refine2(adj, ca, cb):
    """Refine colorings ca, cb jointly; return (ca, cb) or None if they diverge."""
    nc = len(set(ca))
    while True:
        sa = [(ca[v], tuple(sorted(ca[u] for u in adj[v]))) for v in range(len(adj))]
        sb = [(cb[v], tuple(sorted(cb[u] for u in adj[v]))) for v in range(len(adj))]
        ua = sorted(set(sa))
        if ua != sorted(set(sb)): return None
        idx = {s: i for i, s in enumerate(ua)}
        na = [idx[s] for s in sa]; nb = [idx[s] for s in sb]
        # cell sizes must match
        from collections import Counter
        if Counter(na) != Counter(nb): return None
        if len(ua) == nc: return na, nb
        nc = len(ua); ca, cb = na, nb

def search(adj, ca, cb, budget):
    budget[0] -= 1
    if budget[0] < 0: return None
    r = refine2(adj, ca, cb)
    if r is None: return None
    ca, cb = r
    cells = {}
    for v, c in enumerate(ca): cells.setdefault(c, []).append(v)
    target = None
    for c in sorted(cells):
        if len(cells[c]) > 1: target = c; break
    if target is None:
        inv = {c: v for v, c in enumerate(cb)}
        pi = [inv[ca[v]] for v in range(len(adj))]
        # verify edges
        for v in range(len(adj)):
            s = set(pi[u] for u in adj[v])
            if s != set(adj[pi[v]]): return None
        return pi
    a = cells[target][0]
    bs = [v for v, c in enumerate(cb) if c == target]
    newc = max(ca) + 1
    for b in bs:
        ca2 = list(ca); cb2 = list(cb); ca2[a] = newc; cb2[b] = newc
        pi = search(adj, ca2, cb2, budget)
        if pi is not None: return pi
        if budget[0] < 0: return None
    return None

def find(par, a):
    while par[a] != a:
        par[a] = par[par[a]]; a = par[a]
    return a

def orbits(adj, col, n, budget_per=2000):
    N = len(adj)
    base = refine2(adj, col, col)[0]
    par = list(range(N))
    gens = 0; fails = 0; undecided = 0
    for v in range(n):
        for w in range(v + 1, n):
            if base[v] != base[w]: continue
            if find(par, v) == find(par, w): continue
            if find(par, w) != w: continue  # only test w that are still their own root
            ca = list(base); cb = list(base); nc = max(base) + 1
            ca[v] = nc; cb[w] = nc
            budget = [budget_per]
            pi = search(adj, ca, cb, budget)
            if pi is None:
                if budget[0] < 0: undecided += 1
                else: fails += 1
                continue
            gens += 1
            for x in range(N):
                a, b = find(par, x), find(par, pi[x])
                if a != b: par[max(a, b)] = min(a, b)
        # after handling v, all w in v's orbit are merged
    orb = {}
    for q in range(n): orb.setdefault(find(par, q), []).append(q)
    return orb, gens, fails, undecided

def main():
    stem = sys.argv[1]
    hx = load(stem + '_Hx.txt'); hz = load(stem + '_Hz.txt')
    n = max(max(r) for r in hx + hz) + 1
    t0 = time.time()
    adj, col = build(hx, hz, n)
    orb, gens, fails, und = orbits(adj, col, n)
    sizes = sorted(len(o) for o in orb.values())
    from collections import Counter
    print(f"{stem.split('/')[-1]}: n={n} orbits={len(orb)} sizes={dict(Counter(sizes))} gens={gens} "
          f"nonorbit_proofs={fails} undecided={und} t={time.time()-t0:.1f}s", flush=True)
    # XZ swap: Hx rows colored like Hz rows (try to map qubit 0's refinement onto a swapped coloring)
    col_sw = [0] * n + [2] * len(hx) + [1] * len(hz)
    budget = [5000]
    pi = search(adj, list(col), col_sw, budget) if len(hx) == len(hz) else None
    print(f"  xz-swap map: {'found' if pi else ('undecided' if budget[0] < 0 else 'none')}", flush=True)

if __name__ == '__main__':
    main()
