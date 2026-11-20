(* SPDX-License-Identifier: GPL-3.0-or-later.
   Functional connected-cluster search model. Not yet a C refinement proof. *)
From Coq Require Import Bool List Arith Lia.
Require Import CCV.CCModel.
Import ListNotations.
Definition setbit (s:vector) q : vector := fun i=>if Nat.eqb i q then true else s i.
Definition avoids n (e f:vector) := forall i, i<n -> f i=true -> e i=false.
Definition compatible n e s f := subset n s e /\ avoids n e f.
Definition goodb n hs ls s :=
 andb (0 <? weight n s) (andb (forallb (fun h=>negb (parity n h s)) hs)
                              (existsb (fun l=>parity n l s) ls)).
Lemma goodb_spec n hs ls s : goodb n hs ls s=true <-> good n hs ls s.
Proof.
 unfold goodb,good,kernel,logical.
 rewrite !andb_true_iff,Nat.ltb_lt,forallb_forall,existsb_exists.
 split;intros [Hp [Hk Hl]];split;[exact Hp|split|exact Hp|split];try assumption.
 - intros h Hh;apply negb_true_iff;apply Hk;exact Hh.
 - intros h Hh;apply negb_true_iff;apply Hk;exact Hh.
Qed.
Lemma weight_ext n a b : (forall i, i<n -> a i=b i) -> weight n a=weight n b.
Proof.
 induction n as [|n IH];intros H;simpl;[reflexivity|].
 rewrite (H n ltac:(lia)). rewrite IH;[reflexivity|]. intros i Hi;apply H;lia.
Qed.
Lemma parity_ext n h a b : (forall i, i<n -> a i=b i) -> parity n h a=parity n h b.
Proof.
 induction n as [|n IH];intros H;simpl;[reflexivity|].
 rewrite (H n ltac:(lia)). rewrite IH;[reflexivity|]. intros i Hi;apply H;lia.
Qed.
Lemma subset_equal_weight_ext n s e : subset n s e -> weight n s=weight n e ->
 forall i, i<n -> s i=e i.
Proof.
 intros Hsub Hw i Hi;destruct (s i) eqn:Hs,(e i) eqn:He;try reflexivity.
 - specialize (Hsub i Hi Hs);congruence.
 - pose proof (weight_strict_extra n s e i Hsub Hi Hs He);lia.
Qed.
Lemma good_subset_equal_weight n hs ls e s : good n hs ls e ->
 subset n s e -> weight n s=weight n e -> good n hs ls s.
Proof.
 intros [Hp [Hk [l [Hin Hl]]]] Hsub Hw.
 pose proof (subset_equal_weight_ext n s e Hsub Hw) as E.
 split;[lia|split].
 - intros h Hh;rewrite (parity_ext n h s e E);apply Hk;assumption.
 - exists l;split;[exact Hin|rewrite (parity_ext n l s e E);assumption].
Qed.
Lemma setbit_subset n s e q : subset n s e -> e q=true -> subset n (setbit s q) e.
Proof.
 intros Hsub He i Hi;unfold setbit;destruct (Nat.eqb i q) eqn:E.
 - apply Nat.eqb_eq in E;subst;auto.
 - apply Hsub;assumption.
Qed.
Lemma setbit_weight n s q : q<n -> s q=false -> weight n (setbit s q)=weight n s+1.
Proof.
 revert q;induction n as [|n IH];intros q Hq Hs;[lia|].
 change (weight n (setbit s q)+(if setbit s q n then 1 else 0)=
         weight n s+(if s n then 1 else 0)+1).
 destruct (Nat.eq_dec q n) as [->|Hneq].
 - assert (E:weight n (setbit s n)=weight n s).
   { apply weight_ext;intros i Hi;unfold setbit.
     assert (Nat.eqb i n=false) by (apply Nat.eqb_neq;lia). rewrite H;reflexivity. }
   rewrite E,Hs;unfold setbit;rewrite Nat.eqb_refl;lia.
 - rewrite (IH q ltac:(lia) Hs). unfold setbit.
   assert (Nat.eqb n q=false) by (apply Nat.eqb_neq;lia). rewrite H;lia.
Qed.
Lemma avoids_setbit n e f q : avoids n e f -> e q=false -> avoids n e (setbit f q).
Proof.
 intros Hf He i Hi;unfold setbit;destruct (Nat.eqb i q) eqn:E.
 - apply Nat.eqb_eq in E;subst;auto.
 - apply Hf;assumption.
