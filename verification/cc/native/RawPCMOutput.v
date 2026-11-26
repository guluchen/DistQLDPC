(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver ClightSelect raw_pcm_ast RawPCMPrimitives.
#[local] Existing Instance RawPCMComposites.
Local Open Scope Z_scope.

Definition output_loop:statement:=ltac:(native_fragment (counts_on _i) f_run_weights).
Definition byte_ones n path:=fold_left (fun bytes q=>upd_Znth (Int.signed q) bytes (Vint Int.one))
 path (Zrepeat (Vint Int.zero) n).
Lemma byte_ones_app n xs q:byte_ones n (xs++[q])=upd_Znth (Int.signed q) (byte_ones n xs) (Vint Int.one).
Proof. unfold byte_ones;rewrite fold_left_app;reflexivity. Qed.
Lemma byte_ones_length n xs:0<=n -> Zlength (byte_ones n xs)=n.
Proof.
 intros cap;induction xs using rev_ind.
 - unfold byte_ones;simpl;rewrite Zlength_Zrepeat;lia.
 - rewrite byte_ones_app,Zlength_upd_Znth;assumption.
Qed.
Definition output_trace sh s cp path:=
 (field_at sh (Tstruct _cc_level noattr) [StructField _cur] cp s *
  data_at sh (tarray tint (Zlength path)) (map Vint path) cp)%logic.
Definition output_regs s path_out w:=[temp _s s;temp _witness path_out;temp _w (Vint (Int.repr w))].
Definition output_calls:funspecs:=ltac:(with_library prog (@nil (ident*funspec))).

(* The real write loop starts immediately after memset in run_weights.
   Preserve the source trace and materialize its prefix in the output bytes. *)
Theorem materialize_physical_output {Espec:OracleKind} s cp dest sh n w path:
 readable_share sh -> 0<=n<=Int.max_signed -> 0<=w<=Int.max_signed -> w<=Zlength path ->
 (forall i,0<=i<w -> 0<=Int.signed (Znth i path)<n) ->
 semax (func_tycontext f_run_weights raw_vars output_calls [])
 (PROPx [] (LOCALx (output_regs s dest w) (SEPx [output_trace sh s cp path;
   data_at Tsh (tarray tuchar n) (Zrepeat (Vint Int.zero) n) dest])))
 output_loop (normal_ret_assert (PROPx [] (LOCALx (output_regs s dest w)
   (SEPx [output_trace sh s cp path;data_at Tsh (tarray tuchar n) (byte_ones n (sublist 0 w path)) dest])))).
Proof.
 intros readable dimension bound fits valid;unfold output_loop,output_regs;abbreviate_semax.
 forward_for_simple_bound w
  (EX i:Z, PROP() LOCAL(temp _s s;temp _witness dest;temp _w (Vint (Int.repr w)))
   SEP(output_trace sh s cp path;data_at Tsh (tarray tuchar n) (byte_ones n (sublist 0 i path)) dest)).
 - rewrite sublist_nil;unfold byte_ones;simpl;entailer!;try cancel;try apply derives_refl;try (apply andp_left2;apply derives_refl).
 - assert (room:0<=i<Zlength path) by lia.
   specialize (valid i ltac:(lia)).
   unfold output_trace;Intros;forward;forward;try rewrite Znth_map by lia.
   forward;try solve [entailer!;rewrite ?byte_ones_length by lia;lia].
   replace (sublist 0 (i+1) path) with (sublist 0 i path++[Znth i path]) by list_solve.
   rewrite byte_ones_app;unfold output_trace;entailer!;try cancel;try apply derives_refl.
 - entailer!;try cancel;try apply derives_refl.
Qed.
