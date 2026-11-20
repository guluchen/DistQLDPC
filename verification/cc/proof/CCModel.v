(* SPDX-License-Identifier: GPL-3.0-or-later
   Pure algorithm mathematics, not a VST body proof of ccv.c. *)
From Coq Require Import Bool List Arith Lia.
Import ListNotations.
Definition vector := nat -> bool.
Definition vxor (a b:vector) : vector := fun i => xorb (a i) (b i).
Definition vdiff (a b:vector) : vector := fun i => andb (a i) (negb (b i)).
Definition subset (n:nat) (s e:vector) := forall i, i<n -> s i=true -> e i=true.
Fixpoint weight (n:nat) (e:vector) : nat :=
 match n with O=>O | S k=>weight k e + if e k then 1 else 0 end.
Fixpoint parity (n:nat) (h e:vector) : bool :=
 match n with O=>false | S k=>xorb (andb (h k) (e k)) (parity k h e) end.
Definition kernel n (hs:list vector) e := forall h, In h hs -> parity n h e=false.
Definition logical n (ls:list vector) e := exists l, In l ls /\ parity n l e=true.
Definition good n hs ls e := 0<weight n e /\ kernel n hs e /\ logical n ls e.
Definition minimum n hs ls e := good n hs ls e /\
 forall f, good n hs ls f -> weight n e<=weight n f.
Lemma parity_xor n h a b :
 parity n h (vxor a b)=xorb (parity n h a) (parity n h b).
Proof.
 induction n as [|n IH]; simpl; [reflexivity|].
 rewrite IH. unfold vxor.
 destruct (h n), (a n), (b n), (parity n h a), (parity n h b); reflexivity.
Qed.
Lemma subset_down n s e : subset (S n) s e -> subset n s e.
Proof. unfold subset; intros H i Hi; apply H; lia. Qed.
Lemma subset_split n s e : subset n s e ->
 weight n e=weight n s+weight n (vdiff e s).
Proof.
 induction n as [|n IH]; intros H; simpl; [reflexivity|].
 rewrite (IH (subset_down n s e H)). unfold vdiff.
 specialize (H n ltac:(lia)).
 destruct (s n) eqn:Hs, (e n) eqn:He; simpl in *; try lia.
Qed.
Lemma parity_split n h s e : subset n s e ->
 parity n h e=xorb (parity n h s) (parity n h (vdiff e s)).
Proof.
 induction n as [|n IH]; intros H; simpl; [reflexivity|].
 rewrite (IH (subset_down n s e H)). unfold vdiff.
 assert (Hbit: s n=true -> e n=true) by (apply H; lia).
 destruct (s n), (e n), (h n), (parity n h s),
 (parity n h (fun i => e i && negb (s i))); simpl in *; try reflexivity;
 exfalso; specialize (Hbit eq_refl); discriminate.
Qed.
Lemma existsb_parity_false n rows s :
 existsb (fun h=>parity n h s) rows=false ->
 forall h, In h rows -> parity n h s=false.
Proof.
 intros H h Hin. destruct (parity n h s) eqn:E; [|reflexivity].
 assert (existsb (fun h=>parity n h s) rows=true).
 { apply existsb_exists. exists h; split; assumption. }
 congruence.
Qed.
(* Core CC completeness ingredient: every nonempty proper subset of a
   globally minimum logical target has an odd check. *)
Theorem minimum_prefix_has_odd_row n hs ls e s :
 minimum n hs ls e -> subset n s e ->
 0<weight n s -> weight n s<weight n e ->
 exists h, In h hs /\ parity n h s=true.
