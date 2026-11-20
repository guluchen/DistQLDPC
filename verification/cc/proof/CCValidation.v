(* Connect the numeric stabilizer validation precondition to GF(2) parity. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCRows CCV.VerifDot.
Open Scope Z_scope.
Definition row_vector n i (h:list Z) : CCModel.vector :=
 fun q=>nth q (matrix_row n i h) 0=?1.
Theorem flat_dot_kernel n m k a b h g :
 0<n -> 0<=a<m -> 0<=b<k -> Zlength h=(m*n)%Z -> Zlength g=(k*n)%Z ->
 Forall(fun z:Z=>z=0 \/ z=1) h -> Forall(fun z:Z=>z=0 \/ z=1) g ->
 CCModel.parity (Z.to_nat n) (row_vector n a h) (row_vector n b g)=false ->
 flat_dot n n a b h g=Int.zero.
Proof.
 intros Hn Ha Hb Hh Hg Bh Bg P;unfold flat_dot.
 rewrite (flat_dot_rows n m k a b h g (Z.to_nat n)) by (try assumption;lia).
 rewrite word_dot_GF2 by (apply matrix_row_bits;assumption).
 unfold row_vector in P;rewrite P;reflexivity.
Qed.
Definition kernel_metadata n m l k hs ls gs :=
 forall i:Z,0<=i<k ->
 (forall j:Z,0<=j<m -> CCModel.parity (Z.to_nat n) (row_vector n j hs) (row_vector n i gs)=false) /\
 (forall j:Z,0<=j<l -> CCModel.parity (Z.to_nat n) (row_vector n j ls) (row_vector n i gs)=false).
Theorem GF2_metadata_implies_runtime_dots n m l k hs ls gs :
 0<n -> 0<=m -> 0<=l -> 0<=k ->
 Zlength hs=(m*n)%Z -> Zlength ls=(l*n)%Z -> Zlength gs=(k*n)%Z ->
 Forall(fun z:Z=>z=0 \/ z=1) hs -> Forall(fun z:Z=>z=0 \/ z=1) ls ->
 Forall(fun z:Z=>z=0 \/ z=1) gs -> kernel_metadata n m l k hs ls gs ->
 forall i j:Z,0<=i<k -> 0<=j<m+l ->
 (if zlt j m then flat_dot n n j i hs gs else flat_dot n n (j-m) i ls gs)=Int.zero.
Proof.
 intros Hn Hm Hl Hk Hh Hlg Hg Bh Bl Bg Hmeta i j Hi Hj.
 destruct(Hmeta i Hi) as [Mh Ml];destruct(zlt j m).
 - apply (flat_dot_kernel n m k j i hs gs);try assumption;try lia;apply Mh;lia.
 - apply (flat_dot_kernel n l k (j-m) i ls gs);try assumption;try lia;apply Ml;lia.
Qed.
Print Assumptions flat_dot_kernel.
Print Assumptions GF2_metadata_implies_runtime_dots.
