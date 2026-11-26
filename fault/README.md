# Circuit distance with DistQLDPC

Open the [browser workbench](https://guluchen.github.io/DistQLDPC/fault/), choose **Your circuit**, and paste or upload an annotated Clifford circuit in Stim text or DistQLDPC JSON. Use **Load repetition example** or **Load hook-fault example** to see a complete input. Under **Search settings**, choose MaxSAT, connected cluster (CC), or frontier DP.

The browser runs the solver locally using WebAssembly. Direct circuit inputs use the circuit's fault annotations and require no precomputed detector error model (DEM).

## What the distance measures

Circuit distance is the minimum number of faulty locations that leave every detector parity unchanged and flip at least one declared logical observable. An allowed Pauli alternative costs one fault at its location. For example, an `XZ` error after a CNOT is one fault. Positive probabilities specify the allowed alternatives. Alternatives from the same Pauli channel are mutually exclusive.

A timeout or resource limit may leave only bounds. A verified fault witness establishes an upper bound. An exact finite result also requires ruling out every smaller fault weight.

## Prepare the input

- **Stim text** declares the operations, noise channels, `DETECTOR` parities, and `OBSERVABLE_INCLUDE` parities. Only the supported Clifford and Pauli-noise subset is accepted. Unannotated locations have no faults.
- **Circuit JSON** lists the operations and their fault alternatives. Detectors and logical observables are parity lists of zero-based measurement-record indices. The declared parities must be deterministic in the noiseless circuit.
- **Code memory** accepts binary CSS stabilizer matrices `Hx` and `Hz`, a memory basis, and a round count. Choose **Gate-level** for the built-in serial extraction circuit. To measure a particular extraction schedule, supply that annotated circuit directly.
- **Fault model** accepts an existing sparse JSON model of detector and logical flips, with group IDs for mutually exclusive alternatives.

## Input errors

To model a Pauli error already present at the circuit input, add one explicit fault location per data qubit after state preparation and before the first extraction round. In circuit JSON this can be an `I` operation with `"faults": ["X", "Y", "Z"]`. In Stim text, a supported `DEPOLARIZE1(p)` channel with positive `p` gives the same allowed alternatives. Each affected data qubit costs one fault. The identity in JSON marks the location without requiring a physical wait.

Set the boundary detectors to reflect the syndrome information available to the experiment. An input error that changes a first-round syndrome can be missed if that syndrome is used only as a baseline for later comparisons. The generated memory model uses a clean reference round and places the first noisy data idles after it.

See the [in-page input guide](https://guluchen.github.io/DistQLDPC/fault/#guide) and the [release notices](NOTICE.txt).
