(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import seed_ast SeedExemptionState SiblingCounters.
Local Open Scope Z_scope.
#[local] Instance SeedC:compspecs. make_compspecs prog. Defined.
Definition SVars:varspecs. mk_varspecs prog. Defined.
Definition seed_type:=Tstruct _cc_seed_policy noattr.
Record seed_arrays:={ current_ptr:val; limit_ptr:val; blocked_ptr:val; events_ptr:val }.
Definition seed_move_mem p a (current limits blocks:list int) events :=
 (field_at Tsh seed_type [StructField _current] (current_ptr a) p *
  field_at Tsh seed_type [StructField _limit] (limit_ptr a) p *
  field_at Tsh seed_type [StructField _blocked;StructField _overlap] (blocked_ptr a) p *
  field_at Tsh seed_type [StructField _forbidden;StructField _overlap] (events_ptr a) p *
  data_at Tsh (tarray tint (Zlength current)) (map Vint current) (current_ptr a) *
  data_at Tsh (tarray tint (Zlength limits)) (map Vint limits) (limit_ptr a) *
  data_at Tsh (tarray tuint (Zlength blocks)) (map Vint blocks) (blocked_ptr a) *
  data_at Tsh tulong (Vlong events) (events_ptr a))%logic.
Definition moved_mem p a current limits blocks events row next :=
 let old:=Znth row current in
 if Int.eq old (Int.repr next) then seed_move_mem p a current limits blocks events else
 let updated:=upd_Znth row current (Int.repr next) in
 if Int.eq (Znth row limits) Int.zero then
   seed_move_mem p a updated limits (reassign_blocks blocks (Int.signed old) next)
     (new_forbidden_count events blocks (Int.signed old) next)
 else seed_move_mem p a updated limits blocks events.
Definition move_spec:ident*funspec:=
 DECLARE _cc_move_exemption
 WITH p:val,a:seed_arrays,cur:list int,limits:list int,blocks:list int,events:int64,row:Z,next:Z
 PRE [tptr seed_type,tuint,tint]
 PROP(0<=row<Zlength cur;Zlength cur=Zlength limits;row<=Int.max_unsigned;
      0<=next<=Int.max_signed;next<Zlength blocks;0<=Int.signed (Znth row cur)<Zlength blocks)
 PARAMS(p;Vint (Int.repr row);Vint (Int.repr next)) SEP(seed_move_mem p a cur limits blocks events)
 POST [tvoid] PROP() RETURN() SEP(moved_mem p a cur limits blocks events row next).
Definition SGprog:funspecs:=ltac:(with_library prog [move_spec]).
Theorem body_move_exemption:semax_body SVars SGprog f_cc_move_exemption move_spec.
Proof.
 start_function;unfold seed_move_mem;Intros.
 do 2 forward;forward_if.
 - forward;unfold moved_mem,seed_move_mem;rewrite H5,Int.eq_true;entailer!;try apply derives_refl.
 - assert (different:Int.eq (Znth row cur) (Int.repr next)=false) by (apply Int.eq_false;assumption).
   do 2 forward;apply semax_if_seq;forward_if.
   + do 4 forward;rewrite upd_Znth_map,decrement_word.
     change (upd_Znth next blocks (Int.add (Znth next blocks) (Int.repr (-1)))) with (adjust (-1) blocks next).
     assert (alen:Zlength (adjust (-1) blocks next)=Zlength blocks) by (unfold adjust;apply upd_Znth_Zlength;lia).
     do 6 forward;do 4 forward;rewrite upd_Znth_map;do 2 forward;try forward.
     unfold moved_mem;rewrite different,H6,Int.eq_true.
     unfold seed_move_mem,reassign_blocks,new_forbidden_count.
     rewrite upd_Znth_Zlength by lia;rewrite ?alen,?upd_Znth_map;entailer!;try apply derives_refl.
     assert (n_b:Zlength (adjust 1 (adjust (-1) blocks next) (Int.signed (Znth row cur)))=Zlength blocks).
     { unfold adjust at 1;rewrite upd_Znth_Zlength by lia;exact alen. }
     rewrite n_b;change (Int.repr 0) with Int.zero.
     destruct (Int.eq (Znth (Int.signed (Znth row cur)) (adjust (-1) blocks next)) Int.zero);apply derives_refl.
   + do 2 forward;try forward.
     unfold moved_mem;rewrite different,Int.eq_false by assumption.
     unfold seed_move_mem;rewrite upd_Znth_Zlength by lia;rewrite upd_Znth_map;entailer!;try apply derives_refl.
Qed.
