(* SPDX-License-Identifier: GPL-3.0-or-later
 * Sparse balanced blocks for preprocessing arbitrary-width binary PCMs.
 * Dense output is retained in exactly the original detector order. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCRepresentation
 CCV.CCSearchSpecs CCV.CCPCMInput CCV.CCPCMLayout CCV.CCPCMDetectors CCV.CCPCMChunks
 CCV.CCPCMFast CCV.CCPCMBitRows.
Import ListNotations.
Local Open Scope nat_scope.

Inductive cell := Gap | One | Fork (left right:cell).
Definition atom b := if b:bool then One else Gap.
Definition join2 x y := match x,y with Gap,Gap => Gap | _,_ => Fork x y end.
Fixpoint product (a b:cell) : bool :=
 match a,b with One,One=>true | Fork x y,Fork u v=>xorb(product x u)(product y v) | _,_=>false end.
Fixpoint pluscell a b :=
 match a,b with
 |Gap,_=>b |_,Gap=>a
 |Fork x y,Fork u v=>join2 (pluscell x u) (pluscell y v)
 |_,_=>Gap end.
Lemma product_join a b c d : product (join2 a b) (join2 c d)=xorb(product a c)(product b d).
Proof. destruct a,b,c,d;reflexivity. Qed.
Lemma plus_join a b c d : pluscell (join2 a b) (join2 c d)=join2 (pluscell a c) (pluscell b d).
Proof. destruct a,b,c,d;reflexivity. Qed.
Fixpoint pairs (xs:list cell) :=
 match xs with []=>[] | [x]=>[join2 x Gap] | x::y::t=>join2 x y::pairs t end.
Fixpoint scalar (a b:list cell) : bool :=
 match a,b with x::xs,y::ys=>xorb(product x y)(scalar xs ys) | _,_=>false end.
Fixpoint plusrow (a b:list cell) :=
 match a,b with x::xs,y::ys=>pluscell x y::plusrow xs ys | _,_=>[] end.
Lemma pairs_length xs ys : length xs=length ys -> length(pairs xs)=length(pairs ys).
Proof. revert xs ys;fix IH 1;intros [|x [|y t]] [|a [|b u]] H;simpl in *;try discriminate;try reflexivity. f_equal;apply IH;lia. Qed.
Lemma scalar_pairs xs ys : length xs=length ys -> scalar (pairs xs)(pairs ys)=scalar xs ys.
Proof.
 revert xs ys;fix IH 1;intros [|x [|y t]] [|a [|b u]] H;simpl in H;try discriminate;try reflexivity.
 - cbn [pairs scalar];rewrite product_join;destruct (product x a);reflexivity.
 - cbn [pairs scalar];rewrite product_join,IH by lia.
   destruct (product x a),(product y b),(scalar t u);reflexivity.
Qed.
Lemma plus_pairs xs ys : length xs=length ys -> plusrow (pairs xs)(pairs ys)=pairs(plusrow xs ys).
Proof.
 revert xs ys;fix IH 1;intros [|x [|y t]] [|a [|b u]] H;simpl in H;try discriminate;try reflexivity.
 - cbn [pairs plusrow];rewrite plus_join;reflexivity.
 - cbn [pairs plusrow];rewrite plus_join,IH by lia;reflexivity.
Qed.
Fixpoint layers k xs := match k with 0=>xs | S h=>layers h (pairs xs) end.
Definition encode xs := layers 5 (map atom xs).
Lemma scalar_layers k xs ys : length xs=length ys -> scalar (layers k xs)(layers k ys)=scalar xs ys.
Proof. revert xs ys;induction k;intros;simpl;auto. rewrite IHk,scalar_pairs;auto using pairs_length. Qed.
Lemma plus_layers k xs ys : length xs=length ys -> plusrow (layers k xs)(layers k ys)=layers k (plusrow xs ys).
Proof. revert xs ys;induction k;intros;simpl;auto. rewrite IHk,plus_pairs;auto using pairs_length. Qed.
Lemma encoded_dot a b : length a=length b ->scalar (encode a)(encode b)=row_dot a b.
Proof.
 intros E;unfold encode;rewrite scalar_layers by now rewrite !map_length.
 revert b E;induction a as [|x t IH];intros [|y u] E;try discriminate;try reflexivity.
 cbn [map scalar row_dot];rewrite IH by (injection E;auto);destruct x,y;reflexivity.
Qed.
Lemma encoded_plus a b : length a=length b ->plusrow (encode a)(encode b)=encode(row_xor a b).
Proof.
 intros E;unfold encode;rewrite (plus_layers 5 (map atom a) (map atom b)) by (rewrite !map_length;exact E). f_equal.
 revert b E;induction a as [|x t IH];intros [|y u] E;try discriminate;try reflexivity.
 cbn [map plusrow row_xor];rewrite IH by (injection E;auto);destruct x,y;reflexivity.
Qed.

(* Read at most n bytes once. Short rows are padded, exactly as nth defaults. *)
Fixpoint read_bits n (xs:list Z) := match n with
 |0=>[]|S k=>match xs with []=>false::read_bits k [] | x::t=>(Z.eqb x 1)::read_bits k t end end.
Lemma read_at n xs j : j<n -> nth j (read_bits n xs) false=Z.eqb (nth j xs 0%Z) 1.
Proof. revert xs j;induction n;intros [|x xs] [|j] H;try lia;cbn [read_bits nth];auto with arith. all: try (rewrite IHn by lia; destruct j; reflexivity).
Qed.
Lemma read_length n xs : length(read_bits n xs)=n.
Proof. revert xs;induction n;intros [|x t];simpl;auto. Qed.
Lemma read_tab n xs : read_bits n xs=tabulate n (fun j=>Z.eqb (nth j xs 0%Z) 1).
Proof.
 apply nth_ext with (d:=false) (d':=false).
 - unfold tabulate;rewrite read_length,map_length,seq_length;reflexivity.
 - intros j H;rewrite read_length in H;rewrite read_at,tabulate_at by lia;reflexivity.
Qed.
Definition fast_rows w m xs := map (read_bits (Z.to_nat w))(row_chunks (Z.to_nat w)(Z.to_nat m) xs).
Lemma fast_rows_eq w m xs : fast_rows w m xs=map (tabulate (Z.to_nat w))(sliced_vectors w m xs).
Proof. unfold fast_rows,sliced_vectors;rewrite map_map;apply map_ext;intro;apply read_tab. Qed.
Definition both (r:list bool) := (r,encode r).
Definition addrow (a b:list bool*list cell) :=
 (row_xor (fst a)(fst b),plusrow (snd a)(snd b)).
Lemma add_both x y : length x=length y ->addrow (both x)(both y)=both(row_xor x y).
Proof. intro H;unfold addrow,both;cbn [fst snd];rewrite encoded_plus by exact H;reflexivity. Qed.
Lemma xor_len a b : length a=length b ->length(row_xor a b)=length a.
Proof. revert b;induction a;intros [|t u] E;try discriminate;simpl;auto. Qed.
Definition wide n (rows:list(list bool)) := Forall (fun r=>length r=n) rows.
Lemma seed_wide n : wide n (map (fun i=>tabulate n (unit_vector i)) (seq 0 n)).
Proof. apply Forall_forall;intros t H;apply in_map_iff in H as [i [<- _]].
 unfold tabulate;rewrite map_length,seq_length;reflexivity. Qed.
Lemma partition_wide n (p:list bool->bool) rs a b :
 wide n rs -> List.partition p rs=(a,b) -> wide n a /\ wide n b.
Proof. intros H;rewrite partition_filters;intros [= <- <-];split;apply Forall_forall;
 intros y InY;apply filter_In in InY as [InY _];now apply Forall_forall with (x:=y) in H. Qed.
Lemma mapped_partition {A B} (f:A->B)(p:B->bool)(q:A->bool) xs :
 Forall (fun x=>p(f x)=q x) xs ->
 List.partition p (map f xs)=(map f (fst(List.partition q xs)), map f (snd(List.partition q xs))).
Proof. intro H;induction H as [|x xs E All IH];[reflexivity|].
 simpl;rewrite IH,E;destruct (List.partition q xs), (q x);reflexivity. Qed.
Fixpoint forest_detectors n (gs:list(list cell)) :=
 match gs with
 |[]=>map both (map (fun i=>tabulate n (unit_vector i))(seq 0 n))
 |g::t=>let rs:=forest_detectors n t in
   let '(a,b):=List.partition (fun r=>scalar (snd r) g) rs in
   match a with []=>rs | p::rest=>b++map (fun r=>addrow r p) rest end end.
Lemma forest_detectors_eq n gs : wide n gs ->
 forest_detectors n (map encode gs)=map both (bit_detectors n gs) /\ wide n (bit_detectors n gs).
Proof.
 intro H;induction H as [|g gs G All [IH Wide]].
 - split;[reflexivity|apply seed_wide].
 - cbn [map forest_detectors bit_detectors];rewrite IH,mapped_partition with (q:=fun r=>row_dot r g).
   2:{ apply Forall_forall;intros x I;unfold both;cbn [snd];apply encoded_dot.
       apply Forall_forall with (x:=x) in Wide;auto;lia. }
   destruct (List.partition _ _) as [odd even] eqn:E;cbn [fst snd].
   apply (partition_wide n _ _ _ _ Wide) in E as [O Ev].
   destruct odd as [|p rest];[tauto|]. inversion O as [|? ? P Rest];subst.
   split.
   + cbn [map];rewrite map_app,!map_map;f_equal;apply map_ext_in;intros r R;apply add_both.
     apply Forall_forall with (x:=r) in Rest;auto;lia.
   + apply Forall_app;split;[exact Ev|]. apply Forall_forall;intros x X.
     apply in_map_iff in X as [r [<- R]]. apply Forall_forall with (x:=r) in Rest;auto.
     rewrite xor_len;lia.
Qed.
Definition forest_commute hs gs :=
 forallb (fun g=>forallb (fun h=>negb(scalar h g)) hs) gs.
Lemma all_image {A B} (f:A->B) p q xs : (forall x, In x xs -> p(f x)=q x) -> forallb p (map f xs)=forallb q xs.
Proof. induction xs as [|a t IH];intro H;cbn;auto. rewrite H by (left;auto). f_equal;apply IH;intros;apply H;right;auto. Qed.
Lemma forest_commute_eq n hs gs : wide n hs -> wide n gs ->
 forest_commute (map encode hs)(map encode gs)=bit_commute hs gs.
Proof. intros H G;unfold forest_commute,bit_commute;apply all_image;intros g I;apply all_image;intros h J. rewrite encoded_dot;[reflexivity|]. apply Forall_forall with (x:=g) in G;auto. apply Forall_forall with (x:=h) in H;auto;lia. Qed.

Definition compact_prepare q : option half_model :=
 if raw_shape q then
 let n:=Z.to_nat(width q) in
 let hs:=fast_rows (width q)(check_count q)(checks q) in
 let gs:=fast_rows (width q)(same_count q)(same_bytes q) in
 let ge:=map encode gs in
 if forest_commute (map encode hs) ge then
   let ds:=match forest_detectors n ge with []=>[tabulate n zero_vector] |rs=>map fst rs end in
   let count:=Zlength ds in
   if (count <=? 2147483647 / width q)%Z then
    Some {|model_n:=width q;model_m:=check_count q;model_k:=same_count q;model_l:=count;
           model_h:=checks q;model_g:=same_bytes q;model_lg:=flat_map (map bitZ) ds |}
   else None else None else None.
Lemma fast_wide w m xs : wide (Z.to_nat w)(fast_rows w m xs).
Proof. unfold fast_rows; apply Forall_forall;intros y I;apply in_map_iff in I as [x [<- _]];apply read_length. Qed.
Theorem compact_prepare_exact q : compact_prepare q=prepare_pcm_half q.
Proof.
 rewrite <-bit_prepare_correct;unfold compact_prepare,bit_prepare.
 rewrite <-!fast_rows_eq.
 rewrite (forest_commute_eq (Z.to_nat(width q))) by apply fast_wide.
 rewrite (proj1 (forest_detectors_eq _ _ (fast_wide _ _ _))).
 destruct (bit_detectors _ _) as [|x xs];[reflexivity|].
 assert (F: forall t:list (list bool), map (@fst (list bool) (list cell)) (map both t)=t).
 { induction t as [|a t IH];[reflexivity|]. cbn [map];rewrite IH;reflexivity. }
 cbn [map]. rewrite F;reflexivity.
Qed.
Print Assumptions compact_prepare_exact.
