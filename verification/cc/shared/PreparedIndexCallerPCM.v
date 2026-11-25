(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected PreparedIndexEpoch PreparedIndexWhile PreparedIndexFinish
 PreparedIndexChooser PreparedPCMChooser PreparedIndexCall PreparedIndexChildrenView PreparedChoiceCall flag_level_ast.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import NativePackingScan LeafMatrix PreparedIndexWords SparseFlipBits SparseSyndrome.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Local Delimit Scope Z_scope with coqZ.
Local Open Scope ring_scope.

Section Call.
Variables m n:nat.
Variables (rows:'I_m->seq 'I_n) (H:'M['F_2]_(m,n)) (prefix:'cV['F_2]_n)
 (free:{set 'I_n}) (blocks cols:seq Integers.int) (offsets:seq Z) (budget:nat) (dep w:Z).
Variables (words:seq int64) (count:Z) (marks:seq int64) (last:int64) (old:seq Integers.int).
Hypotheses (m_fits:(Z.of_nat m<=Int.max_signed)%coqZ) (n_fits:(0<Z.of_nat n<=Int.max_signed)%coqZ)
 (available:forall q:'I_n,Znth (Z.of_nat q) blocks=Int.zero <-> q \in free)
 (block_width:Zlength blocks=Z.of_nat n) (mark_width:Zlength marks=Z.of_nat n)
 (covers:forall r q,H r q!=0 -> q \in rows r) (distinct:forall r,uniq (rows r))
 (offset_count:Zlength offsets=(Z.of_nat m+1)%coqZ)
 (csr:forall r:'I_m,let a:=Znth (Z.of_nat r) offsets in let b:=Znth (Z.of_nat r+1)%coqZ offsets in
    (0<=a<=b)%coqZ /\ (b<=Int.max_unsigned)%coqZ /\ (b<=Zlength cols)%coqZ /\ sublist a b cols=encoded rows r)
 (remaining:(w-dep)%coqZ=Z.of_nat budget)
 (stored:stores_odd (words,count) (support (H*m prefix))) (padding:clear_padding (Z.of_nat m) words) (live:(0<count)%coqZ)
 (capacity:forall r:'I_m,(Znth (Z.of_nat r+1)%coqZ offsets-Znth (Z.of_nat r) offsets<=Zlength old)%coqZ)
 (buffer_signed:(Zlength old<=Int.max_signed)%coqZ).
Let picks:=output_columns offsets cols blocks.
Definition complete_choices result:=
 List.NoDup (map Int.unsigned (picks result)) /\
 (forall target:'cV['F_2]_n,support prefix \subset support target -> H*m target=0 ->
   support target :\: support prefix \subset free -> (#|support target :\: support prefix|<=budget)%N ->
   exists q:'I_n,q \in support target :\: support prefix /\ List.In (Z.of_nat q) (map Int.unsigned (picks result))).

Variables (gv:globals) (sh:share) (s sp op cp bp mp children:Values.val) (nc pk:int64).
Let before:=call_before gv sh s sp op cp bp mp children offsets cols blocks w words nc pk old last marks.
Let after:=call_after gv sh s sp op cp bp mp children offsets cols blocks w words nc pk old last marks.
Let size:=call_count offsets cols blocks.
Let spec:=call_spec gv s children dep before after size complete_choices.

Theorem verified_choices_at_dfs {Espec:OracleKind} bits :
 readable_share sh -> (1<=dep<=w)%coqZ -> (w<=Int.max_signed)%coqZ -> (Zlength words<=Int.max_signed)%coqZ ->
 Int.and bits (Int.repr 1)=Int.zero -> is_pointer_or_null s -> is_pointer_or_null children ->
 semax_body Vprog index_calls f_index_children spec /\
 semax (func_tycontext f_dfs Vprog (caller_functions spec) nil)
   (PROPx nil (LOCALx (caller_locals gv s children dep bits) (SEPx [::before])))
   choose_count (normal_ret_assert (EX result:scan_exit,PROPx [::complete_choices result]
    (LOCALx (temp _count (Vint (Int.repr (size result)))::caller_locals gv s children dep bits)
       (SEPx [::after result]))))%assert.
Proof.
 move=>readable depth signed words_fit direct valid out;split.
 - apply:body_with_chooser_post=> oracle.
   exact:(@complete_physical_index_children m n rows H prefix free blocks cols offsets budget dep w words count
      marks last old m_fits n_fits available block_width mark_width covers distinct offset_count csr remaining
      stored padding live capacity buffer_signed oracle gv sh s sp op cp bp mp children nc pk readable depth signed words_fit).
 - exact:(@dfs_calls_index Espec gv s children dep bits before after size complete_choices direct valid out).
Qed.
(* The prefix array is separated from its precise scratch suffix, as
   expected by the verified C sibling loop at the same address. *)
Theorem verified_row_for_sibling_loop {Espec:OracleKind} bits :
 readable_share sh -> (1<=dep<=w)%coqZ -> (w<=Int.max_signed)%coqZ -> (Zlength words<=Int.max_signed)%coqZ ->
 Int.and bits (Int.repr 1)=Int.zero -> is_pointer_or_null s -> is_pointer_or_null children ->
 semax_body Vprog index_calls f_index_children spec /\
 semax (func_tycontext f_dfs Vprog (caller_functions spec) nil)
  (PROPx nil (LOCALx (caller_locals gv s children dep bits) (SEPx [::before])))
  choose_count (normal_ret_assert (EX result:scan_exit,PROPx [::complete_choices result]
    (LOCALx (temp _count (Vint (Int.repr (size result)))::caller_locals gv s children dep bits)
       (SEPx [::VerifChildVisit.child_array children (map Int.unsigned (picks result));
           retained_by_parent gv sh s sp op cp bp mp children offsets cols blocks w words nc pk old last marks result]))))%assert.
Proof.
 move=>readable depth signed fits direct valid out;split.
 - exact:(proj1 (@verified_choices_at_dfs Espec bits readable depth signed fits direct valid out)).
 - exact:(@direct_call_supplies_child_array Espec gv sh s sp op cp bp mp children offsets cols blocks dep w words nc pk old last marks bits complete_choices direct valid out).
Qed.
End Call.