Qed.
Definition candidates n h s f := filter (fun q=>h q && negb (s q || f q)) (seq 0 n).
Lemma candidates_spec n h s f q : In q (candidates n h s f) <->
 q<n /\ h q=true /\ s q=false /\ f q=false.
Proof.
 unfold candidates;rewrite filter_In,in_seq.
 rewrite andb_true_iff,negb_true_iff,orb_false_iff;intuition lia.
Qed.
Fixpoint walk (rec:vector->vector->option vector) s f (qs:list nat) : option vector :=
 match qs with
 | []=>None
 | q::tail=>match rec (setbit s q) f with
            | Some e=>Some e | None=>walk rec s (setbit f q) tail end
 end.
Definition prune_contract n hs ls cap (prune:vector->vector->option vector) :=
 forall e s f, minimum n hs ls e -> weight n e<=cap -> compatible n e s f ->
 exists f', prune s f=Some f' /\ avoids n e f'.
Fixpoint tree n hs ls (prune:vector->vector->option vector) fuel s f : option vector :=
 if goodb n hs ls s then Some s else
 match fuel with
 | O=>None
 | S smaller=>
   match find (fun h=>parity n h s) hs,prune s f with
   | Some h,Some f'=>walk (fun s' f''=>tree n hs ls prune smaller s' f'') s f' (candidates n h s f')
   | _,_=>None
   end
 end.
Lemma walk_sound rec s f qs (P:vector->Prop) :
 (forall a b e, rec a b=Some e -> P e) ->
 forall e, walk rec s f qs=Some e -> P e.
Proof.
 intros Hrec;revert f;induction qs as [|q qs IH];intros f e H;simpl in H;[discriminate|].
 destruct (rec (setbit s q) f) eqn:E.
 - inversion H;subst;eapply Hrec;eassumption.
 - eapply IH;exact H.
Qed.
Theorem tree_sound n hs ls prune fuel s f e :
 tree n hs ls prune fuel s f=Some e -> good n hs ls e.
Proof.
 revert s f e;induction fuel as [|fuel IH];intros s f e H;simpl in H;
 destruct (goodb n hs ls s) eqn:G.
 - inversion H;subst;apply goodb_spec;assumption.
 - discriminate.
 - inversion H;subst;apply goodb_spec;assumption.
 - destruct (find (fun h=>parity n h s) hs);[|discriminate].
   destruct (prune s f);[|discriminate].
   eapply walk_sound;[exact IH|exact H].
Qed.
Lemma walk_complete rec s e f qs n :
 avoids n e f ->
 (forall q f', In q qs -> e q=true -> avoids n e f' ->
              exists out, rec (setbit s q) f'=Some out) ->
 (exists q, In q qs /\ e q=true) ->
 exists out,walk rec s f qs=Some out.
Proof.
 revert f;induction qs as [|q qs IH];intros f Hf Hrec [hit [Hin He]];simpl in *;[contradiction|].
 destruct (rec (setbit s q) f) eqn:E;[eauto|].
 assert (Hq:e q=false).
 { destruct (e q) eqn:Eq;[|reflexivity].
   destruct (Hrec q f (or_introl eq_refl) Eq Hf) as [out Hout];congruence. }
 apply IH.
 - apply avoids_setbit;assumption.
 - intros a f' Ha Hea Hfa;apply Hrec;[right;exact Ha|exact Hea|exact Hfa].
 - exists hit;split;[destruct Hin;[subst;congruence|assumption]|exact He].
Qed.
Theorem tree_complete_for_minimum n hs ls prune fuel e s f cap :
 prune_contract n hs ls cap prune -> minimum n hs ls e -> weight n e<=cap -> compatible n e s f ->
 0<weight n s -> weight n e<=weight n s+fuel ->
 exists out, tree n hs ls prune fuel s f=Some out.
Proof.
 revert s f;induction fuel as [|fuel IH];intros s f Hpr Hmin Hcap [Hsub Havoid] Hpos Hbudget.
 - assert (Hw:weight n s=weight n e) by (pose proof (subset_split n s e Hsub);lia).
   assert (Hg:good n hs ls s) by (eapply good_subset_equal_weight;[exact (proj1 Hmin)|exact Hsub|exact Hw]).
   exists s;simpl;apply goodb_spec in Hg;rewrite Hg;reflexivity.
 - simpl;destruct (goodb n hs ls s) eqn:Gs;[eauto|].
   assert (Hlt:weight n s<weight n e).
   { pose proof (subset_split n s e Hsub) as E.
     destruct (Nat.eq_dec (weight n s) (weight n e)) as [Hw|Hw];[|lia].
     assert (Hg:good n hs ls s) by (eapply good_subset_equal_weight;[exact (proj1 Hmin)|exact Hsub|exact Hw]).
     apply goodb_spec in Hg;congruence. }
   assert (Hfound:exists h,find (fun h=>parity n h s) hs=Some h).
   { destruct (find (fun h=>parity n h s) hs) eqn:F;[eauto|].
     destruct (minimum_prefix_has_odd_row n hs ls e s Hmin Hsub Hpos Hlt) as [h [Hin Hodd]].
     apply find_none with (x:=h) in F;[congruence|assumption]. }
   destruct Hfound as [h F];rewrite F.
   destruct (Hpr e s f Hmin Hcap (conj Hsub Havoid)) as [f' [P Hf']];rewrite P.
   apply walk_complete with (e:=e) (n:=n).
   + exact Hf'.
   + intros q f'' Hq Heq Hf''.
     apply candidates_spec in Hq;destruct Hq as [Hqn [Hhq [Hsq Hfq]]].
     apply IH;[exact Hpr|exact Hmin|exact Hcap|split| |].
     * apply setbit_subset;assumption.
     * exact Hf''.
     * rewrite (setbit_weight n s q Hqn Hsq);lia.
     * rewrite (setbit_weight n s q Hqn Hsq);lia.
   + apply find_some in F;destruct F as [Hin Hodd].
     destruct (odd_row_has_target_extension n h s e Hsub Hodd (proj1 (proj2 (proj1 Hmin)) h Hin)) as [q [Hqn [Hhq [Heq Hsq]]]].
     exists q;split;[apply candidates_spec;repeat split;try assumption|exact Heq].
     destruct (f' q) eqn:Hfq;[specialize (Hf' q Hqn Hfq);congruence|reflexivity].
