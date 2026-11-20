From Coq Require Import Extraction ExtrOcamlBasic ExtrOcamlNatInt ExtrOcamlZInt ExtrOCamlInt63.
Require Import CCV.CCPCMBitRows CCV.CCPCMAnswer CCV.CCPackedAnswer CCV.CCPackedWords CCV.CCPackedHalf.
Extraction Language OCaml.
Extraction "pcm_generated.ml" bit_prepare finish_pcm packed_report.
