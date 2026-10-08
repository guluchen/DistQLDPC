# Disabled Tier1 namespace repair

Independent integrator review of prerecord91361a7 found two inherited GH-40
functional paths: the committed-driver Git show path and experiment-record path.
Both now point to GH-44. Provenance text now explicitly identifies the actual
executed GH40 standard48 source driver and its original SHA rather than implying
direct derivation from GH27. This is a prelaunch engineering copy mistake; no
Tier1 command, solve or timing ran. No production/input/binary/parser/order/limit/
threshold or scientific rule changed. Full source AST and old namespace-literal
checks rerun; historical GH40 provenance is intentionally retained as provenance.
