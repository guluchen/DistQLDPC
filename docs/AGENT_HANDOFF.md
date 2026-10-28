# Handoff for Codex and other agents

State as of 2026-10-28. This file gives a new agent (Codex, Claude or a person) what it needs to contribute to DistQLDPC without the chat history.
Read it together with [AGENTS.md](../AGENTS.md) and the [optimization loop policy](OPTIMIZATION_LOOP_POLICY.md). Where this file and those disagree, the stricter rule wins and you ask the PI.

## 1. What the project does

DistQLDPC computes the exact minimum distance d = min(dX, dZ) of CSS / qLDPC quantum codes. Inputs are four GF(2) matrices per code: `Hx`, `Hz`, `Gx`, `Gz`. Output is the distance, or certified lower and verified upper bounds when the time limit hits.

It has two search engines:

- **MaxSAT path (default).** Each CSS half is a weighted MaxSAT problem solved by the embedded MaxCDCL engine (`src/solver/`, MIT, patched; see MODIFICATIONS.md).
  - Current defaults: `-frontier=auto` (GH-130), `-oddcap-skip` (GH-133), orbit symmetry breaking (GH-85), dual-map bound sharing (GH-107), and the verified upper-bound pre-pass `-ub-pre` with the Stern finder `-ub-isd=stern` (GH-144, GH-146).
- **Connected-cluster engine (`-engine=cc`, opt-in).** Exact level-by-level search (`src/cc/`).
  - Rules: `excl,pack,orbf,parity,leaf,overlap`.
  - Also: single-half search under a verified X/Z dual map, a stop rule, independent witness verification, and `-ub-search` (Stern finder).
  - CC stays **off by default** (PI decision): do not make it the default or `-engine=auto`'s default without the PI.

