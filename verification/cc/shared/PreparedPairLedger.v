(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected EnabledCall OverlapColumnState OverlapView
 VerifLookup VerifFlipBody NativeFlipPayload HashLookup BuiltLookup PreparedOpenPair PreparedPairStorage
 PreparedClosedPair PreparedClosedPairMemory PreparedWitnessRegister.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* Both fast paths use the same register for the output length. The
   open path increments leaf2 and the closed path increments closed.
   Keep the actual ownership explicit while lending the remaining fields. *)
Definition pair_registers s (closed leaves:int64) (size:int) :=
 (field_at Tsh level_type [StructField _closed] (Vlong closed) s *
  field_at Tsh level_type [StructField _leaf2] (Vlong leaves) s * witness_register s size)%logic.
Definition pair_storage c s cp w st path t policy p ks mask tab links closed leaves size:=
 (enabled_memory c s cp w path st * packed_mem s (pk p) policy ks t *
  lookup_index s (table_book ks mask (checksum t) tab links (OverlapColumnState.blocked st)) p *
  pair_registers s closed leaves size)%logic.

Lemma lend_to_open c s cp w st path t policy p ks mask tab links closed leaves size:
 let b:=table_book ks mask (checksum t) tab links (OverlapColumnState.blocked st) in
 pair_storage c s cp w st path t policy p ks mask tab links closed leaves size =
 (active_pair c s cp w st path t policy b p leaves size *
  field_at Tsh level_type [StructField _closed] (Vlong closed) s)%logic.
Proof.
 intro b;unfold pair_storage,active_pair,pair_statistics,pair_registers,witness_register,b.
 cbn [table_book keys];apply pred_ext;cancel.
Qed.

Definition outside_closed_lookup s p mask tab links leaves :=
 (lookup_index s (table_book [] mask Int64.zero tab links []) p *
  field_at Tsh level_type [StructField _leaf2] (Vlong leaves) s)%logic.

Lemma lend_to_closed c s cp w st path t policy p ks mask tab links closed leaves size:
 pair_storage c s cp w st path t policy p ks mask tab links closed leaves size =
 (closed_pair_heap c s cp w st path t policy (pk p) ks closed size *
  outside_closed_lookup s p mask tab links leaves)%logic.
Proof.
 unfold pair_storage,closed_pair_heap,pair_registers,closed_stats,witness_register,outside_closed_lookup,lookup_index.
 cbn [table_book slots HashLookup.mask HashLookup.links];apply pred_ext;cancel.
Qed.
