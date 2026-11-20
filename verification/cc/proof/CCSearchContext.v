(* Shared specification environment for the actual search blocks.
   Defining the environment does not prove the search callee or program link. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.VerifPrimitives
 CCV.VerifDot CCV.VerifWeight CCV.VerifToggle CCV.VerifStats
 CCV.VerifShape CCV.VerifValidate CCV.VerifClear CCV.VerifCoreToggle
 CCV.VerifNontrivial CCV.VerifRestore CCV.VerifForbid CCV.VerifOverlap
 CCV.VerifBounds CCV.VerifLeaf.
Import ListNotations.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition Vprog :varspecs. mk_varspecs ccv_core.prog. Defined.
Definition Gprog :funspecs :=ltac:(with_library ccv_core.prog
 [VerifPrimitives.ceil_div_spec;VerifDot.dot_spec;VerifWeight.weight_spec;
  VerifToggle.toggle_spec;VerifStats.stats_init_spec;VerifShape.shape_spec;
  VerifValidate.validate_spec;VerifClear.clear_spec;VerifCoreToggle.core_toggle_spec;
  VerifNontrivial.nontrivial_spec;VerifRestore.restore_spec;VerifForbid.forbid_spec;
  VerifOverlap.overlap_spec;VerifBounds.bounds_spec;VerifLeaf.leaf_spec;
  CCSearchSpecs.search_spec;CCSearchSpecs.decide_spec;CCSearchSpecs.distance_spec]).
Definition Delta:tycontext :=func_tycontext ccv_core.f_search Vprog Gprog [].
