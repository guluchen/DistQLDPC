# H010 / GH-16 Tier0 result

Tier0 PASS. Performance UNTESTED; disposition NOT ADOPTED. No Tier1/2/3 result.
Production candidate467433133851f25a1ab76b662ca93250acf46d03,
baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a,
QDistSAT7c4774fffc49856f48a22ae5f9063d00b2661aaa.
Draft [PR19](https://github.com/guluchen/DistQLDPC/pull/19).

Local CSS18 correct results, identical original WCNF dumps, three smoke passes,
eight actual production cross-repo pilot solves and six valid timeout outputs
are retained under raw/windows-* and covered by raw-sha256.json. Cleanup restores
affinity/priority/sleep requirements. Profiles show89 search and375867 propagation
family calls; the latter substring includes propagateForLK. Final production
build excludes instrumentation and training hook, nm has no gcov symbols.

Hosted ordinary [CI37795915802](https://github.com/guluchen/DistQLDPC/actions/runs/37795915802)
and required [cross-repo37795915838](https://github.com/guluchen/DistQLDPC/actions/runs/37795915838)
both SUCCESS. Cross-repo builds actual PGO-use after the same fixed training;
all four case/mode comparisons return0 and retain exact distance/objective/LB/UB
4/10, no timeout. The decoded job records synthetic merge8c29836 of467433 onto
24572 and pinned QDistSAT7c477. Shared CI timing has no performance evidentiary role.

Complete downloaded artifact11558338471 is durable in
[raw/hosted-4674331](raw/hosted-4674331), ZIP SHA256
cf722192a8ba30f6494852fe426cf3ecc9cb349f0237e6b8061c5dda490c2837,
matching GitHub metadata. Complete ZIP retains training objects; decoded report
omits .o duplicates. Member hash manifest, profiles/coverage/buildlogs/symbols,
scientific report, metadata and job log are retained. Four gcda hashes match.

Independent reviewer verified307 preexisting raw entries, actual local binaries,
hosted science/profiles/hook exclusion and resource restoration. Its provenance
query is resolved by [source reconciliation](raw/hosted-4674331/source-reconciliation.json):
executed Makefile/core byte hashes exactly match prior commitad06d1a blobs;
their content is identical to467433 after CRLF normalization. Unchanged engine
files match tested current checkout bytes and normalized committed content.
Normalization affected no solver/application token or compilation flag.
No assertion of byte-identical rebuilt executable across paths/line endings.

Next: serial same-CPU Tier1 only after coordinator assigns a host. Preserve
profiles and binary identities before/after; no retraining against evaluation.
