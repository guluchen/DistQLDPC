(* Counter transitions for the actual phase0 caller. Pure arithmetic obligations;
   the corresponding complete C body is composed separately. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCSearchSpecs CCV.CCStatsInvariant CCV.CCLoopInvariant.
Open Scope Z_scope.
Definition node_only_stats s:={|
 stat_steps:=stat_steps s;stat_nodes:=stat_nodes s+1;stat_pack:=stat_pack s;
 stat_charge:=stat_charge s;stat_overlap:=stat_overlap s|}.
Definition bounds_stats s pc cc:={|
 stat_steps:=stat_steps s;stat_nodes:=stat_nodes s;stat_pack:=pc;
 stat_charge:=cc;stat_overlap:=stat_overlap s|}.
Lemma node_only_after_step s:node_only_stats(step_stats s)=node_stats s.
Proof. reflexivity. Qed.
Theorem node_only_safe budget s:
 legal_stats budget s ->stat_nodes s<stat_steps s ->
 legal_stats budget(node_only_stats s) /\stats_monotone s(node_only_stats s) /\
 stat_pack(node_only_stats s)<stat_nodes(node_only_stats s) /\
 stat_charge(node_only_stats s)<stat_nodes(node_only_stats s) /\
 stat_overlap(node_only_stats s)<stat_nodes(node_only_stats s).
Proof. unfold legal_stats,node_only_stats,stats_monotone;cbn;intros;lia. Qed.
Lemma step_creates_node_room budget s:
 legal_stats budget s ->stat_nodes(step_stats s)<stat_steps(step_stats s).
Proof. unfold legal_stats,step_stats;cbn;intros;lia. Qed.
Theorem bounds_stats_safe budget s pc cc:
 legal_stats budget s ->stat_pack s<stat_nodes s ->stat_charge s<stat_nodes s ->
 stat_pack s<=pc<=stat_pack s+1 ->stat_charge s<=cc<=stat_charge s+1 ->
 legal_stats budget(bounds_stats s pc cc) /\stats_monotone s(bounds_stats s pc cc).
Proof. unfold legal_stats,bounds_stats,stats_monotone;cbn;intros;lia. Qed.
Lemma loop_shape_replace_packed a cap seed path ghosts log buf xs ys zs oldpk newpk frames:
 loop_shape a cap seed path ghosts log buf xs ys zs oldpk frames ->
 Zlength newpk=model_n a ->Forall(fun z:Z=>z=0\/z=1)newpk ->
 loop_shape a cap seed path ghosts log buf xs ys zs newpk frames.
Proof. unfold loop_shape;intros;tauto. Qed.
Print Assumptions node_only_safe.
Print Assumptions bounds_stats_safe.
Print Assumptions loop_shape_replace_packed.
