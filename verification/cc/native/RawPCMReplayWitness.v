(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto raw_pcm_ast RawPCMPrimitives RawPCMReplayChecks.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import PreparedObservedWitness PreparedReplaySyndrome.
#[local] Existing Instance RawPCMComposites.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section PhysicalReplay.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(k,n)).
Variables (cells:seq bool) (cur:seq Integers.int) (weight:Z).
Hypotheses (rows:(Z.of_nat m<=Int.max_signed)%coqZ) (width:(Z.of_nat n<=Int.max_signed)%coqZ)
 (bytes:Zlength cells=(Z.of_nat m*Z.of_nat n)%coqZ)
 (row_major:forall (r:'I_m) (q:'I_n),Znth (Z.of_nat r*Z.of_nat n+Z.of_nat q)%coqZ cells=(H r q!=0))
 (witness:stored_css_prefix H S weight cur).

(* A stored physical certificate implies every test needed by the real
   nested C loops. No separate premise about the computed XOR is needed. *)
Theorem witness_passes_native_check_rows {Espec:OracleKind} s checks same cp buf sa sp:
 readable_share sa -> readable_share sp ->
 let memory:=(matrix_bytes sa checks buf (Z.of_nat m) (Z.of_nat n) cells *
   replay_trace sp s cp weight cur)%logic in
 let loc:=replay_loc s checks same in
 semax (func_tycontext f_replay raw_vars replay_check_calls [::])
 (PROPx [::] (LOCALx loc (SEPx [::memory]))) replay_checks
 (normal_ret_assert (PROPx [::] (LOCALx loc (SEPx [::memory])))).
Proof.
 move=>readable_a readable_p memory loc;have [length _ _ [size _]]:=witness.
 have maxweight:=max_card (LeafMatrix.support (LevelSearch.indicator (@PreparedChildPrefix.prefix_set n
   (PreparedDepthSpec.active_prefix weight cur)))).
 rewrite card_ord in maxweight;have small:=elimT leP maxweight.
 apply:every_physical_syndrome_zero;try assumption;try lia.
 - exact:(stored_signed_coordinate width witness).
 - move=>r valid;have in_rows:(Z.to_nat r<m)%N by apply/ltP;lia.
   pose i:'I_m:=Ordinal in_rows.
   have address:Z.of_nat i = r by rewrite /i /= Z2Nat.id;lia.
   rewrite -address;exact:(replay_of_stored_witness width row_major witness i).
Qed.
End PhysicalReplay.
