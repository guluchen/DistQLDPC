# E006 exact reproduction / controlled follow-up commands

Executed on Windows from the task workspace, with the installed/pinned Cygwin
runtime and immutable prior package already verified. Candidate worktree is
exactc91b19bbf29a28a6e808c8ef2c328cb9cef784e8. Do not use the history checkout
or E004 LTO candidate as either E006 executable. Native Python uses UTF8.

```powershell
python -X utf8 DistQLDPC/optimization/experiments/E006/tier0_windows.py --out E006-validation-01
python -X utf8 DistQLDPC/optimization/experiments/E006/run_windows_tier1.py --prior E004-windows-tier2-02 --cygwin-root E004-windows-runtime/cygwin --candidate-tree E006-BDD --validation E006-validation-01 --output E006-windows-tier1-01 --preflight-wait-sec 30 --priority-class above-normal
python -X utf8 DistQLDPC/optimization/experiments/E006/audit_partial.py E006-windows-tier1-01 --prior E004-windows-tier2-02 --candidate E006-BDD
```

First two commands create fresh directories; retained existing directories must
not be overwritten. The last command reads existing evidence and writes a
separate audit. Any future full run needs a new preregistered output directory,
no pooling with this partial round. The Tier1 driver pins local binaries and
validates source/build/hosted receipts; it is specific to this retained runtime.

## Prepared yfclab2 follow-up, not executed

Only after actual fixed-core lease acquisition/nonzero-command cleanup/recovery
validation described in E004/CONTROLLED-FOLLOWUP.md. Existing installation and
busy-core refusals do not establish those validations. Preserve original
authorized helper and pair102/230; no root scope extension or moving others'
work. Supply real reservation evidence, never a made-up attestation. The helper
requires global spare>50% and allocation<=half spare; this runner additionally
checks sibling idle>=95%. It builds/tests/benchmarks serially as unprivilegedyfc.

The retained E006-server-handoff.tar.gz contains this exact reviewed runner
and12 css1/css4/css5_{Hx,Hz,Gx,Gz}.txt fixtures. Its SHA256 is
cf377091c5b52c8785b754091227250090d0cf2a475153fabb8f50c58504270f;
server-handoff-manifest.json lists all13 payload hashes. Transfer from the
Windows task workspace (these commands are prepared, not executed):

```powershell
ssh yfclab2 "test ! -e /home/yfc/codex-e006-bdd-20261008 && mkdir /home/yfc/codex-e006-bdd-20261008"
scp DistQLDPC/optimization/experiments/E006/E006-server-handoff.tar.gz yfclab2:/home/yfc/codex-e006-bdd-20261008/
scp DistQLDPC/optimization/experiments/E006/server-handoff-manifest.json yfclab2:/home/yfc/codex-e006-bdd-20261008/
```

Do not overwrite an existing directory. Verify the driver and fixtures using
the supplied manifest; driver SHA256:
55edb431354606954d0b4943f851f5a944e790119d7e911f89381fba83f3de94.
Example handoff layout on the server:
/home/yfc/codex-e006-bdd-20261008/server_tier1.py and fixtures/*.txt.
Clone exact independent source commits into that new directory:

```bash
set -eu
: "${DISTQLDPC_RESERVATION_NOTE:?Provide actual validated reservation evidence}"
experiment_root=/home/yfc/codex-e006-bdd-20261008
cd "$experiment_root"
printf '%s  %s\n' cf377091c5b52c8785b754091227250090d0cf2a475153fabb8f50c58504270f E006-server-handoff.tar.gz | sha256sum --check
tar -xzf E006-server-handoff.tar.gz
python3 -c 'import hashlib,json,pathlib; m=json.loads(pathlib.Path("server-handoff-manifest.json").read_text()); assert all(hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()==h for p,h in m["files"].items())'
printf '%s  %s\n' 55edb431354606954d0b4943f851f5a944e790119d7e911f89381fba83f3de94 server_tier1.py | sha256sum --check
test ! -e baseline
test ! -e candidate
test ! -e tier1-01
git clone https://github.com/guluchen/DistQLDPC.git baseline
git -C baseline checkout --detach 24572d6d09cce9a4a5faa58300a89e0feba9da6a
git clone https://github.com/guluchen/DistQLDPC.git candidate
git -C candidate checkout --detach c91b19bbf29a28a6e808c8ef2c328cb9cef784e8
sudo -n /usr/local/sbin/distqldpc-cpu-run run --cwd "$experiment_root" -- \
  /usr/bin/python3 "$experiment_root/server_tier1.py" \
  --baseline "$experiment_root/baseline" --candidate "$experiment_root/candidate" \
  --fixtures "$experiment_root/fixtures" --out "$experiment_root/tier1-01" \
  --cpu 102 --sibling 230 --reservation-note "$DISTQLDPC_RESERVATION_NOTE" \
  > "$experiment_root/lease-tier1-01.log" 2>&1
sudo -n /usr/local/sbin/distqldpc-cpu-run status
```

If the benchmark command fails, independently run the final status command;
set-e intentionally prevents further experimental commands. Preserve failed
wrapper logs/partial output. Confirm lease release even after success; the
runner itself never changes system isolation or priorities.

Prepared runner is syntax-checked only, not a demonstrated Linux integration.
It checks exact source commits/clean trees, fresh make-j1 builds, BDD production
probe, smoke, retained tiny-CSS distances, LP136/BB108 both modes, sound one-second
timeout results, then all48 Tier1 serial AB/BA/AB solves.180s internal/195s
external limit, recorded2s resource observations, no automatic retry/Tier2/3.
Original tiny-CSS exhaustive oracle and full hosted QDistSAT check are retained
in this experiment; this server script checks those same distances but does not
claim to rerun the complete cross-repo comparison helper. Any unexpected setup
failure or semantic assertion stops before performance. Verify fixture bytes
against raw-sha256.json before launch; never edit matrices to satisfy results.

Audit raw d/objective/LB/UB, return codes, expected ground truth, all timing
samples, compiler/binary hashes, topology/lease/cleanup and unchanged decision
gate before reconciling state. Full medians do not automatically promote:
report serious per-case regressions, distinguish OFF controls from the changed
encoding, require reproducibility/noise evidence. Only a justified Tier1 pass
or separately preregistered authorized exploratory step reaches LP340.
Budget one worker, typical minutes, worst144 solver-min exceeds a single2h
lease if every run uses its full limit; expiry is INCONCLUSIVE, not extension.
No research-grade claim or merge from this prepared command sheet.
