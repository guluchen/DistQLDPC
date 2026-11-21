(* The immutable row index is validated once for every legal lookup.
   Even a malformed index cannot license an incorrect split or packing cut. *)
From Coq Require Import List Bool Arith Lia Uint63.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCPackedWords CCV.CCPackedBranch
 CCV.CCPackedRefute CCV.CCPackedLayout.
Import ListNotations. Local Open Scope nat_scope.

Definition same_bits a b := is_empty (add_bits a b).
Lemma same_bits_eq a b : same_bits a b=true ->a=b.
Proof.
  unfold same_bits;intros H;apply empty_none in H;apply bits_ext;intros i I.
  pose proof(f_equal (fun w=>decode w i) H) as E;cbn beta in E;rewrite decode_add,decode_none in E.
  destruct (decode a i),(decode b i);simpl in E;congruence.
Qed.
Definition same_column c d := (position c=?position d) && same_bits (mark c) (mark d) &&
  same_bits (check_delta c) (check_delta d) && same_bits (logical_delta c) (logical_delta d).
Lemma same_column_eq c d : same_column c d=true -> c=d.
Proof.
  unfold same_column;rewrite !andb_true_iff,Nat.eqb_eq.
  destruct c,d;cbn;intros [[[A B] C] D];apply same_bits_eq in B,C,D;congruence.
Qed.
Fixpoint same_columns cs ds :=
  match cs,ds with
  | [],[]=>true | c::ct,d::dt=>same_column c d && same_columns ct dt
  | _,_=>false end.
Lemma same_columns_eq cs ds : same_columns cs ds=true ->cs=ds.
Proof.
  revert ds;induction cs as [|c cs IH];intros [|d ds];cbn;try discriminate;try reflexivity.
  rewrite andb_true_iff;intros [H T];apply same_column_eq in H;apply IH in T;congruence.
Qed.
Definition entry := (packed_row*bits)%type.
Definition index_ok (rows:list packed_row) (read:nat->entry) :=
  forallb (fun i=>let '(r,tag):=read i in let original:=nth i rows bad_row in
    same_bits tag (singleton i) &&
    same_bits (support_mask r) (support_mask original) && same_columns (neighbors r) (neighbors original))
    (seq 0 (length rows)).
Lemma entry_valid rows read : index_ok rows read=true -> forall i,i<length rows ->
  read i=(nth i rows bad_row,singleton i).
Proof.
  unfold index_ok;rewrite forallb_forall;intros All i I;specialize(All i ltac:(apply in_seq;lia)).
  destruct(read i) as [[m cs] tag];destruct(nth i rows bad_row) as [m' ds].
  rewrite !andb_true_iff in All;cbn in All;destruct All as [[T M] C].
  apply same_bits_eq in T,M;apply same_columns_eq in C;congruence.
Qed.

Lemma meet_single_bit sy i : i<189 ->
  negb(is_empty(meet sy (singleton i)))=decode sy i.
Proof.
  intro I;destruct (is_empty (meet sy (singleton i))) eqn:E;cbn.
  - apply empty_none in E;pose proof(f_equal (fun a=>decode a i) E) as Eq;cbn beta in Eq.
    rewrite decode_meet,singleton_at,Nat.eqb_refl,andb_true_r,decode_none in Eq by exact I;auto.
  - destruct (decode sy i) eqn:F;[reflexivity|].
    assert (Z:meet sy (singleton i)=none).
    { apply bits_ext;intros j J;rewrite decode_meet,singleton_at,decode_none by exact I.
      destruct (Nat.eqb_spec i j);[subst;rewrite F|rewrite andb_false_r];reflexivity. }
    rewrite Z in E;discriminate.
Qed.
Definition indexed_active m (read:nat->entry) sy i :=
  (i <? m) && negb(disjoint sy (snd(read i))).
Lemma compiled_index n hs ls read : n<=189 ->length hs<=189 ->length ls<=189 ->
 index_ok (compiled_rows n hs ls) read=true ->
 active_ok (length hs) (indexed_active (length hs) read) /\
 layout n hs ls (fun i=>fst(read i)).
Proof.
  intros N H L V;pose proof(entry_valid _ _ V) as All.
  assert (Len:length(compiled_rows n hs ls)=length hs) by (unfold compiled_rows;rewrite map_length;reflexivity).
  split.
  - intros sy i;unfold indexed_active,active;rewrite disjoint_meet;destruct (i <? length hs) eqn:B;[|discriminate].
    apply Nat.ltb_lt in B;rewrite All by lia;cbn [snd];rewrite meet_single_bit by lia;auto.
  - intros i I;rewrite All by lia;apply (compile_layout n hs ls N H L i I).
Qed.
