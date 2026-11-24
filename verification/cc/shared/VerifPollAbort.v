(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require Import level_ast VerifDetected VerifClosedPrefix.
Definition poll_true (before after:val->mpred) : funspec :=
 WITH ctx:val
 PRE [tptr tvoid] PROP(is_pointer_or_null ctx) PARAMS(ctx) SEP(before ctx)
 POST [tbool] PROP() RETURN(Vint Int.one) SEP(after ctx).

Definition poll_fields s bp cb ctx w words nodes mask :=
 (field_at Tsh level_type [StructField _nodes] (Vlong nodes) s *
  field_at Tsh level_type [StructField _by_budget] bp s *
  data_at Tsh (tarray tulong (Zlength words)) (map Vlong words) bp *
  field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s *
  field_at Tsh level_type [StructField _poll] cb s *
  field_at Tsh level_type [StructField _poll_ctx] ctx s *
  field_at Tsh level_type [StructField _poll_mask] (Vlong mask) s)%logic.
Definition abort_dfs (before after:val->mpred) : ident*funspec :=
 DECLARE _dfs
 WITH s:val,bp:val,cb:val,ctx:val,policy:val,depth:Z,w:Z,words:list int64,nodes:int64,mask:int64
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint]
   PROP(isptr cb;is_pointer_or_null ctx;is_pointer_or_null policy;0<=depth<=w;w<=Int.max_signed;
        w-depth<Zlength words;Int64.and (Int64.add nodes Int64.one) mask=Int64.zero)
   PARAMS(s;policy;Vint (Int.repr depth))
   SEP(poll_fields s bp cb ctx w words nodes mask; func_ptr' (poll_true before after) cb;weak_valid_pointer cb;before ctx)
 POST [tint] PROP() RETURN(Vint (Int.repr 2))
   SEP(poll_fields s bp cb ctx w (bump words (w-depth)) (Int64.add nodes Int64.one) mask;
       func_ptr' (poll_true before after) cb;weak_valid_pointer cb;after ctx).
Definition PollGprog before after : funspecs:=ltac:(let f:=constr:([abort_dfs before after]) in with_library prog f).
(* ABORTED is distinguishable from EMPTY, even at terminal depth and at a
   node-counter wrap. The driver may only use EMPTY to raise the lower bound. *)
Theorem body_dfs_abort before after :
 semax_body Vprog (PollGprog before after) f_dfs (abort_dfs before after).
Proof.
 start_function;unfold poll_fields;Intros;do 9 (forward;try solve [entailer!]).
 apply semax_if_seq;forward_if;try solve [entailer!|subst cb;contradiction].
 { entailer!;destruct cb;try contradiction;cbn [denote_tc_test_eq];apply andp_right;[entailer!|auto 40 with valid_pointer]. }
 do 3 forward. change (Int64.repr (Int.signed (Int.repr 1))) with Int64.one in *.
 rewrite H5. apply semax_if_seq;forward_if;try solve [entailer!|congruence|discriminate].
 forward;forward;forward_call ctx;forward.
 apply semax_if_seq;forward_if;[|discriminate].
 forward;unfold poll_fields,bump;rewrite upd_Znth_Zlength by lia;entailer!;
 rewrite upd_Znth_map;apply derives_refl.
Qed.
