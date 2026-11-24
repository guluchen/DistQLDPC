(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require Import ClightSelect level_ast VerifDetected VerifChildVisit OverlapColumnState.

(* Call the C++ policy shim through its actual owner and function pointer.
   The mutable state can share block counts across several tight rows. *)
Definition callback_contract owner g (storage:snapshot->mpred):funspec :=
 WITH st:snapshot,q:Z,enter:bool
 PRE [tptr tvoid,tint,tbool]
 PROP(is_pointer_or_null owner;admissible g q enter st)
 PARAMS(owner;Vint (Int.repr q);Vint (if enter then Int.one else Int.zero))
 SEP(storage st)
 POST [tvoid] PROP() RETURN() SEP(storage (after_column g q enter st)).
Definition callback_fields p owner fp :=
 (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _overlap] fp p *
  field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _owner] owner p)%logic.
Definition stmt_for tmp (stmt:statement):=
 match stmt with
 | Sifthenelse (Etempvar b _) (Ssequence (Sset f _) _) _ => andb (Pos.eqb b _update_overlap) (Pos.eqb f tmp)
 | _=>false end.
Definition on_child:statement:=ltac:(native_fragment (stmt_for _t'40) f_dfs).
Definition off_child:statement:=ltac:(native_fragment (stmt_for _t'32) f_dfs).
Definition callback_loc p q:=
 [temp _policy p;temp _a (Vint (Int.repr q));temp _update_overlap (Vint Int.one)].
Theorem semax_enabled_callback {Espec:OracleKind} c p owner fp g storage st q enter:
 is_pointer_or_null owner -> admissible g q enter st ->
 semax (func_tycontext f_dfs Vprog (NestedGprog c) [])
   (PROPx nil (LOCALx (callback_loc p q) (SEPx [callback_fields p owner fp;
      func_ptr' (callback_contract owner g storage) fp;storage st])))
   (if enter then on_child else off_child)
   (normal_ret_assert (PROPx nil (LOCALx (callback_loc p q)
     (SEPx [callback_fields p owner fp;func_ptr' (callback_contract owner g storage) fp;
      storage (after_column g q enter st)])))).
Proof.
 intros own safe. destruct enter.
 all: unfold callback_loc,callback_fields,on_child,off_child.
 all: abbreviate_semax.
 all: forward_if;try solve [discriminate].
 all: Intros;do 2 forward.
 - forward_call (st,q,true);try solve [entailer!].
 - forward_call (st,q,false);try solve [entailer!].
Qed.
