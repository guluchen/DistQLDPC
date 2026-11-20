From Coq Require Import ZArith List Bool.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCSearchSpecs CCV.CCPCMInput CCV.CCRawCSS CCV.CCPCMPair.
Import ListNotations. Local Open Scope Z_scope.
Definition input n m k h g:= {|width:=n;check_count:=m;same_count:=k;checks:=h;same_bytes:=g|}.
Definition prepared_det q := option_map model_lg (prepare_pcm_half q).
Example repetition_x : prepared_det (input 3 2 0 [1;1;0;0;1;1] [])=Some [1;0;0;0;1;0;0;0;1].
Proof. vm_compute;reflexivity. Qed.
Example repetition_z : prepared_det (swap_half(input 3 2 0 [1;1;0;0;1;1] []))=Some [1;1;1].
Proof. vm_compute;reflexivity. Qed.
Example dependent_and_zero_rows : prepared_det (input 2 0 3 [] [1;1;0;0;1;1])=Some [1;1].
Proof. vm_compute;reflexivity. Qed.
Example full_rowspan : prepared_det (input 2 0 2 [] [1;0;0;1])=Some [0;0].
Proof. vm_compute;reflexivity. Qed.
Example noncommuting_rejected : prepare_pcm_half (input 1 1 1 [1] [1])=None.
Proof. vm_compute;reflexivity. Qed.
Example bad_bit_rejected : prepare_pcm_half (input 2 0 1 [] [2;0])=None.
Proof. vm_compute;reflexivity. Qed.
Example short_matrix_rejected : prepare_pcm_half (input 3 1 0 [1;0] [])=None.
Proof. vm_compute;reflexivity. Qed.
Example zero_width_rejected : prepare_pcm_half (input 0 0 0 [] [])=None.
Proof. vm_compute;reflexivity. Qed.
Example over_extent_rejected : prepare_pcm_half (input 107374183 0 0 [] [])=None.
Proof. vm_compute;reflexivity. Qed.
Example partial_result_unresolved : join_halves 3 (found zero_vector) unresolved=unresolved.
Proof. reflexivity. Qed.
