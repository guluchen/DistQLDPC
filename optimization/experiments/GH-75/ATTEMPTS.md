# GH-75 attempts log (all retained)

- **tier0-science-01 (Mac, Apple clang 21, ABORTED by agent, not a failure).** Frozen
  binaries `raw/tier0-science-01/binaries.sha256` (base72 = 72d1fe1 build, cand =
  bbe5055). `--jobs 2`, 60 s, load guard. Stopped after 39/200 jobs (all 39 OK: no
  value mismatch, no unsound bound) when the coordinator reserved the Mac for timing and
  provided the Linux server for correctness work. Partial logs and `progress.txt` kept.
- **tier0-science-02 (yfclab2, Linux, GCC 13.3, `make -j8`)**: full 50 x 4 sweep with the
  unmodified GH-60 harness (`~/mac-agent-20261009/tier0_science.py`, byte-identical to
  GH-60's), `--jobs 4`, 60 s. This is the decisive Tier0 science run (see TIER0_RESULT.md).
- `verify_autos.py` first run reported spurious FAILs for 14 no-symmetry codes (n > 64):
  checker bug comparing a 64-entry truncated list with a full list; fixed before commit,
  rerun ALL_PASS (binary output unchanged).
