# GH-227 Mac diagnosis (single runs, default seed, serial, caffeinate -i -s)

Binaries (Mac builds of the branch):
- dq_v1: gate with period 32 for every class;
- dq_v2: period 32 while a class is on, 256 while it is off;
- dq_c3 = 03113cb1 (default period 128 / 1024, erasure in the default rules).

Configurations:
- run3.sh: M = default rules of v1/v2 (= main); N = `+erasure -cc-erasure-gate=none`; C = `+erasure` (gate); the k64/k128 runs pass `-cc-erasure-sample`.
- runcfg.sh: M3 = dq_c3 with the explicit main rules; C3 = dq_c3 defaults.

`mac_diag_logs.tgz` holds every -cc-stats log, including the per-class gate lines (`erasure class r R x X on|off ... test .. saved ..`). The summary is in issue #227.
