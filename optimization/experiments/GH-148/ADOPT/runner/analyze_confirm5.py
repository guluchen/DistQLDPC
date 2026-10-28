#!/usr/bin/env python3
"""GH-148 adoption check: 5-seed TN_216_4_18 / TN_144_2_13 (main 12b3e05 vs -stab-overlap=auto 2b297b5, both arms of a
cell concurrently on pinned cores 0-39). Prints a markdown table: per seed solve times and ratio, seed medians, the
ratio of medians and the per-seed ratio range. usage: analyze_confirm5.py results.jsonl"""
import json, statistics as st, collections, sys
R = [json.loads(l) for l in open(sys.argv[1] if len(sys.argv) > 1 else "out/results.jsonl")]
by = collections.defaultdict(dict)
for r in R: by[(r["stem"], r["mode"], r["seed"])][r["arm"]] = r
print("| Code | Mode | seed: main s / cand s (cand/main) | main median (range) | cand median (range) | median ratio | per-seed ratio range |")
print("|---|---|---|---|---|---:|---|")
for stem in ("TN_216_4_18", "TN_144_2_13"):
    for mode in ("no-card", "card-mto"):
        cells = []; txt = []
        for s in range(5):
            d = by.get((stem, mode, s), {})
            m, c = d.get("main"), d.get("cand")
            tm = m["result"][0] if m and m["result"] else None
            tc = c["result"][0] if c and c["result"] else None
            if tm and tc:
                cells.append((tm, tc)); txt.append(f"s{s}: {tm:.0f} / {tc:.0f} ({tc / tm:.2f})")
            else:
                f = lambda r, t: f"{t:.0f}" if t else ("timeout" if r else "-")
                txt.append(f"s{s}: {f(m, tm)} / {f(c, tc)}")
        if len(cells) < 5:
            print(f"| {stem} | {mode} | {'; '.join(txt)} | incomplete | | | |"); continue
        a = [x for x, _ in cells]; b = [y for _, y in cells]; rr = [y / x for x, y in cells]
        print(f"| {stem} | {mode} | {'; '.join(txt)} | {st.median(a):.0f} ({min(a):.0f}-{max(a):.0f}) | "
              f"{st.median(b):.0f} ({min(b):.0f}-{max(b):.0f}) | {st.median(b) / st.median(a):.3f} | {min(rr):.2f}-{max(rr):.2f} |")
bad = [r["id"] for r in R if not r.get("science_ok", True) or r.get("issues")]
ans = sorted(set((r["stem"], r["result"][1]) for r in R if r["result"]))
print(f"\n{len(R)} records; answers {ans}; science/runner issues: {bad if bad else 'none'}; "
      f"peak RSS {max(r['maxrss_kb'] for r in R) // 1024} MB")
