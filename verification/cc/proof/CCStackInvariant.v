(* Candidate whole-loop ghost invariant, with checked projection/root-exit facts.
   Its preservation by all actual C iterations is NOT established here. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchHeap CCV.CCModel
 CCV.CCFunctional CCV.CCSearchPhases CCV.CCCriticalFrame CCV.CCProtectedFrames
 CCV.CCRepresentation CCV.CCJournalArray CCV.CCSeedCoverage.
Import ListNotations. Open Scope nat_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Record ghost_frame:Type:={
 ghost_phase:nat;ghost_row:nat;ghost_next:nat;ghost_chosen:nat;ghost_mark:Z
}.
Definition empty_ghost:ghost_frame:={|
 ghost_phase:=0;ghost_row:=0;ghost_next:=0;ghost_chosen:=0;ghost_mark:=0%Z|}.
Definition frame_represents(g:ghost_frame)(raw:frame_value):Prop:=
 let mark:=Vint(Int.repr(ghost_mark g))in
 match ghost_phase g with
 |0=>exists r nx ch:val,raw=(r,(nx,(ch,(mark,Vint Int.zero))))
 |1=>exists ch:val,raw=(Vint(Int.repr(Z.of_nat(ghost_row g))),
   (Vint(Int.repr(Z.of_nat(ghost_next g))),(ch,(mark,Vint(Int.repr 1)))))
 |2=>raw=(Vint(Int.repr(Z.of_nat(ghost_row g))),
   (Vint(Int.repr(Z.of_nat(ghost_next g))),
    (Vint(Int.repr(Z.of_nat(ghost_chosen g))),(mark,Vint(Int.repr 2)))))
 |_=>False end.
Definition prefix_selected(path:list nat)k:=path_bits(firstn(S k)path).
Definition frame_snapshot (n:nat) base log(ghosts:list ghost_frame)k:vector:=
 if lt_dec(S k)(length ghosts)then
 decode(journal_bitmap base(sublist 0(ghost_mark(nth(S k)ghosts empty_ghost))log))
 else decode(journal_bitmap base log).
Definition critical_at n hs base log path ghosts e k:=exists g,
 nth_error ghosts k=Some g /\
 let s:=prefix_selected path k in
 let f:=frame_snapshot n base log ghosts k in
 match ghost_phase g with
 |0=>compatible n e s f
 |1=>critical_frame n(nth(ghost_row g)hs zero_vector)e s f(ghost_next g)
 |2=>critical_frame n(nth(ghost_row g)hs zero_vector)e s f(ghost_next g)/\e(ghost_chosen g)=false
 |_=>False end.
Definition target_stack_live n hs ls cap seed base log path ghosts:=forall e,
 minimum n hs ls e ->weight n e<=cap ->e seed=true ->
 exists k,critical_at n hs base log path ghosts e k.
Definition physical_stack n(ghosts:list ghost_frame)(raw:list frame_value):Prop:=
 Zlength raw=Z.of_nat n /\forall k,k<n ->
 if lt_dec k(length ghosts)then
 frame_represents(nth k ghosts empty_ghost)(Znth(Z.of_nat k)raw)
 else Znth(Z.of_nat k)raw=@default_val CCSearchSpecs.CompSpecs CCSearchSpecs.frame_type.
Definition stack_geometry n m cap hs(path:list nat)(ghosts:list ghost_frame)(log:list Z):Prop:=
 length path=length ghosts /\NoDup path /\Forall(fun q=>q<n)path /\
 (length path=0\/0<length path<=cap) /\
 forall k g,nth_error ghosts k=Some g ->
 ghost_phase g<=2 /\(0<=ghost_mark g<=Zlength log)%Z /\
 (k=0->ghost_mark g=0%Z) /\
 (S k<length ghosts ->ghost_phase g=2 /\ghost_chosen g=nth(S k)path 0 /\
   ghost_next g=S(ghost_chosen g) /\
   (ghost_mark g<=ghost_mark(nth(S k)ghosts empty_ghost))%Z) /\
 ((ghost_phase g=1\/ghost_phase g=2)->
   ghost_row g<m /\ghost_next g<=n /\S k<cap /\
   parity n(nth(ghost_row g)hs zero_vector)(prefix_selected path k)=true).
Lemma critical_at_index n hs base log path ghosts e k:
 critical_at n hs base log path ghosts e k ->k<length ghosts.
Proof.
 intros[g[At Critical]].
 apply nth_error_Some;rewrite At;discriminate.
Qed.
Theorem empty_stack_has_no_target n hs ls cap seed base log path:
 target_stack_live n hs ls cap seed base log path [] ->
 forall e,minimum n hs ls e ->weight n e<=cap ->e seed=true ->False.
Proof.
 intros Live e Min Cap Hit.
 destruct(Live e Min Cap Hit)as[k Critical].
 pose proof(critical_at_index _ _ _ _ _ _ _ _ Critical);simpl in *;lia.
Qed.
Theorem empty_stack_advances_seed n hs ls cap seed base log path:
 seeds_before_clear n hs ls cap seed ->
 target_stack_live n hs ls cap seed base log path [] ->
 seeds_before_clear n hs ls cap(S seed).
Proof.
 intros Before Live;apply completed_seed_advances;[assumption|].
 apply(empty_stack_has_no_target n hs ls cap seed base log path);assumption.
Qed.
Print Assumptions critical_at_index.
Print Assumptions empty_stack_advances_seed.
