# yfclab2 fixed-core lease setup

This is benchmark infrastructure, not an E001 optimization. It changes no
DistQLDPC/QDistSAT solver, input, timeout/result meaning or scientific semantics.

Setup status (2026-10-07): the user deferred CPU permission/isolation setup.
The prepared tools remain available, but installation is not complete. Read-only
verification found no installed helper, sudoers rule, recovery timer or CPU
partition. Pending installer processes were checked/cancelled. Do not resume
administrator installation without renewed user instruction. Ordinary authorized
spare-capacity use remains separate from this deferred setup; E001 remains
INCONCLUSIVE and no higher-tier gate has passed.

An administrator installs `cpu_run.py` as a root-owned executable and grants
only its `run ...` and `status` operations to yfc without a password. Arbitrary
benchmark arguments are executed only after dropping to yfc, setting
no-new-privileges and restricting affinity to CPU 102. The helper reserves
102 and its verified SMT sibling 230 in a cgroup v2 isolated partition; other
ordinary workloads temporarily lose access to those two logical CPUs. Their
processes are not killed and their configured CPU masks are not edited.
Both logical CPUs count against the user's half-spare capacity allowance.

The pair must be >=95% idle at acquisition and global idle >50%. The lease
supervisor checks global capacity and partition validity every two seconds.
Lease duration is capped at two hours. Normal completion, command failure,
capacity loss, signal or deadline kills only remaining processes in the lease
and removes the partition. A root recovery timer checks once per minute for
stale groups after supervisor death, and signals expired active leases.
Do not claim zero IRQ/kernel interference or host exclusivity: memory/cache,
package power and kernel interrupts can still affect timings. Existing E001
promotion methodology is not changed by installing this helper.

No GRUB/reboot, CPU governor, IRQ affinity, other user's permissions, general
passwordless sudo or permanent CPU reservation is configured. Root-owned helper
and installation files cannot be edited through the granted commands. There
is no user-supplied root output path, PID, CPU pair or shell execution.

After staging the reviewed files on the server, install once:

```sh
sudo /usr/bin/python3 -I /home/yfc/distqldpc-isolation-setup/install.py install
```

Subsequent uses need no password:

```sh
sudo -n /usr/local/sbin/distqldpc-cpu-run status
sudo -n /usr/local/sbin/distqldpc-cpu-run run --cwd /home/yfc -- \
  /usr/bin/python3 -c 'import os,time; print(os.getuid(),os.sched_getaffinity(0)); time.sleep(5)'
```

Capture wrapper stdout/stderr and benchmark outputs separately. An
`ISOLATION_ERROR` invalidates that attempt; do not remove or silently retry
affected samples. The helper exits with the command's exit status when it
finishes normally. It does not replace scientific correctness/timing guards.

Review the supervisor's root-owned `/run/distqldpc-bench/lease.json`, captured
events, cgroup membership and effective/exclusive CPU sets during validation.
Verify cgroup removal and CPU availability after success, nonzero command exit
and forced supervisor death before using it for performance conclusions.

Uninstall (administrator password required; refuses an active lease or changed
installation files):

```sh
sudo /usr/bin/python3 -I /home/yfc/distqldpc-isolation-setup/install.py uninstall
```

Installation targets: `/usr/local/sbin/distqldpc-cpu-run`,
`/etc/sudoers.d/distqldpc-bench`, and the matching recovery service/timer under
`/etc/systemd/system/`. Existing conflicting files are never overwritten.
The helper refuses to enable a missing global cpuset controller or remove all
CPUs from an existing cgroup. Host-specific kernel partition failures are
retained and cleaned up, not bypassed by widening sudo permissions.

Reference: Linux 6.8 [cgroup v2 cpuset partitions](https://www.kernel.org/doc/html/v6.8/admin-guide/cgroup-v2.html#cpuset).
