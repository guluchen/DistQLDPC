(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra fingroup perm.
Require Import PreparedRawRREF PreparedRawReduction PreparedRawRank.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.

Section Map.
Variables m n:nat.
Implicit Types (A:'M['F_2]_(m,n)).
(* Kept in increasing pivot-row order. The C array contains the inverse
   association: pivot[q] is the index at which q was appended, or -1. *)
Definition track_column (state:(nat*'M['F_2]_(m,n))*seq 'I_n) (q:'I_n):=
 let result:=scan_column state.1 q in
 (result,if (state.1.1<result.1)%N then rcons state.2 q else state.2).
Definition recorded A k (cols:seq 'I_n):Prop:=
 size cols=k /\ forall i:'I_m,forall j:'I_n,(i<k)%N -> nth j cols i=j -> unit_column A i j.

Lemma preserve_recorded A k cols q:recorded A k cols ->
 let next:=track_column ((k,A),cols) q in recorded next.1.2 next.1.1 next.2.
Proof.
 move=>[count units];rewrite /track_column /= /scan_column.
 case:insubP=>[p inside pk|past];last by rewrite /= ltnn;split.
 case pick:(candidates A k q)=>[|found rest] /=;first by rewrite ltnn;split.
 rewrite ltnSn /recorded size_rcons count;split=> //.
 have [after one]:=selected_row pick.
 move=>i j;rewrite ltnS leq_eqVlt=>/orP[/eqP last|earlier].
 - rewrite nth_rcons count last ltnn eqxx=> qj;subst j.
   have ->:i=p by apply:val_inj;rewrite pk.
   exact:new_unit_column one.
 - rewrite nth_rcons count earlier=>at_old.
   have distinct:p!=i by apply/eqP=>same;move:earlier;rewrite -pk same ltnn.
   have below:found!=i by apply/eqP=>same;move:after;rewrite same leqNgt earlier.
   exact:(earlier_unit_survives one distinct below (units i j earlier at_old)).
Qed.

Lemma tracked_projection state order:
 (foldl track_column state order).1=foldl (@scan_column m n) state.1 order.
Proof. by elim:order state=>[|q rest ih] [st cols] //=;rewrite ih. Qed.
Lemma recorded_after_scan state order:
 recorded state.1.2 state.1.1 state.2 ->
 let done:=foldl track_column state order in recorded done.1.2 done.1.1 done.2.
Proof.
 elim:order state=>[|q rest ih] [[k A] cols] //= before.
 exact:(ih (track_column ((k,A),cols) q) (preserve_recorded q before)).
Qed.
Theorem actual_pivot_columns A:
 let result:=foldl track_column ((0%N,A),[::]) (enum 'I_n) in
 (result.1.2:=:A)%MS /\ size result.2=\rank A /\
 forall i:'I_m,forall j:'I_n,(i<size result.2)%N ->
      nth j result.2 i=j -> unit_column result.1.2 i j.
Proof.
 move=>result.
 have start:recorded A 0 [::] by split.
 have [count units]:=@recorded_after_scan ((0%N,A),[::]) (enum 'I_n) start.
 have same:result.1=foldl (@scan_column m n) (0%N,A) (enum 'I_n) by apply tracked_projection.
 have [_ span]:=@scan_all_columns m n (0%N,A) (enum 'I_n) (leq0n m).
 split;first by rewrite same.
 change (size result.2=result.1.1) in count.
 split;first by rewrite count same complete_reduction_reports_rank.
 by rewrite count.
Qed.
End Map.
