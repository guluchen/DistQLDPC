# GH21 O2-only experiment

Selected proposal and paper-derived unselected alternative: [PROPOSAL](PROPOSAL.md), [BibTeX](references.bib). Issue: https://github.com/guluchen/DistQLDPC/issues/21 . Owner independent-brain-20261008-round2, exclusive branch experiment/gh21-o2; baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a. Preregistration commit5f6358d preceded implementation.

Production diff: Makefile CXXFLAGS -O3 to -O2, one token. All src, other flags, libraries, attribution unchanged. MODIFICATIONS/NOTICE need no solver-patch entry because no embedded source patch is made. No combined PGO/LTO/native/scratch/watch-copy change. Hosted tests exercise default Makefile flags; shared CI timings are informational. Local host assignment remains NONE; no build or solver workload executed.

Reproduction in TWO fresh source checkouts on the same assigned host (baseline24572 vs this candidate), from each directory:

```sh
make -j1
bash scripts/smoke_test.sh
g++ --version
g++ -Q -O3 --help=optimizers > o3-optimizers.txt
g++ -Q -O2 --help=optimizers > o2-optimizers.txt
size bin/distqldpc bin/maxcdcl
```

Do not override CXXFLAGS. Record exact compiler/environment/default build logs; clean source directories prevent mixed objects. Set CXX consistently only if the existing make built-in selection differs on the host; retain every other flag. Source semantic hashes normalize CRLF only for Git working-tree checkout differences, with original raw hashes also recorded.

Tier0 package preparation pending: tiny independent CSS oracle/WCNF/smoke/timeout pairs and standalone tiny MaxSAT oracle, supervised Windows Job/capacity/cleanup wrapper. Hosted CI and QDistSAT correctness pending; no Tier1/2/3 evidence, medians or speed conclusion.

Tier1 commands must use fixed explicit no-card/card-mto for BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6, three serial pairs AB/BA/AB each and180s parent195s watchdog. See preregistration for gates and resource policy. No timing runner is authorized by this README.
