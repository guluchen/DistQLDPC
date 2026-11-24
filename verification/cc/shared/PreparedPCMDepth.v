(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import VerifDetected VerifChildVisit EnabledCall OverlapColumnState VerifClosesBody VerifFlipBody
 RedundantState NativeFlipPayload PreparedFlip PreparedSeedDispatch PreparedDepthSpec NativeDepthFlip PhysicalPrefixInvariant.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Delimit Scope Z_scope with coqZ.

Theorem body_flip_from_one_pcm m (inc:Z->seq 'I_m) c p bits keys addr initial workspace:
 nested_policy (nested c)=policy_ptr p -> redundant_option bits p ->
 (Z.of_nat m<Int.max_signed)%coqZ ->
 (forall q,column_in c q -> uniq (inc q)) ->
 (forall q,column_in c q -> Forall (fun r=>(Z.of_nat m<=Int.unsigned r)%coqZ) (extra_rows p q)) ->
 pcm_state inc (column_in c) p keys initial ->
 semax_body prepared_vars PreparedFlip.FlipGprog f_flip
   (depth_flip c (physical_store c p keys addr initial workspace) bits).
Proof.
move=> owner redundant size unique high start;apply body_flip_any_depth=> //.
have pos:forall q,column_in c q -> (0<=q)%coqZ by move=>q [[ok _] _].
move=>path q allowed member;apply pcm_state_pair with (m:=m) (inc:=inc) (usable:=column_in c)=> //.
unfold payload_after;apply pcm_prefix with (inc:=inc) (usable:=column_in c)=> //.
Qed.
