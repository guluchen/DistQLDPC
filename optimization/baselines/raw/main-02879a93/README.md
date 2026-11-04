# Raw records: main 02879a93 re-tier panel on yfclab2 (2026-11-04)

Binary: frozen/server-main-02879a93/distqldpc (`binary.sha256`). Tables built from these files: ../../SERVER.md and
../../main_server_reference.json (runner/retier_make_baseline.py).

| File | Content |
|---|---|
| `inputs.json` | the 100 inputs of the panel: 51 tiered codes, the 24 library codes (generator stems `*_unknown`) and the 25 codes of pending data PRs #210-#214 (measured for their reviews only, not added here), with sha256 of every matrix file and the claim used for consistency checks |
| `server_panel_results.jsonl` | one record per run of runner/server_retier_20261104.py (1173 runs): command, core, wall/user time, max RSS, answer, timestamped lb/ub events |
| `server_extra_results.jsonl` | runner/server_retier_extra_20261104.py: COLOR_331 no-card seeds 3-4 and the relabeled (`-seed=1`) CC reproduction attempts (stopped after 5910 s, see ../../SERVER.md notes) |
| `drift_c914ef5_results.jsonl`, `drift_02879a93_results.jsonl` | same-day drift check (previous baseline binary c914ef5 and 02879a93 on 5 codes x 2 modes x seeds 0-2) |
| `witness_check.jsonl` | runner/retier_verify_witnesses.py over every CC `-v` log: every printed word and every bundled basis row checked from scratch in GF(2) |
| `witnesses_lightest.txt` | the lightest verified word per code (stem as run; the placed stems are in ../../SERVER.md, placement table) |
| `load.txt` | per-minute load average and queue state during the panel |
| `logs.tar.xz` | elapsed-time-stamped output of every run |

Inputs were run from a flat copy (`data/t0` … `data/t5`, `data/untiered`, `data/pr210` … `data/pr214`) with the stems
as they were on main 02879a93 and on the PR heads.
