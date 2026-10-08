# GH26 prototype gate

This is a test-only pure snapshot model. No production source or build flag is changed.
No tests have been run; source review does not mean Tier0 PASS.
The C++ kernel implements one covered small-core certificate. The Python reference
enumerates complete truth tables independently and validates every OLD core and
returned lower bound. It does not call a SAT/MaxSAT engine as its reference.

After explicit Windows host assignment, use the scheduler's frozen toolchain,
owned Job, one compiler worker and capacity/watchdog/cleanup wrapper. Commands
inside that wrapper, from repository root, are:

```text
g++ -std=c++11 -O0 -g -Wall -Wextra -pedantic optimization/experiments/GH-26/prototype/driver.cc -o <assigned-output>/fla-model.exe
python optimization/experiments/GH-26/prototype/oracle.py --driver <assigned-output>/fla-model.exe --output <assigned-output>/model-oracle.json
```

Fixed budget: 16 focused fixtures, 512 fixed-seed four-variable cases, and six
malformed/precondition-declined snapshots; no claimed bound for invalid old K. Driver
60-second subprocess cap; whole prototype slot at most five minutes. No parameter
sweep or timed solver. Retain compiler output, all input/result records, exact
commands, toolchain/input/binary hashes and wrapper telemetry/cleanup. A fixture
assertion mismatch must be investigated; an actual returned LB above exact
feasible optimum is a semantic rejection of the kernel and stops integration.

The core-snapshot source adapter, existing conflict analyzer's learned nogood
and bound lifetime are still UNIMPLEMENTED/UNTESTED. This model gate does not
certify production FLA or authorize performance. Those obligations must be
completed before a production hook; original production files remain identical
to baseline24572d6.
