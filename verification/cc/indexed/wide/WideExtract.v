From Coq Require Import Extraction ExtrOcamlBasic ExtrOcamlNatInt ExtrOcamlZInt ExtrOCamlInt63.
Require Import CCV.CCPCMBitRows CCV.CCPCMAnswer CCV.CCPackedAnswer CCV.CCPackedWords CCV.CCPackedHalf.
Require Import CCCompactPrepare CCWideWords CCWideHalf CCWideAnswer CCWideRaw.
Extraction Language OCaml.
Extraction "wide_generated.ml" compact_prepare finish_pcm CCWideAnswer.packed_report CCWideRaw.raw_packed_report CCWideWords.singleton CCWideWords.none.
