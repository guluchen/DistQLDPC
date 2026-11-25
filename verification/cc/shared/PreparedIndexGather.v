(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected ClightSelect VerifGather RowTally RowGather.
Require Import level_ast.
Require flag_level_ast.

Definition gather_then_return (s:statement) :=
 match s with
 | Ssequence loop (Sreturn (Some (Etempvar result _))) =>
   (gather_loop loop && Pos.eqb result _count__1)%bool
 | _=>false end.
Definition index_emit:statement:=ltac:(native_fragment gather_then_return flag_level_ast.f_index_children).

Theorem compiled_index_emit {Espec:OracleKind} s op rp bp children os cols blocks old r lo hi :
 0<=r<Int.max_signed -> r+1<Zlength os -> Znth r os=lo -> Znth (r+1) os=hi ->
 0<=lo<=hi -> hi<=Int.max_unsigned -> hi<=Zlength cols -> hi-lo<=Zlength old ->
 Zlength old<=Int.max_signed ->
 (forall j,lo<=j<hi -> Int.unsigned (Znth j cols)<Zlength blocks) ->
 let picks:=gathered blocks cols lo hi in
 semax (func_tycontext flag_level_ast.f_index_children Vprog [] [])
   (PROPx [] (LOCALx (gather_loc s children r 0) (SEPx [gather_mem s op rp bp children os cols blocks old])))
   index_emit (function_body_ret_assert tint
     (PROP() LOCAL(temp ret_temp (Vint (Int.repr (Zlength picks))))
      SEP(gather_mem s op rp bp children os cols blocks (filled picks old))))%assert.
Proof.
 intros row offset start finish ordered fits within room signed indices picks.
 change index_emit with (Ssequence native_gather (Sreturn (Some (Etempvar _count__1 tint)))).
 eapply semax_seq' with (P':=PROPx [] (LOCALx (gather_loc s children r (Zlength picks))
       (SEPx [gather_mem s op rp bp children os cols blocks (filled picks old)]))).
 - exact (@semax_gather_row Espec s op rp bp children os cols blocks old r lo hi row offset
     start finish ordered fits within room signed indices).
 - eapply semax_pre with (P':= (PROP() LOCAL(temp _count__1 (Vint (Int.repr (Zlength picks))))
       SEP(gather_mem s op rp bp children os cols blocks (filled picks old)))%assert).
   { unfold gather_loc;entailer!. }
   abbreviate_semax.
   eapply semax_pre;[|apply semax_return];apply andp_right;[entailer!|].
   match goal with post:=_ : ret_assert |- _ => unfold post,abbreviate end.
   cbn [RA_return function_body_ret_assert liftx cast_expropt id ret_type].
   simpl liftx;go_lowerx;entailer!.
   all: match goal with
   | rho:environ, h:context[eval_id _count__1] |- _ =>
      assert (value:Vint (Int.repr (Zlength picks))=eval_id _count__1 rho) by exact (proj1 h);
      unfold liftx;cbn;rewrite ?(eq_sym value);cbn;try solve [auto|entailer!|cancel]
   end.
Qed.

From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix IndexRowBridge NativePackingScan PreparedRowCoverage PreparedResidualIndex
 PreparedIndexWords PreparedIndexCandidates.
Set Implicit Arguments.
Unset Strict Implicit.
Local Delimit Scope Z_scope with coqZ.
Local Open Scope ring_scope.

Section PCM.
Variables m n:nat.
Variables (H:'M['F_2]_(m,n)) (prefix:'cV['F_2]_n) (branch:'I_m) (row:seq 'I_n)
 (free:{set 'I_n}) (blocks:seq Integers.int).
Hypotheses (fits:(Z.of_nat n<=Int.max_unsigned)%coqZ)
 (extent:Zlength blocks=Z.of_nat n)
 (repr:forall q:'I_n,Znth (Z.of_nat q) blocks=Int.zero <-> q \in free)
 (covers:forall q,H branch q!=0 -> q \in row)
 (odd:(H*m prefix) branch 0!=0) (unique:uniq row).

Definition covers_completions (picks:seq Integers.int) :=
 forall target:'cV['F_2]_n, support prefix \subset support target -> H*m target=0 ->
 support target :\: support prefix \subset free ->
 exists q:'I_n,q \in support target :\: support prefix /\ List.In (Z.of_nat q) (map Int.unsigned picks).

Theorem physical_index_emit {Espec:OracleKind} s op rp bp children os cols old lo hi:
 let r:=Z.of_nat branch in let picks:=free_row blocks (map (@address n) row) in
 (r<Int.max_signed)%coqZ -> (r+1<Zlength os)%coqZ -> Znth r os=lo -> Znth (r+1)%coqZ os=hi ->
 (0<=lo<=hi)%coqZ -> (hi<=Int.max_unsigned)%coqZ -> (hi<=Zlength cols)%coqZ ->
 (hi-lo<=Zlength old<=Int.max_signed)%coqZ -> sublist lo hi cols=map (@address n) row ->
 covers_completions picks /\ List.NoDup (map Int.unsigned picks) /\
 semax (func_tycontext flag_level_ast.f_index_children Vprog nil nil)
   (PROPx nil (LOCALx (gather_loc s children r 0) (SEPx [::gather_mem s op rp bp children os cols blocks old])))
   index_emit (function_body_ret_assert tint
    (PROP()
     LOCAL(temp ret_temp (Vint (Int.repr (Zlength picks))))
     SEP(gather_mem s op rp bp children os cols blocks (filled picks old))))%assert.
Proof.
 move=>r picks row_fits off lo_ok hi_ok slice hi_u within room image.
 have actual:gathered blocks cols lo hi=picks by rewrite /gathered image.
 have in_bounds j:(lo<=j<hi)%coqZ -> (Int.unsigned (Znth j cols)<Zlength blocks)%coqZ.
 { move=>live.
   have entry:List.In (Znth j cols) (sublist lo hi cols).
   { have pos:(0<=j-lo<Zlength (sublist lo hi cols))%coqZ by rewrite Zlength_sublist;lia.
     have mem:List.In (Znth (j-lo)%coqZ (sublist lo hi cols)) (sublist lo hi cols)
       by apply Znth_In;exact pos.
     rewrite Znth_sublist in mem;try lia.
     replace (j-lo+lo)%coqZ with j in mem by lia;exact mem. }
   rewrite image in entry;case/List.in_map_iff:entry=>a [<- _].
   rewrite extent unsigned_address //;have:=elimT ltP (ltn_ord a);lia. }
 have emits:=@compiled_index_emit Espec s op rp bp children os cols blocks old r lo hi
    ltac:(unfold r;lia) off lo_ok hi_ok slice hi_u within (proj1 room) (proj2 room) in_bounds.
 cbn zeta in emits;rewrite actual in emits.
 have cov:covers_completions picks.
 { move=>target sub closed available.
   exact:(@odd_candidate_buffer_hits m n H prefix target branch row blocks free fits repr covers sub closed odd available). }
 have no_dup:=@emitted_unique n row blocks free fits repr unique.
 split;[exact cov|split;[exact no_dup|exact emits]].
Qed.
End PCM.
