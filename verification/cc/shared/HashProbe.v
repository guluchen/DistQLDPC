(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import VerifClosesBody HashLookup.

(* The C++ producer allocates a power-of-two table and leaves at least
   one cell empty. Its descending insertion order makes chains increase. *)
Lemma masked_modulo k x : 0<=k<64 ->
  Int64.unsigned (Int64.and x (Int64.repr (Z.ones k))) = Int64.unsigned x mod 2^k.
Proof.
  intros K. unfold Int64.and.
  assert (P: 0<2^k) by (apply Z.pow_pos_nonneg;lia).
  assert (B: 2^k<=2^63) by (apply Z.pow_le_mono_r;lia).
  rewrite Int64.unsigned_repr with (z:=Z.ones k).
  2: { rewrite Z.ones_equiv. change Int64.max_unsigned with (2^64-1); lia. }
  rewrite Z.land_ones by lia. rewrite Int64.unsigned_repr; [reflexivity|].
  pose proof (Z.mod_pos_bound (Int64.unsigned x) (2^k) P).
  change Int64.max_unsigned with (2^64-1);lia.
Qed.

Fixpoint hop b i (n:nat) := match n with O => i | S t => hop b (advance b i) t end.

Lemma next_mod b k i : 0<=k<64 -> mask b=Int64.repr (Z.ones k) ->
  0<=Int64.unsigned i<2^k ->
  Int64.unsigned (advance b i) = (Int64.unsigned i+1) mod 2^k.
Proof.
  intros K M B. unfold advance. rewrite M, masked_modulo by assumption.
  unfold Int64.add. change (Int64.unsigned Int64.one) with 1.
  rewrite Int64.unsigned_repr; [reflexivity|].
  assert (C:2^k<=2^63) by (apply Z.pow_le_mono_r;lia).
  change Int64.max_unsigned with (2^64-1);lia.
Qed.

Lemma hop_mod b k i n : 0<=k<64 -> mask b=Int64.repr (Z.ones k) ->
  0<=Int64.unsigned i<2^k ->
  Int64.unsigned (hop b i n) = (Int64.unsigned i+Z.of_nat n) mod 2^k.
Proof.
  intros K M; revert i; induction n as [|t IH]; intros i I.
  - cbn [hop]. rewrite Z.add_0_r, Z.mod_small by assumption; reflexivity.
  - cbn [hop]. assert (P:0<2^k) by (apply Z.pow_pos_nonneg;lia).
    rewrite IH; rewrite next_mod with (k:=k) by assumption.
    + rewrite Z.add_mod_idemp_l by lia. f_equal; lia.
    + apply Z.mod_pos_bound; assumption.
Qed.

Theorem visit_slot b k i e : 0<=k<64 -> mask b=Int64.repr (Z.ones k) ->
  0<=Int64.unsigned i<2^k -> 0<=e<2^k ->
  exists hops, (Z.of_nat hops<2^k) /\ Int64.unsigned (hop b i hops)=e.
Proof.
  intros K M I E. set (size:=2^k) in *. assert (P:0<size) by lia.
  set (delta := (e-Int64.unsigned i) mod size).
  assert (D:0<=delta<size) by (unfold delta; apply Z.mod_pos_bound;assumption).
  exists (Z.to_nat delta); rewrite hop_mod with (k:=k) by assumption.
  rewrite Z2Nat.id by lia. split; [lia|].
  fold size. unfold delta. rewrite Z.add_mod_idemp_r by lia.
  replace (Int64.unsigned i + (e-Int64.unsigned i)) with e by ring.
  apply Z.mod_small;assumption.
Qed.

Section Termination.
Variables (b : lookup_data) (v : close_view) (odd : Z).
Variable n : Z.
Hypothesis successor : forall q, 0 <= q < n ->
  Znth q (links b)<0 \/ q < Znth q (links b) < n.

Lemma finite_chain q : q<n -> exists qs, chain_lists b q qs.
Proof.
  intros maxq; remember (Z.to_nat (n-q)) as fuel eqn:Fuel.
  revert q maxq Fuel; induction fuel using lt_wf_ind; intros q maxq Fuel.
  destruct (Z_lt_dec q 0) as [neg|pos].
  - exists nil;constructor;assumption.
  - destruct (successor q ltac:(lia)) as [last|higher].
    + exists [q]; constructor; [lia|constructor;assumption].
    + destruct (H (Z.to_nat (n-Znth q (links b))) ltac:(lia) _ (proj2 higher) eq_refl) as [qs path].
      exists (q::qs); constructor; [lia|assumption].
Qed.

Hypothesis heads : forall i, slot b i < n.
Lemma stops_before_empty i hops : slot b (hop b i hops)<0 ->
  exists a, probe_run b v odd i a.
Proof.
  revert i; induction hops as [|t IH]; intros i empty.
  - exists (-1);constructor;exact empty.
  - destruct (Z_lt_dec (slot b i) 0) as [neg|pos].
    + exists (-1);constructor;assumption.
    + destruct (Int64.eq_dec (Znth (slot b i) (keys b)) (query b)) as [hit|miss].
      * destruct (finite_chain _ (heads i)) as [qs path].
        destruct (chain_complete b v odd _ _ path) as [a [trace _]].
        exists a; apply probe_found; [lia|assumption|assumption].
      * destruct (IH (advance b i) empty) as [a trace].
        exists a; apply probe_next; [lia|assumption|assumption].
Qed.

Theorem finite_lookup k e : 0<=k<64 -> mask b=Int64.repr (Z.ones k) ->
  0<=e<2^k -> Znth e (slots b)<0 ->
  exists a, probe_run b v odd (origin b) a.
Proof.
  intros K M E empty. assert (start: 0 <= Int64.unsigned (origin b) < 2^k).
  { unfold origin; rewrite M, masked_modulo by assumption. apply Z.mod_pos_bound.
    apply Z.pow_pos_nonneg; lia. }
  destruct (visit_slot b k (origin b) e K M start E) as [h [_ reach]].
  apply (stops_before_empty _ h). unfold slot. rewrite reach;assumption.
Qed.
(* The producer invariant identifies the exact bucket visited by the C
   probe. Empty tables and absent keys have an empty candidate list. *)
Inductive bucket_path i : list Z -> Prop :=
| path_empty : slot b i<0 -> bucket_path i nil
| path_chain : forall qs, 0<=slot b i -> Znth (slot b i) (keys b)=query b ->
    chain_lists b (slot b i) qs -> bucket_path i qs
| path_next : forall qs, 0<=slot b i -> Znth (slot b i) (keys b)<>query b ->
    bucket_path (advance b i) qs -> bucket_path i qs.

Theorem exhausted_bucket i qs a : bucket_path i qs -> probe_run b v odd i a ->
  (a = -1 <-> forall x, In x qs -> ~usable b v odd x).
Proof.
  intros bucket; induction bucket; intro trace.
  - assert (a= -1) by (inversion trace;subst;lia). simpl;intuition.
  - destruct (chain_complete b v odd _ _ H1) as [c [run [miss _]]].
    assert (same_answer : a = c) by (eapply chain_deterministic; [eapply probe_at_match; eauto|exact run]).
    now rewrite same_answer.
  - apply IHbucket. eapply probe_at_miss;eauto.
Qed.

Corollary physical_lookup i qs a : bucket_path i qs -> probe_run b v odd i a ->
  (forall q, 0<=q<n -> usable b v odd q -> In q qs) ->
  (forall q, In q qs -> 0<=q<n) ->
  (a = -1 <-> forall q, 0<=q<n -> ~usable b v odd q).
Proof.
  intros path run complete range; rewrite (exhausted_bucket _ _ _ path run).
  split; intros miss q present yes.
  - exact (miss q (complete q present yes) yes).
  - exact (miss q (range q present) yes).
Qed.
Corollary unique_lookup k e : 0<=k<64 -> mask b=Int64.repr (Z.ones k) ->
  0<=e<2^k -> Znth e (slots b)<0 ->
  exists! a, probe_run b v odd (origin b) a.
Proof.
  intros K M E empty; destruct (finite_lookup k e K M E empty) as [a run].
  exists a; split; [assumption|]. intros other trace. eapply probe_deterministic; eauto.
Qed.
End Termination.
