(* Standalone preparation front end. C inputs and outputs use 32-bit
   extents; the wire adapter requires a 64-bit OCaml runtime. *)
From Coq Require Import Extraction ExtrOcamlBasic ExtrOcamlNatInt ExtrOcamlZInt.
Require Import CCV.CCPCMBitRows CCV.CCPCMAnswer.
Extraction Language OCaml.
Extraction "pcm_generated.ml" bit_prepare finish_pcm.
