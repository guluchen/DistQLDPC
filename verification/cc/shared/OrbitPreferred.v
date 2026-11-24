(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra perm.
Require Import LeafMatrix MinimumPrefix LevelSearch OrbitLevel TiebreakTarget.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.

Section Seeds.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)).
Variable rank:'I_n->nat.
Variable rep:nat->'I_n.
Variable tail:nat->seq 'I_n.
Hypothesis transport:forall q:'I_n,exists p:{perm 'I_n},
  [ /\ p q=rep (rank q),forall a,rank (p a)=rank a &
       forall S,logical H L (indicator S)->logical H L (indicator (p @: S)) ].

(* The earliest orbit is taken over all supports at the minimum weight.
   This makes a representative-first order compatible with the exclusion
   of previously exhausted blocks even when each seed uses its own order. *)
Theorem reachable_preferred (x:'cV['F_2]_n) :
 minimum H L x -> exists i y,
 [ /\ preferred H L (rep i::tail i) y, #|support y|=#|support x|,
      rep i \in support y, (forall q,q \in support y->(i<=rank q)%N) & rank (rep i) = i ].
Proof.
move=> minx;have /set0Pn[q0 hit] := logical_nonempty (proj1 minx).
pose valid (a:'cV['F_2]_n * 'I_n) :=
  logical H L a.1 && (#|support a.1|==#|support x|)%N && (a.2 \in support a.1).
have start : valid (x,q0) by rewrite /valid /= (proj1 minx) eqxx hit.
case: (@arg_minnP _ (x,q0) valid (fun a=>rank a.2) start)=> [[z q] /=].
rewrite /valid /= => /andP[/andP[lz /eqP wz] member] earliest.
have [p [to_rep stays closed]]:=transport q.
pose S:=p @: support z.
have wt:#|S|=#|support x| by rewrite /S card_imset //;exact:perm_inj.
have iz:indicator (support z)=z by apply:binary_support_inj;rewrite support_indicator.
have good:logical H L (indicator S) by apply:closed;rewrite iz.
have mn:minimum H L (indicator S).
  split=> // y ly;rewrite support_indicator wt;exact:(proj2 minx y ly).
have rrep:rep (rank q) \in S by rewrite -to_rep;exact:imset_f.
have [y [best same]]:=preferred_exists (rep (rank q)::tail (rank q)) mn.
rewrite support_indicator wt in same.
exists (rank q),y;split=> //.
- case E:(rep (rank q) \in support y)=> //.
  have prior:=proj2 best (indicator S) good.
  rewrite support_indicator wt same in prior;have impossible:=prior (erefl _).
  have prefix_same (a:'I_n) : a \in [::] -> (a \in S)=(a \in support y) by [].
  have favors:=@first_wins _ [::] (rep (rank q)) (tail (rank q)) S (support y)
                  prefix_same rrep (negbT E).
  by move:impossible;rewrite leqNgt favors.
- move=> a mem;apply:(earliest (y,a));by rewrite /= (proj1 (proj1 best)) same eqxx mem.
- by rewrite -to_rep stays.
Qed.
End Seeds.
