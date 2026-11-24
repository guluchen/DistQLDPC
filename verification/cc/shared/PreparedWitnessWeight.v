(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch CSSLevelDistance DetectorRank SparseSyndrome PreparedMatrixPath.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.

Lemma singleton_coordinate n (q r:'I_n):
 (r \in support (delta_mx q 0:'cV['F_2]_n))=(r==q).
Proof. rewrite /support inE mxE eqxx andbT;case:(r==q)=> //. Qed.

Lemma distinct_path_changes_members n (r:'I_n) path (x:'cV['F_2]_n):
 uniq path -> (r \in support (vector_on x path))=xorb (r \in path) (r \in support x).
Proof.
elim:path x=> [|q tail ih] x //= /andP[fresh unique].
change ((r \in support (vector_on (x+delta_mx q 0) tail))=xorb (r \in q::tail) (r \in support x)).
rewrite ih // sum_support_bit singleton_coordinate inE.
case same:(r==q).
- move/eqP:same=> ->;rewrite (negbTE fresh) in_cons eqxx;by case:(x q 0!=0).
- rewrite in_cons same /=;by case:(r \in tail);case:(x r 0!=0).
Qed.

Theorem selected_path_weight n (path:seq 'I_n):
 uniq path -> #|support (vector_on (0:'cV['F_2]_n) path)|=size path.
Proof.
move=> unique;have same:support (vector_on (0:'cV['F_2]_n) path)=[set r in path].
{ apply/setP=>r;rewrite distinct_path_changes_members // support_zero !inE;by case:(r \in path). }
by rewrite same cardsE (card_uniqP unique).
Qed.

Theorem witnessed_half_distance_bound m s k n (H:'M['F_2]_(m,n)) (S:'M['F_2]_(s,n)) (G:'M['F_2]_(k,n)) path:
 H*m S^T=0 -> G*m S^T=0 -> (\rank (col_mx H G)+\rank S=n)%N -> uniq path ->
 let x:=vector_on (0:'cV['F_2]_n) path in logical H G x ->
 [ /\ H*m x=0, ~~(x^T<=S)%MS, #|support x|=size path & (distance_index H (detectors S)<=size path)%N ].
Proof.
move=> orthH orthG shape unique x found.
have valid:=found;rewrite (@validated_logical m s k n H S G orthH orthG shape x) in valid.
have /andP[/eqP kernel nontrivial]:=valid;move:nontrivial;rewrite detector_rowspan=>outside.
have weight:=selected_path_weight unique;fold x in weight.
split=> //;rewrite -weight;exact:distance_index_lower valid.
Qed.
