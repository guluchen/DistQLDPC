(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import OverlapColumnState OverlapRowState OverlapRowSpecs overlap_ast.
#[local] Existing Instance OverlapSpecs.
Local Open Scope Z_scope.
Definition view_type:=Tstruct _cc_overlap_view noattr.
Record addresses := {
 colp:val; rowp:val; rowoffp:val; qubitp:val; exemp:val; slackp:val; blockp:val;
 tightp:val; extrap:val; forbidp:val
}.
Definition signed_array (xs:list int) p:=if Z.eq_dec (Zlength xs) 0 then emp else
 data_at Tsh (tarray tint (Zlength xs)) (map Vint xs) p.
Lemma signed_live xs p:0<Zlength xs->signed_array xs p=data_at Tsh (tarray tint (Zlength xs)) (map Vint xs) p.
Proof. unfold signed_array;destruct Z.eq_dec;[lia|reflexivity]. Qed.
Definition exemptp a g := match exempt_qubits g with None=>nullval | Some _=>exemp a end.
Definition exempt_store a g := match exempt_qubits g with None=>emp | Some xs=>signed_array xs (exemp a) end.
Definition view_mem p a g st :=
 (field_at Tsh view_type [StructField _column_start] (colp a) p *
  field_at Tsh view_type [StructField _column_row] (rowp a) p *
  field_at Tsh view_type [StructField _row_start] (rowoffp a) p *
  field_at Tsh view_type [StructField _row_qubit] (qubitp a) p *
  field_at Tsh view_type [StructField _exempt] (exemptp a g) p *
  field_at Tsh view_type [StructField _slack] (slackp a) p *
  field_at Tsh view_type [StructField _blocked] (blockp a) p *
  field_at Tsh view_type [StructField _first_extra_row] (Vint (first_extra g)) p *
  field_at Tsh view_type [StructField _tight] (tightp a) p *
  field_at Tsh view_type [StructField _tight_extra] (extrap a) p *
  field_at Tsh view_type [StructField _forbidden] (forbidp a) p *
  array32 (column_offsets g) (colp a) * array32 (column_rows g) (rowp a) *
  array32 (row_offsets g) (rowoffp a) * array32 (row_qubits g) (qubitp a) * exempt_store a g *
  signed_array (slack st) (slackp a) * array32 (blocked st) (blockp a) *
  data_at Tsh tulong (Vlong (tight st)) (tightp a) *
  data_at Tsh tulong (Vlong (tight_extra st)) (extrap a) *
  data_at Tsh tulong (Vlong (forbidden st)) (forbidp a))%logic.
Definition flag_value (b:bool):=if b then Vint Int.one else Vint Int.zero.
Definition update_spec:ident*funspec :=
 DECLARE _cc_update_overlap WITH p:val,a:addresses,g:layout,q:Z,enter:bool,st:snapshot
 PRE [tptr view_type,tint,tbool]
 PROP(admissible g q enter st;is_pointer_or_null (qubitp a);is_pointer_or_null (blockp a))
 PARAMS(p;Vint (Int.repr q);flag_value enter) SEP(view_mem p a g st)
 POST [tvoid] PROP() RETURN() SEP(view_mem p a g (after_column g q enter st)).
