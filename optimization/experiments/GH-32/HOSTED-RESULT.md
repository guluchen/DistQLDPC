# GH32 hosted correctness

Actual support99f53a62acf4e08b5febd96479f460091825be02 required ordinary CI and QDistSAT cross-repo checks **PASS**. Productioncandidate6b99e13 unchanged. Local assigned Tier0 NOT RUN, performance UNTESTED; hosted timing informational only.

CI37813272248/job113435292693 builds all4engine objects and bothexecutables with actual defaultO3+mtune native flags, original smokePASS. Cross-repo37813272107/job113435290541 logs6defaultO3 baseline commands then6defaultO3+mtune candidate commands; originalbaseline24572d6 and QDistSAT7c4774fffc49856f48a22ae5f9063d00b2661aaa pinned. Synthetic mergef6fef43db78f69b0245fdf32bbe54204afb43b65 fetched/read-only and exacttreec4d67585cbb619a697067362df458de2d7514b86 equals support99f53a6; no checkout/source alteration.

Four pairs/eight solves LP_136_32_4 and BB_108_8_10, explicit OFF/MTO. All exit0/no timeout; expected d/objective/LB/UB4/10 identical. Independent artifact audit PASS. Artifact11565922012 exactZIP SHA2561cad5b0ae38b70526f9cae42d1fd44124a94c7bc7e646b42ac83aa1d9e052f32. Public raw artifact/results/full joblogs/identity archived in raw/hosted-99f53a6 and PUBLIC-SHA256.json; no expiry-only link dependency. `python optimization/experiments/GH-32/audit_hosted.py optimization/experiments/GH-32/raw/hosted-99f53a6` checks expected scientific results/artifact bytes without executing solver.

Native tuning was selected on the CI host; this is not evidence of Windows CPU tuning expansion, ISA validation or performance. Those remain independently assigned local Tier0 obligations. Shared CI has neither controlled timing nor a full all-interim-bound raw stream; do not label hosted artifact as the local all-bounds test. No local build/test/diagnostic/timing or performance acceptance inferred.
