# DistQLDPC live demo (WebAssembly), phase 1

A static web page that runs DistQLDPC itself, compiled to WebAssembly, in the visitor's browser: pick a bundled
code (tiers 0-3 and four tier-5 LP codes) or paste / upload your own `Hx` / `Hz` (and optionally `Gx` / `Gz`),
choose the MaxSAT engine (default) or the connected-cluster engine (`-engine=cc`), and watch the proven lower bound
and the best upper bound converge to the distance. The result panel shows `d`, `n`, `k`, a verified minimum-weight
witness (downloadable; drawn on the two `l x m` torus grids for bivariate bicycle codes) and the comparison with
the distance in the stem name.

Planned host: https://guluchen.github.io/DistQLDPC (GitHub Pages of this repository). **Not published yet**: Pages is
not enabled and no workflow is active; see "Deploying later".

## How it works

| Piece | What it does |
|---|---|
| `src/core/dq_api.{h,cc}` | In-process library entry point `dq_solve(hx, hz, gx_or_null, gz_or_null, flags, callback, user)`. It is a unity build of `src/core/distqldpc.cc` with `DQ_LIBRARY` defined, so the option parser, the checks, both engines and the stdout text are the CLI's own; only the plumbing differs (no fork, pipe or signals; matrices from memory; `-cpu-lim` is a deadline polled inside both engines; `dq_cancel()`). Events (one line each): `TRY`, `LB`, `UB`, `RESULT` (the CLI's pipe protocol), `INFO`, `LOGICALS`, `ENGINE`, `PROBE` (one MaxSAT oracle call), `LEVEL` (one CC weight level), `WITNESS` (a verified support), `FINAL`; see the header. `Gx` / `Gz` are computed when not given (port of `scripts/compute_logicals.py`). |
| `Makefile` targets | `make test-dq-api` (native library + `build/dq_api_test`), `make wasm` (`web/dq.js` + `web/dq.wasm`, Emscripten: `MODULARIZE`, single-threaded, `ALLOW_MEMORY_GROWTH` up to 2 GB, 8 MB stack). The CLI objects never see `DQ_LIBRARY`. |
| `web/worker.js` | Web Worker: loads `dq.js`, runs one `dq_solve`, posts every event and the stdout / stderr lines to the page. The page starts a fresh worker per run; **Stop = `worker.terminate()`**. |
| `web/index.html`, `app.js`, `style.css` | The page (no framework, no CDN). Left: code and options (engine, CC rules, dual map, upper-bound finder / pre-pass, symmetry breaking, seed, time limit, `-v`). Center: live chart of `d_lb` / `d_ub` versus time, the per-probe (MaxSAT) or per-level (CC) table, the log (exactly the CLI's stdout). Right: result and witness. Footer: commit, the flags of the last run, GPL-3.0-or-later notice and source link, MaxCDCL MIT notice, NOTICE credits. Deep links: `#code=TN_108_2_12&engine=cc&limit=60&run=1`. |
| `scripts/web_export_codes.py` | Writes `web/codes/<stem>.json` (sparse rows) and `web/codes/index.json` from `data/matrices`, with the native reference times of `web/timings.json` and, for BB codes, an `l x m` torus factorization verified on `Hx` (used only for the drawing). |
| `web/build.sh` | `make wasm` + code export + `web/version.json` (commit, date, emcc version). |
| `web/pages-workflow.draft.yml` | Draft GitHub Actions workflow (inactive, `workflow_dispatch` only, kept outside `.github/`). |
| `web/test-records/` | Records of the checks below. |

Generated files (`dq.js`, `dq.wasm`, `codes/`, `version.json`) are git-ignored.

## Building

Needs the Emscripten SDK (official source: https://github.com/emscripten-core/emsdk), `python3`, `make`.

```bash
git clone https://github.com/emscripten-core/emsdk.git ~/emsdk
~/emsdk/emsdk install 6.0.13 && ~/emsdk/emsdk activate 6.0.13
source ~/emsdk/emsdk_env.sh
JOBS=8 web/build.sh            # -> web/dq.js, web/dq.wasm, web/codes/, web/version.json
```

Phase 1 was built on yfclab2 (`taskset -c 100-107`, emscripten 6.0.13); a full build with 8 jobs takes well under a minute.
Sizes: `dq.wasm` 428,816 bytes (162 KB gzip), `dq.js` 61,521 bytes (17 KB gzip), `codes/` 0.99 MB (255 KB gzip;
`LP_2610_744_16.json` alone 498 KB). The page itself is about 40 KB.

Native checks of the library (no Emscripten needed):

```bash
make test-dq-api
build/dq_api_test solve data/matrices/tier0/BB_72_12_6 -engine=cc        # stdout = the CLI's stdout, events on stderr
build/dq_api_test solve data/matrices/tier0/BB_72_12_6 --compute-g      # Gx, Gz computed
build/dq_api_test logicals data/matrices/tier0/BB_72_12_6               # computed Gx/Gz vs bundled
build/dq_api_test cancel data/matrices/tier2/TN_108_2_12 1.0            # dq_cancel() after 1 s
node tests/wasm_node_run.js data/matrices/tier2/TN_108_2_12 -engine=cc  # the wasm module under Node.js
```

## Testing locally

```bash
python3 -m http.server 8765 --bind 127.0.0.1 --directory web
# open http://127.0.0.1:8765/
```

Any static server works (the page needs `fetch` and a Web Worker, so not `file://`). No COOP/COEP headers are
needed (single-threaded build).

## Checks done for phase 1 (2026-10-23)

- **CLI unchanged** (`web/test-records/cli_identity_tier01.txt`): branch binary vs main 12b3e05 on yfclab2, all 15
  tier0+1 codes x {default, `-v`} x {MaxSAT, CC}: default output byte-identical in all 30 runs; `-v` logs identical
  after masking timing numbers, except the order of two `ub-pre` / ub-search lines that also differs between two runs
  of main itself (wall-clock scheduling of the finder). The library's stdout equals the CLI's stdout in all 30
  default runs.
- **Gx / Gz in C++** (`web/test-records/logicals.txt`): on all 51 bundled codes the computed bases have the bundled
  number of rows, lie in `ker H`, and span the same space modulo the stabilizers as the bundled `Gx` / `Gz`
  (rank `[S; G_computed]` = rank `[S; G_bundled]` = rank of both).
- **wasm vs native, same machine** (yfclab2, one pinned core each, `web/test-records/wasm_vs_native_*.txt`): every
  answer equals the stem (27 codes, both engines where feasible). Runs over 10 s: wasm (Node 18) / native =
  1.19-1.32 for MaxSAT and CC; short runs are dominated by about 0.6 s of Node start-up and wasm compilation.
- **Browser** (Claude desktop built-in browser, Chromium, Apple Silicon Mac): see the table below; Stop and the time
  limit keep the proven bounds; the wasm heap stayed at its initial 64 MB in every run.

| Code | Engine | d (stem) | Browser total | Native, yfclab2 | wasm under Node, yfclab2 |
|---|---|---|---|---|---|
| BB_72_12_6 | MaxSAT | 6 (6) | 0.10 s | 0.03 s | 0.95 s |
| BB_72_12_6 | CC | 6 (6) | 0.05 s | 0.03 s | 0.63 s |
| LP_442_68_10 | MaxSAT | 10 (10) | 2.37 s | 6.33 s | 7.85 s |
| LP_442_68_10 | CC | 10 (10) | 0.11 s | 0.04 s | 0.75 s |
| TN_108_2_12 | MaxSAT | 12 (12) | 10.10 s | 22.86 s | 27.92 s |
| TN_108_2_12 | CC | 12 (12) | 1.91 s | 0.97 s | 1.72 s |

(The Mac's cores are faster than yfclab2's; native timing was not run on the Mac, which is reserved for serial
timing. Node runs include about 0.6 s of start-up.) Also run in the browser: BB_288_12_18 CC (d = 18, 0.12 s),
BB_144_12_12 CC (12), TN_144_2_13 CC (13, 0.78 s), BB_72_12_6 pasted with Gx / Gz computed (6); Stop during
LP_714_100_16 MaxSAT after 4 s (bounds 10 / 16 kept, worker gone); TN_144_2_13 MaxSAT with a 2 s limit (TIMEOUT,
bounds 9 / 13, the CLI's summary text). Screenshots: `web/screenshots/`.

## Deploying later (needs the PI)

1. Review the local preview.
2. Copy `web/pages-workflow.draft.yml` to `.github/workflows/pages.yml` (a token with `workflow` scope or a push by the
   PI is needed: the agent token cannot push workflow files).
3. Settings -> Pages -> Source: GitHub Actions; then run the workflow by hand. Nothing is published before that.

## Known limits of phase 1

- One run at a time per tab; each run uses one core of the visitor's machine (the MaxSAT engine on tier-3 codes and
  beyond can take minutes to hours; the page says so and the time limit defaults to 120 s).
- Fatal input errors (malformed matrices, inconsistent widths) end the worker with the CLI's error message.
- Witness drawings only for BB codes (torus factorization verified on `Hx`); other families show the support list.
