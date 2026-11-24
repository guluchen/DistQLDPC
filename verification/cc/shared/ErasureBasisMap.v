(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch ErasureElimination ErasureBacksub ColumnParityPCM.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Import GRing.Theory.
Local Open Scope ring_scope.
Section Build.
Variables m k:nat.
Definition matrix_of (a:'I_m->'cV['F_2]_k) : 'M['F_2]_(k,m) :=
 \matrix_(i,j) a j i 0.
Lemma assignment_col a j : col j (matrix_of a)=a j.
Proof. apply/matrixP=>r t;by rewrite (ord1 t) /matrix_of !mxE. Qed.
Lemma assignment_sum a (xs:seq 'I_m):
 matrix_of a *m (\sum_(i <- xs) (delta_mx i 0:'cV['F_2]_m))=\sum_(i <- xs) a i.
Proof. elim:xs=>[|i xs IH];by rewrite ?big_nil ?mulmx0 ?big_cons ?mulmxDr -?colE ?assignment_col ?IH. Qed.
Lemma assignment_equation a (e:pivot_eq m k):
 matrix_of a *m indicator (row_set e)=value a e.
Proof.
pose S:=row_set e;pose qs:=enum S.
have same:[set i in qs]=S by apply/setP=>i;rewrite inE mem_enum.
have R:=assignment_sum a qs.
rewrite (indicator_from_list (enum_uniq S)) same in R.
move:R;rewrite /qs big_enum;done.
Qed.
Definition entry (e:pivot_eq m k) : labelled m k := (indicator (row_set e),rhs e).
Theorem solved_basis (eqs:seq (pivot_eq m k)) a : triangular eqs ->
 forall u,List.In u (map entry eqs) -> satisfies (matrix_of (backsub eqs a)) u.
Proof.
move=> tri u member;have [e [<- ine]]:=proj1 (List.in_map_iff _ _ _) member.
rewrite /satisfies /entry /= assignment_equation;exact:(@backsub_solves m k eqs a tri e ine).
Qed.

(* Earlier pivot columns need only stay represented in the final basis.
   A new physical column reduces either to a zero/zero pair or to a
   represented pivot. Both cases certify its equation before any XOR. *)
Theorem original_column
  (eqs:seq (pivot_eq m k)) (initial:'I_m->'cV['F_2]_k)
  (pivot:labelled m k->'I_m) (used:seq (labelled m k)) (b:labelled m k) :
 triangular eqs -> (forall c,List.In c used-> List.In c (map entry eqs)) ->
 let residual:=foldl (fun x u=>reduce_one pivot u x) b used in
 (residual=(0,0) \/ List.In residual (map entry eqs)) ->
 satisfies (matrix_of (backsub eqs initial)) b.
Proof.
move=> tri covered /= finish.
have basis:=@solved_basis eqs initial tri.
have old:forall u,List.In u used->satisfies (matrix_of (backsub eqs initial)) u by move=>u /covered;apply:basis.
apply:(proj1 (@reduce_columns m k pivot (matrix_of (backsub eqs initial)) used b old)).
case:finish=>[->|known];last exact:basis known.
by rewrite /satisfies /= mulmx0.
Qed.
End Build.
