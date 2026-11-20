(* Shared physical search heap. No global search invariant or body theorem. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchMemory CCV.VerifPhaseTwo CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition frame_value:Type:=(val*(val*(val*(val*val))))%type.
Definition search_heap sh a p tp rp top xs fs ys zs pk buf(frames:list frame_value)out s:mpred:=
 (problem_repr sh a p*workspace_fields sh p*
  data_at Tsh(tarray tuchar(model_n a))(tbytes xs)(ptr_selected p)*
  data_at Tsh(tarray tuchar(model_n a))(tbytes fs)(ptr_forbidden p)*
  data_at Tsh(tarray tuchar(model_m a))(tbytes ys)(ptr_syndrome p)*
  data_at Tsh(tarray tuchar(model_l a))(tbytes zs)(ptr_logical_value p)*
  data_at Tsh(tarray tuchar(model_n a))(tbytes pk)(ptr_packed p)*
  data_at Tsh(tarray tuint(model_n a))buf(ptr_undo p)*
  data_at Tsh(tarray CCSearchSpecs.frame_type(model_n a))frames(ptr_frames p)*
  data_at Tsh(tarray tuchar(model_n a))(tbytes out)(ptr_out p)*
  stats_repr(ptr_stats p)s*data_at Tsh tuint(Vint(Int.repr top))tp*
  data_at_ Tsh tuint rp)%logic.
Definition search_phase2_extra sh a p rp pk out s:mpred:=
 (field_at sh CCSearchSpecs.problem_type[StructField _stabilizers](Vint(Int.repr(model_k a)))(ptr_problem p)*
  field_at sh CCSearchSpecs.problem_type[StructField _stabilizer](ptr_g p)(ptr_problem p)*
  data_at sh(tarray tuchar(model_k a*model_n a))(tbytes(model_g a))(ptr_g p)*
  field_at sh CCSearchSpecs.workspace_type[StructField _capacity](Vint(Int.repr(workspace_capacity p)))(ptr_workspace p)*
  field_at sh CCSearchSpecs.workspace_type[StructField _frame_capacity](Vint(Int.repr(workspace_frame_capacity p)))(ptr_workspace p)*
  field_at sh CCSearchSpecs.workspace_type[StructField _packed](ptr_packed p)(ptr_workspace p)*
  data_at Tsh(tarray tuchar(model_n a))(tbytes pk)(ptr_packed p)*
  data_at Tsh(tarray tuchar(model_n a))(tbytes out)(ptr_out p)*
  stats_repr(ptr_stats p)s*data_at_ Tsh tuint rp)%logic.
Lemma search_heap_phase2 sh a p tp rp top xs fs ys zs pk buf frames out s:
 search_heap sh a p tp rp top xs fs ys zs pk buf frames out s=
 (phase2_memory sh p tp(model_n a)(model_m a)(model_l a)top
  (model_h a)(model_lg a)xs fs ys zs frames buf*
  search_phase2_extra sh a p rp pk out s)%logic.
Proof.
 unfold search_heap,phase2_memory,phase1_memory,search_phase2_extra,
   problem_repr,workspace_fields.
 apply pred_ext;cancel.
Qed.
Print Assumptions search_heap_phase2.
