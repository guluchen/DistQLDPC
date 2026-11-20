(* Array focus/reassembly for the actual C frame structure. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core.
Import ListNotations.
Definition frame_type:=Tstruct _ccv_frame noattr.
Section ArrayProof.
Context{CS:compspecs}.
Open Scope Z_scope.
Definition frame_remainder sh n i(frames:list(reptype frame_type))p:mpred:=
 (data_at sh(tarray frame_type i)(sublist 0 i frames)p*
  data_at sh(tarray frame_type(n-(i+1)))(sublist(i+1)n frames)
   (field_address0(tarray frame_type n)[ArraySubsc(i+1)]p))%logic.
Lemma frame_array_focus sh n i(frames:list(reptype frame_type))p:
 Zlength frames=n ->0<=i<n ->
 data_at sh(tarray frame_type n)frames p=
 (data_at sh frame_type(Znth i frames)
   (field_address0(tarray frame_type n)[ArraySubsc i]p)*
  frame_remainder sh n i frames p)%logic.
Proof.
 intros Len Index.
 unfold tarray.
 assert(Full:frames=sublist 0 n frames)by(rewrite <-Len;autorewrite with sublist;reflexivity).
 rewrite(@split3_data_at_Tarray CS sh frame_type n i(i+1)frames frames
   (sublist 0 i frames)(sublist i(i+1)frames)(sublist(i+1)n frames)p
   ltac:(split;reflexivity) ltac:(lia) ltac:(lia) Full eq_refl eq_refl eq_refl).
 replace(i+1-i)with 1 by lia.
 rewrite(sublist_one i(i+1)frames)by lia.
 rewrite(data_at_singleton_array_eq sh frame_type(Znth i frames)[Znth i frames])by reflexivity.
 unfold frame_remainder;apply pred_ext;cancel.
Qed.
Print Assumptions frame_array_focus.
Lemma frame_remainder_update sh n i(frames:list(reptype frame_type))p v:
 Zlength frames=n ->0<=i<n ->
 frame_remainder sh n i(upd_Znth i frames v)p=frame_remainder sh n i frames p.
Proof.
 intros Len Index;unfold frame_remainder.
 rewrite sublist_upd_Znth_l by lia.
 rewrite sublist_upd_Znth_r by lia;reflexivity.
Qed.
Lemma frame_array_reassemble sh n i(frames:list(reptype frame_type))p v:
 Zlength frames=n ->0<=i<n ->
 data_at sh(tarray frame_type n)(upd_Znth i frames v)p=
 (data_at sh frame_type v(field_address0(tarray frame_type n)[ArraySubsc i]p)*
  frame_remainder sh n i frames p)%logic.
Proof.
 intros Len Index.
 rewrite(frame_array_focus sh n i(upd_Znth i frames v)p)
   by(try rewrite upd_Znth_Zlength by lia;lia).
 rewrite upd_Znth_same by lia;rewrite frame_remainder_update by assumption;reflexivity.
Qed.
Print Assumptions frame_array_reassemble.

End ArrayProof.
