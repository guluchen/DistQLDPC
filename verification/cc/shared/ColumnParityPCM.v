(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch ParityPrune.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Import GRing.Theory.
Local Open Scope ring_scope.
Section PhysicalParity.
Variables m n:nat.
Variable H:'M['F_2]_(m,n).
Hypothesis odd_columns:forall q,odd #|support (col q H)|.
Lemma add_matrix_columns qs (v:'cV['F_2]_m) :
 add_columns H qs v=v+H *m (\sum_(q <- qs) delta_mx q 0).
Proof.
elim:qs v=>[|q qs IH] v.
- by rewrite big_nil mulmx0 addr0.
- by rewrite /= IH big_cons mulmxDr -colE addrA.
Qed.
Lemma indicator_from_list (qs:seq 'I_n) : uniq qs ->
 \sum_(q <- qs) (delta_mx q 0:'cV['F_2]_n) = indicator [set q in qs].
Proof.
elim:qs=>[|a qs IH] //=.
- move=> _;rewrite big_nil;apply/matrixP=> i j;by rewrite /indicator !mxE inE.
- move=> /andP[fresh rest];rewrite big_cons (IH rest).
  apply/matrixP=>i j;rewrite (ord1 j) /indicator !mxE !inE eqxx andbT.
  case E:(i==a).
  + move/eqP:E=> ->;by rewrite (negbTE fresh) addr0.
  + by rewrite add0r.
Qed.
Lemma parity_from_pcm (x:'cV['F_2]_n) :
 odd #|support (H *m x)|=odd #|support x|.
Proof.
pose qs:=enum (support x).
have ux:uniq qs:=enum_uniq _.
have sx:[set q in qs]=support x by apply/setP=>q;rewrite inE mem_enum.
have xx:indicator (support x)=x by apply:binary_support_inj;rewrite support_indicator.
have eval:=add_matrix_columns qs (0:'cV['F_2]_m).
rewrite (indicator_from_list ux) sx xx add0r in eval.
have pars:=parity_after odd_columns qs (0:'cV['F_2]_m).
have zsup:support (0:'cV['F_2]_m)=set0 by apply/setP=>q;rewrite /support !inE mxE eqxx.
by move:pars;rewrite eval zsup cards0 /= /qs -cardE.
Qed.
Lemma odd_level_empty k (L:'M['F_2]_(k,n)) w : odd w ->
 forall x,minimum H L x -> #|support x|!=w.
Proof.
move=> parity x [/andP[/eqP hx lit] _];apply/eqP=> wgt.
have eqv:=parity_from_pcm x;rewrite hx wgt parity in eqv.
have empty:support (0:'cV['F_2]_m)=set0 by apply/setP=>q;rewrite /support !inE mxE eqxx.
by rewrite empty cards0 in eqv.
Qed.
End PhysicalParity.
