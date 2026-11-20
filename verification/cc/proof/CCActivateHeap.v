(* Complete heap frame around the exact row/next/phase stores. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCRowHeap CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition activate_heap_extra sh a p tp top xs fs ys zs pk buf out s:mpred:=
 (problem_repr sh a p*workspace_fields sh p*
 data_at Tsh(tarray tuchar(model_n a))(tbytes xs)(ptr_selected p)*
 data_at Tsh(tarray tuchar(model_n a))(tbytes fs)(ptr_forbidden p)*
 data_at Tsh(tarray tuchar(model_m a))(tbytes ys)(ptr_syndrome p)*
 data_at Tsh(tarray tuchar(model_l a))(tbytes zs)(ptr_logical_value p)*
 data_at Tsh(tarray tuchar(model_n a))(tbytes pk)(ptr_packed p)*
 data_at Tsh(tarray tuint(model_n a))buf(ptr_undo p)*
 data_at Tsh(tarray tuchar(model_n a))(tbytes out)(ptr_out p)*
 stats_repr(ptr_stats p)s*data_at Tsh tuint(Vint(Int.repr top))tp)%logic.
Lemma row_heap_activate_split sh a p tp rp top row xs fs ys zs pk buf frames out s:
 row_heap sh a p tp rp top row xs fs ys zs pk buf frames out s=
 (data_at Tsh(tarray CCSearchSpecs.frame_type(model_n a))frames(ptr_frames p)*
 data_at Tsh tuint(Vint(Int.repr row))rp*
 activate_heap_extra sh a p tp top xs fs ys zs pk buf out s)%logic.
Proof.
 unfold row_heap,search_core_heap,activate_heap_extra;apply pred_ext;cancel.
Qed.
Print Assumptions row_heap_activate_split.
