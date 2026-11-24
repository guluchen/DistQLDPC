(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch CSSLevelDistance DetectorRank DetectorMatrix VerifDetected
 VerifClosesBody NativeFlipPayload PreparedSeedDispatch PreparedDFSTerminal PreparedTerminalPoll
 PreparedMatrixResponse PreparedMatrixPath PreparedWitnessWeight.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section CSS.
Variables m r k n:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n)) (rowkey:'I_m->int64).
Variables (path:seq 'I_n) (payload:packed_support).
Let selected_vector:=vector_on (0:'cV['F_2]_n) path.
Let selected_weight:=Z.of_nat (size path).
Let words:=parities (words_at payload).
Let odd:=odd_count payload.
Let accepted:=((H*m selected_vector==0) && ~~(selected_vector^T<=S)%MS)%bool.
Variables (before:Values.val->mpred) (after:bool->Values.val->mpred).

Definition result_word event:=if abort_answer event then Int.repr 2 else if accepted then Int.one else Int.zero.
Definition saved_witness event prior:=if abort_answer event then prior else if accepted then Int.repr selected_weight else prior.
Definition css_terminal:ident*funspec:= DECLARE _dfs
 WITH s:Values.val,policy:Values.val,b:Values.val,par:Values.val,nodes:int64,budget:int64,saved:Integers.int,bits:Integers.int,site:poll_site
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint,tuint]
 PROP(site_matches bits (Int64.add nodes Int64.one) site;is_pointer_or_null policy;(1<=selected_weight<=Int.max_signed)%coqZ;
   (0<=odd<=Int.max_signed)%coqZ;(Zlength words<=Int.max_signed)%coqZ)
 PARAMS(s;policy;Vint (Int.repr selected_weight);Vint bits)
 SEP(terminal_fields s b par selected_weight odd words nodes budget (Vint saved);poll_frame s site before after None)
 POST [tint] EX event:option bool,
 PROP(observed site event; #|support selected_vector|=size path;
  result_word event=Int.one -> (distance_index H (detectors S)<=size path)%N)
 RETURN(Vint (result_word event))
 SEP(terminal_fields s b par selected_weight odd words (Int64.add nodes Int64.one) (Int64.add budget Int64.one)
  (Vint (saved_witness event saved));poll_frame s site before after event).

Theorem native_terminal_returns_css_value:
 H*m S^T=0 -> G*m S^T=0 -> (\rank (col_mx H G)+\rank S=n)%N ->
 uniq path -> pcm_response H G rowkey selected_vector payload ->
 semax_body prepared_vars (TimedLeafG before after) f_dfs css_terminal.
Proof.
 move=> orthH orthG shape distinct rep.
 have model:leaf_accept odd words=accepted.
 { rewrite (physical_terminal rep);unfold accepted;case closed:(H*m selected_vector==0)=> //=.
   by rewrite (validated_detector orthH orthG shape (eqP closed)). }
 have len:#|support selected_vector|=size path by apply selected_path_weight.
 have bound:accepted -> (distance_index H (detectors S)<=size path)%N.
 { move=> live;rewrite -len;apply distance_index_lower;by rewrite /logical detector_rowspan. }
 eapply semax_body_funspec_sub;[exact (body_terminal_all_poll_sites before after)| |].
 - do_funspec_sub;destruct w as [[[[[[[[s policy] b] par] nodes] budget] saved] bits] site];cbn [fst snd];normalize.
   Exists (s,policy,b,par,selected_weight,odd,words,nodes,budget,saved,bits,site) emp;apply andp_right.
   + entailer!;cancel.
   + apply prop_right;intro rho;normalize;Exists x.
     have answer:result_word x=Int.one -> (distance_index H (detectors S)<=size path)%N.
     { unfold result_word;case:(abort_answer x);first discriminate.
       case keep:accepted;last discriminate;move=>_;exact:(bound keep). }
     unfold terminal_code,terminal_witness,result_word,saved_witness in *;rewrite model;
      repeat match goal with K:context[leaf_accept odd words] |- _=>rewrite model in K end;
      entailer!;try cancel;try congruence.
 - vm_compute;repeat (apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
Qed.
End CSS.
