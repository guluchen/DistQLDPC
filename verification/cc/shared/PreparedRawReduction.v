(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra fingroup perm.
Require Import PreparedRawRREF.
Set Implicit Arguments.
Unset Strict Implicit.
Import GRing.Theory.
Local Open Scope ring_scope.

Section Reduction.
Variables m n:nat.
Implicit Types (A:'M['F_2]_(m,n)).
(* One successful outer iteration. The selected row is moved to the
   next basis position, then every other one in the column is cleared. *)
Definition pivot_step A (p found:'I_m) (q:'I_n):=
 let swapped:=xrow p found A in
 foldl (visit_row p q) swapped (enum 'I_m).

Lemma swapped_cell A (p found i:'I_m) j:
 xrow p found A i j=A (tperm p found i) j.
Proof. by rewrite xrowEsub mxE. Qed.
Lemma swap_involutive A (p found:'I_m):xrow p found (xrow p found A)=A.
Proof. by apply/matrixP=>i j;rewrite !swapped_cell tpermK. Qed.
Lemma swap_inside A (p found:'I_m):(xrow p found A<=A)%MS.
Proof. apply/submxP;exists (tperm_mx p found);exact:xrowE. Qed.
Lemma swap_space A (p found:'I_m):(xrow p found A:=:A)%MS.
Proof.
 apply/eqmxP/andP;split;first exact:swap_inside.
 by rewrite -{1}(swap_involutive A p found);apply:swap_inside.
Qed.

Lemma pivot_step_space A p found q:A found q= 1 ->
 (pivot_step A p found q:=:A)%MS.
Proof.
 move=>one;set B:=xrow p found A.
 have pivot:B p q= 1 by rewrite /B swapped_cell tpermL.
 have step:pivot_step A p found q=add_pivot B p q B
    by rewrite /pivot_step;exact:native_row_visits_clear_the_pivot.
 rewrite step;have [smaller larger]:=pivot_operation_preserves_span B p q.
 apply/eqmxP/andP;split.
 - apply:(submx_trans smaller);exact:swap_inside.
 - apply:(submx_trans _ larger);by rewrite (swap_space A p found) submx_refl.
Qed.

Lemma new_unit_column A p found q:A found q= 1 -> forall i,
 pivot_step A p found q i q=(i==p)%:R.
Proof.
 move=>one i;set B:=xrow p found A.
 have pivot:B p q= 1 by rewrite /B swapped_cell tpermL.
 rewrite /pivot_step (native_row_visits_clear_the_pivot B p q).
 exact:(@cleared_column m n B p q pivot i).
Qed.

Lemma earlier_unit_survives A p found q old row:
 A found q= 1 -> p!=row -> found!=row ->
 (forall i,A i old=(i==row)%:R) ->
 forall i,pivot_step A p found q i old=(i==row)%:R.
Proof.
 move=>one fresh below old_unit i;set B:=xrow p found A.
 have pivot:B p q= 1 by rewrite /B swapped_cell tpermL.
 have fixed:tperm p found row=row by rewrite tpermD.
 have already u:B u old=(u==row)%:R.
 { rewrite /B swapped_cell old_unit.
   have eql:(tperm p found u==row)=(u==row) by rewrite -{1}fixed (inj_eq perm_inj).
   by rewrite eql. }
 have off:B p old=0 by rewrite already (negbTE fresh).
 rewrite /pivot_step (native_row_visits_clear_the_pivot B p q) add_pivot_cell off mulr0 addr0.
 exact:already.
Qed.
(* Scanning in ordinal order picks the first remaining row with a one,
   including for rectangular or rank-deficient matrices. *)
Definition candidates A (k:nat) (q:'I_n):=
 filter (fun i:'I_m=>(k<=val i)%N && (A i q!=0)) (enum 'I_m).
Lemma selected_row A k q i rest:candidates A k q = i::rest ->
 (k<=i)%N /\ A i q= 1.
Proof.
 move=>same;have picked:i \in candidates A k q by rewrite same in_cons eqxx.
 move:picked;rewrite /candidates mem_filter=>/andP[/andP[after nonzero] _].
 by split;last exact:binary_unit nonzero.
Qed.

Definition scan_column (state:nat*'M['F_2]_(m,n)) (q:'I_n):=
 let: (k,A):=state in
 if (insub k : option 'I_m) is Some p then
   if candidates A k q is i::rest then (k.+1,pivot_step A p i q) else (k,A)
 else (k,A).

Lemma scan_step_space k A q:((scan_column (k,A) q).2:=:A)%MS.
Proof.
 rewrite /scan_column;case:insub=>[p|] //;case pick:(candidates A k q)=>[|i rest] //=.
 have [_ one]:=selected_row pick;exact:pivot_step_space one.
Qed.

Lemma scan_step_rank_bound k A q:(k<=m)%N -> ((scan_column (k,A) q).1<=m)%N.
Proof.
 move=>bound;rewrite /scan_column;case:insub=>[p|] //;case pick:(candidates A k q)=>[|i rest] //=.
 have [after _]:=selected_row pick;exact:leq_ltn_trans after (ltn_ord i).
Qed.

Theorem scan_all_columns state order: (state.1<=m)%N ->
 let done:=foldl scan_column state order in
 (done.1<=m)%N /\ (done.2:=:state.2)%MS.
Proof.
 elim:order state=>[|q rest ih] [k A] bound;first by split.
 have small:=scan_step_rank_bound A q bound.
 have [bound' space]:=ih (scan_column (k,A) q) small.
 split=> //;exact:(eqmx_trans space (scan_step_space k A q)).
Qed.
End Reduction.