Proof.
 intros [He Hmin] Hsub Hpos Hlt.
 destruct (existsb (fun h=>parity n h s) hs) eqn:Hsyn.
 - apply existsb_exists in Hsyn; exact Hsyn.
 - assert (Hker:kernel n hs s) by (intros h Hin; exact (existsb_parity_false n hs s Hsyn h Hin)).
   destruct (existsb (fun l=>parity n l s) ls) eqn:Hlog.
   + apply existsb_exists in Hlog.
     assert (Hg:good n hs ls s) by (split;[exact Hpos|split;assumption]).
     specialize (Hmin s Hg); lia.
   + assert (Hsplit:weight n e=weight n s+weight n (vdiff e s))
       by (apply subset_split; exact Hsub).
     destruct He as [Hep [Hek [l [Hin Hl]]]].
     assert (Hdk:kernel n hs (vdiff e s)).
     { intros h Hh. specialize (Hek h Hh). specialize (Hker h Hh).
       pose proof (parity_split n h s e Hsub) as E.
       rewrite Hek,Hker in E. simpl in E; symmetry; exact E. }
     assert (Hdl:logical n ls (vdiff e s)).
     { exists l; split; [exact Hin|].
       pose proof (existsb_parity_false n ls s Hlog l Hin) as Hsl.
       pose proof (parity_split n l s e Hsub) as E.
       rewrite Hl,Hsl in E. simpl in E; symmetry; exact E. }
     assert (Hdg:good n hs ls (vdiff e s)) by (split;[lia|split;assumption]).
     specialize (Hmin (vdiff e s) Hdg); lia.
Qed.
(* First target candidate in a branch leaves all earlier siblings outside e.
   This local lemma is composable with pruning that preserves that same e. *)
Theorem first_target_sibling_safe (candidates:list nat) (target:nat->bool) a before after :
 candidates=before++a::after -> target a=true ->
 Forall (fun q=>target q=false) before ->
 ~ In a before /\ forall q, In q before -> target q=false.
Proof.
 intros _ Ha Hbefore; split.
 - intro Hin. rewrite Forall_forall in Hbefore.
   specialize (Hbefore a Hin); congruence.
 - intros q Hin. rewrite Forall_forall in Hbefore; auto.
Qed.
(* Packing/charge arithmetic is pure natural-number arithmetic; the link to
   actual row scans and candidate ownership is a separate VST obligation. *)
Theorem packing_prune_sound pack remaining needed :
 pack<=needed -> needed<=remaining -> pack>remaining -> False.
Proof. lia. Qed.
Theorem charge_prune_sound odd maxdeg remaining needed :
 0<maxdeg -> odd<=needed*maxdeg -> needed<=remaining ->
 remaining*maxdeg<odd -> False.
Proof. intros Hd Hi Hn Hbad; nia. Qed.
Print Assumptions minimum_prefix_has_odd_row.
Print Assumptions first_target_sibling_safe.
Print Assumptions packing_prune_sound.
Print Assumptions charge_prune_sound.
Definition vinter (a b:vector) : vector := fun i=>andb (a i) (b i).
Lemma xor_weight_balance n a b :
 weight n (vxor a b)+2*weight n (vinter a b)=weight n a+weight n b.
Proof.
 induction n as [|n IH]; simpl; [lia|]. unfold vxor,vinter in *.
 destruct (a n),(b n); simpl in *; lia.
Qed.
Lemma xor_good n hs ls e g :
 good n hs ls e -> kernel n hs g ->
 (forall l, In l ls -> parity n l g=false) ->
 logical n ls (vxor e g) /\ kernel n hs (vxor e g).
Proof.
 intros [_ [Hek [l [Hin Hl]]]] Hg Hgl; split.
 - exists l; split; [assumption|]. rewrite parity_xor,Hl,(Hgl l Hin); reflexivity.
 - intros h Hh; rewrite parity_xor,(Hek h Hh),(Hg h Hh); reflexivity.
Qed.
Lemma weight_zero_parity_false n h e : weight n e=0 -> parity n h e=false.
Proof.
 induction n as [|n IH]; simpl; [reflexivity|].
 destruct (e n) eqn:En; simpl; intros H; [lia|].
 rewrite andb_false_r. simpl. apply IH; lia.
Qed.
Lemma logical_positive n ls e : logical n ls e -> 0<weight n e.
Proof.
 intros [l [_ Hl]]. destruct (weight n e) eqn:E; [|lia].
 pose proof (weight_zero_parity_false n l e E); congruence.
Qed.
Theorem minimum_stabilizer_overlap n hs ls e g :
 minimum n hs ls e -> kernel n hs g ->
 (forall l, In l ls -> parity n l g=false) ->
 2*weight n (vinter e g)<=weight n g.
