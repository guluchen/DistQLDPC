(* Read-only borrowing preserves the complementary share; callers recover their
   full writable ownership after a read-only callee returns unchanged bytes. *)
Require Import VST.floyd.proofauto.
Section Borrow.
Context{CS:compspecs}.
#[local] Existing Instance CS.
Lemma read_share_split sh t(v:reptype t)p:
 data_at Tsh t v p=(data_at sh t v p*data_at(Share.comp sh)t v p)%logic.
Proof. symmetry;apply(@data_at_share_join CS);apply comp_join_top. Qed.
Lemma read_share_rejoin sh t(v:reptype t)p:
 (data_at sh t v p*data_at(Share.comp sh)t v p)%logic |--data_at Tsh t v p.
Proof. rewrite <-read_share_split;apply derives_refl. Qed.
End Borrow.
Print Assumptions read_share_split.
