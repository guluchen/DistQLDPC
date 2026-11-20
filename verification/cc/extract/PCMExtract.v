(* Standalone preparation front end. C inputs and outputs use 32-bit
   extents; the wire adapter requires a 64-bit OCaml runtime. *)
From Coq Require Import Extraction ExtrOcamlBasic ExtrOcamlNatInt ExtrOcamlZInt.
Require Import CCV.CCPCMInput CCV.CCPCMAnswer.
Extraction Language OCaml.
Extraction "pcm_generated.ml" prepare_pcm_half finish_pcm.