Proof.
 intros [He Hmin] Hg Hgl.
 destruct (xor_good n hs ls e g He Hg Hgl) as [Hlog Hker].
 assert (Hgood:good n hs ls (vxor e g)).
 { split; [apply (logical_positive n ls);assumption|split;assumption]. }
 specialize (Hmin (vxor e g) Hgood).
 pose proof (xor_weight_balance n e g); lia.
Qed.
Lemma intersection_mono n s e g : subset n s e ->
 weight n (vinter s g)<=weight n (vinter e g).
Proof.
 induction n as [|n IH]; intros H; simpl; [lia|].
 specialize (IH (subset_down n s e H)). unfold vinter in *.
 assert (HB:s n=true -> e n=true) by (apply H;lia).
 destruct (s n),(e n),(g n);simpl in *;try lia;
 exfalso;specialize (HB eq_refl);discriminate.
Qed.
Theorem overlap_prune_preserves_minimum n hs ls e g s :
 minimum n hs ls e -> kernel n hs g ->
 (forall l, In l ls -> parity n l g=false) -> subset n s e ->
 weight n g<2*weight n (vinter s g) -> False.
Proof.
 intros Hmin Hg Hgl Hsub Hbad.
 pose proof (minimum_stabilizer_overlap n hs ls e g Hmin Hg Hgl).
 pose proof (intersection_mono n s e g Hsub);lia.
Qed.
Print Assumptions minimum_stabilizer_overlap.
Print Assumptions overlap_prune_preserves_minimum.
(* A real candidate-set packing lemma, not just its final arithmetic test. *)
Lemma forall2_right_member {A B:Type} (R:A->B->Prop) xs ys y :
 Forall2 R xs ys -> In y ys -> exists x, In x xs /\ R x y.
Proof.
 intros HR; induction HR as [|a b xs ys Hab Hrest IH]; simpl; intros Hin.
 - contradiction.
 - destruct Hin as [<-|Hin].
   + exists a;split;[left;reflexivity|assumption].
   + destruct (IH Hin) as [x [Hx HRx]]. exists x;split;[right;assumption|assumption].
