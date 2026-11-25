(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifClosesBody VerifToggleBody VerifChildVisit VerifFlipBody
 VerifLookup NativeFlipPayload OverlapColumnState NativeDepthFlip PreparedDFSClosed PreparedDFSTerminal
 PreparedIndexBaseCases PreparedIndexWitnessLeaf PreparedCounterJoin PreparedIndexArena PreparedWitnessRegister
 PreparedFlip PreparedLeafWorkspace flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* The terminal branch borrows the current parity array and odd-check
   count; the sparse matrix and its hash table stay owned by the caller. *)
Definition terminal_sparse_part s kp (keys:list int64) (t:packed_support):=
 let v:=words_at t in
 (field_at Tsh level_type [StructField _cstart] (poff v) s *
  field_at Tsh level_type [StructField _cr] (prows v) s *
  field_at Tsh level_type [StructField _syn] (psyn v) s *
  field_at Tsh level_type [StructField _gmask] (pmasks v) s *
  field_at Tsh level_type [StructField _synkey] (Vlong (checksum t)) s *
  field_at Tsh level_type [StructField _colkey] kp s *
  data_at Tsh (tarray tuint (Zlength (offsets v))) (map (fun z=>Vint (Int.repr z)) (offsets v)) (poff v) *
  data_at Tsh (tarray tuint (Zlength (rows v))) (map Vint (rows v)) (prows v) *
  data_at Tsh (tarray tulong (Zlength (syndrome v))) (map Vlong (syndrome v)) (psyn v) *
  data_at Tsh (tarray tulong (Zlength (masks v))) (map Vlong (masks v)) (pmasks v) *
  data_at Tsh (tarray tulong (Zlength keys)) (map Vlong keys) kp)%logic.
Definition trace_and_blocks s cp bp (blocks cells:list int):=
 (field_at Tsh level_type [StructField _blk] bp s *
  data_at Tsh (tarray tuint (Zlength blocks)) (map Vint blocks) bp *
  field_at Tsh level_type [StructField _cur] cp s *
  data_at Tsh (tarray tint (Zlength cells)) (map Vint cells) cp)%logic.

Lemma lend_terminal_fields s cp bp kp tally w blocks cells ks t nodes counts saved:
 let v:=words_at t in 0<width v ->
 (child_fields s cp bp w blocks cells * packed_mem s kp Bare ks t *
    tally_cells s tally nodes counts * witness_register s saved)%logic =
 (budget_leaf_fields s tally (ppar v) w (odd_count t) (parities v) nodes counts (Vint saved) *
    terminal_sparse_part s kp ks t * trace_and_blocks s cp bp blocks cells)%logic.
Proof.
 intros v positive;unfold child_fields,packed_mem,toggle_mem,tally_cells,witness_register,
   budget_leaf_fields,terminal_sparse_part,trace_and_blocks.
 cbn [policy_storage];unfold v,width in *.
 rewrite parity_storage_nonempty by assumption;apply pred_ext;cancel.
Qed.

Definition terminal_frame s cp p blocks cells ks mask tab links init words base stride levels
   (outside:val->mpred):=
 (terminal_sparse_part s (pk p) ks (payload_after Bare ks init words) *
   trace_and_blocks s cp (pb p) blocks cells *
   static_leaf_index s p mask tab links * independent_leaf_counters s *
   outside s * live_arena base stride levels (Zlength words))%logic.

Lemma terminal_arena_split c s cp p budget base stride levels w blocks cells ks mask tab links init words outside saved:
 let t:=payload_after Bare ks init words in let v:=words_at t in
 let heap:=index_flip_heap c p ks mask tab links init
   (fun level=>(visit_storage level budget levels * outside level)%logic) in
 let rest:=terminal_frame s cp p blocks cells ks mask tab links init words base stride levels outside in
 0<width v ->
 (child_fields s cp (pb p) w blocks cells * weight_bounded_rows base stride levels heap w s words *
     witness_register s saved)%logic =
 (!!(w<=levels /\ physical_prefix c words) &&
  (EX nodes:int64,EX counts:list int64,!!(Zlength counts=levels) &&
      (budget_leaf_fields s budget (ppar v) w (odd_count t) (parities v) nodes counts (Vint saved)*rest)))%logic.
Proof.
 intros t v heap rest wide;unfold heap,weight_bounded_rows,depth_rows,index_flip_heap,physical_store,visit_storage,
   rest,terminal_frame.
 unfold budget_leaf_fields,terminal_sparse_part,trace_and_blocks,child_fields,packed_mem,toggle_mem,
   tally_cells,witness_register.
 cbn [policy_storage];unfold v,width in *;fold t;rewrite parity_storage_nonempty by assumption.
 apply pred_ext;Intros nodes counts;Exists nodes counts;entailer!;cancel;try apply derives_refl.
Qed.
