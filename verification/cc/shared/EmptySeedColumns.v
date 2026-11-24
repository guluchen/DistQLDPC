(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import seed_ast VerifSeedMove SeedPolicyView SeedBlockView.
#[local] Existing Instance SeedC.
Local Open Scope Z_scope.

(* A C++ empty vector may have null data(). The seed visitor only borrows
   the column-start vector when a seed has no incident stabilizer row. *)
Definition offsets_at p cp starts :=
 (field_at Tsh seed_type [StructField _column_start;StructField _overlap] cp p *
  data_at Tsh (tarray tuint (Zlength starts)) (map Vint starts) cp)%logic.
Definition empty_visit:ident*funspec:=
 DECLARE _cc_seed_exemption WITH p:val,cp:val,starts:list int,q:Z,enter:bool
 PRE [tptr tvoid,tint,tbool]
 PROP(0<=q<Int.max_signed;q+1<Zlength starts;Znth (q+1) starts=Znth q starts)
 PARAMS(p;Vint (Int.repr q);flag enter) SEP(offsets_at p cp starts)
 POST [tvoid] PROP() RETURN() SEP(offsets_at p cp starts).
Definition EmptyG:funspecs:=ltac:(with_library prog [empty_visit]).
Theorem body_empty_seed:semax_body SVars EmptyG f_cc_seed_exemption empty_visit.
Proof.
 start_function;assert (bool_ok:tc_val tbool (flag enter)) by (destruct enter;compute;auto).
 unfold offsets_at;Intros;reassoc_seq;do 3 forward.
 forward_loop (PROP() LOCAL(temp _state p;temp _seed (Vint (Int.repr q));temp _i (Vint (Znth q starts)))
   SEP(offsets_at p cp starts))%assert
 continue:(PROP(False) LOCAL() SEP())%assert
 break:(PROP() LOCAL() SEP(offsets_at p cp starts))%assert.
 - unfold offsets_at;entailer!;try apply derives_refl.
 - unfold offsets_at;Intros;do 2 (forward;try solve [entailer!;rep_lia]);rewrite H1;forward_if.
   { apply Int.ltu_inv in H2;lia. }
   forward;unfold offsets_at;entailer!;try apply derives_refl.
 - unfold POSTCONDITION,abbreviate;cbn [RA_normal frame_ret_assert function_body_ret_assert normal_ret_assert].
   unfold stackframe_of;simpl fn_vars;cbn [fold_right map];rewrite sepcon_emp;entailer!;try apply derives_refl.
Qed.
