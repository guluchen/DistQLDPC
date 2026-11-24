(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast VerifDetected VerifChildVisit EnabledCall OverlapView OverlapColumnState
 OverlapSharedBlocks SeedBlockView SeedBlockModel SeedPolicyView VerifSeedMove SeedSharedView VerifSeedBranch
 RootOwnerMemory SeedOrbitStorage ActualOrbitCommit LiveRootPolicy UniversalRootSearch OrbitHeapLoan PreparedOwnerLoan PreparedSeedDispatch PreparedOverlapCalls.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition registered_block p fp:=
 (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _block_done] fp p *
 func_ptr' (snd exhausted_spec) fp)%logic.
Definition pending_block c b fp:=
 (blocks_at (callback_owner c) b * registered_block (nested_policy (nested c)) fp *
 field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _block_start] (offset_addr b) (nested_policy (nested c)) *
 field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _block] (member_addr b) (nested_policy (nested c)))%logic.
Definition shared_root c s cp w path run:=
 (dynamic_field c * level_links s cp (blockp (conn c)) w path *
 overlap_private (callback_owner c) (conn c) (geometry c) run)%logic.
Definition outside_block c s cp w path seed_fp run:=
 (seed_field (nested_policy (nested c)) seed_fp * dynamic_field c *
 field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s *
 field_at Tsh level_type [StructField _cur] cp s *
 data_at Tsh (tarray tint (Zlength path)) (map Vint path) cp *
 overlap_private (callback_owner c) (conn c) (geometry c) run)%logic.

Lemma specialize_root_storage c s cp w path run ex:
 shared_root c s cp w path run=(root_storage (at_seed c ex) s cp w path run * reusable_pointer c)%logic.
Proof.
 unfold shared_root,root_storage;rewrite (specialize_owned_field c ex).
 change (overlap_private (callback_owner (at_seed c ex)) (conn (at_seed c ex)) (geometry (at_seed c ex)) run)
   with (overlap_private (callback_owner c) (conn c) (geometry c) run).
 change (conn (at_seed c ex)) with (conn c);apply pred_ext;cancel.
Qed.

Theorem lend_exhausted_orbit c s cp w path sf bf lp basep fbp g b limits st run :
 ((seed_owner c sf lp basep fbp (dynamic_rows g st) limits (live_rows st) *
    shared_root c s cp w path run) * pending_block c b bf)%logic =
 ((search_arrays s (nested_policy (nested c)) (callback_owner c) (live_arrays c lp) (live_csr c basep fbp) g b limits st *
   done_fields (nested_policy (nested c)) (callback_owner c) bf) *
   outside_block c s cp w path sf run)%logic.
Proof.
 unfold seed_owner,shared_root,pending_block,search_arrays,outside_block,live_arrays,live_csr,
  registered_block,optional_seed,seed_field,level_links,exhausted_at,traversal_slots,done_fields.
 cbn [blocked_ptr];apply pred_ext;cancel.
Qed.
