# Hosted correctness

Candidate596510ccda48361b34158927607a58988402ff91; ordinary CI37800958166 and
required cross-repo37800958168 both SUCCESS. Actual hosted merge4101b79 matches
candidate src/Makefile/scripts/.github tree exactly. Baseline24572d6;
QDistSAT platform7c4774fffc49856f48a22ae5f9063d00b2661aaa. DistQLDPC remains
its own instrumented downstream MaxCDCL-derived implementation.

Independent report audit: eight correct solves, LP136 d/objective/LB/UB4 and
BB10810, both OFF/MTO, return0/no timeout and baseline/candidate semantics equal.
Artifact11560163762 ZIP SHA256459415faf90151c5ad9ecc6e95c5778ec0de96c7092551e0b17654127c38b180
matches GitHub digest; exact ZIP members and decoded job log retained underraw.
Artifact contains final report only, not raw solver output or all interim bounds.
Those require the local Tier0 checks; do not invent missing CI evidence.

Shared CI timing is informational, never a performance filter. Local Tier0,
diagnostic and comparative performance remain unrun/unassigned. No acceptance.