The sister repository [QDistSAT](https://github.com/guluchen/QDistSAT) mirrors the same 51 benchmark codes (`data/tier0..tier5`) and hosts the cross-repo CI check.

## 2. Build, run, test

```bash
make                                          # Linux (g++, zlib) -> bin/distqldpc
make CXX="c++ -Wno-reserved-user-defined-literal"   # macOS clang
./bin/distqldpc BB_72_12_6                    # stem is looked up in data/matrices/tier*/
./bin/distqldpc -engine=cc -v TN_108_2_12     # CC engine with progress
./bin/distqldpc -cpu-lim=300 -seed=3 LP_442_68_10
./bin/distqldpc -h                            # all flags
make test-cc                                  # CC unit and randomized correctness tests (incl. mutants)
make test-cc-flags                            # flag-combination and CLI behaviour checks
```

Every PR that can change solver behaviour also needs the `QDistSAT cross-repo benchmark` check ([docs](QDISTSAT_CROSS_REPO_CI.md)).

## 3. Benchmarks, tiers and names

- **Codes** live in `data/matrices/tier0..tier5/` (51 stems). Codes that have not been run yet go in `data/matrices/untiered/` (section 7).
- **Stem format** is `{family}_{n}_{k}_{d}`. When d is not certified, the stem carries the proven bounds as `{lb}to{ub}`, e.g. `BB_1080_4_30to48`.
- **Renames** need a PI decision and a history row in `data/matrices/README.md` and NOTICE. Mirror every rename or new code into QDistSAT.
- **Tier membership** is set by main's time on the dedicated server, using the slower cardinality mode:

  | Tier | Main's time |
  |---|---|
  | 0 | < 1 s |
  | 1 | 1–10 s |
  | 2 | 10–100 s |
  | 3 | 100–2000 s |
  | 4 | 2000–5000 s |
  | 5 | > 5000 s or unsolved |

  Tier 5 runs with a 6 h limit.
- **Current timing basis** is main 12b3e05, recorded 2026-10-23 on branch `baselines/main-12b3e05`, `optimization/baselines/`; not yet merged.
  - e52d15b only changed the finder default and was not re-recorded (PI decision).
  - Proposed tier moves, pending PI: GB_144_12_12 t2→t1, TN_144_2_13 t3→t2, TN_250_10_15 t4→t3, LP_1020_136_16 t5→t3.

**Best current results, server, one core:**

- **Tier 0–4 (24 codes):** both engines solve every code. CC is 10–743x faster on tiers 1–4, e.g.:
  - LP_714: 579 s → 0.78 s;
  - TN_250: 1484 s → 117 s.
- **Tier 5 (27 codes, 6 h):**
  - CC solves 10: BB_360, LP_1020/1054/1122/1428/1768/2610, TN_180/216/252.
  - MaxSAT solves 3: LP_1020, TN_180, TN_216.
- **17 open codes:**
  - CC lower bounds: BB 30; TN 20–24, not yet independently re-certified, so the stems keep older lower bounds.
  - Verified upper bounds: 24–48, with witnesses in `optimization/experiments/GH-146/witnesses/`.
  - The gap is on the lower-bound side.

## 4. Rules the PI has set (in addition to AGENTS.md)

1. **Merges need explicit PI approval** for anything that changes solver behaviour, defaults, benchmark data, names or tiers, even when all gates pass. Open the PR, report, and wait for the PI to say "merge". Docs- or CI-only fixes: ask once if unsure.
2. **Adoption only after Tier 5.** A candidate replaces main behaviour only after passing Tier 0 → Tier 5 in order. Re-record the baselines after a default-changing merge unless the PI waives it.
3. **Seed-median judging (Tier 1–4).**
   - Run every cell (code x mode) with seeds 0–4 for main and candidate, concurrently, on pinned server cores.
   - Pass = for each tier and mode, the geomean of median ratios is < 1 and no cell exceeds 1.25.
   - Report seed ranges. Tier 5 uses the default seed.
4. **No external solvers for verification.** Verify only with DistQLDPC's own formulations, independent re-implementations, or GF(2) witness checks. Do not run third-party distance tools (dist-m4ri, Qubitserf, Magma, Gurobi, …) as evidence without PI approval.
5. **New scientific results** (a new exact distance or a raised lower bound on an open code):
   - mark them PLAUSIBLE until cross-checked by an independent search order or implementation, with witnesses verified in GF(2);
   - never rename a stem yourself.
6. **Clean-room rule for third-party ideas.** Implement from published descriptions and mathematics only. Credit the source in NOTICE / MODIFICATIONS.md / docs. Do not copy code from Qubitserf, dist-m4ri, Crocker, Lee or others.
7. **External communication goes through the PI.** Do not reply to outside issues or e-mails, and do not share unpublished optimizations or results with other authors. Example: issue #150 is an external, independent confirmation of BB_756 ≥ 30 and is waiting for the PI.
8. **Language.** GitHub records (issues, PRs, commits, reports) are in English.
9. **Resource limits.**
   - Dedicated server (`yfclab2`): one process per pinned core (`taskset -c <core>`), 4 GB address-space cap (`prlimit --as=4294967296`), `nohup … < /dev/null`.
   - Check that cores are free before starting.
   - The PI's Mac is reserved for baseline timing: no experiments there; at most a 2 GB cap and serial runs if the PI asks.
   - Codex Cloud and GitHub Actions: only builds, unit tests, smoke tests and short checks (AGENTS.md). Anything long becomes a reproducible server run package for the PI or a server-enabled agent.

## 5. How a round works

1. Read prior records in `optimization/experiments/GH-*/`: accepted, rejected and neutral. Rejected or neutral examples: GH-127 ladder, GH-128 p1skip, GH-129 frontier-on everywhere. Also read `docs/LITERATURE_CC_2026.md`.
2. Write 3 short proposals (hypothesis, change, expected effect, correctness risk) and pick 1.
3. Open an issue titled `[Codex] <one-line hypothesis>` and link it from hub issue #15. Claude agents use `[Mac agent]`.
4. Branch `experiment/gh-<issue>-<slug>` from current main.
5. Implement behind a flag, **default off**.
   - With the flag off, output must be byte-identical to main: compare the tier0+1 `-v` logs for `-no-card` and `-card-mto`, and for `-engine=cc` when CC is touched.
   - New pruning or bounds need a written soundness proof (MODIFICATIONS.md), randomized tests, and a mutant that the tests catch.
6. Run Tier 0 → 5 in order and stop at the first failed gate. Runners and job formats are in `optimization/baselines/runner/` and earlier experiments' `S1/runner/` folders.
7. Record everything in `optimization/experiments/GH-<N>/REPORT.md` using the policy fields: commands, binaries, raw outputs, medians, seed ranges and verdicts.
8. Push the branch, comment the result on the issue, and open a PR only when asked.

## 6. Coordination with the Claude agents

Claude agents run rounds from the PI's Mac and use the server. To avoid collisions:

- **Before starting a topic**, check open issues and branches (`gh issue list`, `git branch -r`). Do not work on a hypothesis that already has an open `[Mac agent]` issue or `experiment/` branch. To claim a topic, comment on its issue.
- **Active as of 2026-10-28:**

  | Work | Issue / branch | Server cores |
  |---|---|---|
  | GH-148 Tier 5: MaxSAT stabilizer-overlap propagator | #148, `experiment/gh-148-stab-overlap` | 0–53 |
  | CC lower-bound round on the 17 open tier5 codes | new `[Mac agent]` issue, number pending | 64–123 |
  | Baseline tables for 12b3e05 | `baselines/main-12b3e05`, not merged | — |
  | WebAssembly demo | `web/demo-phase1`, not merged | — |

  The demo is live at https://guluchen.github.io/DistQLDPC/ from the `gh-pages` branch.
- **Server cores 54–63 are unassigned.** Ask the PI before using them or anything else.
- **Branch prefixes:** use `codex/…` for engineering branches. Never push to `main` or `gh-pages` directly.

## 7. Codex's main task: grow the parity-check-matrix library

The PI has assigned Codex to make the benchmark library richer: more code **families** and a wider range of **sizes**. New codes go into a separate directory until they have been run.

### 7.1 Where new codes go

- **Directory:** `data/matrices/untiered/`, never directly into `tier0..tier5`.
  - The binary resolves a bare stem only in `data/matrices/` and `tier0..tier5`. Codes here therefore run by path, e.g. `./bin/distqldpc data/matrices/untiered/BB_576_16_unknown`.
  - This keeps every existing tier test, baseline and CI job unchanged.
- **Stem:** `{family}_{n}_{k}_unknown` until a DistQLDPC run gives bounds. n = columns of Hx, k = rows of Gx.
  - Use the family prefixes `BB`, `GB`, `LP`, `TN`. For a new family, propose a short prefix in the PR (e.g. `HGP`, `CBB`).
  - Two different codes with equal n and k get `_a`, `_b`.
- **Manifest:** one row per code in `data/matrices/untiered/MANIFEST.csv`, with these columns:
  - `stem`, `family`, `n`, `k`;
  - `construction` (parameters, e.g. l, m, A, B polynomials or lift and base matrices);
  - `source` (paper with arXiv/DOI, or repository with commit) and `license`;
  - `claimed_d` (as published: exact, ≤, or a range);
  - `generator` (script path and command), `checks`, `date`.
- **Generators:** under `scripts/codegen/`. Every matrix must be reproducible from its script and parameters. Prefer building codes from the published construction over copying matrix files.
- **Logicals:** compute Gx/Gz with `python3 scripts/compute_logicals.py --dir data/matrices/untiered <stem>`.
- **QDistSAT:** do not mirror untiered codes yet. QDistSAT's tests require every stem to sit in a known tier, so a code is mirrored only after it is tiered.

### 7.2 Checks every new code must pass (in the PR)

1. Hx · Hzᵀ = 0 over GF(2).
2. k = n − rank(Hx) − rank(Hz), and it equals the row counts of Gx and Gz.
3. Gx and Gz are valid logical bases:
   - Gx rows lie in ker Hx and outside rowspace(Hz);
   - Gz rows lie in ker Hz and outside rowspace(Hx);
   - Gx·Gzᵀ has full rank k.
4. **Not a duplicate:** compare with every existing code with the same n and k, in `tier0..tier5` and `untiered/`.
   - Check whether the row spaces of Hx and Hz are equal, also after swapping X/Z.
   - Report suspected equivalences (e.g. column permutations) instead of adding a second copy.
5. **Short smoke run** (allowed in Codex Cloud by AGENTS.md): `./bin/distqldpc -cpu-lim=60 data/matrices/untiered/<stem>` loads the code and prints consistent bounds.
   - Record the 60 s lower and upper bounds in the manifest.
   - For small codes with a published exact d, the run should reproduce it. A mismatch is a scientific escalation.
6. **Provenance in NOTICE:** redistribute only what the license allows.
   - CC BY and MIT sources need their attribution text.
   - For unlicensed or GPL-incompatible matrix files, rebuild the code from the published construction and cite the paper instead.

### 7.3 What to add (priorities)

1. **Families we do not have yet:**
   - hypergraph-product codes;
   - generalized toric / twisted-torus BB codes (Liang et al. 2025);
   - weight-8 BB codes (Lu–Yang–Guo 2026);
   - coprime / cyclic two-block codes (Lu–Guo–Liu–Yang 2026);
   - quantum Tanner codes from QuantumExpanders.jl (Mian et al. 2026);
   - ZSZ-LP codes (Hong 2026);
   - pair-partition and group-valued codes (Lee 2026);
   - BB codes from covering graphs (Symons–Rajput–Browne 2025);
   - LLM- and evolution-discovered BB codes (Cruz-Benito et al. 2026);
   - surface and toric codes of increasing size, as scaling checks with known d.
2. **Size coverage:**
   - Fill the gaps between current sizes, roughly n = 100–3000.
   - Give each family a ladder of sizes, so the library shows how solve time grows with d.
   - Include codes with **known exact d** (ground truth for correctness) as well as **open** codes.
3. **Codes with only estimated distances:** codes named in papers with only BP-OSD or heuristic distance estimates are valuable open targets. Record the published estimate as `claimed_d`.

Make one family per PR: generator, codes, manifest rows, NOTICE, checks. This keeps review simple.

### 7.4 What happens next (not Codex's job)

A server-enabled agent times the new codes with main under the baseline protocol and proposes a tier for each. On PI approval, the code moves to `tierN` under its final stem (`{d}` or `{lb}to{ub}`), and QDistSAT mirrors it.

## 8. Other good tasks for Codex

These do not overlap the active rounds. Each fits Codex Cloud: code, unit tests, short checks.

1. **Cross-repo data consistency check.** Write a script plus a CI job that fails when DistQLDPC `data/matrices/` and QDistSAT `data/` differ in stems, tiers or file contents, or when NOTICE and data README tier tables disagree with the directories.
2. **Library API tests.** On `web/demo-phase1`, `src/core/dq_api.{h,cc}` provides an in-process `dq_solve`. Strengthen `make test-dq-api`:
   - cancellation;
   - deadlines;
   - computed Gx/Gz versus the bundled ones on all 51 codes;
   - stdout identity with the CLI.
   Do not merge; report.
3. **Flag documentation audit.** Check that every flag in `-h` appears in README with its current default (several defaults changed in #142–#149). Fix the drift in a docs-only PR.
4. **Test coverage for `-ub-isd`.** Add randomized tests that `-ub-isd=off|stern|dumer` never report an unverified or too-low word on random CSS halves. Include a mutant check.
5. **Server run packages.** For any heavy idea, prepare a job file and script in the format of `optimization/baselines/runner/`, so a server-enabled agent can run it unchanged.
6. **After GH-148 reports**, a proposal for a MaxSAT-side follow-up: the CC packing bound as a MaxCDCL propagator. Open it as a `[Codex]` issue with a design only; implementation waits for the PI.

## 9. Where things are

| What | Where |
|---|---|
| CLI, encoding, split search, flags | `src/core/distqldpc.cc` |
| CC engine | `src/cc/` (`cc_half.*`, `cc_driver.*`, finder) |
| MaxCDCL patches and their documentation | `src/solver/`, `MODIFICATIONS.md` |
| Credits and data provenance | `NOTICE`, `data/matrices/README.md` |
| Experiment records | `optimization/experiments/GH-*/` |
| Timing baselines | `optimization/baselines/` |
| Literature survey and idea ranking | `docs/LITERATURE_CC_2026.md` |
| Hub issue | https://github.com/guluchen/DistQLDPC/issues/15 |

## 10. Completion report (every task)

Use the AGENTS.md format:

- what changed;
- validation performed;
- results;
- unresolved issues;
- `Scientific semantics changed: yes/no`;
- `PI action required: yes/no`.
