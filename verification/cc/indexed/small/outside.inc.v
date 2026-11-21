
Lemma outside a i : 189<=i -> decode a i=false.
Proof. intro I;unfold decode;destruct (Nat.ltb_spec0 i 63),(Nat.ltb_spec0 i 126),(Nat.ltb_spec0 i 189);try lia;reflexivity. Qed.
