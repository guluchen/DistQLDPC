(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import level_ast VerifDetected VerifClosesBody VerifLookup HashLookup HashProbe
  LeafMatrix LevelSearch ClosureMatrix SyndromeHash NativeLeafChoice LeafAPI PCMLeafAPI
  TableFlow TableCoverage TableMembers BuiltLookup BucketPipeline.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Constructed.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)) (P F:{set 'I_n}).
Variables (v:close_view) (physical:'I_n -> seq 'I_m) (rowkey:'I_m -> int64).
Variables (ks:seq int64) (mask key:int64) (cap bits:Z) (tab links:seq Z) (blk:seq Integers.int).
Let b:=table_book ks mask key tab links blk.
Let rows:=support (H *m indicator P).
Let odd:=Z.of_nat #|rows|.
Hypothesis built : history ks mask cap (-1)%coqZ tab links.
Hypothesis npos : (0<Zlength ks)%coqZ.
Hypothesis length_ok : Zlength ks=Z.of_nat n.
Hypothesis room : (Zlength ks<cap)%coqZ.
Hypothesis period : cap=(2^bits)%coqZ.
Hypothesis index_bits : (0<=bits<64)%coqZ.
Hypothesis mask_bits : mask=Int64.repr (Z.ones bits).
Hypothesis disj : [disjoint F & P].
Hypothesis blocks : forall q:'I_n, Znth (Z.of_nat q) blk=Int.zero <-> q \in F.
Hypothesis columns : forall q:'I_n, @layout m n k H L (indicator P) q (physical q) v.
Hypothesis target_key : key=signature rowkey rows.
Hypothesis column_keys : forall q:'I_n, Znth (Z.of_nat q) ks=signature rowkey (support (col q H)).

(* No externally supplied bucket, coverage lemma, search trace or
   predicted answer is needed once the C builder has returned. *)
Theorem constructor_pcm_image : exists qs, leaf_image (pcm_completion H L P F) b v odd qs.
Proof.
have mf : (Int64.unsigned mask<cap)%coqZ by eapply low_mask;eassumption.
have [a [run _]] := @built_lookup_unique ks mask cap bits index_bits period mask_bits room
  tab links blk key v odd npos built.
have [qs path] := @terminal_bucket ks mask key cap tab links blk built mf npos v odd _ _ run.
have members := @exact_bucket ks mask key cap tab links blk built mf npos qs path.
exists qs;apply: (@physical_leaf_image m n k H L P F v b physical disj blocks columns length_ok
                    rowkey target_key column_keys qs path).
- move=> ix equal;apply/(members (Z.of_nat ix));split=> //;rewrite length_ok.
  have bounded := elimT ltP (ltn_ord ix);lia.
- move=> z inside;rewrite -length_ok;exact: (proj1 (proj1 (members z) inside)).
Qed.

Definition built_leaf_spec : ident * funspec :=
 DECLARE _closing_qubit
 WITH s:Values.val,p:lookup_ptrs
 PRE [tptr level_type] PROP(book_safe b v odd) PARAMS(s)
      SEP(close_mem Tsh s odd v;book_mem s b p)
 POST [tint] EX answer:Z, PROP(leaf_answer (pcm_completion H L P F) (Z.of_nat n) answer)
      RETURN(Vint (Int.repr answer)) SEP(close_mem Tsh s odd v;book_mem s b p).

Lemma built_leaf_refines : funspec_sub (snd (leaf_api (pcm_completion H L P F))) (snd built_leaf_spec).
Proof.
  destruct constructor_pcm_image as [qs image].
  do_funspec_sub. destruct w as [s p];cbn [fst snd];normalize.
  Exists (s,p,b,v,odd,qs) emp;apply andp_right.
  - entailer!;cancel.
  - apply prop_right;intros rho';normalize.
    match goal with h:leaf_answer _ _ ?a |- _ => Exists a end.
    change (extent b=Z.of_nat n) in length_ok;rewrite <-length_ok;entailer!;cancel.
Qed.
Theorem body_leaf_for_built_pcm : semax_body Vprog LookupGprog f_closing_qubit built_leaf_spec.
Proof.
  eapply semax_body_funspec_sub;[apply body_leaf_api|exact built_leaf_refines|].
  vm_compute;repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
Qed.
End Constructed.
