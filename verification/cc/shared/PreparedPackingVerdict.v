(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch IndexPacking ChargeBound NativePackingScan
 OverlapColumnState PreparedMatrixPath PreparedChildPrefix PreparedPCMLeafVisit PreparedInteriorReport.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section AtNode.
Variables m n r k checks:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (extra:'M['F_2]_(checks,n)) (inc:'I_checks->seq 'I_n) (ids:seq 'I_n)
 (st:snapshot) (order:seq 'I_checks) (remaining:nat)
 (qualified:seq Integers.int->'cV['F_2]_n->Prop).
Let P:=[set a:'I_n | a \in ids].
Let F:=@available_now n st.
Let oddrows:=support (extra*m indicator P).
Let w:=Z.of_nat (size ids+remaining)%N.
Let incidence:=NativePackingScan.neighbors inc.
Hypotheses (distinct:uniq ids) (dims:(Z.of_nat n<=Int.max_signed)%coqZ)
 (consequence:forall x:'cV['F_2]_n,H*m x=0 -> extra*m x=0)
 (covers:forall j q,extra j q!=0 -> q \in inc j).

(* This also permits a redundant check matrix obtained by adding
   original rows. A compatible minimum must spend one of its remaining
   qubits on every odd check in that matrix. *)
Lemma residual_cover x:
 minimum H G x -> Z.of_nat #|support x|=w -> P \subset support x ->
 let T:=support x :\: P in #|T|=remaining /\
 forall j,j \in oddrows -> exists2 q, q \in T & q \in incidence j.
Proof.
 move=> [/andP[/eqP closed _] _] weight sub T;split.
 - have count:#|P|=size ids by rewrite /P cardsE (card_uniqP distinct).
   have total:#|support x|=(#|P|+remaining)%N by apply Nat2Z.inj;rewrite count;exact weight.
   have split_count:=cardsID P (support x);have eqset:support x :&: P = P:=elimT setIidPr sub.
   rewrite eqset total in split_count;exact: addnI split_count.
 - move=> j;rewrite /oddrows /support inE=>active.
   have within:support (indicator P) \subset support x by rewrite support_indicator.
   have [q [left hit]]:=@odd_row_hits_residual checks n extra (indicator P) x j within (consequence closed) active.
   exists q;[by rewrite /T -(support_indicator P)|by rewrite /incidence /NativePackingScan.neighbors inE covers].
Qed.

Theorem failing_pack_or_charge_returns_empty stamp marks marked charges capacity tail:
 let counters:=blocked st in
 (forall j,(Zlength (encoded inc j)<=Int.max_unsigned)%coqZ) ->
 @tags_for n stamp marks marked ->
 {subset order <= oddrows} ->
 (forall q,q \in F -> (\sum_(j in oddrows) load incidence charges j q<=capacity)%N) ->
 ((cpu_scan inc counters stamp remaining order marks 0=false) \/
  (remaining*capacity<\sum_(j in oddrows) charges j)%N) ->
 recursive_result H S G qualified w st (literal_path ids) 0%coqZ tail.
Proof.
 move=>counters width tags only_odd feasible cut;split;last by split;discriminate.
 rewrite literal_prefix_set //;move=>x _ best weight inside free.
 have [count cover]:=residual_cover best weight inside.
 pose T:=support x :\: P;move:cut=>[pruned|expensive].
 - have unsigned:(Z.of_nat n<=Int.max_unsigned)%coqZ by move:dims;change Int.max_signed with 2147483647%coqZ;
     change Int.max_unsigned with 4294967295%coqZ;lia.
   have size_ok:(#|T|<=remaining)%N by rewrite count.
   have allowed:=@scan_keeps_target _ _ incidence F T oddrows remaining free
     size_ok cover order marked 0 only_odd (leq0n _).
   rewrite (@agrees_with_packing n _ inc F counters stamp unsigned (@available_in_view n st)
      width remaining order marks marked 0 tags) in pruned.
   by rewrite pruned in allowed.
 - have bound:=@charge_bound _ _ oddrows T incidence charges capacity cover
      (fun q used=>feasible q (subsetP free q used)).
   by move:expensive;rewrite -count ltnNge bound.
Qed.
End AtNode.
