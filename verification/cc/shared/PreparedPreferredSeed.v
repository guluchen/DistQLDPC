(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra perm.
Require Import LeafMatrix MinimumPrefix LevelSearch TiebreakTarget OrbitPreferred
 VerifRootAdmission VerifRootCall SeedLoopModel SeedExecution RootDriver SeedPolicyView
 OverlapColumnState OverlapChildState EnabledCall PreparedSeed PreparedLevelStorage PreparedSeedResult
 PreparedSourceDriver PreparedDepthSpec PreparedInteriorReport PreparedExhaustionEvidence
 PreparedChildPrefix PreparedPCMLeafVisit PreparedMatrixPath.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Seeds.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (rank:'I_n->nat) (rep:nat->'I_n) (tail_order:nat->seq 'I_n)
 (by_seed:Integers.int->seq 'I_n) (e:seed_level) (initial:root_state).
Definition preferred_by_root (words:seq Integers.int) (x:'cV['F_2]_n):Prop:=
 if words is first::_ then preferred H G (by_seed first) x else False.
Lemma extending_keeps_root_preference (parent:seq 'I_n) (a:'I_n) x:
 preferred_by_root (literal_path parent) x ->
 preferred_by_root (literal_path parent++[::Int.repr (Z.of_nat a)]) x.
Proof. by case:parent. Qed.
Let report:=root_projection (recursive_report H S G preferred_by_root (weight e)).
Let schedule:=PreparedSourceDriver.schedule e report initial.
Hypotheses (nfit:(Z.of_nat n<=Int.max_signed)%coqZ)
 (slots:forall q:'I_n,(rank q<seed_slots schedule)%N)
 (numbers:forall i,(i<seed_slots schedule)%N -> root_number e (Z.of_nat i)=Z.of_nat (rep i))
 (orders:forall i,(i<seed_slots schedule)%N -> by_seed (Int.repr (Z.of_nat (rep i)))=rep i::tail_order i)
 (transport:forall q:'I_n,exists p:{perm 'I_n},[ /\ p q=rep (rank q),forall a,rank (p a)=rank a &
    forall T,logical H G (indicator T)->logical H G (indicator (p @: T)) ]).

(* A physical admission invariant. It refers only to the selected
   representative, the visited orbit blocks and the resulting free qubits. *)
Hypothesis admits_earliest:forall i y st,(i<seed_slots schedule)%N ->
 PreparedSourceDriver.reached e report initial (Z.of_nat i) st ->
 preferred H G (rep i::tail_order i) y -> rep i \in support y ->
 (forall b,b \in support y -> (i<=rank b)%N) -> rank (rep i) = i ->
 let q:=Z.of_nat (rep i) in let active:=active_at e st q in
 let entered:=after_column (geometry (root_at e st q)) q true (selected active q) in
 available active q=true /\ support y :\ rep i \subset @available_now n entered.

Theorem exhausted_native_orbits_exclude_distance stop:
 (0<=weight e<=Z.of_nat n)%coqZ -> reported_stop schedule stop 0%coqZ ->
 weight e<>Z.of_nat (distance_index H G).
Proof.
 move=> bound finished same.
 case any:([exists x:'cV['F_2]_n,logical H G x]).
 - have /existsP[x found]:=any.
   have [z [best d]]:=@distance_index_spec m n k H G (ex_intro _ x found).
   have [i [y [pref equal seed earliest leader]]]:=@reachable_preferred m n k H G rank rep tail_order transport z best.
   have within:(i<seed_slots schedule)%N by rewrite -leader;exact:(slots (rep i)).
   have pos:=@completed_positions schedule stop finished i (elimT ltP within).
   have [result [st [final [path [left [reached [observation endstate]]]]]]]:=pos.
   have [on free]:=admits_earliest within reached pref seed earliest leader.
   have [_ [_ [_ [_ run]]]]:=observation.
   rewrite (numbers within) in run;have [child _]:=run on.
   have [keeps _]:=child.
   have head_ok:preferred_by_root [::Int.repr (Z.of_nat (rep i))] y by rewrite /preferred_by_root (orders within).
   have wt:Z.of_nat #|support y|=weight e by rewrite equal -d same.
   have set_ok:@prefix_set n [::Int.repr (Z.of_nat (rep i))]=[set rep i].
   { change (@prefix_set n (literal_path [::rep i])=[set rep i]);rewrite literal_prefix_set //.
     apply/setP=>q;by rewrite !inE. }
   have cannot:=keeps y head_ok (proj1 pref) wt;rewrite set_ok sub1set in cannot.
   exact:(cannot seed free (erefl _)).
 - have none:forall x,~~logical H G x by apply/existsPn;rewrite any.
   have impossible:=@distance_index_empty m n k H G none;rewrite impossible in same;lia.
Qed.
End Seeds.
