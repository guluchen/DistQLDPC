(* Kernel-checked absence of recursive/indirect calls in the frozen library.
   This closes only the call-graph obligation, not loop termination. *)
Require Import VST.floyd.proofauto.
Require Import Coq.Arith.Wf_nat.
Require Import CCV.CCLinkedProgram.
Import ListNotations.
Fixpoint call_edges(s:statement):list(option ident):=
 match s with
 |Sskip|Sassign _ _|Sset _ _|Sbreak|Scontinue|Sreturn _=>[]
 |Scall _ f _=>[match f with Evar id _=>Some id|_=>None end]
 |Sbuiltin _ _ _ _|Sswitch _ _|Sgoto _=>[None]
 |Ssequence s t|Sifthenelse _ s t|Sloop s t=>call_edges s++call_edges t
 |Slabel _ t=>call_edges t
 end.
Definition call_rank(id:ident):option nat:=
 if existsb(Pos.eqb id)[ccv_primitives._ccv_bit_xor;ccv_primitives._ccv_ceil_div;
 ccv_primitives._ccv_dot;ccv_primitives._ccv_weight;ccv_primitives._ccv_toggle]
 then Some 0%nat else
 if existsb(Pos.eqb id)[ccv_core._shape;ccv_core._validate;ccv_core._clear;
 ccv_core._toggle;ccv_core._nontrivial;ccv_core._restore;ccv_core._forbid;ccv_core._stats_init]
 then Some 1%nat else
 if existsb(Pos.eqb id)[ccv_core._overlap;ccv_core._bounds;ccv_core._leaf]
 then Some 2%nat else
 if Pos.eqb id ccv_core._search then Some 3%nat else
 if existsb(Pos.eqb id)[ccv_core._ccv_decide;ccv_core._ccv_distance]
 then Some 4%nat else None.
Definition edge_below(owner:nat)(edge:option ident):bool:=
 match edge with Some id=>match call_rank id with Some rank=>Nat.ltb rank owner|None=>false end
 |None=>false end.
Definition checked_function(id:ident)(f:function):bool:=
 match call_rank id with
 |Some rank=>forallb(edge_below rank)(call_edges(fn_body f))
 |None=>false end.
Definition checked_global(d:ident*globdef Clight.fundef type):bool:=
 match d with (id,Gfun(Internal f))=>checked_function id f|_=>true end.
Definition checked_call_graph:bool:=forallb checked_global(prog_defs linked_prog).
Theorem actual_call_graph_checked:checked_call_graph=true.
Proof. vm_compute;reflexivity. Qed.
Lemma checked_function_edge id f callee:
 checked_function id f=true ->In(Some callee)(call_edges(fn_body f)) ->
 exists owner rank,call_rank id=Some owner /\call_rank callee=Some rank /\(rank<owner)%nat.
Proof.
 unfold checked_function;destruct(call_rank id)as[owner|]eqn:Owner;[|discriminate].
 intros Checked Member;rewrite forallb_forall in Checked.
 specialize(Checked(Some callee)Member);cbn[edge_below]in Checked.
 destruct(call_rank callee)as[rank|]eqn:Rank;[|discriminate].
 apply Nat.ltb_lt in Checked;exists owner,rank;auto.
Qed.
Definition actual_call_edge(callee caller:ident):Prop:=
 exists f,In(caller,Gfun(Internal f))(prog_defs linked_prog) /\
 In(Some callee)(call_edges(fn_body f)).
Lemma actual_edge_rank callee caller:
 actual_call_edge callee caller ->
 exists owner rank,call_rank caller=Some owner /\call_rank callee=Some rank /\(rank<owner)%nat.
Proof.
 intros[f[Member Edge]].
 pose proof actual_call_graph_checked as Checked.
 unfold checked_call_graph in Checked;rewrite forallb_forall in Checked.
 specialize(Checked(caller,Gfun(Internal f))Member);cbn[checked_global]in Checked.
 eapply checked_function_edge;eassumption.
Qed.
Theorem actual_functions_have_no_unchecked_edges id f:
 In(id,Gfun(Internal f))(prog_defs linked_prog) ->
 ~In None(call_edges(fn_body f)).
Proof.
 intros Member Missing;pose proof actual_call_graph_checked as Checked.
 unfold checked_call_graph in Checked;rewrite forallb_forall in Checked.
 specialize(Checked(id,Gfun(Internal f))Member);cbn[checked_global]in Checked.
 unfold checked_function in Checked;destruct(call_rank id)as[owner|]eqn:Rank;[|discriminate].
 rewrite forallb_forall in Checked;specialize(Checked None Missing);discriminate.
Qed.
Definition call_measure id:=match call_rank id with Some rank=>rank|None=>0%nat end.
Theorem actual_call_graph_well_founded:well_founded actual_call_edge.
Proof.
 apply(well_founded_lt_compat ident call_measure).
 intros callee caller Edge;destruct(actual_edge_rank _ _ Edge)as[owner[rank[Owner[Rank Lower]]]].
 unfold call_measure;rewrite Owner,Rank;exact Lower.
Qed.
Theorem actual_call_graph_irreflexive:forall id,~actual_call_edge id id.
Proof.
 intros id Edge;destruct(actual_edge_rank _ _ Edge)as[owner[rank[Owner[Rank Lower]]]].
 rewrite Owner in Rank;injection Rank;intro;subst;lia.
Qed.
Example recursive_search_mutant_rejected:
 forallb(edge_below 3)[Some ccv_core._search]=false.
Proof. vm_compute;reflexivity. Qed.
Example indirect_call_mutant_rejected:forallb(edge_below 4)[None]=false.
Proof. reflexivity. Qed.
Print Assumptions actual_call_graph_checked.
Print Assumptions actual_call_graph_well_founded.
Print Assumptions actual_call_graph_irreflexive.
Print Assumptions actual_functions_have_no_unchecked_edges.
