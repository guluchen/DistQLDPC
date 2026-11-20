(* Full search ownership with an initialized addressable row scratch cell.
   Phase0 needs this stronger form; ordinary while heads forget the row value. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchHeap CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition search_core_heap sh a p tp top xs fs ys zs pk buf frames out s:mpred:=
 (problem_repr sh a p*workspace_fields sh p*
 data_at Tsh(tarray tuchar(model_n a))(tbytes xs)(ptr_selected p)*
 data_at Tsh(tarray tuchar(model_n a))(tbytes fs)(ptr_forbidden p)*
 data_at Tsh(tarray tuchar(model_m a))(tbytes ys)(ptr_syndrome p)*
 data_at Tsh(tarray tuchar(model_l a))(tbytes zs)(ptr_logical_value p)*
 data_at Tsh(tarray tuchar(model_n a))(tbytes pk)(ptr_packed p)*
 data_at Tsh(tarray tuint(model_n a))buf(ptr_undo p)*
 data_at Tsh(tarray CCSearchSpecs.frame_type(model_n a))frames(ptr_frames p)*
 data_at Tsh(tarray tuchar(model_n a))(tbytes out)(ptr_out p)*
 stats_repr(ptr_stats p)s*data_at Tsh tuint(Vint(Int.repr top))tp)%logic.
Definition row_heap sh a p tp rp top row xs fs ys zs pk buf frames out s:mpred:=
 (search_core_heap sh a p tp top xs fs ys zs pk buf frames out s*
 data_at Tsh tuint(Vint(Int.repr row))rp)%logic.
Lemma search_heap_row_split sh a p tp rp top xs fs ys zs pk buf frames out s:
 search_heap sh a p tp rp top xs fs ys zs pk buf frames out s=
 (search_core_heap sh a p tp top xs fs ys zs pk buf frames out s*data_at_ Tsh tuint rp)%logic.
Proof. unfold search_heap,search_core_heap;reflexivity. Qed.
Lemma row_heap_forget sh a p tp rp top row xs fs ys zs pk buf frames out s:
 row_heap sh a p tp rp top row xs fs ys zs pk buf frames out s |--
 search_heap sh a p tp rp top xs fs ys zs pk buf frames out s.
Proof.
 rewrite search_heap_row_split;unfold row_heap.
 apply sepcon_derives;[apply derives_refl|apply data_at_data_at_].
Qed.
Print Assumptions search_heap_row_split.
Print Assumptions row_heap_forget.
