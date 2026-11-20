(* Arithmetic along the legal-dimension path of the frozen shape check. *)
Require Import VST.floyd.proofauto.
Require Import compcert.cfrontend.Clight compcert.cfrontend.Cop.
Open Scope Z_scope.
Lemma shape_eq_zero ce m x : 0 < x <= Int.max_unsigned ->
 sem_binary_operation ce Oeq (Vint (Int.repr x)) tuint (Vint Int.zero) tuint m = Some (Vint Int.zero).
Proof.
 intros R. change (Some (Val.of_bool (Int.eq (Int.repr x) Int.zero)) = Some (Vint Int.zero)).
 rewrite Int.eq_false; [reflexivity|].
 intro E; apply (f_equal Int.unsigned) in E; rewrite Int.unsigned_zero,Int.unsigned_repr in E by lia; lia.
Qed.
Lemma shape_cmp_gt ce m x y : 0 <= x <= Int.max_unsigned -> 0 <= y <= Int.max_unsigned -> x <= y ->
 sem_binary_operation ce Ogt (Vint (Int.repr x)) tuint (Vint (Int.repr y)) tuint m = Some (Vint Int.zero).
Proof.
 intros. change (Some (Val.of_bool (Int.ltu (Int.repr y) (Int.repr x))) = Some (Vint Int.zero)).
 unfold Int.ltu; rewrite !Int.unsigned_repr by lia; destruct (zlt y x); [lia|reflexivity].
Qed.
Lemma shape_cmp_lt ce m x y : 0 <= x <= Int.max_unsigned -> 0 <= y <= Int.max_unsigned -> y <= x ->
 sem_binary_operation ce Olt (Vint (Int.repr x)) tuint (Vint (Int.repr y)) tuint m = Some (Vint Int.zero).
Proof.
 intros. change (Some (Val.of_bool (Int.ltu (Int.repr x) (Int.repr y))) = Some (Vint Int.zero)).
 unfold Int.ltu; rewrite !Int.unsigned_repr by lia; destruct (zlt x y); [lia|reflexivity].
Qed.
Lemma shape_divisor ce m n : 0<n<=Int.max_unsigned ->
 sem_binary_operation ce Odiv (Vint (Int.repr 2147483647)) tuint (Vint (Int.repr n)) tuint m =
 Some (Vint (Int.repr (2147483647/n))).
Proof.
 intros H. change ((if Int.eq (Int.repr n) Int.zero then None else
 Some (Vint (Int.divu (Int.repr 2147483647) (Int.repr n)))) = Some (Vint (Int.repr (2147483647/n)))).
 rewrite Int.eq_false.
 - unfold Int.divu; rewrite !Int.unsigned_repr by rep_lia; reflexivity.
 - intro E; apply (f_equal Int.unsigned) in E; rewrite Int.unsigned_zero,Int.unsigned_repr in E by lia; lia.
Qed.
Lemma shape_long_gt ce m x y : 0<=x<=Int.max_unsigned -> 0<=y<=Int64.max_unsigned -> x<=y ->
 sem_binary_operation ce Ogt (Vint (Int.repr x)) tuint (Vlong (Int64.repr y)) tulong m = Some (Vint Int.zero).
Proof.
 intros. change (Some (Val.of_bool (Int64.ltu (Int64.repr y) (Int64.repr (Int.unsigned (Int.repr x))))) = Some (Vint Int.zero)).
 rewrite Int.unsigned_repr by lia.
 unfold Int64.ltu; rewrite !Int64.unsigned_repr by rep_lia; destruct (zlt y x); [lia|reflexivity].
Qed.
