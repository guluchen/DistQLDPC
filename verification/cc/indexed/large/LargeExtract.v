From Coq Require Import Extraction ExtrOcamlBasic ExtrOcamlNatInt ExtrOcamlZInt ExtrOCamlInt63.
Require Import CCV.CCPCMBitRows CCV.CCPCMAnswer CCV.CCPackedAnswer CCV.CCPackedWords CCV.CCPackedHalf.
Require Import CCCompactPrepare CCLargeWords CCLargeHalf CCLargeAnswer CCLargeRaw.
Extraction Language OCaml.
Extraction "large_generated.ml" compact_prepare finish_pcm CCLargeAnswer.packed_report CCLargeRaw.raw_packed_report CCLargeWords.singleton CCLargeWords.none.
