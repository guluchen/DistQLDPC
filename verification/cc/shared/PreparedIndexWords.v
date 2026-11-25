(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto CSRWordTraversal SparseFlipBits.
Local Open Scope Z_scope.

(* The nonzero-word loop numbers bits relative to the current word.
   The physical syndrome representation uses a quotient and remainder. *)
Lemma scan_reads_stored_bit ws base j :
  0 <= j < 64 * Zlength ws ->
  packed_odd base (base+j) ws = syndrome_bit ws j.
Proof.
  revert base j. induction ws as [|w ws IH]; intros base j within.
  - rewrite Zlength_nil in within; lia.
  - rewrite Zlength_cons in within. cbn [packed_odd].
    destruct (Z_lt_dec (base+j) (base+64)) as [first|later].
    + rewrite (proj2 (Z.leb_le base (base+j)) ltac:(lia)), Bool.andb_true_l.
      replace (base+j-base) with j by lia.
      unfold syndrome_bit. rewrite Z.div_small, Z.mod_small by lia. reflexivity.
    + replace (base+j) with ((base+64)+(j-64)) by lia.
      rewrite IH by lia. unfold syndrome_bit.
      pose proof (Z.div_mod j 64 ltac:(lia)) as divided.
      pose proof (Z.mod_pos_bound j 64 ltac:(lia)) as remainder.
      assert (word:(j-64)/64=j/64-1) by
        (symmetry;apply Z.div_unique with (r:=j mod 64); [left;lia|lia]).
      assert (bit:(j-64) mod 64=j mod 64) by
        (symmetry;apply Z.mod_unique with (q:=j/64-1); [left;lia|lia]).
      rewrite word,bit,Znth_pos_cons by lia. reflexivity.
Qed.

From mathcomp Require Import all_ssreflect.
Require Import SparseSyndrome PreparedRowCoverage.
Set Implicit Arguments.
Unset Strict Implicit.
Local Delimit Scope Z_scope with coqZ.

Section PhysicalRows.
Variables (m:nat) (words:seq int64) (count:Z) (odd:{set 'I_m}).
Hypothesis image : stores_odd (words,count) odd.
(* Pure C index mode has only physical rows. Unused high bits must be
   clear; stores_odd alone makes no such promise for redundant checks. *)
Hypothesis padding : forall j, (Z.of_nat m <= j < 64*Zlength words)%coqZ ->
                               syndrome_bit words j=false.

Theorem word_scan_physical_rows raw :
 row_order 0 words raw ->
 List.NoDup raw /\
 forall j,List.In j raw <-> exists r:'I_m,j=Z.of_nat r /\ r \in odd.
Proof.
 move=> scanned;have [unique member]:=packed_scan_exact 0 words raw scanned.
 have bounds:=rows_range 0 words raw scanned.
 case:image=>cap [bits size];cbn [fst snd] in cap,bits,size.
 split=> // j;split.
 - move=> inside.
   have ran:=proj1 (List.Forall_forall _ _) bounds j inside.
   have on:=proj1 (member j) inside.
   change (packed_odd 0 (0+j) words=true) in on.
   rewrite scan_reads_stored_bit in on;last lia.
   have below:(j<Z.of_nat m)%coqZ.
   { case:(Z_lt_dec j (Z.of_nat m))=> // greater.
     have off:=@padding j ltac:(lia). congruence. }
   have sm:(Z.to_nat j<m)%N by apply/ltP;lia.
   exists (Ordinal sm);split;first by simpl;rewrite Z2Nat.id;lia.
   rewrite -(bits (Ordinal sm));change (syndrome_bit words (Z.of_nat (Z.to_nat j))=true).
   rewrite Z2Nat.id //;lia.
 - move=> [r [-> live]];apply/(member _).
   have small:=elimT ltP (ltn_ord r).
   change (packed_odd 0 (0+Z.of_nat r) words=true).
   by rewrite scan_reads_stored_bit ?bits;try lia.
Qed.
End PhysicalRows.

(* Decode the actual scan order instead of assuming a separately supplied
   permutation of the odd rows. *)
Lemma decode_physical_rows m (odd:{set 'I_m}) (raw:seq Z):
 (forall j,List.In j raw -> exists r:'I_m,j=Z.of_nat r /\ r \in odd) ->
 exists order:seq 'I_m, raw=map (fun r:'I_m=>Z.of_nat r) order /\ {subset order <= odd}.
Proof.
 elim:raw=>[|j rest IH] complete.
 - by exists [::];split.
 - have [r [value active]]:=complete j (or_introl erefl).
   have [order [encoded sound]]:=IH (fun a used=>complete a (or_intror used)).
   exists (r::order);split;first by rewrite /= -encoded -value.
   move=>a;rewrite inE=>/orP[/eqP ->|later];[exact active|exact:sound later].
Qed.

Theorem physical_branch_from_words m words count (odd:{set 'I_m}) raw:
 stores_odd (words,count) odd ->
 (forall j,(Z.of_nat m<=j<64*Zlength words)%coqZ -> syndrome_bit words j=false) ->
 row_order 0 words raw -> (0<count)%coqZ ->
 exists (first:'I_m) rest,
 raw=map (fun r:'I_m=>Z.of_nat r) (first::rest) /\
 {subset first::rest <= odd} /\
 (forall r:'I_m,r \in odd -> List.In (Z.of_nat r) raw).
Proof.
 move=> stored pad trace positive.
 have [_ decode]:=@word_scan_physical_rows m words count odd stored pad raw trace.
 have [order [order_ok sound]]:=decode_physical_rows (fun j=>proj1 (decode j)).
 have included (r:'I_m): r \in odd -> List.In (Z.of_nat r) raw.
 { move=>active;apply/(decode _);by exists r. }
 case:order order_ok sound=>[|r rs] eqrows subset.
 - case:stored=>_ [_ count_ok];cbn [snd] in count_ok.
   have some:(0<#|odd|)%N by apply/ltP;lia.
   have /card_gt0P [r active]:=some.
   by move:(included r active);rewrite eqrows.
 - exists r,rs;by split=> //;split.
Qed.

Require Import VerifClosesBody VerifToggleBody VerifFlipBody SparseRollback
 NativeFlipPayload NativeDepthFlip.
Local Open Scope Z_scope.

Definition clear_padding (m:Z) (syn:list int64) :=
 forall j, m<=j<64*Zlength syn -> syndrome_bit syn j=false.

Lemma initialized_padding m words : 0<=m ->
 (forall i,0<=i<Zlength words -> Znth i words=Int64.zero) -> clear_padding m words.
Proof.
 intros positive zero j inside. unfold syndrome_bit.
 rewrite zero;[apply Int64.bits_zero|split;[apply Z.div_pos|apply Z.div_lt_upper_bound];lia].
Qed.

Lemma physical_flip_keeps_padding m keys q state :
 0<=m<=64*Zlength (syndrome (words_at state)) ->
 List.Forall (fun r=>Int.unsigned r<m) (column_list (words_at state) q) ->
 clear_padding m (syndrome (words_at state)) ->
 clear_padding m (syndrome (words_at (step_support Bare keys q state))).
Proof.
 intros size physical clear j range.
 set (v:=words_at state) in *.
 change (m<=j<64*Zlength (fst (fold_left sparse_flip (column_list v q)
       (syndrome v,odd_count state)))) in range.
 rewrite walk_length in range;cbn [fst] in range.
 change (syndrome_bit (fst (fold_left sparse_flip (column_list v q)
            (syndrome v,odd_count state))) j=false).
 assert (bounded:List.Forall (fun r=>Int.unsigned r<64*Zlength (syndrome v)) (column_list v q)).
 { apply Forall_forall; intros r inside.
   pose proof (proj1 (Forall_forall _ _) physical r inside) as below; exact (Z.lt_le_trans _ _ _ below (proj2 size)). }
 rewrite (walk_bit (column_list v q) (syndrome v) (odd_count state) j ltac:(lia) bounded).
 assert (dark:forall rs, List.Forall (fun r=>Int.unsigned r<m) rs -> toggled_row j rs=false).
 { intros rs below;induction below as [|r rs short tail IH];[reflexivity|].
   cbn [toggled_row]. rewrite (proj2 (Z.eqb_neq j (Int.unsigned r)) ltac:(lia)) IH.
   reflexivity. }
 rewrite (dark _ physical) (clear j range);reflexivity.
Qed.

(* Applying or undoing any number of columns keeps the unused bits clear. *)
Theorem reachable_index_padding m keys path initial :
 0<=m<=64*Zlength (syndrome (words_at initial)) ->
 (forall q,List.In q path -> List.Forall (fun r=>Int.unsigned r<m)
   (column_list (words_at initial) (Int.signed q))) ->
 clear_padding m (syndrome (words_at initial)) ->
 clear_padding m (syndrome (words_at (payload_after Bare keys initial path))).
Proof.
 revert initial. induction path as [|q path IH];intros initial size physical clear;[exact clear|].
 apply IH.
 - change (0<=m<=64*Zlength (fst (fold_left sparse_flip
      (column_list (words_at initial) (Int.signed q)) (syndrome (words_at initial),odd_count initial)))).
   rewrite walk_length;exact size.
 - intros a member;apply physical;right;exact member.
 - apply physical_flip_keeps_padding;[exact size|apply physical;left;reflexivity|exact clear].
Qed.
