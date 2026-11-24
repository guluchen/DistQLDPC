(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import VerifDetected VerifChildVisit EnabledCall PreparedChildCall PreparedTerminalTrace
 PreparedPairDispatch PreparedOpenPair PreparedCallerLocals.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition siblings_live_at_pair c q children n i bits :=
 [temp _policy (nested_policy (nested c));temp _options (Vint bits);
  temp _a (Vint (Int.repr q));temp _update_overlap (Vint Int.zero);
  temp _children children;temp _count (Vint (Int.repr n));
  temp _i (Vint (Int.repr i));temp _excluded (Vint (Int.repr i))].

(* Before and after the fast leaf the overlap flag is false. The child
   selected by the sibling loop is written into the actual trace before
   the dispatch. The dispatch may write one more cell or report a shorter
   closure. Its result, path and counters survive the enclosing bracket. *)
Theorem run_two_move_bracket {A:Type} {Espec:OracleKind} c s cp depth q
 children n i bits path (rest:mpred) (at_pair:list int->mpred)
 (facts:A->Prop) (code:A->Z) (returned:A->mpred):
 1<=depth<=Int.max_signed-2 -> depth+1<Zlength path ->
 (forall cells, at_pair cells=(terminal_trace s cp cells * rest)%logic) ->
 let chosen:=upd_Znth depth path (Int.repr q) in
 semax pair_delta (PROPx [] (LOCALx (pair_loc s depth 0) (SEPx [at_pair chosen])))
 prepared_pair (normal_ret_assert (EX a:A,PROPx [facts a]
     (LOCALx (pair_loc s depth (code a)) (SEPx [returned a])))) ->
 let locals:=descent_loc c s depth q children n i bits false in
 semax pair_delta (PROPx [] (LOCALx (temp _result (Vint Int.zero)::locals) (SEPx [at_pair path])))
 child_bracket (normal_ret_assert (EX a:A,PROPx [facts a]
   (LOCALx (temp _result (Vint (Int.repr (code a)))::locals) (SEPx [returned a])))).
Proof.
 intros depth_ok room layout chosen dispatch locals.
 pose (saved:=siblings_live_at_pair c q children n i bits).
 assert (stable:closed_wrt_modvars prepared_pair (LOCALx saved (SEPx []))).
 { unfold prepared_pair,saved,siblings_live_at_pair;auto 100 with closed. }
 pose proof (@keep_caller_locals_for_answer A Espec VerifDetected.CompSpecs pair_delta prepared_pair
   [] (pair_loc s depth 0) [at_pair chosen] saved [] (fun a=>[facts a])
   (fun a=>pair_loc s depth (code a)) (fun a=>[returned a]) stable dispatch) as keep.
 unfold locals,descent_loc,child_bracket;rewrite layout;unfold terminal_trace;abbreviate_semax;Intros.
 apply semax_if_seq;forward_if;try solve [contradiction|congruence|discriminate].
 do 2 forward;rewrite upd_Znth_map;reassoc_seq;unfold_abbrev'.
 match goal with |- semax _ _ ?body _ =>
   let suffix:=lazymatch body with Ssequence _ (Ssequence _ ?rest)=>rest end in
   apply (semax_unfold_seq (Ssequence prepared_pair suffix) body eq_refl) end.
 eapply semax_seq'.
 { eapply semax_pre;[|exact keep];unfold pair_loc,saved,siblings_live_at_pair,chosen;
   rewrite layout;unfold terminal_trace;rewrite upd_Znth_Zlength by lia;cbn [app];entailer!;cancel. }
 Intros a;unfold pair_loc,saved,siblings_live_at_pair;cbn [app];Intros.
 forward_if;try solve [contradiction|congruence|discriminate];forward;Exists a;entailer!.
Qed.
