(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected PackedDetector VerifPackedDetector
 PreparedSeedDispatch PreparedDFSTerminal PreparedDeadline.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Inductive poll_site:=Off | Between (mask:int64) | Due (mask:int64) (cb ctx:val).
Definition site_matches bits nodes site:=match site with
 | Off => Int.and bits (Int.repr 2)=Int.zero
 | Between mask => Int.and bits (Int.repr 2)<>Int.zero /\ Int64.and nodes mask<>Int64.zero
 | Due mask cb ctx => Int.and bits (Int.repr 2)<>Int.zero /\ Int64.and nodes mask=Int64.zero /\ is_pointer_or_null ctx end.
Definition poll_frame s site before after (answer:option bool):mpred:=match site with
 | Off => emp
 | Between mask => field_at Tsh level_type [StructField _poll_mask] (Vlong mask) s
 | Due mask cb ctx =>
  (field_at Tsh level_type [StructField _poll_mask] (Vlong mask) s * polling s cb ctx before after *
  (match answer with None=>before ctx|Some x=>after x ctx end))%logic end.
Definition observed site (answer:option bool):Prop:=match site,answer with
 | Due _ _ _,Some _ =>True | Off,None |Between _,None =>True |_,_=>False end.
Definition abort_answer (event:option bool):=match event with Some true=>true|_=>false end.
Definition terminal_code event odd words:=if abort_answer event then Int.repr 2
 else if leaf_accept odd words then Int.one else Int.zero.
Definition terminal_witness event odd words w saved:=if abort_answer event then saved
 else if leaf_accept odd words then Int.repr w else saved.

Definition timed_terminal before after:ident*funspec:=DECLARE _dfs
 WITH s:val,policy:val,b:val,par:val,w:Z,odd:Z,words:list int64,nodes:int64,budget:int64,saved:int,bits:int,site:poll_site
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint,tuint]
 PROP(site_matches bits (Int64.add nodes Int64.one) site;is_pointer_or_null policy;1<=w<=Int.max_signed;
   0<=odd<=Int.max_signed;Zlength words<=Int.max_signed)
 PARAMS(s;policy;Vint (Int.repr w);Vint bits)
 SEP(terminal_fields s b par w odd words nodes budget (Vint saved);poll_frame s site before after None)
 POST [tint] EX event:option bool,PROP(observed site event) RETURN(Vint (terminal_code event odd words))
 SEP(terminal_fields s b par w odd words (Int64.add nodes Int64.one) (Int64.add budget Int64.one)
     (Vint (terminal_witness event odd words w saved));poll_frame s site before after event).
Definition TimedLeafG before after:funspecs:=ltac:(let fs:=constr:([detected_spec;timed_terminal before after]) in with_library prog fs).

Ltac finish_terminal event s par odd words :=
 forward;apply semax_if_seq;forward_if;[|congruence];
 forward;apply semax_if_seq;forward_if;
 [forward;apply semax_if_seq;forward_if;[|discriminate];forward;Exists event;
  unfold terminal_fields,terminal_code,terminal_witness,leaf_accept;cbn [observed abort_answer poll_frame];
  rewrite (proj2 (Z.eqb_neq odd 0) ltac:(rep_lia));entailer!
 |match goal with H:Int.repr odd=Int.zero |- _=>apply (f_equal Int.unsigned) in H;
  rewrite Int.unsigned_repr in H by rep_lia;change (odd=0) in H;subst odd end;
  forward_call (s,par,words,Tsh);
  rewrite detected_return_bits;destruct (packed_detects words) eqn:E;
  [forward;apply semax_if_seq;forward_if;[solve [contradiction|congruence|discriminate]|];forward;forward
  |forward;apply semax_if_seq;forward_if;[|discriminate];forward];Exists event;
  unfold terminal_fields,terminal_code,terminal_witness,leaf_accept;cbn [observed abort_answer poll_frame];rewrite ?E;try unfold polling;entailer!].

Theorem body_terminal_all_poll_sites before after:
 semax_body prepared_vars (TimedLeafG before after) f_dfs (timed_terminal before after).
Proof.
 start_function;unfold terminal_fields;Intros;do 8 (forward;try solve [rewrite ?Z.sub_diag;entailer!]);reassoc_seq;rewrite ?Z.sub_diag.
 destruct site as [|mask|mask cb ctx];cbn [poll_frame site_matches] in *;Intros.
 - apply semax_if_seq;forward_if;[congruence|forward];apply semax_if_seq;forward_if;[solve [contradiction|discriminate]|forward].
   apply semax_if_seq;forward_if;[contradiction|];finish_terminal (@None bool) s par odd words.
 - match goal with H:Int.and bits _<>Int.zero /\ _ |- _=>destruct H as [on between] end.
   apply semax_if_seq;forward_if;[|congruence];do 3 forward;change (Int64.repr (Int.signed (Int.repr 1))) with Int64.one in *.
   apply semax_if_seq;forward_if.
   { destruct (Int64.eq (Int64.and (Int64.add nodes Int64.one) mask) Int64.zero) eqn:E;
     [apply Int64.same_if_eq in E;congruence|cbn in *;congruence]. }
   forward;apply semax_if_seq;forward_if;[contradiction|];finish_terminal (@None bool) s par odd words.
 - match goal with H:Int.and bits _<>Int.zero /\ _ /\ _ |- _=>destruct H as [on [due context]] end.
   unfold polling;Intros;apply semax_if_seq;forward_if;[|congruence];do 3 forward.
   change (Int64.repr (Int.signed (Int.repr 1))) with Int64.one in *;rewrite due.
   apply semax_if_seq;forward_if;[|discriminate];do 2 forward;forward_call ctx;Intros expired;destruct expired;forward.
   + apply semax_if_seq;forward_if;[|discriminate];forward;Exists (Some true);unfold terminal_fields,poll_frame,polling;entailer!.
   + apply semax_if_seq;forward_if;[contradiction|];finish_terminal (Some false) s par odd words.
     all:unfold polling;cancel.
Qed.
