(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch LeafShortcut VerifClosesBody ClosureMatrix
  HashLookup HashProbe LeafAPI NativeLeafChoice SyndromeHash.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Import GRing.Theory.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section PCM.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)) (P F:{set 'I_n}).
Variables (v:close_view) (b:lookup_data) (physical:'I_n -> seq 'I_m).
Let oddrows := support (H *m indicator P).
Let odd := Z.of_nat #|oddrows|.
Let w := (#|P|).+1.
Definition pcm_completion z := exists q:'I_n,
  z=Z.of_nat q /\ q \in F /\ terminal H L w (q |: P).
Hypothesis disj : [disjoint F & P].
Hypothesis blocks : forall q:'I_n, Znth (Z.of_nat q) (blocked b)=Int.zero <-> q \in F.
Hypothesis columns : forall q:'I_n, @layout m n k H L (indicator P) q (physical q) v.
Hypothesis extent_ok : extent b=Z.of_nat n.
Variable rowkey:'I_m->int64.
Hypothesis query_ok : query b=signature rowkey oddrows.
Hypothesis keys_ok : forall q:'I_n, Znth (Z.of_nat q) (keys b)=signature rowkey (support (col q H)).
Variable qs:seq Z.
Hypothesis route : bucket_path b (origin b) qs.
Hypothesis by_key : forall q:'I_n, Znth (Z.of_nat q) (keys b)=query b -> In (Z.of_nat q) qs.
Hypothesis in_bounds : forall z, In z qs -> (0<=z<Z.of_nat n)%coqZ.

Lemma completion_key q : q \in F -> terminal H L w (q |: P) ->
   Znth (Z.of_nat q) (keys b)=query b.
Proof.
move=> free /andP[_ /andP[closed _]].
have fresh : q \notin P by rewrite (disjointFr disj free).
move: closed;rewrite (insert_indicator fresh) mulmxDr -colE addr_eq0 binary_opp=> /eqP eqcol.
by rewrite keys_ok query_ok /oddrows eqcol.
Qed.

Theorem physical_leaf_image : leaf_image pcm_completion b v odd qs.
Proof.
constructor=> //.
- move=> z;rewrite extent_ok=> range.
  have iz : (Z.to_nat z<n)%coq_nat by lia.
  pose q:'I_n := Ordinal (introT ltP iz).
  have addr : Z.of_nat q=z by rewrite /q /= Z2Nat.id;lia.
  split.
  + rewrite -addr=> u. have [free hit] := proj1 (@usable_column m n k H L P F v b physical disj blocks columns q) u.
    by exists q.
  + move=> [a [-> both]];exact: (proj2 (@usable_column m n k H L P F v b physical disj blocks columns a) both).
- move=> z _ [q [-> [allowed hit]]];exact: by_key (completion_key allowed hit).
- by rewrite extent_ok.
Qed.
End PCM.
