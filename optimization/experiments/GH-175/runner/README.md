# One MaxSAT numeric-gate / engine-proof completion — unexecuted

All six distances, including n3000,d20, are already independently certified
by two actual-matrix lower/upper certificate implementations, CC and GF(2)
words. Default MaxSAT reproduces the first five distances; on n3000 its60s
run times out with no numeric fields. That numeric smoke gate is INCOMPLETE.
This single job can complete MaxSAT's own output/proof; it is not outstanding
mathematical distance certification or authorization to use server resources.

Frozen job: TOR_3000_6_unknown, MaxSAT default flags, seed0, verbose,6hCPU,
600s extra wall backstop,4GiB, serial on one PI-allocated free yfclab2 core,
null stdin.6hCPU and6h10mwall are configured limits, not an ETA. No core is
allocated and no server job has run. Do not execute on the Mac or Actions.

Use a clean frozen checkout, check ownership/availability and build the
unchanged solver serially on the assigned core. The runner binds case SHA,
retained independent certificate SHA, all matrix SHA256s and frozen argv;
it records source, binary, jobs, proof and matrix hashes with raw outputs.
Reference exact20 comes from independent finite matrix proofs, not an
individually published rectangular distance claim (manifest keeps upper20).

Inspect, default dry-run (replace CORE with the assigned integer):

```sh
python3 optimization/experiments/GH-175/runner/run_serial.py --cpu CORE --out /absolute/new/evidence
```

Only after PI allocation and a fresh free-core check:

```sh
nohup python3 optimization/experiments/GH-175/runner/run_serial.py --cpu CORE --out /absolute/new/evidence --execute --allocation-ref 'PI allocation comment URL' --core-confirmed-free > /absolute/new/runner.log 2>&1 < /dev/null &
```

Host, dirty-checkout, altered-job, missing-allocation/free-core, occupied-core
and frozen-input guards prevent unintended execution. Dry-run, Mac refusal
and altered-argv refusal tested without running any solver. Actual numeric
bounds/words are checked; a wall backstop or contradiction retains evidence
and stops. A timeout remains incomplete. No stem/tier/QDistSAT/default/merge
change occurs. Independent library construction can continue meanwhile.
