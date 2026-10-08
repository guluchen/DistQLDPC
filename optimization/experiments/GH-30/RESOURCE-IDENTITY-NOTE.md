# Actual helper selection versus shorthand assignment prose

Audit during Tier2 found the assignment/plan prose said CPU14 for all stages.
The unchanged reviewed Window(True,0x8000) helper selects a quiet physical pair
ONCE per invocation; 0x8000 is AboveNormal priority, not an affinity mask. Its
actual window.json is authoritative, retained unchanged with all raw evidence.

| Invocation | Actual selected CPU | Sibling | Mask |
|---|---:|---:|---:|
| GH30 Tier0 | 14 | 15 | 16384 |
| GH30 Tier1 | 12 | 13 | 4096 |
| GH30 exploratory Tier2 | 10 | 11 | 1024 |

Each invocation enforces the SAME one selected CPU for baseline, candidate,
supervisor and owned descendants throughout that comparison; it does not move
mid-run or put versions on sibling cores concurrently. All recorded descendant
mask/priority checks use window.mask, rather than hardcoding14. Pair differences
across tiers are an environment limitation; absolute times across stages are not
compared for speedup. Per-stage baseline/candidate paired results remain separate.

This corrects imprecise source/assignment prose, not execution or raw evidence.
Original prerecords preserved. No claim of exclusive CPU reservation; formal
controlled status remains INCONCLUSIVE. Publish this deviation before drawing
any final Tier2 conclusion. Other experiments' actual windows are independent.