Qed.
Lemma disjoint_transversal (rows:list nat) (candidates:nat->list nat) (target:list nat) :
 NoDup rows ->
 (forall r r' q, In r rows -> In r' rows -> r<>r' ->
   In q (candidates r) -> In q (candidates r') -> False) ->
 (forall r, In r rows -> exists q, In q (candidates r) /\ In q target) ->
 exists chosen, Forall2 (fun r q=>In q (candidates r)/\In q target) rows chosen /\ NoDup chosen.
Proof.
 intros Hnd; induction Hnd as [|r rows Hnot Hnd IH]; intros Hd Hhit.
 - exists [];split;constructor.
 - destruct (Hhit r (or_introl eq_refl)) as [q [Hqc Hqt]].
   assert (Hd':forall a b x, In a rows -> In b rows -> a<>b ->
     In x (candidates a) -> In x (candidates b) -> False).
   { intros a b x Ha Hb Hneq Hax Hbx.
     eapply Hd;[right;exact Ha|right;exact Hb|exact Hneq|exact Hax|exact Hbx]. }
   assert (Hhit':forall a, In a rows -> exists x, In x (candidates a)/\In x target).
   { intros a Ha;apply Hhit;right;assumption. }
   destruct (IH Hd' Hhit') as [chosen [HR Hchosen]].
   exists (q::chosen);split.
   + constructor;[split;assumption|exact HR].
   + constructor;[|exact Hchosen]. intro Hq.
     destruct (forall2_right_member _ _ _ _ HR Hq) as [r' [Hr' [Hqr' _]]].
     assert (Hneq:r<>r') by (intro E;subst;contradiction).
     eapply Hd;[left;reflexivity|right;exact Hr'|exact Hneq|exact Hqc|exact Hqr'].
Qed.
Theorem disjoint_odd_row_packing_bound (rows:list nat) (candidates:nat->list nat) (target:list nat) :
 NoDup rows ->
 (forall r r' q, In r rows -> In r' rows -> r<>r' ->
   In q (candidates r) -> In q (candidates r') -> False) ->
 (forall r, In r rows -> exists q, In q (candidates r) /\ In q target) ->
 length rows<=length target.
Proof.
 intros Hnd Hd Hhit.
 destruct (disjoint_transversal rows candidates target Hnd Hd Hhit) as [chosen [HR Hchosen]].
 assert (Hincl:incl chosen target).
 { intros q Hq;destruct (forall2_right_member _ _ _ _ HR Hq) as [r [_ [_ Hqt]]];assumption. }
 assert (Hlen:length rows=length chosen).
 { clear - HR. induction HR;simpl;congruence. }
 assert (Hbound:length chosen<=length target) by (apply NoDup_incl_length;assumption). lia.
Qed.
Lemma weight_strict_extra n s e q : subset n s e -> q<n ->
 s q=false -> e q=true -> weight n s<weight n e.
Proof.
 revert q;induction n as [|n IH];intros q Hsub Hq Hsq Heq;[lia|].
 assert (Hd:subset n s e) by (apply subset_down;exact Hsub).
 assert (HB:s n=true -> e n=true) by (apply Hsub;lia).
 destruct (Nat.eq_dec q n) as [E|Hneq].
 - subst q. simpl. rewrite Hsq,Heq. simpl.
   pose proof (subset_split n s e Hd);lia.
 - assert (Hqn:q<n) by lia.
   specialize (IH q Hd Hqn Hsq Heq). simpl.
   destruct (s n),(e n);simpl in *;try lia;
   exfalso;specialize (HB eq_refl);discriminate.
Qed.
Theorem tight_overlap_forbid n hs ls e g s limit q :
 minimum n hs ls e -> kernel n hs g ->
 (forall l, In l ls -> parity n l g=false) -> subset n s e ->
 weight n (vinter s g)=limit -> weight n g<2*(limit+1) ->
 q<n -> g q=true -> s q=false -> e q=false.
Proof.
 intros Hmin Hg Hgl Hsub Htight Hround Hq Hgq Hsq.
 destruct (e q) eqn:Heq;[|reflexivity].
 pose proof (minimum_stabilizer_overlap n hs ls e g Hmin Hg Hgl) as Hlimit.
 assert (Hsub':subset n (vinter s g) (vinter e g)).
 { intros i Hi Hsi. unfold vinter in *. apply andb_true_iff in Hsi.
   destruct Hsi as [Hs Hg'];apply andb_true_iff;split;[eapply Hsub;eassumption|assumption]. }
 assert (HS:vinter s g q=false) by (unfold vinter;rewrite Hsq;reflexivity).
 assert (HE:vinter e g q=true) by (unfold vinter;rewrite Heq,Hgq;reflexivity).
 pose proof (weight_strict_extra n (vinter s g) (vinter e g) q Hsub' Hq HS HE).
 lia.
Qed.
Print Assumptions disjoint_odd_row_packing_bound.
Print Assumptions tight_overlap_forbid.
Lemma odd_parity_has_column n h e : parity n h e=true ->
 exists q, q<n /\ h q=true /\ e q=true.
Proof.
 induction n as [|n IH];simpl;intros H;[discriminate|].
 destruct (andb (h n) (e n)) eqn:Hbit.
 - apply andb_true_iff in Hbit. destruct Hbit as [Hh He].
   exists n;repeat split;try assumption;lia.
 - simpl in H. destruct (IH H) as [q [Hq [Hh He]]].
   exists q;repeat split;try assumption;lia.
Qed.
Theorem odd_row_has_target_extension n h s e :
 subset n s e -> parity n h s=true -> parity n h e=false ->
 exists q, q<n /\ h q=true /\ e q=true /\ s q=false.
Proof.
 intros Hsub Hs He.
 pose proof (parity_split n h s e Hsub) as E.
 rewrite Hs,He in E.
 assert (Hd:parity n h (vdiff e s)=true).
 { destruct (parity n h (vdiff e s));simpl in E;congruence. }
 destruct (odd_parity_has_column n h (vdiff e s) Hd) as [q [Hq [Hh Hdiff]]].
 unfold vdiff in Hdiff;apply andb_true_iff in Hdiff;destruct Hdiff as [Heq Hsq].
 apply negb_true_iff in Hsq.
 exists q;repeat split;assumption.
Qed.
(* Finite double counting justifies the uniform charge bound from actual row
   coverage and per-column degree assumptions, rather than assuming its result. *)
Fixpoint sumover (xs:list nat) (f:nat->nat) : nat :=
 match xs with []=>0 | x::tail=>f x+sumover tail f end.
Lemma sumover_plus xs f g :
 sumover xs (fun x=>f x+g x)=sumover xs f+sumover xs g.
Proof. induction xs;simpl;lia. Qed.
Lemma sumover_lower_one xs f :
 (forall x, In x xs -> 1<=f x) -> length xs<=sumover xs f.
Proof.
 induction xs as [|x xs IH];simpl;intros H;[lia|].
 assert (Hx:1<=f x) by (apply H;left;reflexivity).
 assert (Ht:forall y, In y xs -> 1<=f y) by (intros y Hy;apply H;right;assumption).
 specialize (IH Ht);lia.
Qed.
Lemma sumover_upper xs f d :
 (forall x, In x xs -> f x<=d) -> sumover xs f<=length xs*d.
Proof.
 induction xs as [|x xs IH];simpl;intros H;[lia|].
 assert (Hx:f x<=d) by (apply H;left;reflexivity).
 assert (Ht:forall y, In y xs -> f y<=d) by (intros y Hy;apply H;right;assumption).
 specialize (IH Ht);lia.
Qed.
Lemma sumover_hit xs (f:nat->bool) :
 (exists x, In x xs /\ f x=true) -> 1<=sumover xs (fun x=>if f x then 1 else 0).
Proof.
 induction xs as [|x xs IH];simpl;intros [q [Hq Hf]];[contradiction|].
 destruct Hq as [<-|Hq].
 - rewrite Hf;lia.
 - assert (Ht:exists q, In q xs /\ f q=true) by (exists q;split;assumption).
   specialize (IH Ht);destruct (f x);lia.
Qed.
Lemma incidence_double_count rows cols (hit:nat->nat->bool) :
 sumover rows (fun r=>sumover cols (fun q=>if hit r q then 1 else 0))=
 sumover cols (fun q=>sumover rows (fun r=>if hit r q then 1 else 0)).
Proof.
 induction rows as [|r rows IH].
 - simpl;induction cols;simpl;lia.
 - change ((sumover cols (fun q=>if hit r q then 1 else 0)+
           sumover rows (fun r=>sumover cols (fun q=>if hit r q then 1 else 0)))=
          sumover cols (fun q=>(if hit r q then 1 else 0)+
           sumover rows (fun r=>if hit r q then 1 else 0))).
   rewrite sumover_plus,IH;reflexivity.
Qed.
Theorem uniform_charge_bound rows completion (hit:nat->nat->bool) maxdeg :
 (forall r, In r rows -> exists q, In q completion /\ hit r q=true) ->
 (forall q, In q completion -> sumover rows (fun r=>if hit r q then 1 else 0)<=maxdeg) ->
 length rows<=length completion*maxdeg.
Proof.
 intros Hcover Hdeg.
 assert (Hrow:length rows<=sumover rows (fun r=>sumover completion (fun q=>if hit r q then 1 else 0))).
 { apply sumover_lower_one. intros r Hr. apply sumover_hit;apply Hcover;assumption. }
 assert (Hcol:sumover completion (fun q=>sumover rows (fun r=>if hit r q then 1 else 0))<=length completion*maxdeg).
 { apply sumover_upper;assumption. }
 rewrite incidence_double_count in Hrow;lia.
Qed.
Definition ceil_nat a b := a/b + if a mod b =? 0 then 0 else 1.
Theorem ceil_nat_minimal a b k : 0<b ->
 (ceil_nat a b<=k <-> a<=k*b).
Proof.
 intros Hb. unfold ceil_nat.
 pose proof (Nat.div_mod a b ltac:(lia)) as Hsplit.
 pose proof (Nat.mod_upper_bound a b ltac:(lia)) as Hrem.
 destruct (a mod b =? 0) eqn:E.
 - apply Nat.eqb_eq in E. rewrite E in Hsplit. split;intros H;nia.
 - apply Nat.eqb_neq in E. split;intros H;nia.
Qed.
Print Assumptions odd_row_has_target_extension.
Print Assumptions uniform_charge_bound.
Print Assumptions ceil_nat_minimal.
