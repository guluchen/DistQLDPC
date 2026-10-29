# GH-148 status: complete (Tiers 0-5 PASS), awaiting PI decisions

Issue #148. Baseline main 12b3e05; evaluated binary 2b297b5 (`-stab-overlap=auto`, native propagator in MaxCDCL).
Final Tier 5 (54 cells x 6 h, yfclab2 cores 0-53, 2026-10-28): solved 10 vs main's 6, no cell lost, lb higher on 5
cells, ub identical, no semantic issue; watch TN_216 (1.15-1.57x). Full record: REPORT.md. Default stays `off`; no PR,
no merge. Adoption needs a rebase onto e52d15b (re-run Tier 0) and a PI decision on the default.
