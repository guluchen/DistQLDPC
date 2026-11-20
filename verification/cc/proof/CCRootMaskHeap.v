(* Spatial split for the actual root exclusion loop, including raw scratch. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchHeap CCV.CCRawTopHeap CCV.CCRootArray
 CCV.VerifRootMask CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition workspace_without_forbidden sh p :=
 (
 field_at sh workspace_type[StructField _capacity](Vint(Int.repr(workspace_capacity p)))(ptr_workspace p)*
 field_at sh workspace_type[StructField _frame_capacity](Vint(Int.repr(workspace_frame_capacity p)))(ptr_workspace p)*
 field_at sh workspace_type[StructField _selected](ptr_selected p)(ptr_workspace p)*
 field_at sh workspace_type[StructField _syndrome](ptr_syndrome p)(ptr_workspace p)*
 field_at sh workspace_type[StructField _logical_value](ptr_logical_value p)(ptr_workspace p)*
 field_at sh workspace_type[StructField _packed](ptr_packed p)(ptr_workspace p)*
 field_at sh workspace_type[StructField _undo](ptr_undo p)(ptr_workspace p)*
 field_at sh workspace_type[StructField _frames](ptr_frames p)(ptr_workspace p))%logic.
Definition root_mask_rest sh a p tp rp top xs ys zs pk buf(frames:list frame_value)out s:mpred:=
 (problem_repr sh a p*workspace_without_forbidden sh p*
  data_at Tsh(tarray tuchar(model_n a))(tbytes xs)(ptr_selected p)*
   data_at Tsh(tarray tuchar(model_m a))(tbytes ys)(ptr_syndrome p)*
  data_at Tsh(tarray tuchar(model_l a))(tbytes zs)(ptr_logical_value p)*
  data_at Tsh(tarray tuchar(model_n a))(tbytes pk)(ptr_packed p)*
  data_at Tsh(tarray tuint(model_n a))buf(ptr_undo p)*
  data_at Tsh(tarray CCSearchSpecs.frame_type(model_n a))frames(ptr_frames p)*
  data_at Tsh(tarray tuchar(model_n a))(tbytes out)(ptr_out p)*
  stats_repr(ptr_stats p)s*data_at Tsh tuint(top)tp*
  data_at_ Tsh tuint rp)%logic.


Lemma raw_top_heap_mask_split sh a p tp rp top xs ys zs pk buf frames out s seed:
 search_heap_raw_top sh a p tp rp top xs(root_mask(model_n a)seed)ys zs pk buf frames out s=
 (mask_memory sh(ptr_workspace p)(ptr_forbidden p)(model_n a)seed*
 root_mask_rest sh a p tp rp top xs ys zs pk buf frames out s)%logic.
Proof.
 unfold search_heap_raw_top,mask_memory,root_mask_rest,workspace_fields,workspace_without_forbidden.
 apply pred_ext;cancel.
Qed.
