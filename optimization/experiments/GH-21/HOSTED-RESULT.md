# Hosted correctness evidence

Production candidate e1aa9175c511b72dbb7305f5769b1e11f41bc05f passed ordinary CI37800657699 and required QDistSAT cross-repo37800657708. Four pairs/eight solves, LP136 and BB108 both explicit modes, distance/objective/LB/UB4 and10 respectively; no timeout. All raw report fields and ZIP SHA256 independently audited by audit_hosted.py, PASS. Actual default O3 vs O2 compile commands for four objects/two executables per version checked in saved cross-job.log.

Hosted PR synthetic merge ee64f798637aa65b254aaac25268dccc4927168c differs from literal production SHA; fetched immutable merge and verified both tree hashes c71ff6802133c19a307ceede9ac2c96a2b5c131d match exactly. QDistSAT actual7c4774fffc49856f48a22ae5f9063d00b2661aaa. Artifact11560775779 SHA2563d15eca87b8990a4fc667ab485626491bdc615405d65fa3bdca52b401d569822.

Durable raw/hosted-e1aa917 contains ZIP, JSON/Markdown report, ordinary/cross job logs, identity and SHA256 manifest. Signed download URL not retained. Follow-up support/documentation commits do not change tested production source; they are not falsely described as the exact hosted tested tree. Check actual new HEAD as needed before execution.

No local build/solver/timing executed while host reserved for other runner. Hosted timing is informational only. Local Tier0 remains NOT_RUN; Tier1/2/3 NOT_RUN. Formal performance UNTESTED; no adoption or rejection inferred.
