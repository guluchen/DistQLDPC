(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq ClightSelect.
Require Import seed_ast SeedPolicyView SeedExemptionState SeedColumnModel SeedBlockModel VerifSeedMove.
#[local] Existing Instance SeedC.
Local Open Scope Z_scope.

Definition initializes_row_index (s:statement) :=
 match s with Ssequence (Ssequence _ (Sset i _)) (Sloop _ _) => Pos.eqb i _i | _=>false end.
Definition inner_scan:statement:=ltac:(native_fragment initializes_row_index f_cc_seed_block_done).
Record orbit_blocks:={ block_offsets:list int; block_members:list int; offset_addr:val; member_addr:val }.
Definition blocks_at p b:=
 (field_at Tsh seed_type [StructField _block_start] (offset_addr b) p *
  field_at Tsh seed_type [StructField _block_qubit] (member_addr b) p *
  unsigned_rows (block_offsets b) (offset_addr b) * unsigned_rows (block_members b) (member_addr b))%logic.
Definition dynamic_rows g state:=Build_seed_column (col_starts g) (col_rows g) (base_order g) (exhausted_fallback state).
Definition exhausted_at p a pa g b limits st:=
 (blocks_at p b * scans_at p pa (dynamic_rows g st) * moving_at p a limits (live_rows st))%logic.
Definition before_row g limits q st i :=
 remember_column limits (base_order g) q (index_at g q) i (col_rows g) st.
Definition process_qubit g limits st word :=
 let q:=Int.unsigned word in before_row g limits q st (index_at g (q+1)).
Definition crossed_block g b limits initial lo j :=
 fold_left (process_qubit g limits) (sublist lo j (block_members b)) initial.
Lemma crossed_next g b limits initial lo j :
 0<=lo<=j -> j<Zlength (block_members b) ->
 crossed_block g b limits initial lo (j+1)=
 process_qubit g limits (crossed_block g b limits initial lo j) (Znth j (block_members b)).
Proof.
 intros;unfold crossed_block;rewrite (sublist_split lo j (j+1)),(sublist_one j),fold_left_app by lia;reflexivity.
Qed.
Definition inner_safe g limits q initial:=
 0<=q<=Int.max_signed /\ q+1<Zlength (col_starts g) /\
 0<=index_at g q<=index_at g (q+1) /\ index_at g (q+1)<=Zlength (col_rows g) /\
 forall i,index_at g q<=i<index_at g (q+1) ->
 let r:=Int.unsigned (Znth i (col_rows g)) in let st:=before_row g limits q initial i in
 0<=r<Zlength (base_order g) /\ r<Zlength (exhausted_fallback st) /\
 (0<=Int.signed (Znth r (base_order g)) -> Int.signed (Znth r (exhausted_fallback st))<0 ->
 let v:=live_rows st in r<Zlength (exempts v) /\ Zlength (exempts v)=Zlength limits /\
 q<Zlength (reference_counts v) /\ 0<=Int.signed (Znth r (exempts v))<Zlength (reference_counts v)).
Definition block_at b idx:=Int.unsigned (Znth idx (block_offsets b)).
Definition block_safe g b limits block initial:=
 0<=block<Int.max_signed /\ block+1<Zlength (block_offsets b) /\
 0<=block_at b block<=block_at b (block+1) /\ block_at b (block+1)<=Zlength (block_members b) /\
 forall j,block_at b block<=j<block_at b (block+1) ->
 inner_safe g limits (Int.unsigned (Znth j (block_members b))) (crossed_block g b limits initial (block_at b block) j).
Definition exhausted_spec:ident*funspec:=
 DECLARE _cc_seed_block_done WITH p:val,a:seed_arrays,pa:seed_column_ptrs,g:seed_column,b:orbit_blocks,
  limits:list int,block:Z,initial:exhausted_state
 PRE [tptr tvoid,tint] PROP(block_safe g b limits block initial)
 PARAMS(p;Vint (Int.repr block)) SEP(exhausted_at p a pa g b limits initial)
 POST [tvoid] PROP() RETURN() SEP(exhausted_at p a pa g b limits
   (crossed_block g b limits initial (block_at b block) (block_at b (block+1)))).
Definition BlockG:funspecs:=ltac:(with_library prog [move_spec;exhausted_spec]).
