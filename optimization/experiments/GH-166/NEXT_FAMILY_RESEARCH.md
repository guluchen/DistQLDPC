# Next separate family: pair-partition CPM CSS

Primary source inspected: Okada-Kasai arXiv:2607.14091v4, Sections II/VI,
Table I. Code parameters come from complete all-one J-by-L protographs and
CPM row a incident to column a-s mod P. Paired mixed differences cancel
in GF(2). Reconstruct binary matrices from published exponent facts with
original code; do not copy any external constructor or verifier.

Authoritative catalogue opened:
https://kasai.ict.eng.isct.ac.jp/pair_partition_cpm_css_codes_20260714.html
It explicitly separates independent exact certificates from contributor-reported
claims, and includes subsequent GPM/APM variants not all in v4. Preserve that
provenance distinction. The parameter triple alone is not an instance identity:
both [[472,122,14]] and [[472,122,16]] exist, with different exponents/girth.
Do not add both same-(n,k) variants casually; choose a representative and
perform row-space/permutation-equivalence review for any shared parameters.

Two published mathematical parameter examples were read (no implementation):
CPM_CSS_V1, P=59,L=8,Jx=Jz=3:
https://kasai.ict.eng.isct.ac.jp/pair_partition_cpm_css_codes_data/cpm/qc_472_122_16_g8.cpm
Small reported anchor P=13,L=8,Jx=Jz=3, [[104,30,8]]:
https://kasai.ict.eng.isct.ac.jp/pair_partition_cpm_css_codes_data/contributed_codes/jong_yeon_lee/codes/PPS104_n104_k30_d8.cpm
Full exponent arrays and published SHA256 identities must be resolved before
implementation. Candidate ladder should include a small anchor, one high-girth
case and sizes up to about 1800-2230, without duplicate-equivalent variants.

Software repository metadata (not code) inspected:
https://github.com/kasaikenta/pair-partition-cpm-css-codes
Reported repository license MIT, default branch main. This is not a blanket
license claim for the separately maintained authoritative website. Original
binary reconstruction from published construction/parameter facts is preferred;
record source and attribution carefully, include required notices for any
material actually reused. The paper is CC BY 4.0. Do not redistribute downloaded
matrix/implementation files under an assumed license or use external solver
certificates as our own verification.

Before starting: recheck current branches/issues, open a separate Codex issue
with three proposals, choose the exact source instances, independently verify
paired-difference certificates and block shifts, ranks/logicals/duplicates,
regenerate files, then bounded Linux DistQLDPC smoke/witness validation. Keep
all claims distinct; a contributor-reported exact value can be cross-checked
internally but cannot be described as previously independently certified.