Qed.
Print Assumptions tree_sound.
Print Assumptions tree_complete_for_minimum.
Lemma walk_result rec s f qs e : walk rec s f qs=Some e ->
 exists q f', In q qs /\ rec (setbit s q) f'=Some e.
Proof.
 revert f;induction qs as [|q qs IH];intros f H;simpl in H;[discriminate|].
 destruct (rec (setbit s q) f) eqn:E.
 - inversion H;subst;exists q,f;split;[left;reflexivity|exact E].
 - destruct (IH (setbit f q) H) as [a [f' [Ha Hout]]].
   exists a,f';split;[right;assumption|assumption].
Qed.
Theorem tree_weight_bound n hs ls prune fuel s f e :
 tree n hs ls prune fuel s f=Some e -> weight n e<=weight n s+fuel.
Proof.
 revert s f e;induction fuel as [|fuel IH];intros s f e H;simpl in H;
 destruct (goodb n hs ls s) eqn:G;try (inversion H;subst;lia).
 destruct (find (fun h=>parity n h s) hs);[|discriminate].
 destruct (prune s f);[|discriminate].
 destruct (walk_result _ _ _ _ _ H) as [q [f' [Hq Hout]]].
 apply candidates_spec in Hq;destruct Hq as [Hqn [_ [Hsq _]]].
 specialize (IH _ _ _ Hout);rewrite (setbit_weight n s q Hqn Hsq) in IH;lia.
Qed.
Definition zero_vector : vector := fun _=>false.
Lemma zero_weight n : weight n zero_vector=0.
Proof. induction n;cbn [weight zero_vector];lia. Qed.
Lemma zero_subset n e : subset n zero_vector e.
Proof. intros i Hi H;discriminate H. Qed.
Lemma zero_avoids n e : avoids n e zero_vector.
Proof. intros i Hi H;discriminate H. Qed.
Lemma positive_weight_has_bit n e : 0<weight n e -> exists q,q<n /\ e q=true.
Proof.
 induction n as [|n IH];simpl;intros H;[lia|].
 destruct (e n) eqn:E.
 - exists n;split;[lia|assumption].
 - destruct (IH ltac:(lia)) as [q [Hq Hbit]];exists q;split;[lia|assumption].
Qed.
Definition root_search n hs ls prune cap : option vector :=
 match cap with
 | O=>None
 | S fuel=>walk (fun s f=>tree n hs ls prune fuel s f) zero_vector zero_vector (seq 0 n)
 end.
Theorem root_search_sound n hs ls prune cap e :
 root_search n hs ls prune cap=Some e -> good n hs ls e /\ weight n e<=cap.
Proof.
 destruct cap as [|fuel];simpl;intros H;[discriminate|].
 destruct (walk_result _ _ _ _ _ H) as [q [f [Hq Hout]]].
 apply in_seq in Hq.
 split;[eapply tree_sound;exact Hout|].
 pose proof (tree_weight_bound n hs ls prune fuel _ _ _ Hout) as Hw.
 rewrite (setbit_weight n zero_vector q ltac:(lia) eq_refl),zero_weight in Hw;lia.
Qed.
Theorem root_search_complete_minimum n hs ls prune cap e :
 prune_contract n hs ls cap prune -> minimum n hs ls e -> weight n e<=cap ->
 exists out,root_search n hs ls prune cap=Some out.
Proof.
 intros Hpr Hmin Hcap;destruct cap as [|fuel];simpl.
 - destruct Hmin as [[Hp _] _];lia.
 - apply walk_complete with (e:=e) (n:=n).
   + apply zero_avoids.
   + intros q f Hq Heq Havoid;apply in_seq in Hq.
     eapply tree_complete_for_minimum with (e:=e) (cap:=S fuel).
     * exact Hpr.
     * exact Hmin.
     * exact Hcap.
     * split;[apply setbit_subset;[apply zero_subset|assumption]|assumption].
     * rewrite (setbit_weight n zero_vector q ltac:(lia) eq_refl),zero_weight;lia.
     * rewrite (setbit_weight n zero_vector q ltac:(lia) eq_refl),zero_weight;lia.
   + destruct (positive_weight_has_bit n e (proj1 (proj1 Hmin))) as [q [Hqn Hbit]].
     exists q;split;[apply in_seq;lia|exact Hbit].
Qed.
(* Finite enumeration below is a proof device for existence of a minimum.
   The CC search does not run this exponential enumeration. *)
Definition put_last (n:nat) (b:bool) (v:vector) : vector :=
 fun i=>if Nat.eqb i n then b else v i.
Fixpoint all_vectors n : list vector :=
 match n with
 | O=>[zero_vector]
 | S k=>map (put_last k false) (all_vectors k) ++ map (put_last k true) (all_vectors k)
 end.
Lemma all_vectors_cover n e : exists v, In v (all_vectors n) /\
 forall i,i<n -> v i=e i.
Proof.
 induction n as [|n IH].
 - exists zero_vector;split;[simpl;auto|intros;lia].
 - destruct IH as [v [Hin Heq]].
   exists (put_last n (e n) v);split.
   + simpl;apply in_or_app;destruct (e n) eqn:E.
     * right;apply in_map;assumption.
     * left;apply in_map;assumption.
   + intros i Hi;unfold put_last;destruct (Nat.eqb i n) eqn:E.
     * apply Nat.eqb_eq in E;subst;reflexivity.
     * apply Nat.eqb_neq in E;apply Heq;lia.
Qed.
Lemma good_ext n hs ls e v : (forall i,i<n -> v i=e i) ->
 good n hs ls e -> good n hs ls v /\ weight n v=weight n e.
Proof.
 intros E [Hp [Hk [l [Hin Hl]]]].
 pose proof (weight_ext n v e E) as Hw;split;[|assumption].
 split;[lia|split].
 - intros h Hh;rewrite (parity_ext n h v e E);apply Hk;assumption.
 - exists l;split;[assumption|rewrite (parity_ext n l v e E);assumption].
Qed.
Fixpoint best_vector n hs ls (vs:list vector) : option vector :=
 match vs with
 | []=>None
 | v::tail=>
   if goodb n hs ls v then
     match best_vector n hs ls tail with
     | None=>Some v
     | Some w=>if weight n v <=? weight n w then Some v else Some w
     end
   else best_vector n hs ls tail
 end.
Lemma best_vector_none n hs ls vs : best_vector n hs ls vs=None ->
 forall v,In v vs -> ~good n hs ls v.
Proof.
 induction vs as [|v vs IH];simpl;intros H w Hin;[contradiction|].
 destruct (goodb n hs ls v) eqn:G.
 - destruct (best_vector n hs ls vs);[destruct (weight n v<=?weight n v0)|];discriminate.
 - destruct Hin as [<-|Hin].
   + intro Hg;apply goodb_spec in Hg;congruence.
   + apply IH;assumption.
Qed.
Lemma best_vector_spec n hs ls vs out : best_vector n hs ls vs=Some out ->
 In out vs /\ good n hs ls out /\ forall v,In v vs -> good n hs ls v -> weight n out<=weight n v.
Proof.
 revert out;induction vs as [|v vs IH];intros out H;simpl in H;[discriminate|].
 destruct (goodb n hs ls v) eqn:G.
 - apply goodb_spec in G;destruct (best_vector n hs ls vs) eqn:B.
   + specialize (IH v0 eq_refl);destruct IH as [Hin [Hg Hleast]].
     destruct (weight n v<=?weight n v0) eqn:Cmp;inversion H;subst.
     * apply Nat.leb_le in Cmp;split;[left;reflexivity|split;[assumption|]].
       intros w [<-|Hw] Hgw;[lia|specialize (Hleast w Hw Hgw);lia].
     * apply Nat.leb_gt in Cmp;split;[right;assumption|split;[assumption|]].
       intros w [<-|Hw] Hgw;[lia|apply Hleast;assumption].
   + inversion H;subst;split;[left;reflexivity|split;[assumption|]].
     intros w [<-|Hw] Hgw;[lia|].
     exfalso;apply (best_vector_none n hs ls vs B w Hw Hgw).
 - specialize (IH out H);destruct IH as [Hin [Hg Hleast]].
   split;[right;assumption|split;[assumption|]].
   intros w [<-|Hw] Hgw;[apply goodb_spec in Hgw;congruence|apply Hleast;assumption].
Qed.
Theorem minimum_exists_below_witness n hs ls e : good n hs ls e ->
 exists v, minimum n hs ls v /\ weight n v<=weight n e.
Proof.
 intros He;destruct (all_vectors_cover n e) as [ec [Hin E]].
 destruct (good_ext n hs ls e ec E He) as [Hec Hwc].
 destruct (best_vector n hs ls (all_vectors n)) eqn:B.
 - destruct (best_vector_spec n hs ls _ _ B) as [Hinv [Hgv Hleast]].
   exists v;split;[split;[assumption|]|specialize (Hleast ec Hin Hec);lia].
   intros f Hf;destruct (all_vectors_cover n f) as [fc [Hfin Ef]].
   destruct (good_ext n hs ls f fc Ef Hf) as [Hfc Hwf].
   specialize (Hleast fc Hfin Hfc);lia.
 - exfalso;apply (best_vector_none n hs ls _ B ec Hin Hec).
Qed.
Theorem root_search_complete n hs ls prune cap e :
 prune_contract n hs ls cap prune -> good n hs ls e -> weight n e<=cap ->
 exists out,root_search n hs ls prune cap=Some out.
Proof.
 intros Hpr He Hcap;destruct (minimum_exists_below_witness n hs ls e He) as [v [Hmin Hle]].
 eapply root_search_complete_minimum;[exact Hpr|exact Hmin|lia].
Qed.
Theorem root_search_empty_iff n hs ls prune cap :
 prune_contract n hs ls cap prune ->
 (root_search n hs ls prune cap=None <-> ~exists e,good n hs ls e /\ weight n e<=cap).
Proof.
 intros Hpr;split.
 - intros H [e [He Hcap]]. destruct (root_search_complete n hs ls prune cap e Hpr He Hcap) as [out Hout];congruence.
 - intros H;destruct (root_search n hs ls prune cap) eqn:R;[|reflexivity].
   exfalso;apply H;exists v;apply root_search_sound with (prune:=prune);assumption.
Qed.
Print Assumptions root_search_sound.
Print Assumptions minimum_exists_below_witness.
Print Assumptions root_search_empty_iff.
Definition no_prune (_:vector) (f:vector) := Some f.
Lemma no_prune_contract n hs ls cap : prune_contract n hs ls cap no_prune.
Proof. intros e s f _ _ [_ Hf];exists f;split;[reflexivity|assumption]. Qed.
Lemma vector_weight_bound n e : weight n e<=n.
Proof. induction n;simpl;[lia|destruct (e n);lia]. Qed.
Fixpoint distance_scan n hs ls (prune:nat->vector->vector->option vector) count cap : option vector :=
 match count with
 | O=>None
 | S remaining=>match root_search n hs ls (prune cap) cap with
           | Some e=>Some e | None=>distance_scan n hs ls prune remaining (S cap) end
 end.
Theorem distance_scan_found_minimum n hs ls prune count cap out :
 (forall c,prune_contract n hs ls c (prune c)) ->
 (forall e,good n hs ls e -> cap<=weight n e) ->
 distance_scan n hs ls prune count cap=Some out -> minimum n hs ls out.
Proof.
 revert cap;induction count as [|count IH];intros cap Hpr Hlb H;simpl in H;[discriminate|].
 destruct (root_search n hs ls (prune cap) cap) eqn:R.
 - inversion H;subst;destruct (root_search_sound n hs ls _ _ _ R) as [Hg Hcap].
   split;[assumption|intros e He;specialize (Hlb _ He);lia].
 - apply IH with (cap:=S cap);[exact Hpr| |exact H].
   intros e He;specialize (Hlb e He).
   assert (~weight n e<=cap).
   { intro Hle;pose proof (proj1 (root_search_empty_iff n hs ls _ cap (Hpr cap)) R) as Hempty.
     apply Hempty;exists e;split;assumption. }
   lia.
Qed.
(* Correct range contract includes cap<=weight(e). *)
Lemma distance_scan_complete n hs ls prune count cap e :
 (forall c,prune_contract n hs ls c (prune c)) ->
 good n hs ls e -> cap<=weight n e -> weight n e<cap+count ->
 exists out,distance_scan n hs ls prune count cap=Some out.
Proof.
 revert cap;induction count as [|count IH];intros cap Hpr He Hlo Hbudget;[lia|].
 simpl;destruct (root_search n hs ls (prune cap) cap) eqn:R;[eauto|].
 apply IH;[exact Hpr|exact He| |lia].
 assert (~weight n e<=cap).
 { intro Hle;pose proof (proj1 (root_search_empty_iff n hs ls _ cap (Hpr cap)) R) as Hempty.
   apply Hempty;exists e;split;assumption. }
 lia.
Qed.
Definition code_half_distance n hs ls prune := distance_scan n hs ls prune n 1.
Theorem code_half_distance_found n hs ls prune out :
 (forall c,prune_contract n hs ls c (prune c)) ->
 code_half_distance n hs ls prune=Some out -> minimum n hs ls out.
Proof.
 intros Hpr H;apply distance_scan_found_minimum with (count:=n) (cap:=1) (prune:=prune).
 - exact Hpr.
 - intros e [Hp _];lia.
 - exact H.
Qed.
Theorem code_half_distance_none n hs ls prune :
 (forall c,prune_contract n hs ls c (prune c)) ->
 (code_half_distance n hs ls prune=None <-> ~exists e,good n hs ls e).
Proof.
 intros Hpr;split.
 - intros H [e He].
   destruct (distance_scan_complete n hs ls prune n 1 e Hpr He) as [out Hout].
   + destruct He as [Hp _];lia.
   + pose proof (vector_weight_bound n e);lia.
   + unfold code_half_distance in H;congruence.
 - intros H;destruct (code_half_distance n hs ls prune) eqn:R;[|reflexivity].
   exfalso;apply H;exists v;apply (proj1 (code_half_distance_found n hs ls prune v Hpr R)).
Qed.
Print Assumptions code_half_distance_found.
Print Assumptions code_half_distance_none.

Theorem baseline_found_correct_for_all_inputs n hs ls out : code_half_distance n hs ls (fun _=>no_prune)=Some out -> minimum n hs ls out.
Proof. apply code_half_distance_found;intros c;apply no_prune_contract. Qed.
Theorem baseline_none_correct_for_all_inputs n hs ls : code_half_distance n hs ls (fun _=>no_prune)=None <-> ~exists e,good n hs ls e.
Proof. apply code_half_distance_none;intros c;apply no_prune_contract. Qed.
Print Assumptions baseline_found_correct_for_all_inputs.
Print Assumptions baseline_none_correct_for_all_inputs.
