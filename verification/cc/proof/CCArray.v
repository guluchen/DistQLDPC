Require Import VST.floyd.proofauto.
Require Import VST.zlist.list_solver.
Definition zero_prefix (xs:list val) (i:Z) :=
 Zrepeat (Vint Int.zero) i ++ sublist i (Zlength xs) xs.
Lemma zero_prefix_length xs i : 0<=i<=Zlength xs -> Zlength (zero_prefix xs i)=Zlength xs.
Proof. intros;unfold zero_prefix;autorewrite with sublist;lia. Qed.
Lemma zero_prefix_start xs : zero_prefix xs 0=xs.
Proof. unfold zero_prefix;autorewrite with sublist;reflexivity. Qed.
Lemma zero_prefix_finish xs : zero_prefix xs (Zlength xs)=Zrepeat (Vint Int.zero) (Zlength xs).
Proof. unfold zero_prefix;autorewrite with sublist;reflexivity. Qed.
Lemma zero_prefix_step xs i : 0<=i<Zlength xs ->
 upd_Znth i (zero_prefix xs i) (Vint Int.zero)=zero_prefix xs (i+1).
Proof. intros;unfold zero_prefix;list_solve. Qed.
Print Assumptions zero_prefix_step.

Lemma zero_prefix_full xs n : n=Zlength xs -> zero_prefix xs n=Zrepeat (Vint Int.zero) n.
Proof. intros ->;apply zero_prefix_finish. Qed.
Definition copy_prefix (xs ys:list val) (i:Z) := sublist 0 i ys ++ sublist i (Zlength xs) xs.
Lemma copy_prefix_length xs ys i : Zlength xs=Zlength ys -> 0<=i<=Zlength xs -> Zlength(copy_prefix xs ys i)=Zlength xs.
Proof. intros;unfold copy_prefix;autorewrite with sublist;lia. Qed.
Lemma copy_prefix_start xs ys : copy_prefix xs ys 0=xs.
Proof. unfold copy_prefix;autorewrite with sublist;reflexivity. Qed.
Lemma copy_prefix_finish xs ys : Zlength xs=Zlength ys -> copy_prefix xs ys (Zlength xs)=ys.
Proof. intros;unfold copy_prefix;list_solve. Qed.
Lemma copy_prefix_step xs ys i : Zlength xs=Zlength ys -> 0<=i<Zlength xs ->
 upd_Znth i (copy_prefix xs ys i) (Znth i ys)=copy_prefix xs ys (i+1).
Proof. intros;unfold copy_prefix;list_solve. Qed.
Lemma copy_prefix_old xs ys i : Zlength xs=Zlength ys -> 0<=i<Zlength xs ->
 Znth i (copy_prefix xs ys i)=Znth i xs.
Proof. intros;unfold copy_prefix;list_solve. Qed.

Lemma copy_prefix_full xs ys n : Zlength xs=Zlength ys -> n=Zlength xs -> copy_prefix xs ys n=ys.
Proof. intros H ->;apply copy_prefix_finish;assumption. Qed.
