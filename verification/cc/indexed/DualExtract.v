From Coq Require Import Extraction ExtrOcamlBasic ExtrOcamlNatInt ExtrOcamlZInt ExtrOCamlInt63.
Require Import CCV.CCPCMBitRows CCV.CCPCMAnswer CCV.CCPackedAnswer CCV.CCPackedWords CCV.CCPackedHalf.
Require Import CCCompactPrepare CCRawDual CCBoundReplay.
Extraction Language OCaml.
Extraction "pcm_generated.ml" compact_prepare finish_pcm packed_report raw_dual_check finish_dual replay_upper replay_cap replay_report.
