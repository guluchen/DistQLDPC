(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require Import VerifDetected VerifClosedPrefix VerifPollAbort PreparedSeedDispatch.
Require flag_level_ast.
Import flag_level_ast.
Definition abort_dfs (before after:val->mpred) : ident*funspec :=
 DECLARE _dfs
 WITH s:val,bp:val,cb:val,ctx:val,policy:val,depth:Z,w:Z,words:list int64,nodes:int64,mask:int64,bits:int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint,tuint]
   PROP(Int.and bits (Int.repr 2)<>Int.zero;is_pointer_or_null ctx;is_pointer_or_null policy;0<=depth<=w;w<=Int.max_signed;
        w-depth<Zlength words;Int64.and (Int64.add nodes Int64.one) mask=Int64.zero)
   PARAMS(s;policy;Vint (Int.repr depth);Vint bits)
   SEP(poll_fields s bp cb ctx w words nodes mask; func_ptr' (poll_true before after) cb;before ctx)
 POST [tint] PROP() RETURN(Vint (Int.repr 2))
   SEP(poll_fields s bp cb ctx w (bump words (w-depth)) (Int64.add nodes Int64.one) mask;
       func_ptr' (poll_true before after) cb;after ctx).
Definition PollGprog before after : funspecs:=ltac:(let f:=constr:([abort_dfs before after]) in with_library prog f).
(* ABORTED is distinguishable from EMPTY, even at terminal depth and at a
   node-counter wrap. The driver may only use EMPTY to raise the lower bound. *)
Theorem body_dfs_abort before after :
 semax_body prepared_vars (PollGprog before after) f_dfs (abort_dfs before after).
Proof.
 start_function;unfold poll_fields;Intros;do 8 (forward;try solve [entailer!]). reassoc_seq.
 apply semax_if_seq;forward_if;try solve [contradiction|congruence].
 do 3 forward. change (Int64.repr (Int.signed (Int.repr 1))) with Int64.one in *.
 match goal with M:Int64.and (Int64.add nodes Int64.one) mask=Int64.zero |- _=>rewrite M end. apply semax_if_seq;forward_if;try solve [entailer!|congruence|discriminate].
 forward;forward;forward_call ctx;forward.
 apply semax_if_seq;forward_if;[|discriminate].
 forward;unfold poll_fields,bump;rewrite upd_Znth_Zlength by lia;entailer!;
 rewrite upd_Znth_map;apply derives_refl.
Qed.
