# Hosted correctness evidence — local Tier0 pending

Production58fbae546e74c158c21070cd10106e94d6bd2b98;
support7a257083d7f9988612954d93c9ed4c81f1e4fc67.
Ordinary CI37811855749 and QDistSAT cross-repo37811855712 succeeded.
Cross-repo job113430454106 checked out actual merge
7e139c60b0f32733bc3f693a77ca3a8837072f08 into baseline24572d6;
QDistSAT checkout7c4774fffc49856f48a22ae5f9063d00b2661aaa.

Artifact11565053649 original ZIP SHA256
1d8cb98d7dde83f672302214850b1453341c7c1de39be606ca30753b42a5323c
matches GitHub metadata. Raw ZIP/result/summary/decoded job log/metadata/audit
are retained under raw/hosted-7a25708; raw-sha256.json covers public bytes.
Exact executed Git source bytes src/Makefile/scripts/.github match production58fbae5;
six critical compiled-source blob hashes are retained. This does not infer
binary identity or bit-identical rebuilds from source/newline normalization.

Four comparisons/eight solves: LP136 distance4, BB108 distance10, OFF and MTO.
All reported final distance/objective/lower/upper bounds exact, rc0/no timeout,
same_semantics true. Artifact contains final reports only, no complete solver
stdout/binaries: every interim bound and local fixture/crash/timeout coverage
must still be checked by the assigned guarded driver. Overall Tier0 incomplete.

Shared CI timing is informational; no performance measurement, medians, filter
promotion or adoption claimed. GH27 remains PROPOSED / UNTESTED locally.
No Windows/remote workload was launched to obtain or audit these artifacts.
