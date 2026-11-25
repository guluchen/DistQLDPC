(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra fingroup perm.
Require Import PreparedRawRREF PreparedRawReduction.
Set Implicit Arguments.
Unset Strict Implicit.
Import GRing.Theory.
Local Open Scope ring_scope.

Section Rank.
Variables m n:nat.
Implicit Types (A:'M['F_2]_(m,n)).

Lemma normalized_rank A k (size_ok:(k<=m)%N) (pivot:'I_k->'I_n):
 (forall i:'I_k,forall u:'I_m,A u (pivot i)=(u==widen_ord size_ok i)%:R) ->
 (forall u:'I_m,(k<=u)%N -> row u A=0) -> \rank A=k.
Proof.
 move=>unit zero;pose include:=widen_ord size_ok;pose B:=rowsub include A.
 have included:(B<=A)%MS by apply:rowsub_sub.
 have contains:(A<=B)%MS.
 { apply/row_subP=>u;case live:(u<k)%N.
   - pose i:'I_k:=Ordinal live.
     have address:include i=u by apply:val_inj.
     apply:(eq_row_sub i);apply/matrixP=>a j.
     by rewrite /B !mxE address.
   - rewrite zero ?sub0mx //;by rewrite leqNgt live. }
 have rank_eq : \rank A = \rank B by apply/eqP;rewrite eqn_leq (mxrankS contains) (mxrankS included).
 have basis:rowsub pivot B^T = 1%:M.
 { apply/matrixP=>i j;rewrite /B !mxE unit.
   have inj:injective include by move=>u v same;apply:val_inj;exact:(congr1 val same).
   by rewrite (inj_eq inj) eq_sym. }
 have enough:=mxrankS (rowsub_sub pivot B^T);rewrite basis mxrank1 mxrank_tr in enough.
 by rewrite rank_eq;apply/eqP;rewrite eqn_leq rank_leq_row enough.
Qed.

Definition unit_column A (i:'I_m) j:=forall u,A u j=(u==i)%:R.
Definition scan_invariant A k (done:seq 'I_n):Prop:=
 (k<=m)%N /\
 (forall u:'I_m,(u<k)%N -> exists j:'I_n,unit_column A u j) /\
 (forall j:'I_n,j \in done -> forall u:'I_m,(k<=u)%N -> A u j=0).

Lemma original_form A:scan_invariant A 0 [::].
Proof. split;first exact:leq0n;split;by []. Qed.

Lemma none_left_in_column A k q:candidates A k q=[::] ->
 forall u:'I_m,(k<=u)%N -> A u q=0.
Proof.
 move=>empty u past;apply/eqP.
 apply/negPn/negP=>nz;have member:u \in candidates A k q
    by rewrite /candidates mem_filter past nz mem_enum.
 by rewrite empty in member.
Qed.

Lemma pivot_keeps_zero_below A (p found:'I_m) q old:
 A found q= 1 -> (forall u:'I_m,(p<=u)%N -> A u old=0) ->
 (p<=found)%N -> forall u:'I_m,(p<u)%N -> pivot_step A p found q u old=0.
Proof.
 move=>one zero picked u later;set B:=xrow p found A.
 have pzero:B p old=0 by rewrite /B swapped_cell tpermL zero.
 have uzero:B u old=0.
 { rewrite /B swapped_cell;case:tpermP=>[_|_|_ _];apply:zero;[exact picked|exact:leqnn|exact:ltnW later]. }
 by rewrite /pivot_step (native_row_visits_clear_the_pivot B p q) add_pivot_cell pzero mulr0 addr0.
Qed.
Lemma scan_preserves_form A k done q:scan_invariant A k done ->
 let next:=scan_column (k,A) q in scan_invariant next.2 next.1 (q::done).
Proof.
 move=>[size [units zeros]];rewrite /scan_column;case:insubP=>[p inside pk|past].
 - case pick:(candidates A k q)=>[|i rest] /=.
   + split=> //;split=> //;move=>j;rewrite in_cons=>/orP[/eqP->|old] u lower.
     * exact:(none_left_in_column pick lower).
     * exact (zeros j old u lower).
   + have [after one]:=selected_row pick.
     have after_p:(p<=i)%N by rewrite pk.
     split;first exact:leq_ltn_trans after (ltn_ord i).
     split.
     * move=>u;rewrite ltnS leq_eqVlt=>/orP[/eqP last|earlier].
       -- have ->:u=p by apply:val_inj;rewrite pk.
          exists q;exact:new_unit_column one.
       -- have [old normalized]:=units u earlier.
          have pu:p!=u by apply/eqP=>same;move:earlier;rewrite -pk same ltnn.
          have iu:i!=u by apply/eqP=>same;move:after;rewrite same leqNgt earlier.
          exists old;apply:earlier_unit_survives one pu iu normalized.
     * move=>j;rewrite in_cons=>/orP[/eqP->|old] u below.
       -- have different:u!=p by apply/eqP=>same;move:below;rewrite same pk ltnn.
          by rewrite (@new_unit_column m n A p i q one u) (negbTE different).
       -- apply:(pivot_keeps_zero_below one _ after_p);last by rewrite pk.
          move=>z lower;apply (zeros j old z);by rewrite pk in lower.
 - split=> //;split=> //;move=>j member u lower.
   have bad: (k<m)%N:=leq_ltn_trans lower (ltn_ord u).
   by rewrite bad in past.
Qed.

Lemma finished_form state order done:scan_invariant state.2 state.1 done ->
 let final:=foldl (@scan_column m n) state order in scan_invariant final.2 final.1 (rev order++done).
Proof.
 elim:order state done=>[|q rest ih] [k A] done current;first exact current.
 have one:=scan_preserves_form q current.
 rewrite /= rev_cons -cats1 -catA;exact:(ih (scan_column (k,A) q) (q::done) one).
Qed.

Theorem complete_reduction_reports_rank A:
 let result:=foldl (@scan_column m n) (0%N,A) (enum 'I_n) in result.1 = \rank A.
Proof.
 have reached:=@finished_form (0%N,A) (enum 'I_n) [::] (original_form A).
 have [_ equivalent]:=@scan_all_columns m n (0%N,A) (enum 'I_n) (leq0n m).
 set result:=foldl (@scan_column m n) _ _ in reached equivalent |- *.
 have [bound [units zeros]]:=reached.
 have has (i:'I_result.1):exists j:'I_n,
     [forall u:'I_m,result.2 u j==(u==widen_ord bound i)%:R].
 { have [j ok]:=units (widen_ord bound i) (ltn_ord i).
   exists j;apply/forallP=>u;by rewrite ok eqxx. }
 pose pivot (i:'I_result.1):=xchoose (has i).
 have norm:=@normalized_rank result.2 result.1 bound pivot.
 have piv i u:result.2 u (pivot i)=(u==widen_ord bound i)%:R.
 { apply/eqP;exact:(forallP (xchooseP (has i)) u). }
 have dead (u:'I_m):(result.1<=u)%N -> row u result.2=0.
 { move=>lower;apply/matrixP=>a j;rewrite !mxE;apply (zeros j ltac:(by rewrite cats0 mem_rev mem_enum) u lower). }
 exact (etrans (esym (norm piv dead)) equivalent.1).
Qed.
End Rank.
