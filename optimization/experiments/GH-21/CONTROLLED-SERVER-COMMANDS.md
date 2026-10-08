# GH21 controlled server reproduction

Prepared commands only; not executed on yfclab2. A fresh scheduler lease and eligible aggregate resource window remain required. No timing conclusions from shared CI. Rebuild on Linux because Windows executables are Cygwin-specific; require the SAME GCC14.4.0 for both versions and run Linux Tier0 again before performance. Do not silently substitute compiler flags or label untested Linux binaries equivalent to frozen Windows artifacts.

Use an empty user-owned directory under yfc's workspace; the commands below fail if either checkout already exists. Original baseline and production candidate are pinned, independent of later support/documentation commits:

```bash
set -eu
test ! -e GH21-linux-baseline && test ! -e GH21-linux-candidate
git clone --no-checkout https://github.com/guluchen/DistQLDPC.git GH21-linux-baseline
git clone --no-checkout https://github.com/guluchen/DistQLDPC.git GH21-linux-candidate
git -C GH21-linux-baseline checkout --detach 24572d6d09cce9a4a5faa58300a89e0feba9da6a
git -C GH21-linux-candidate checkout --detach e1aa9175c511b72dbb7305f5769b1e11f41bc05f
CXX="$(command -v g++)"
test "$("$CXX" -dumpfullversion)" = 14.4.0
"$CXX" --version > GH21-linux-compiler.txt
make -C GH21-linux-baseline -j1 CXX="$CXX" bin/distqldpc > GH21-linux-baseline-build.log 2>&1
make -C GH21-linux-candidate -j1 CXX="$CXX" bin/distqldpc > GH21-linux-candidate-build.log 2>&1
sha256sum GH21-linux-baseline/bin/distqldpc GH21-linux-candidate/bin/distqldpc > GH21-linux-binary-sha256.txt
git -C GH21-linux-baseline rev-parse HEAD > GH21-linux-baseline-source.txt
git -C GH21-linux-candidate rev-parse HEAD > GH21-linux-candidate-source.txt
git -C GH21-linux-candidate diff 24572d6d09cce9a4a5faa58300a89e0feba9da6a HEAD -- Makefile src > GH21-linux-production.diff
```

The production diff must be exactly the one O3→O2 token; compile logs must show default flags on every object/link. Obtain pinned original QDistSAT matrices through its existing manifest-controlled package, not regenerated ground truth. Record source/input/compiler/library/environment/binary hashes before/after. Smoke is a subset: full Linux Tier0 must also cover tiny independent CSS/PMS oracles, explicit-mode identical WCNFs and actual timeout/bounds before timing. No `make`/smoke/testing outside an assigned resource slot.

Inside the reviewed fixed-core lease, run each exact command serially on the SAME logical CPU while its sibling is excluded from competing work. Substitute the verified baseline/candidate binary and immutable matrix stem as shown; all stdout/stderr/wall timing goes to separate fresh raw files:

```bash
/usr/bin/time -f '%e' -o "$label.elapsed" "$binary" -v -cpu-lim=180 "-$mode" "$matrix_stem" > "$label.stdout" 2> "$label.stderr"
```

Fixed Tier1 outer order BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6; each case no-card then card-mto; repeats1,2,3; version order baseline/candidate, candidate/baseline, baseline/candidate,48 solves. Parent watchdog195s with bounded process-tree cleanup; active2s capacity/isolation telemetry, per-command frozen identities, all science and settings cleanup required. `/usr/bin/time` above alone is not a resource supervisor: integrate into the already reviewed server lease runner; never run it naked as a controlled benchmark.

The existing source-reviewed helper CLI is `/usr/local/sbin/distqldpc-cpu-run run --cwd <absolute> -- <absolute executable> ...` (primary repository optimization/server/isolation/cpu_run.py). Its source performs active2s aggregate capacity/partition checks and cgroup cleanup, sets fixedCPU102 while reserving sibling230, and drops to yfc. Installation status alone is not a successful live-isolation validation; validate installed identity/isolation/recovery and scheduler ownership before use. It strips custom environment variables, so verify compiler/runtime libraries work in its actual sanitized environment.

After those guards and Linux Tier0 pass, this is the exact per-solve lease command preserving scientific output separately from lease events; variables must be absolute verified paths and fresh labels:

```bash
sudo -n /usr/local/sbin/distqldpc-cpu-run run --cwd "$PWD" -- \
  /bin/bash -c 'exec /usr/bin/timeout --signal=KILL "$1" /usr/bin/time -f "%e" -o "$2.elapsed" "$3" -v "-cpu-lim=$4" "-$5" "$6" > "$2.stdout" 2> "$2.stderr"' \
  gh21 195s "$PWD/$label" "$binary" 180 "$mode" "$matrix_stem" \
  > "$label.lease.stdout" 2> "$label.lease.stderr"
```

Execute only the fixed AB/BA/AB order above; keep every nonzero exit and missing elapsed file as incomplete, never substitute a limit. Verify empty cgroup/released partition after each lease and all16 input/binary hashes before/after. Helper acquisition can legitimately refuse busy102/230 even when aggregate idle is high; record an INCONCLUSIVE/no-run, not retry until favorable. One lease per solve avoids the helper's two-hour cap and always uses the same fixed core. Retain acquisition/cleanup differences as possible noise; commands do not prove frequency/cache isolation.

For the separately preregistered one-round exploratory Tier2 ONLY, same ordering and identities but case LP_340_56_8, CPU argument600 and external615s,12 solves; no Tier1 PASS inferred. No remote run or adoption claimed. Wrapper/live isolation evidence and full scientific parsing/audit are still required for any actual controlled replication.
