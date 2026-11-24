(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix VerifRootCall VerifRootAdmission SeedLoopModel SeedExecution RootDriver
 PreparedSeed PreparedSeedResult PreparedSourceDriver PreparedDepthSpec PreparedLevelStorage
 PreparedInteriorReport PreparedObservedWitness.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section RootReturns.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (qualified:seq Integers.int->'cV['F_2]_n->Prop) (e:seed_level) (initial:root_state).
Let root_r:=root_projection (recursive_report H S G qualified (weight e)).
Definition returned_witness code st:Prop:=
 (code = 1%coqZ -> stored_css_prefix H S (weight e) (witness_path st)) /\
 (code = 3%coqZ -> exists len,(0<len<weight e)%coqZ /\ stored_css_prefix H S len (witness_path st)).

Theorem root_keeps_found_witness i code st:
 PreparedSourceDriver.left_root e root_r initial i code st -> returned_witness code st.
Proof.
 move=>[before [final [tail [left [_ [[_ [_ [_ [skipped admitted]]]] ->]]]]]].
 unfold returned_witness;cbn [PreparedSeed.returned_state witness_path].
 case entry:(available (active_at e before (root_number e i)) (root_number e i)).
 - have [report _]:=admitted entry.
   have [_ witness]:=report;exact witness.
 - have [empty _]:=skipped entry;by subst code;split;discriminate.
Qed.

Let sched:=PreparedSourceDriver.schedule e root_r initial.
Definition after_css_stop i code:mpred:=
 if Z.eq_dec code 0 then waiting sched i else
 (EX st:root_state,!!(PreparedSourceDriver.left_root e root_r initial i code st /\ returned_witness code st)
  && PreparedLevelStorage.seed_memory e st)%logic.
Lemma stopped_memory_contains_css_trace i code:
 after_stop sched i code=after_css_stop i code.
Proof.
 unfold after_stop,after_css_stop;destruct (Z.eq_dec code 0);first reflexivity.
 unfold sched,PreparedSourceDriver.schedule;cbn [returned proj_sumbool].
 apply pred_ext;Intros st;Exists st;entailer!;try apply derives_refl;try tauto.
 apply root_keeps_found_witness with (i:=i);assumption.
Qed.
End RootReturns.
