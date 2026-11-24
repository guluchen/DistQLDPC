(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto WordScan.
From Coq Require Import List Lia.
Import ListNotations.

(* base is the physical row number of the low bit, i.e. 64*wi. Each
   nonzero word in the native loop is cleared in least-set-bit order. *)
Inductive row_order:Z->list int64->list Z->Prop :=
| rows_done base : row_order base [] []
| rows_word base w ws bits later : scan_word w bits -> row_order (base+64) ws later ->
  row_order base (w::ws) (map (Z.add base) bits++later).

Fixpoint packed_odd (base r:Z) (ws:list int64) : bool :=
 match ws with []=>false | w::rest=>
 if Z_lt_dec r (base+64) then (Z.leb base r && Int64.testbit w (r-base))%bool
 else packed_odd (base+64) r rest end.
Lemma rows_finite base ws : exists xs,row_order base ws xs.
Proof.
 revert base;induction ws as [|w ws IH];intro base;[exists [];constructor|].
 destruct (scan_finite w) as [bits step].
 destruct (IH (base+64)) as [tail later].
 eexists;econstructor;eassumption.
Qed.

Lemma rows_range base ws xs : row_order base ws xs ->
 Forall (fun r=>base<=r<base+64*Zlength ws) xs.
Proof.
 induction 1 as [b|b w ws bits later word rest IH];[constructor|].
 rewrite Zlength_cons;apply Forall_app;split;apply Forall_forall;intros r member.
 - apply in_map_iff in member;destruct member as [k [<- inside]].
   destruct (scan_exact _ _ word) as [_ [range _]].
   apply Forall_forall with (x:=k) in range;[pose proof (Zlength_nonneg ws);lia|assumption].
 - apply Forall_forall with (x:=r) in IH;[lia|assumption].
Qed.
Lemma add_in_bits base bits r :
 In r (map (Z.add base) bits) <-> In (r-base) bits.
Proof.
 split;intro mem.
 - apply in_map_iff in mem;destruct mem as [i [eq ok]];replace (r-base) with i by lia;assumption.
 - apply in_map_iff;exists (r-base);split;[lia|assumption].
Qed.
Theorem packed_scan_exact base ws xs : row_order base ws xs ->
 NoDup xs /\ forall r,In r xs <-> packed_odd base r ws=true.
Proof.
 induction 1 as [b|b w ws bits later W R [N later_odd]].
 - split;[constructor|simpl;intuition discriminate].
 - destruct (scan_exact _ _ W) as [distinct [range member]].
   pose proof (rows_range _ _ _ R) as bounds.
   assert (bit_range:forall i,In i bits->0<=i<64) by (rewrite Forall_forall in range;exact range).
   assert (tail_range:forall i,In i later->b+64<=i) by
     (intros i inside;apply Forall_forall with (x:=i) in bounds;lia || assumption).
   split.
   + apply NoDup_app_iff;repeat split;try assumption.
     * apply FinFun.Injective_map_NoDup;[intros i j eq;lia|assumption].
     * intros r inside outside. apply add_in_bits in inside;specialize (bit_range _ inside);specialize (tail_range _ outside);lia.
   + intro r;rewrite in_app_iff,add_in_bits;cbn [packed_odd].
     destruct (Z_lt_dec r (b+64)).
     * destruct (Z_le_dec b r).
       -- rewrite (proj2 (Z.leb_le _ _) l0),Bool.andb_true_l.
          rewrite <-member by lia;split;[intros [yes|bad];[assumption|specialize (tail_range _ bad);lia]|auto].
       -- rewrite (proj2 (Z.leb_gt b r) ltac:(lia));simpl.
          split;[intros [bad|bad];[specialize (bit_range _ bad)|specialize (tail_range _ bad)];lia|discriminate].
     * rewrite <-later_odd;split;[intros [bad|yes];[specialize (bit_range _ bad);lia|assumption]|auto].
Qed.
