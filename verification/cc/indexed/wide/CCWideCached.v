(* Compile a row once, before returning the coordinate accessor. *)
From Coq Require Import FunctionalExtensionality.
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCPCMChunks CCV.CCPCMFast CCWideWords CCWideLayout.
Import ListNotations. Local Open Scope nat_scope.
Definition fast_row (row:list Z) : vector :=
 if length row <=? 378 then
   let packed:=encode (map (fun b => Z.eqb b 1) row) in
   fun j=>decode packed j
 else fun j=>Z.eqb (nth j row 0%Z) 1.
Lemma fast_row_correct row : fast_row row=(fun j=>Z.eqb (nth j row 0%Z) 1).
Proof.
 apply functional_extensionality;intro j;unfold fast_row.
 destruct (Nat.leb_spec0 (length row) 378);[|reflexivity].
 rewrite encode_nth by (rewrite map_length;assumption).
 change (nth j (map (fun b=>Z.eqb b 1) row) (Z.eqb 0 1)=Z.eqb (nth j row 0%Z) 1).
 exact (map_nth (fun b:Z => Z.eqb b 1) row 0%Z j).
Qed.
Definition cached_vectors w m flat :=
 map fast_row (row_chunks (Z.to_nat w) (Z.to_nat m) flat).
Theorem cached_vectors_correct w m flat : cached_vectors w m flat=sliced_vectors w m flat.
Proof. unfold cached_vectors,sliced_vectors;apply map_ext;intro row;apply fast_row_correct. Qed.
Print Assumptions cached_vectors_correct.
