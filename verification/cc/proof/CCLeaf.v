Require Import VST.floyd.proofauto.
Open Scope Z_scope.
Fixpoint row_matches_nat (t:nat) (n q:Z) (ys h:list Z) : bool :=
 match t with O=>true | S k=>andb (row_matches_nat k n q ys h)
 (Z.eqb (nth k ys 0) (Znth (Z.of_nat k*n+q) h)) end.
Definition row_matches t n q ys h :=row_matches_nat (Z.to_nat t) n q ys h.
Fixpoint row_differs_nat (t:nat) (n q:Z) (zs l:list Z) : bool :=
 match t with O=>false | S k=>orb (row_differs_nat k n q zs l)
 (negb (Z.eqb (nth k zs 0) (Znth (Z.of_nat k*n+q) l))) end.
Definition row_differs t n q zs l :=row_differs_nat (Z.to_nat t) n q zs l.
Definition free_column (xs fs:list Z) q := andb (Znth q xs=?0) (Znth q fs=?0).
Definition leaf_candidate n m l xs fs ys zs h lg q :=
 andb (free_column xs fs q) (andb (row_matches m n q ys h) (row_differs l n q zs lg)).
Lemma nonnegative_Znth (i:Z) (xs:list Z) : 0<=i -> Znth i xs=nth (Z.to_nat i) xs 0.
Proof. intros;unfold Znth;rewrite if_false by lia;reflexivity. Qed.
Lemma row_matches_step t n q ys h : 0<=t -> row_matches (t+1) n q ys h=
 andb (row_matches t n q ys h) (Z.eqb (Znth t ys) (Znth(t*n+q) h)).
Proof.
 intros;unfold row_matches;rewrite Z2Nat.inj_add by lia;change (Z.to_nat 1) with 1%nat.
 rewrite Nat.add_1_r;cbn [row_matches_nat];rewrite Z2Nat.id by lia.
 rewrite (nonnegative_Znth t ys) by assumption;reflexivity.
Qed.
Lemma row_differs_step t n q zs l : 0<=t -> row_differs (t+1) n q zs l=
 orb (row_differs t n q zs l) (negb(Z.eqb (Znth t zs) (Znth(t*n+q) l))).
Proof.
 intros;unfold row_differs;rewrite Z2Nat.inj_add by lia;change (Z.to_nat 1) with 1%nat.
 rewrite Nat.add_1_r;cbn [row_differs_nat];rewrite Z2Nat.id by lia.
 rewrite (nonnegative_Znth t zs) by assumption;reflexivity.
Qed.
Lemma word_or_mismatch (b:bool) (x y:Z) : (x=0 \/ x=1) -> (y=0 \/ y=1) ->
 Int.or (Int.repr(if b then 1 else 0)) (Int.xor (Int.repr x) (Int.repr y))=
 Int.repr(if orb b (negb(x=?y)) then 1 else 0).
Proof.
 intros X Y;destruct X as [X|X];destruct Y as [Y|Y];subst;destruct b;reflexivity.
Qed.
Lemma checked_prefix_extend (P:Z->bool) q :
 (forall r,0<=r<q -> P r=false) -> P q=false ->
 forall r,0<=r<q+1 -> P r=false.
Proof. intros H Hq r Hr;destruct(Z.eq_dec r q);subst;auto;apply H;lia. Qed.
Lemma row_matches_all t n q ys h : 0<=t ->
 (row_matches t n q ys h=true <-> forall i,0<=i<t -> Znth i ys=Znth(i*n+q) h).
Proof.
 intros Ht;unfold row_matches;remember (Z.to_nat t) as k eqn:E.
 assert(T:t=Z.of_nat k) by (subst;rewrite Z2Nat.id by assumption;reflexivity).
 subst t;clear E Ht;induction k as [|k IH];cbn [row_matches_nat].
 - split;[intros _ i Hi;lia|reflexivity].
 - rewrite andb_true_iff,IH,Z.eqb_eq.
   assert(A:nth k ys 0=Znth (Z.of_nat k) ys).
   { rewrite nonnegative_Znth by lia;rewrite Nat2Z.id;reflexivity. } rewrite A.
   split.
   + intros [H Hk] i Hi;destruct(Z.eq_dec i (Z.of_nat k));subst;auto;apply H;lia.
   + intros H;split;[intros i Hi;apply H;lia|apply H;lia].
Qed.
Print Assumptions row_matches_all.
Print Assumptions word_or_mismatch.

Lemma bool_repr_zero (b:bool) : Int.repr(if b then 1 else 0)=Int.zero -> b=false.
Proof. intros E;destruct b;[apply (f_equal Int.unsigned) in E;change (1=0) in E;lia|reflexivity]. Qed.
