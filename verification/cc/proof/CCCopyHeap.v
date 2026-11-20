(* Complete caller frame around the selected-to-output copy block. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCRowHeap CCV.VerifOutputCopy CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition copy_heap_extra sh a p tp rp top row fs ys zs pk buf frames s:mpred:=
 (field_at sh CCSearchSpecs.problem_type[StructField _checks](Vint(Int.repr(model_m a)))(ptr_problem p)*
 field_at sh CCSearchSpecs.problem_type[StructField _logical_rows](Vint(Int.repr(model_l a)))(ptr_problem p)*
 field_at sh CCSearchSpecs.problem_type[StructField _stabilizers](Vint(Int.repr(model_k a)))(ptr_problem p)*
 field_at sh CCSearchSpecs.problem_type[StructField _h](ptr_h p)(ptr_problem p)*
 field_at sh CCSearchSpecs.problem_type[StructField _logical](ptr_lg p)(ptr_problem p)*
 field_at sh CCSearchSpecs.problem_type[StructField _stabilizer](ptr_g p)(ptr_problem p)*
 data_at sh(tarray tuchar(model_m a*model_n a))(tbytes(model_h a))(ptr_h p)*
 data_at sh(tarray tuchar(model_l a*model_n a))(tbytes(model_lg a))(ptr_lg p)*
 data_at sh(tarray tuchar(model_k a*model_n a))(tbytes(model_g a))(ptr_g p)*
 field_at sh CCSearchSpecs.workspace_type[StructField _capacity](Vint(Int.repr(workspace_capacity p)))(ptr_workspace p)*
 field_at sh CCSearchSpecs.workspace_type[StructField _frame_capacity](Vint(Int.repr(workspace_frame_capacity p)))(ptr_workspace p)*
 field_at sh CCSearchSpecs.workspace_type[StructField _forbidden](ptr_forbidden p)(ptr_workspace p)*
 field_at sh CCSearchSpecs.workspace_type[StructField _syndrome](ptr_syndrome p)(ptr_workspace p)*
 field_at sh CCSearchSpecs.workspace_type[StructField _logical_value](ptr_logical_value p)(ptr_workspace p)*
 field_at sh CCSearchSpecs.workspace_type[StructField _packed](ptr_packed p)(ptr_workspace p)*
 field_at sh CCSearchSpecs.workspace_type[StructField _undo](ptr_undo p)(ptr_workspace p)*
 field_at sh CCSearchSpecs.workspace_type[StructField _frames](ptr_frames p)(ptr_workspace p)*
 data_at Tsh(tarray tuchar(model_n a))(tbytes fs)(ptr_forbidden p)*
 data_at Tsh(tarray tuchar(model_m a))(tbytes ys)(ptr_syndrome p)*
 data_at Tsh(tarray tuchar(model_l a))(tbytes zs)(ptr_logical_value p)*
 data_at Tsh(tarray tuchar(model_n a))(tbytes pk)(ptr_packed p)*
 data_at Tsh(tarray tuint(model_n a))buf(ptr_undo p)*
 data_at Tsh(tarray CCSearchSpecs.frame_type(model_n a))frames(ptr_frames p)*
 stats_repr(ptr_stats p)s*data_at Tsh tuint(Vint(Int.repr top))tp*
 data_at Tsh tuint(Vint(Int.repr row))rp)%logic.
Lemma row_heap_copy_split sh a p tp rp top row xs fs ys zs pk buf frames out s:
 row_heap sh a p tp rp top row xs fs ys zs pk buf frames out s=
 (copy_memory sh(ptr_problem p)(ptr_workspace p)(ptr_selected p)(ptr_out p)(model_n a)xs out*
 copy_heap_extra sh a p tp rp top row fs ys zs pk buf frames s)%logic.
Proof.
 unfold row_heap,search_core_heap,copy_memory,copy_heap_extra,problem_repr,workspace_fields.
 apply pred_ext;cancel.
Qed.
Print Assumptions row_heap_copy_split.
