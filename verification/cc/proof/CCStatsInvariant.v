(* Unsigned-counter obligations at the C fuel guard and pruning returns.
   Actual C loop refinement is separate. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCSearchSpecs.
Open Scope Z_scope.
Definition step_stats s :=
 {|stat_steps:=stat_steps s+1;stat_nodes:=stat_nodes s;stat_pack:=stat_pack s;
   stat_charge:=stat_charge s;stat_overlap:=stat_overlap s|}.
Definition node_stats s :=
 {|stat_steps:=stat_steps s+1;stat_nodes:=stat_nodes s+1;stat_pack:=stat_pack s;
   stat_charge:=stat_charge s;stat_overlap:=stat_overlap s|}.
Definition pack_stats s :=
 {|stat_steps:=stat_steps s;stat_nodes:=stat_nodes s;stat_pack:=stat_pack s+1;
   stat_charge:=stat_charge s;stat_overlap:=stat_overlap s|}.
Definition charge_stats s :=
 {|stat_steps:=stat_steps s;stat_nodes:=stat_nodes s;stat_pack:=stat_pack s;
   stat_charge:=stat_charge s+1;stat_overlap:=stat_overlap s|}.
Definition overlap_stats s :=
 {|stat_steps:=stat_steps s;stat_nodes:=stat_nodes s;stat_pack:=stat_pack s;
   stat_charge:=stat_charge s;stat_overlap:=stat_overlap s+1|}.
Theorem fuel_guard_counter_room budget s :
 legal_stats budget s ->stat_steps s<budget ->
 stat_steps s<Int.max_unsigned /\stat_nodes s<Int.max_unsigned /\
 stat_pack s<Int.max_unsigned /\stat_charge s<Int.max_unsigned /\stat_overlap s<Int.max_unsigned.
Proof. unfold legal_stats;intros;lia. Qed.
Theorem other_phase_step_safe budget s :legal_stats budget s ->stat_steps s<budget ->
 legal_stats budget(step_stats s) /\stats_monotone s(step_stats s).
Proof. unfold legal_stats,step_stats,stats_monotone;cbn;intros;lia. Qed.
Theorem entering_node_safe budget s :legal_stats budget s ->stat_steps s<budget ->
 legal_stats budget(node_stats s) /\stats_monotone s(node_stats s) /\
 stat_pack(node_stats s)<stat_nodes(node_stats s) /\
 stat_charge(node_stats s)<stat_nodes(node_stats s) /\
 stat_overlap(node_stats s)<stat_nodes(node_stats s).
Proof. unfold legal_stats,node_stats,stats_monotone;cbn;intros;lia. Qed.
Theorem pack_prune_safe budget s :legal_stats budget s ->stat_pack s<stat_nodes s ->
 legal_stats budget(pack_stats s) /\stats_monotone s(pack_stats s).
Proof. unfold legal_stats,pack_stats,stats_monotone;cbn;intros;lia. Qed.
Theorem charge_prune_safe budget s :legal_stats budget s ->stat_charge s<stat_nodes s ->
 legal_stats budget(charge_stats s) /\stats_monotone s(charge_stats s).
Proof. unfold legal_stats,charge_stats,stats_monotone;cbn;intros;lia. Qed.
Theorem overlap_prune_safe budget s :legal_stats budget s ->stat_overlap s<stat_nodes s ->
 legal_stats budget(overlap_stats s) /\stats_monotone s(overlap_stats s).
Proof. unfold legal_stats,overlap_stats,stats_monotone;cbn;intros;lia. Qed.
Lemma stats_monotone_trans a b c :stats_monotone a b ->stats_monotone b c ->stats_monotone a c.
Proof. unfold stats_monotone;intros;lia. Qed.
Print Assumptions fuel_guard_counter_room.
Print Assumptions entering_node_safe.
Print Assumptions overlap_prune_safe.
