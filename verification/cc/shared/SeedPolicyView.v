(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import seed_ast VerifSeedMove SeedColumnModel SeedExemptionState.
#[local] Existing Instance SeedC.
Local Open Scope Z_scope.

Record seed_column := {col_starts:list int; col_rows:list int; base_order:list int; first_block:list int}.
Record seed_column_ptrs:={ starts_addr:val; rows_addr:val; base_addr:val; first_addr:val }.
Definition flag (b:bool):=Vint (if b then Int.one else Int.zero).
Definition signed_rows (xs:list int) p := if Z.eq_dec (Zlength xs) 0 then emp
 else data_at Tsh (tarray tint (Zlength xs)) (map Vint xs) p.
Definition unsigned_rows (xs:list int) p := if Z.eq_dec (Zlength xs) 0 then emp
 else data_at Tsh (tarray tuint (Zlength xs)) (map Vint xs) p.
Lemma pos_signed xs p:0<Zlength xs ->
 signed_rows xs p=data_at Tsh (tarray tint (Zlength xs)) (map Vint xs) p.
Proof. unfold signed_rows;destruct Z.eq_dec;[lia|reflexivity]. Qed.
Lemma pos_unsigned xs p:0<Zlength xs ->
 unsigned_rows xs p=data_at Tsh (tarray tuint (Zlength xs)) (map Vint xs) p.
Proof. unfold unsigned_rows;destruct Z.eq_dec;[lia|reflexivity]. Qed.

Definition scans_at p a g :=
 (field_at Tsh seed_type [StructField _column_start; StructField _overlap] (starts_addr a) p *
  field_at Tsh seed_type [StructField _column_row; StructField _overlap] (rows_addr a) p *
  field_at Tsh seed_type [StructField _base] (base_addr a) p *
  field_at Tsh seed_type [StructField _fallback] (first_addr a) p *
  unsigned_rows (col_starts g) (starts_addr a) * unsigned_rows (col_rows g) (rows_addr a) *
  signed_rows (base_order g) (base_addr a) * signed_rows (first_block g) (first_addr a))%logic.
Definition moving_at p a limits s:=seed_move_mem p a (exempts s) limits (reference_counts s) (forbidden_events s).
Lemma move_matches p a limits s row next:
 moved_mem p a (exempts s) limits (reference_counts s) (forbidden_events s) row next=
 moving_at p a limits (replace_exemption limits s row next).
Proof.
 unfold moved_mem,moving_at,replace_exemption.
 destruct (Int.eq (Znth row (exempts s)) (Int.repr next));[reflexivity|].
 destruct (Int.eq (Znth row limits) Int.zero);reflexivity.
Qed.

Definition index_at g q:=Int.unsigned (Znth q (col_starts g)).
Definition prefix g limits enter seed initial i :=
 visited_seed_rows limits (base_order g) (first_block g) seed enter initial (index_at g seed) i (col_rows g).
Definition column_safe g limits enter seed initial:=
 0<=seed<Int.max_signed /\ seed+1<Zlength (col_starts g) /\
 0<=index_at g seed<=index_at g (seed+1) /\ index_at g (seed+1)<=Zlength (col_rows g) /\
 forall i,index_at g seed<=i<index_at g (seed+1) ->
 let r:=Int.unsigned (Znth i (col_rows g)) in let st:=prefix g limits enter seed initial i in
 0<=r<Zlength (base_order g) /\ r<Zlength (first_block g) /\
 (0<=Int.signed (Znth r (base_order g)) ->
  let next:=seed_choice (base_order g) (first_block g) r seed enter in
  r<Zlength (exempts st) /\ Zlength (exempts st)=Zlength limits /\ 0<=next<=Int.max_signed /\
  next<Zlength (reference_counts st) /\ 0<=Int.signed (Znth r (exempts st))<Zlength (reference_counts st)).
Definition seed_visit_spec:ident*funspec:=
 DECLARE _cc_seed_exemption WITH p:val, a:seed_arrays, pa:seed_column_ptrs, g:seed_column, limits:list int,
  initial:moving_state, seed:Z, enter:bool
 PRE [tptr tvoid,tint,tbool] PROP(column_safe g limits enter seed initial)
 PARAMS(p;Vint (Int.repr seed);flag enter) SEP(scans_at p pa g;moving_at p a limits initial)
 POST [tvoid] PROP() RETURN() SEP(scans_at p pa g;moving_at p a limits (prefix g limits enter seed initial (index_at g (seed+1)))).
Definition ColumnG:funspecs:=ltac:(with_library prog [move_spec;seed_visit_spec]).
