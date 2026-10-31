# Optional MaxSAT reproduction — unexecuted

The distances of all four cases are already independently certified by
complete classical enumeration/HGP Theorem1 plus CC and GF(2) words. MaxSAT
also solves the first two; it returns[5,6] on N1508/2384 within60s. These two
jobs only complete that internal engine's proof. They are not outstanding
distance certification, a missing numeric gate or an authorization to use
server resources.

Each job: default seed, MaxSAT,6h CPU plus600s wall backstop,4GiB, serial
on one explicitly PI-assigned free yfclab2 core, null stdin. Aggregate12h CPU
and12h20m wall are configured limits, not a forecast. No core is allocated
and no job is launched. Do not run on the Mac or Actions.

Use a clean frozen checkout, check ownership/core availability and build
the unchanged solver serially on the assigned core. The runner verifies
the frozen cases against the retained independent proof and records binary,
source, input, case, proof and job hashes. Expected d=6 is an independently
derived exact result, not the larger initial algebraic upper/source claim.

Inspect, default dry-run:

```sh
python3 optimization/experiments/GH-174/runner/run_serial.py --cpu CORE --out /absolute/new/evidence
```

Only after PI allocation and a fresh free-core check:

```sh
nohup python3 optimization/experiments/GH-174/runner/run_serial.py --cpu CORE --out /absolute/new/evidence --execute --allocation-ref 'PI allocation comment URL' --core-confirmed-free > /absolute/new/runner.log 2>&1 < /dev/null &
```

Execution refuses other hosts, dirty checkouts, missing allocation/free-core
confirmation, occupied cores, stale proof/case identities and altered job
arguments. It rechecks inputs/binary/core between jobs, retains raw failures
and stops after scientific contradictions or a wall backstop. A timeout
remains an incomplete engine proof. No automatic rename/tiering/QDistSAT
mirror/merge occurs, and completing these jobs is not needed for further
independent library construction.
