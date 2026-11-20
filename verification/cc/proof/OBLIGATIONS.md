# Proof obligations and coverage

| Obligation | Checked entry point |
|---|---|
| Search with all 64 masks preserves witness validity and search completeness | [VerifSearch.v](VerifSearch.v) |
| The actual linked C library implements the specifications | [CCCertifiedLibrary.v](CCCertifiedLibrary.v) |
| Legal calls terminate in the original two-unit Clight environment | [CCPublicTermination.v](CCPublicTermination.v) |
| PCM preparation computes detectors whose kernel equals the stabilizer row span | [CCPCMDetectors.v](CCPCMDetectors.v) |
| Accepted raw inputs satisfy the C data and CSS quotient requirements | [CCPCMInput.v](CCPCMInput.v) |
| Sparse preparation and reference preparation return identical models or rejections on every raw input | [CCPCMFast.v](CCPCMFast.v) |
| The linked distance entry implements the prepared-input contract | [CCPCMEntry.v](CCPCMEntry.v) |
| The reported full distance minimizes weight over mixed Pauli operators | [CCPCMAnswer.v](CCPCMAnswer.v) |

The VST entry assumes correctly owned argument objects and buffers. Parsing,
allocation, extraction and runtime integration are covered by executable tests.
The proofs apply to the C kernel and Clight target described in the
[package README](../README.md).
