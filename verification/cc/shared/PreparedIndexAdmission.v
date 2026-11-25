(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import VerifDetected RowTally IndexRowBridge IndexPacking NativePackingScan
 LeafMatrix MinimumPrefix PreparedIndexCandidates PreparedIndexCuts.
Require Import VerifRowTally.
Require flag_level_ast.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Machine.
Variables m n:nat.
Variables (H:'M['F_2]_(m,n)) (prefix:'cV['F_2]_n) (rows:'I_m->seq 'I_n)
 (free:{set 'I_n}) (blocks:seq Integers.int) (stamp:int64) (budget:nat).
Let active:=support (H*m prefix).
Let nonempty:=count_nonzero rows blocks.
Let clash ms row:=row_clash blocks ms stamp (encoded rows row).
Let advance ms row:=mark rows stamp row ms.

(* Residual state after a prefix of non-rejecting rows. These are the
   same count, clash and tag operations as the three compiled row loops. *)
Inductive reaches_row : seq 'I_m -> seq int64 -> nat -> seq 'I_m -> seq int64 -> nat -> Prop :=
| at_row rs ms p : reaches_row rs ms p rs ms p
| passed_clash r rs ms p tail last count :
  nonempty r -> clash ms r -> reaches_row rs ms p tail last count ->
  reaches_row (r::rs) ms p tail last count
| added_row r rs ms p tail last count :
  nonempty r -> clash ms r=false -> (p.+1<=budget)%N ->
  reaches_row rs (advance ms r) p.+1 tail last count ->
  reaches_row (r::rs) ms p tail last count.

Lemma suffix_verdict rs ms p tail last count :
 reaches_row rs ms p tail last count ->
 cpu_scan rows blocks stamp budget rs ms p=cpu_scan rows blocks stamp budget tail last count.
Proof.
 elim=>[|r rest before current later final included ok intersects path ih
       |r rest before current later final included ok disjoint fits path ih];first reflexivity.
 all: cbn [cpu_scan];fold (nonempty r);fold (clash before r).
 - by rewrite ok intersects.
 - by rewrite ok disjoint fits.
Qed.

Lemma count_within_budget rs ms p tail last count :
 reaches_row rs ms p tail last count -> (p<=budget)%N -> (count<=budget)%N.
Proof. by elim=> [|r rest marks current later final included ok intersects path ih
 |r rest marks current later final included ok disjoint within path ih] //;auto. Qed.

(* Every finite row scan generates its own final state or first failing
   row. The residual evidence is not an oracle supplied by a chooser. *)
Theorem classify_scan rs ms p:
 if cpu_scan rows blocks stamp budget rs ms p then
   exists final count,reaches_row rs ms p [::] final count
 else exists r tail last count,reaches_row rs ms p (r::tail) last count /\
   (nonempty r=false \/ (nonempty r /\ clash last r=false /\ (budget<count.+1)%N)).
Proof.
 elim:rs ms p=>[|r rest ih] ms p.
 - exists ms,p;constructor.
 - cbn [cpu_scan];fold (nonempty r);fold (clash ms r).
   case live:(nonempty r);last by exists r,rest,ms,p;split;[constructor|left].
   case blocked_row:(clash ms r).
   + have tail:=ih ms p.
     case:(cpu_scan rows blocks stamp budget rest ms p) tail=>[[final [count run]]|[a [later [last [count [run why]]]]]].
     * exists final,count;exact:passed_clash run.
     * exists a,later,last,count;split=> //;exact:passed_clash run.
   + case fits:(p.+1<=budget)%N;last first.
     * exists r,rest,ms,p;split;first constructor.
       right;split=> //;split=> //;by rewrite ltnNge fits.
     * cbn [andb];fold (advance ms r).
       have tail:=ih (advance ms r) p.+1.
       case:(cpu_scan rows blocks stamp budget rest (advance ms r) p.+1) tail=>[[final [count run]]|[a [later [last [count [run why]]]]]].
       -- exists final,count;eapply added_row;eassumption.
       -- exists a,later,last,count;split=> //;eapply added_row;eassumption.
Qed.

Variables (cap:(Z.of_nat n<=Int.max_unsigned)%coqZ)
 (avail:forall q:'I_n,Znth (Z.of_nat q) blocks=Int.zero <-> q \in free)
 (cover:forall r q,H r q!=0 -> q \in rows r)
 (width:forall r,(Zlength (encoded rows r)<=Int.max_unsigned)%coqZ).
Definition no_completion:Prop:=forall target:'cV['F_2]_n,
 support prefix \subset support target -> H*m target=0 ->
 support target :\: support prefix \subset free ->
 ~ (#|support target :\: support prefix|<=budget)%N.

Theorem cut_at_reached_row first rest initial marked r tail ms p :
 @tags_for n stamp initial marked -> {subset first::rest <= active} ->
 reaches_row (first::rest) initial 0 (r::tail) ms p ->
 (nonempty r=false \/ (nonempty r /\ clash ms r=false /\ (budget<p.+1)%N)) ->
 no_completion.
Proof.
 move=> tags scanned reached reason.
 have same:=suffix_verdict reached.
 have rejected:cpu_scan rows blocks stamp budget (r::tail) ms p=false.
 { cbn [cpu_scan];fold (nonempty r);fold (clash ms r);case:reason=>[empty|[ok [no_overlap excess]]].
   - by rewrite empty.
   - by rewrite ok no_overlap leqNgt excess. }
 have failed:cpu_scan rows blocks stamp budget (first::rest) initial 0=false:=etrans same rejected.
 move=> target sub closed available within.
 have [q [_ listed]]:=@compatible_target_survives m n H rows prefix free blocks stamp initial cap avail
   cover width budget first rest target marked tags scanned sub closed available within.
 change (List.In (Z.of_nat q) (map Int.unsigned
   (if cpu_scan rows blocks stamp budget (first::rest) initial 0 then free_row blocks (encoded rows first) else [::]))) in listed.
 by rewrite failed in listed.
Qed.

(* Derive the safety and arithmetic preconditions of the real C budget
   branch from the completed iterations, including the pending +1. *)
Theorem pack_return_for_pcm {Espec:OracleKind} s visits depth weight first rest initial marked r tail ms p frame:
 @tags_for n stamp initial marked -> {subset first::rest <= active} ->
 reaches_row (first::rest) initial 0 (r::tail) ms p ->
 nonempty r -> clash ms r=false -> (budget<p.+1)%N ->
 (1<=depth<=weight)%coqZ -> (weight<=Int.max_signed)%coqZ -> Z.of_nat budget=(weight-depth)%coqZ ->
 no_completion /\
 semax (func_tycontext flag_level_ast.f_index_children Vprog nil nil)
 (PROP() LOCAL(temp flag_level_ast._s s;temp flag_level_ast._size (Vint (Int.repr depth));
               temp flag_level_ast._packed (Vint (Int.repr (Z.of_nat p))))
  SEP(field_at Tsh level_type [StructField flag_level_ast._w] (Vint (Int.repr weight)) s;
      field_at Tsh level_type [StructField flag_level_ast._packprune] (Vlong visits) s;frame))
 packing_budget_guard (function_body_ret_assert tint
   (PROP() LOCAL(temp ret_temp (Vint Int.zero))
    SEP(field_at Tsh level_type [StructField flag_level_ast._w] (Vint (Int.repr weight)) s;
        field_at Tsh level_type [StructField flag_level_ast._packprune] (Vlong (Int64.add visits Int64.one)) s;frame)))%assert.
Proof.
 move=>tags checked_row reached ok no_overlap excess depth_ok weight_ok budget_size;split.
 - apply:(cut_at_reached_row tags checked_row reached);by right.
 - have count_ok:=elimT leP (count_within_budget reached (leq0n _)).
   have over:=elimT ltP excess.
   apply compiled_packing_cut;lia.
Qed.

Theorem empty_row_return_for_pcm {Espec:OracleKind} s cp bp mp cols visits lo hi
 first rest initial marked r tail ms p :
 @tags_for n stamp initial marked -> {subset first::rest <= active} ->
 reaches_row (first::rest) initial 0 (r::tail) ms p ->
 sublist lo hi cols=encoded rows r ->
 (0<=lo<=hi)%coqZ -> (hi<=Int.max_unsigned)%coqZ -> (hi<=Zlength cols)%coqZ ->
 (forall j,(lo<=j<hi)%coqZ -> (Int.unsigned (Znth j cols)<Zlength blocks)%coqZ) ->
 Zlength ms=Zlength blocks -> fst (counted blocks ms stamp cols lo hi)=Int.zero ->
 let mem:=tally_memory s cp bp mp cols blocks ms in
 let counter v:=field_at Tsh level_type [StructField flag_level_ast._nocand] (Vlong v) s in
 no_completion /\
 semax (func_tycontext flag_level_ast.f_index_children Vprog nil nil)
  (PROPx nil (LOCALx (tally_loc s lo hi stamp (Int.zero,Int.zero)) (SEPx [::counter visits;mem])))
  remaining_row (function_body_ret_assert tint
     (PROP() LOCAL(temp ret_temp (Vint Int.zero)) SEP(counter (Int64.add visits Int64.one);mem)))%assert.
Proof.
 move=> tags scanned reached image slice limit fits indices extent result mem counter.
 split;last exact:(@compiled_count_then_cut Espec s cp bp mp cols blocks ms lo hi stamp visits
   slice limit fits indices extent result).
 apply:(cut_at_reached_row tags scanned reached);left.
 move:result;rewrite /counted image.
 change (fst (List.fold_left (row_step blocks ms stamp) (encoded rows r) (Int.repr 0,flag false))=Int.zero -> nonempty r=false).
 rewrite row_tally;[|lia|rewrite Z.add_0_l;exact:width r].
 cbn [fst];rewrite Z.add_0_l;move=> zero.
 by rewrite /nonempty /count_nonzero zero Int.eq_true.
Qed.

Theorem packed_row_return_for_pcm {Espec:OracleKind} s cp bp mp cols visits lo hi depth weight
 first rest initial marked r tail ms p :
 @tags_for n stamp initial marked -> {subset first::rest <= active} ->
 reaches_row (first::rest) initial 0 (r::tail) ms p ->
 sublist lo hi cols=encoded rows r -> (0<=lo<=hi)%coqZ -> (hi<=Int.max_unsigned)%coqZ ->
 (hi<=Zlength cols)%coqZ -> (forall j,(lo<=j<hi)%coqZ -> (Int.unsigned (Znth j cols)<Zlength blocks)%coqZ) ->
 Zlength ms=Zlength blocks -> nonempty r -> clash ms r=false -> (budget<p.+1)%N ->
 (1<=depth<=weight)%coqZ -> (weight<=Int.max_signed)%coqZ -> Z.of_nat budget=(weight-depth)%coqZ ->
 let mem:=tally_memory s cp bp mp cols blocks ms in
 let saved:=[::temp flag_level_ast._size (Vint (Int.repr depth));
               temp flag_level_ast._packed (Vint (Int.repr (Z.of_nat p)))] in
 let extra v:=[::field_at Tsh level_type [StructField flag_level_ast._w] (Vint (Int.repr weight)) s;
    field_at Tsh level_type [StructField flag_level_ast._packprune] (Vlong v) s] in
 no_completion /\
 semax (func_tycontext flag_level_ast.f_index_children Vprog nil nil)
  (PROPx nil (LOCALx (tally_loc s lo hi stamp (Int.zero,Int.zero)++saved) (SEPx ([::mem]++extra visits))))
  remaining_row (function_body_ret_assert tint
    (PROPx nil (LOCALx [::temp ret_temp (Vint Int.zero)] (SEPx (extra (Int64.add visits Int64.one)++[::mem]))))).
Proof.
 move=>tags scanned reached image slice limit fits indices extent ok no_overlap excess dep capw budget_size mem saved extra.
 split;first by apply:(cut_at_reached_row tags scanned reached);right.
 have before:=elimT leP (count_within_budget reached (leq0n _)).
 have over:=elimT ltP excess.
 have pair_eq:counted blocks ms stamp cols lo hi=
      (Int.repr (Zlength (free_row blocks (encoded rows r))),flag (clash ms r)).
 { unfold counted;rewrite image.
   change (Int.zero,Int.zero) with (Int.repr 0,flag false).
   by rewrite row_tally ?Z.add_0_l //. }
 have count_ok:fst (counted blocks ms stamp cols lo hi)<>Int.zero.
 { rewrite pair_eq /= =>zero;move:ok;by rewrite /nonempty /count_nonzero zero Int.eq_true. }
 have disjoint:snd (counted blocks ms stamp cols lo hi)=Int.zero by rewrite pair_eq /= no_overlap.
 exact:(@compiled_tally_over_budget Espec s cp bp mp cols blocks ms lo hi stamp visits weight depth
    (Z.of_nat p) slice limit fits indices extent ltac:(lia) capw ltac:(lia) ltac:(lia) count_ok disjoint).
Qed.
End Machine.
