# H010 dedicated-server reproduction, pending controlled run

No server benchmark has run. Latest three read-only windows: globalidle
44.6205/44.9836/44.9631%, CPU102idle0%, sibling230idle99.40/99.60/100%.
The user requires globalspare>50%; therefore no remote computation is eligible.
The installed102/230 lease still requires successful acquisition/nonzero-exit/
recovery validation before controlled timing claims; do not infer host exclusivity.

Use a new source directory on the server when the coordinator assigns an
eligible controlled slot. Do not share a build/profile directory between agents.
Run ordinary user commands, one worker, same compiler/runtime on both versions.
Prerecorded source and fixed training are below; no Windows binary/profile reuse.
These exact preparation commands already match the successful Linux CI method;
server training/build/result verification must still run under capacity supervision.

```sh
git clone https://github.com/guluchen/DistQLDPC.git GH16-controlled
cd GH16-controlled
git checkout --detach 467433133851f25a1ab76b662ca93250acf46d03
git archive 24572d6d09cce9a4a5faa58300a89e0feba9da6a > ../GH16-baseline.tar
mkdir ../GH16-baseline
tar -xf ../GH16-baseline.tar -C ../GH16-baseline
mkdir ../GH16-controlled-evidence
make -C ../GH16-baseline -j1 bin/distqldpc > ../GH16-controlled-evidence/build-baseline.log 2>&1
bash scripts/pgo_train_build.sh ../GH16-controlled-evidence/pgo-training
sha256sum ../GH16-baseline/bin/distqldpc bin/distqldpc > ../GH16-controlled-evidence/binaries.sha256
git clone https://github.com/guluchen/QDistSAT.git ../GH16-QDistSAT
git -C ../GH16-QDistSAT checkout --detach 7c4774fffc49856f48a22ae5f9063d00b2661aaa
python3 ../GH16-QDistSAT/benchmarks/compare_distqldpc_binaries.py \
  --baseline-bin ../GH16-baseline/bin/distqldpc --candidate-bin bin/distqldpc \
  --data-root ../GH16-QDistSAT/data --stems LP_136_32_4 BB_108_8_10 \
  --timeout 45 --json-out ../GH16-controlled-evidence/pilot.json \
  --markdown-out ../GH16-controlled-evidence/pilot.md
```

Then repeat the local Tier0 independent CSS/WCNF/smoke/timeout checks on the
actual Linux production binaries before timing. Preparation/pilot times are not
performance samples. Require correct returncodes and every result/bound; any
scientific mismatch rejects immediately. Preserve buildlogs, final symbol report,
profiles/gcov counts, source/input/compiler hashes, and cleanup evidence.

Tier1 exact solve argv for each combination:

```sh
taskset -c 102 ../GH16-baseline/bin/distqldpc -v -cpu-lim=180 -no-card data/matrices/BB_90_8_10
taskset -c 102 bin/distqldpc -v -cpu-lim=180 -no-card data/matrices/BB_90_8_10
```

Use all four fixed stems BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6;
substitute each stem and both -no-card/-card-mto. For each stem/mode run AB/BA/AB,
three baseline/three candidate,48 solves total. Supervise with195s watchdog and
continuous2s spare-capacity guard; log exact argv/fulloutputs/elapsed/per-core
telemetry. Prefer a validated lease of102/230, never simultaneous siblings.
Keep median/range rules from TIER1_PLAN.md and frozen profile hashes. These solve
commands alone do not establish controlled conditions or provide a watchdog.

Only a genuine controlled Tier1 PASS permits the standard Tier2 twelve-solve
LP_340_56_8 comparison, bothmodes3pairs, same AB/BA/AB, internal600s/watchdog615s.
The separate Windows exploratory exception never supplies this server gate.
No Tier3 commands or scientific performance claims are authorized here.
