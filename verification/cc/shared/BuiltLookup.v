(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import TableFlow TableCoverage HashLookup HashProbe VerifClosesBody.

Definition table_book ks mask query tab links blocked : lookup_data :=
  Build_lookup_data tab links blocked ks mask query.
Section PhysicalTable.
Variables (ks:list int64) (mask:int64) (cap bits:Z).
Hypothesis bits_ok : 0<=bits<64.
Hypothesis size_ok : cap=2^bits.
Hypothesis real_mask : mask=Int64.repr (Z.ones bits).
Hypothesis vacancy : Zlength ks<cap.
Lemma low_mask : Int64.unsigned mask<cap.
Proof.
  subst mask cap;rewrite Int64.unsigned_repr,Z.ones_equiv.
  - lia.
  - rewrite Z.ones_equiv;pose proof (Z.pow_pos_nonneg 2 bits ltac:(lia) ltac:(lia)).
    assert (2^bits<=2^63) by (apply Z.pow_le_mono_r;lia).
    change Int64.max_unsigned with (2^64-1);lia.
Qed.

(* At every construction step the masked walk can reach a spare slot
   within one period. An equal key may terminate the step earlier. *)
Theorem insertion_finishes q tab links : history ks mask cap q tab links ->
  exists i, reached ks mask q tab i /\
     (TableFlow.head tab i<0 \/ Znth (TableFlow.head tab i) ks=Znth q ks).
Proof.
  intro built;destruct (@spare_slot ks mask cap low_mask q tab links built vacancy) as [e [e_ok empty]].
  set (b:=table_book ks mask (Znth q ks) tab links []).
  assert (m:HashLookup.mask b=Int64.repr (Z.ones bits)) by exact real_mask.
  pose proof (@TableFlow.masked_inside ks mask cap low_mask (Znth q ks)) as start.
  change (0<=Int64.unsigned (origin b)<cap) in start;rewrite size_ok in start,e_ok.
  destruct (@visit_slot b bits (origin b) e bits_ok m start e_ok) as [ticks [_ end_at]].
  assert (search:forall t i, reached ks mask q tab i -> TableFlow.head tab (hop b i t)<0 ->
    exists j, reached ks mask q tab j /\
        (TableFlow.head tab j<0 \/ Znth (TableFlow.head tab j) ks=Znth q ks)).
  { induction t as [|t IH]; intros i walk finish.
    - exists i;split;[assumption|left;exact finish].
    - destruct (Z_lt_dec (TableFlow.head tab i) 0) as [none|present].
      + exists i;auto.
      + destruct (Int64.eq_dec (Znth (TableFlow.head tab i) ks) (Znth q ks)) as [same|other].
        * exists i;auto.
        * apply (IH (advance b i));[apply after_collision;try assumption;lia|exact finish]. }
  apply (search ticks (origin b));[constructor|].
  unfold TableFlow.head,slot_index;rewrite end_at,empty;lia.
Qed.

(* A finished C producer supplies the spare-slot and increasing-chain
   conditions for the actual C consumer, independently of key collisions. *)
Theorem built_lookup_unique tab links blocked key (v:close_view) odd :
  0<Zlength ks -> history ks mask cap (-1) tab links ->
  let b := table_book ks mask key tab links blocked in
  exists! a, probe_run b v odd (origin b) a.
Proof.
  intros npos built b.
  destruct (@history_shape ks mask cap low_mask _ _ _ built) as [bounds hlen llen heads chain].
  destruct (@spare_slot ks mask cap low_mask _ _ _ built vacancy) as [e [efree empty]].
  eapply (@unique_lookup b v odd (Zlength ks)) with (k:=bits) (e:=e).
  - intros q range. change (Znth q links<0 \/ q<Znth q links<Zlength ks).
    destruct (chain q range) as [last|[more _]];[left;lia|right;exact more].
  - intro i;change (Znth (Int64.unsigned i) tab<Zlength ks).
    pose proof (Int64.unsigned_range i) as I.
    destruct (Z_lt_dec (Int64.unsigned i) cap) as [inrange|out].
    + destruct (heads (Int64.unsigned i) ltac:(lia));lia.
    + rewrite Znth_overflow by lia;exact npos.
  - exact bits_ok.
  - exact real_mask.
  - rewrite <-size_ok;exact efree.
  - change (Znth e tab<0);lia.
Qed.
End PhysicalTable.
