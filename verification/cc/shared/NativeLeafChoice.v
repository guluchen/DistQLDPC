(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch LeafShortcut ClosureMatrix HashLookup HashProbe VerifClosesBody.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Import GRing.Theory.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Lemma insert_indicator n (P:{set 'I_n}) q : q \notin P ->
  indicator (q |: P) = indicator P + delta_mx q 0.
Proof.
move=> fresh;apply/matrixP=> i j;rewrite (ord1 j) /indicator !mxE !inE eqxx andbT.
destruct (i == q) eqn:Hiq.
- move/eqP: Hiq=> ->;by rewrite eqxx (negbTE fresh) /= add0r.
- by rewrite Hiq /= addr0.
Qed.

Section Lookup.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)) (P F:{set 'I_n}).
Variables (v:close_view) (b:lookup_data) (physical:'I_n -> seq 'I_m).
Let odd := Z.of_nat #|support (H *m indicator P)|.
Let wt := (#|P|).+1.
Hypothesis unselected : [disjoint F & P].
Hypothesis blocks : forall q : 'I_n, Znth (Z.of_nat q) (blocked b)=Int.zero <-> q \in F.
Hypothesis columns : forall q : 'I_n, @layout m n k H L (indicator P) q (physical q) v.

Lemma usable_column (q:'I_n) :
  usable b v odd (Z.of_nat q) <-> q \in F /\ terminal H L wt (q |: P).
Proof.
rewrite /usable (blocks q) (closes_value_pcm (columns q)).
split.
- move=> [free hit];split=> //. have fresh : q \notin P by rewrite (disjointFr unselected free).
  rewrite /terminal /wt cardsU1 (negbTE fresh) add1n eqxx /= /logical insert_indicator //.
  by case ok: ((_ == 0) && (_ != 0)) in hit *.
- move=> [free accept];split=> //. have fresh : q \notin P by rewrite (disjointFr unselected free).
  move: accept;rewrite /terminal /wt cardsU1 (negbTE fresh) add1n eqxx /= /logical insert_indicator //.
  by case: ((_ == 0) && (_ != 0)).
Qed.

Variable answer:Z.
Variable bucket:seq Z.
Hypothesis probe : probe_run b v odd (origin b) answer.
Hypothesis traversed : bucket_path b (origin b) bucket.
Hypothesis contains_all : forall z, (0<=z<Z.of_nat n)%coqZ -> usable b v odd z -> In z bucket.
Hypothesis members_valid : forall z, In z bucket -> (0<=z<Z.of_nat n)%coqZ.

(* A complete physical hash search misses iff the executable abstract
   one-move search has no accepting continuation, even with collisions. *)
Theorem native_leaf_misses : answer=(-1)%coqZ <-> ~~ last_move H L wt P F.
Proof.
have missing : answer=(-1)%coqZ <-> forall z, (0<=z<Z.of_nat n)%coqZ -> ~usable b v odd z.
  eapply physical_lookup;eassumption.
rewrite missing;split.
- move=> none;apply/hasPn=> q allowed;move: allowed;rewrite mem_enum=> free.
  apply/negP=> accept.
  have bound := elimT ltP (ltn_ord q).
  exact: (none (Z.of_nat q) ltac:(lia) (proj2 (usable_column q) (conj free accept))).
- move/hasPn=> none z valid found.
  have ix : (Z.to_nat z<n)%coq_nat by lia.
  pose q : 'I_n := Ordinal (introT ltP ix).
  have eqz : Z.of_nat q=z by rewrite /q /= Z2Nat.id;lia.
  have [free accept] := proj1 (usable_column q) ltac:(rewrite eqz;exact found).
  apply: (negP (none q _)) accept. by rewrite mem_enum.
Qed.
Lemma chosen_in_bucket i qs a : bucket_path b i qs -> probe_run b v odd i a ->
  a<>(-1)%coqZ -> In a qs.
Proof.
move=> route. induction route as [i empty|i qs pos same chain|i qs pos other more IH]; intros run success.
- inversion run;subst;lia.
- have [c [trace [_ picked]]] := @chain_complete b v odd _ _ chain.
  have found := @probe_at_match b v odd i a run pos same.
  have same_answer : c=a := @chain_deterministic b v odd _ _ _ trace found.
  subst c; exact: picked success.
- apply: IH _ success; exact: (@probe_at_miss b v odd i a run pos other).
Qed.

Theorem native_leaf_found : answer<>(-1)%coqZ ->
  exists q:'I_n, answer=Z.of_nat q /\ q \in F /\
    (#|q |: P| == wt)%N /\ H *m indicator (q |: P)=0 /\ L *m indicator (q |: P)!=0.
Proof.
move=> found.
have inside := chosen_in_bucket traversed probe found.
have range := members_valid inside.
have isusable : usable b v odd answer.
  have [bad|[_ ok]] := @probe_result b v odd _ _ probe;[contradiction|exact ok].
have ix : (Z.to_nat answer<n)%coq_nat by lia.
pose q:'I_n := Ordinal (introT ltP ix).
have addr : Z.of_nat q=answer by rewrite /q /= Z2Nat.id;lia.
have [free /andP[weight /andP[/eqP closed detected]]] :=
  proj1 (usable_column q) ltac:(rewrite addr;exact isusable).
by exists q; rewrite addr; repeat split.
Qed.
End Lookup.
