(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit VerifClosesBody VerifFlipBody VerifLookup
 HashLookup BuiltLookup NativeFlipPayload NativeDepthFlip EnabledCall OverlapColumnState OverlapView
 PreparedPairStorage PreparedPairLedger PreparedWitnessRegister.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* The static table arrays live outside flip. Statistics and the saved
   length can change while visiting a child. They are owned only once. *)
Definition static_leaf_index s p mask tab links:=
 lookup_index s (table_book [] mask Int64.zero tab links []) p.
Definition mutable_leaf_workspace p mask tab links (frame:val->mpred) s:=
 (static_leaf_index s p mask tab links *
  (EX closed:int64,EX leaves:int64,EX size:int, pair_registers s closed leaves size) * frame s)%logic.

Definition leaf_flip_heap c policy p keys mask tab links initial frame:=
 physical_store c policy keys (pk p) initial (mutable_leaf_workspace p mask tab links frame).

Lemma unpack_leaf_owner c policy p keys mask tab links initial frame s cp w path st prefix:
 let t:=payload_after policy keys initial prefix in
 (enabled_memory c s cp w path st * leaf_flip_heap c policy p keys mask tab links initial frame s prefix)%logic =
 (!!physical_prefix c prefix &&
  (EX closed:int64,EX leaves:int64,EX size:int,
   pair_storage c s cp w st path t policy p keys mask tab links closed leaves size * frame s))%logic.
Proof.
 intro t;unfold leaf_flip_heap,physical_store,mutable_leaf_workspace,static_leaf_index,pair_storage,lookup_index,t.
 cbn [table_book slots HashLookup.mask HashLookup.links];apply pred_ext;normalize;
 Exists closed;normalize;Exists leaves;normalize;Exists size;entailer!;cancel.
Qed.
