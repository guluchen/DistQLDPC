(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import PreparedRawRank PreparedRawReduction PreparedRawPivotMap.
Set Implicit Arguments.
Unset Strict Implicit.
Import GRing.Theory.
Local Open Scope ring_scope.

Section Replay.
Variables m n:nat.
Variables (A:'M['F_2]_(m,n)) (pivot:'I_m->option 'I_n).
Hypotheses (chosen:forall i j,pivot i=Some j -> unit_column A i j)
 (unused:forall i,pivot i=None -> row i A=0).
Definition coefficients (x:'rV['F_2]_n):'rV['F_2]_m:=
 \row_i (if pivot i is Some j then x 0 j else 0).
Definition residue (x:'rV['F_2]_n):=x-coefficients x *m A.
Definition is_free (j:'I_n):=forall i,pivot i<>Some j.

Lemma extract_coefficient (c:'rV['F_2]_m) i j:pivot i=Some j -> (c*m A) 0 j=c 0 i.
Proof.
 move=>assigned;rewrite mxE (bigD1 i) //= (chosen assigned) eqxx mulr1.
 rewrite big1 ?addr0 // =>u different.
 by rewrite (chosen assigned) (negbTE different) mulr0.
Qed.
Lemma assigned_residue x i j:pivot i=Some j -> residue x 0 j=0.
Proof.
 move=>assigned;rewrite /residue mxE mxE (extract_coefficient _ assigned).
 by rewrite /coefficients mxE assigned subrr.
Qed.
Lemma rowspace_residue (x:'rV['F_2]_n):(x<=A)%MS -> residue x=0.
Proof.
 move/submxP=>[c ->];apply/rowP=>j;rewrite /residue !mxE.
 have reconstructed: (\sum_(i:'I_m) coefficients (c*m A) 0 i * A i j)
                     =\sum_(i:'I_m) c 0 i * A i j.
 { apply:eq_bigr=>i _;rewrite /coefficients mxE;case kind:(pivot i)=>[q|].
   - by rewrite (extract_coefficient c kind).
   - have cell:=congr1 (fun z:'rV['F_2]_n=>z 0 j) (unused kind).
     by move:cell=>/=;rewrite !mxE=>->;rewrite !mulr0. }
 by rewrite reconstructed subrr.
Qed.

Theorem replay_free_test (x:'rV['F_2]_n):
 (forall j,is_free j -> residue x 0 j=0) <-> (x<=A)%MS.
Proof.
 split;last by move=>inside j free;rewrite (rowspace_residue inside) mxE.
 move=>passed;have all_zero:residue x=0.
 { apply/rowP=>j;rewrite [RHS]mxE;case assigned:[exists i,pivot i==Some j].
   - move/existsP:assigned=>[i /eqP yes];exact:(assigned_residue x yes).
   - apply passed=>i yes;have present:[exists u,pivot u==Some j] by apply/existsP;exists i;rewrite yes eqxx.
     by rewrite assigned in present. }
 move/eqP:all_zero;rewrite /residue subr_eq0=>/eqP same;apply/submxP.
 by exists (coefficients x).
Qed.
End Replay.

Section Complete.
Variables m n:nat.
Variable A:'M['F_2]_(m,n).
Variable default_qubit:'I_n.
Let final:=foldl (@track_column m n) ((0%N,A),[::]) (enum 'I_n).
Definition pivot_qubit (i:'I_m):option 'I_n:=
 if (i<size final.2)%N then Some (nth default_qubit final.2 i) else None.

Theorem full_scan_replay (x:'rV['F_2]_n):
 (forall j,is_free pivot_qubit j -> residue final.1.2 pivot_qubit x 0 j=0) <-> (x<=A)%MS.
Proof.
 have [span [count units]]:=actual_pivot_columns A.
 fold final in span,count,units.
 have lookup (i:'I_m) j:pivot_qubit i=Some j -> unit_column final.1.2 i j.
 { rewrite /pivot_qubit;case live:(i<size final.2)%N;last by discriminate.
   intro eqj;injection eqj as assigned;subst j.
   apply:(units i _ live).
   by apply set_nth_default. }
 have dead (i:'I_m):pivot_qubit i=None -> row i final.1.2=0.
 { rewrite /pivot_qubit;case live:(i<size final.2)%N;first by discriminate.
   intro skipped.
   have reached:=@finished_form m n (0%N,A) (enum 'I_n) [::] (original_form A).
   have same:=@tracked_projection m n ((0%N,A),[::]) (enum 'I_n);fold final in same.
   rewrite -same in reached;have [_ [_ zeros]]:=reached.
   have rank:final.1.1=\rank A by rewrite same complete_reduction_reports_rank.
   apply/matrixP=>a j;rewrite !mxE;apply:zeros;first by rewrite cats0 mem_rev mem_enum.
   by rewrite rank -count leqNgt live. }
 rewrite (replay_free_test lookup dead) span;split=>//.
Qed.
End Complete.
