(* Actual core-toggle expression forms, including C integer promotions. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.cfrontend.Clight.
Open Scope Z_scope.
Definition byte_xor_expr left right:=Ebinop Oxor(Etempvar left tuchar)(Etempvar right tuchar)tint.
Definition byte_flip_expr old:=Ebinop Oxor(Etempvar old tuchar)(Econst_int(Int.repr 1)tuint)tuint.
Lemma eval_byte_xor ge e le m left right a b:
 PTree.get left le=Some(Vint a) ->PTree.get right le=Some(Vint b) ->
 Clight.eval_expr ge e le m(byte_xor_expr left right)(Vint(Int.xor a b)).
Proof.
 intros Left Right;unfold byte_xor_expr;eapply Clight.eval_Ebinop with(v1:=Vint a)(v2:=Vint b).
 - apply Clight.eval_Etempvar;exact Left.
 - apply Clight.eval_Etempvar;exact Right.
 - reflexivity.
Qed.
Lemma eval_byte_flip ge e le m old a:
 PTree.get old le=Some(Vint a) ->
 Clight.eval_expr ge e le m(byte_flip_expr old)(Vint(Int.xor a Int.one)).
Proof.
 intros Old;unfold byte_flip_expr;eapply Clight.eval_Ebinop with(v1:=Vint a)(v2:=Vint Int.one).
 - apply Clight.eval_Etempvar;exact Old.
 - apply Clight.eval_Econst_int.
 - reflexivity.
Qed.
Print Assumptions eval_byte_xor.
