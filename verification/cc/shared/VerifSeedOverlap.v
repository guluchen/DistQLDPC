(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require Import ClightSelect level_ast VerifDetected VerifChildVisit OverlapColumnState VerifOverlapDispatch.
Local Open Scope Z_scope.

Definition seed_dispatch (condition load:ident) (stmt:statement) :=
 match stmt with
 | Sifthenelse (Etempvar b _) (Ssequence (Sset f _) _) _ =>
   andb (Pos.eqb b condition) (Pos.eqb f load)
 | _=>false end.
Definition push_seed:statement:=ltac:(native_fragment (seed_dispatch _t'4 _t'36) f_cc_run_level).
Definition pop_seed:statement:=ltac:(native_fragment (seed_dispatch _t'6 _t'32) f_cc_run_level).
Definition seed_local (policy:val) q (enter:bool) :=
 [temp _policy policy;temp _q (Vint (Int.repr q));temp (if enter then _t'4 else _t'6) (Vint Int.one)].

(* The two native sites bracketing the root call to dfs are in a different
   function from its recursive child sites and use different locals. *)
Theorem semax_enabled_seed_callback {Espec:OracleKind} c p owner fp g storage st q enter :
 is_pointer_or_null owner -> admissible g q enter st ->
 semax (func_tycontext f_cc_run_level Vprog (NestedGprog c) [])
   (PROPx nil (LOCALx (seed_local p q enter) (SEPx [callback_fields p owner fp;
      func_ptr' (callback_contract owner g storage) fp;storage st])))
   (if enter then push_seed else pop_seed)
   (normal_ret_assert (PROPx nil (LOCALx (seed_local p q enter)
     (SEPx [callback_fields p owner fp;func_ptr' (callback_contract owner g storage) fp;
      storage (after_column g q enter st)])))).
Proof.
 intros own safe;destruct enter;unfold seed_local,callback_fields,push_seed,pop_seed.
 all: abbreviate_semax;forward_if;try solve [discriminate|congruence].
 all: Intros;do 2 forward.
 - forward_call (st,q,true);try solve [entailer!].
 - forward_call (st,q,false);try solve [entailer!].
Qed.
