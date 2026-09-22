# Agent Policy for DistQLDPC

## Objective

Minimize PI attention while preserving the scientific correctness of DistQLDPC's CSS minimum-distance computation and MaxSAT integration.

## Source of truth

- Repository code, build files, and validation scripts.
- `README.md` for supported inputs, outputs, and user-facing behavior.
- `MODIFICATIONS.md` and `NOTICE` for the boundary between DistQLDPC code and the embedded MaxCDCL engine.
- GitHub issues and pull requests for task-specific requirements.

## Autonomous work

Agents should independently handle routine engineering work, including:

- build problems and dependencies;
- compiler warnings or errors caused by their changes;
- ordinary implementation bugs and refactoring;
- CI failures and test infrastructure;
- documentation and formatting.

Every substantive change must include validation appropriate to its risk. Prefer fast, deterministic checks for pull requests; do not run the full 18/22-instance benchmark suite as normal CI.

For changes that can affect solver behavior or performance, require the `QDistSAT cross-repo benchmark` PR check. Treat semantic-result mismatches as scientific escalations; treat timing changes on shared CI as diagnostic signals only unless reproduced in a controlled benchmark environment.

When modifying the embedded MaxCDCL engine under `src/solver/`, preserve upstream notices and update `MODIFICATIONS.md` and `NOTICE` when attribution or the documented patch set changes.

## Scientific boundaries

Do not silently change:

- the definition of quantum-code distance or Pauli weight;
- CSS, stabilizer, or logical-operator semantics;
- MaxSAT encoding semantics;
- cardinality-constraint semantics;
- solver correctness assumptions;
- benchmark ground truth or expected research results;
- interpretation of solver bounds or results;
- benchmark methodology or scientific claims.

If work appears to require one of these changes, stop and escalate before implementing it.

## Escalate only when

- the scientific specification is ambiguous;
- reasonable alternatives could change a scientific conclusion;
- correctness cannot be established after reasonable investigation;
- an unexpected result may be scientifically meaningful;
- a destructive, security-sensitive, irreversible, or unusually expensive action is required.

Do not escalate routine engineering decisions unless they reveal one of the conditions above.

## Routine pull requests

Routine engineering pull requests that satisfy their stated validation criteria may be merged autonomously. Do not require the PI to click merge when no scientific escalation is needed.

## Completion report

- What changed
- Validation performed
- Results, if applicable
- Unresolved issues
- Scientific semantics changed: yes/no
- PI action required: yes/no
