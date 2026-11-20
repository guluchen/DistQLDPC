(* Complete search ownership permitting an uninitialized top scratch value.
   Used before the first root writes top; never assumes an unread value is zero. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchHeap CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition search_heap_raw_top sh a p tp rp top xs fs ys zs pk buf(frames:list frame_value)out s:mpred:=
 (problem_repr sh a p*workspace_fields sh p*
  data_at Tsh(tarray tuchar(model_n a))(tbytes xs)(ptr_selected p)*
  data_at Tsh(tarray tuchar(model_n a))(tbytes fs)(ptr_forbidden p)*
  data_at Tsh(tarray tuchar(model_m a))(tbytes ys)(ptr_syndrome p)*
  data_at Tsh(tarray tuchar(model_l a))(tbytes zs)(ptr_logical_value p)*
  data_at Tsh(tarray tuchar(model_n a))(tbytes pk)(ptr_packed p)*
  data_at Tsh(tarray tuint(model_n a))buf(ptr_undo p)*
  data_at Tsh(tarray CCSearchSpecs.frame_type(model_n a))frames(ptr_frames p)*
  data_at Tsh(tarray tuchar(model_n a))(tbytes out)(ptr_out p)*
  stats_repr(ptr_stats p)s*data_at Tsh tuint(top)tp*
  data_at_ Tsh tuint rp)%logic.

Lemma search_heap_raw_top_initialized sh a p tp rp top xs fs ys zs pk buf frames out s:
 search_heap_raw_top sh a p tp rp(Vint(Int.repr top))xs fs ys zs pk buf frames out s=
 search_heap sh a p tp rp top xs fs ys zs pk buf frames out s.
Proof. reflexivity. Qed.
