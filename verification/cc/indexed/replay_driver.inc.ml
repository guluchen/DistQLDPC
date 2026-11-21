external kernel_decide :
  (int * int * int * int) -> (bytes * bytes * bytes) -> (int * int * int) -> int * bytes
  = "caml_ccv_decide"

(* The checked packed search can exclude smaller words on up to three
   63-bit lanes. Limit speculative work before falling back to bounded C. *)
let packed_trial n ax az side ws calls =
  if n > 189 || List.exists (fun a -> a.model_m > 189 || a.model_l > 189) [ax;az]
  then None else
    let remaining = ref calls in
    let make_choice rows =
      let choose = Packed_advice.make_choice rows in
      fun sy free k ->
        if !remaining = 0 then raise Packed_advice.Advice_limit;
        decr remaining; choose sy free k
    in
    let p,inv = Packed_advice.dual_candidate n ax az in
    let advice = {Packed_advice.advice with make_choice} in
    try packed_report n ax az side ws advice p inv with Packed_advice.Advice_limit -> None

let () =
  try
    if Sys.word_size <> 64 || Array.length Sys.argv <> 6 then
      invalid_arg "usage: pcm-check WIDTH HX HZ BUDGET RULES (stdin: X or Z, then witness)";
    let n = checked_width Sys.argv.(1) in
    let budget = int_of_string Sys.argv.(4) and rules = int_of_string Sys.argv.(5) in
    if budget < 0 || budget > 4294967295 || rules < 0 || rules > 63 then
      invalid_arg "invalid search limits";
    let cmd = read_line () in
    let hx = read_matrix Sys.argv.(2) and hz = read_matrix Sys.argv.(3) in
    let ax = prepare_half n hz hx and az = prepare_half n hx hz in
    if cmd = "PROPOSE" then begin
      if n < 96 || n > 189 || budget <> 100000000 ||
         List.exists (fun a -> a.model_m > 189 || a.model_l > 189) [ax;az]
      then exit (print_report OutOfBudget);
      let dx,x = Packed_advice.upper n ax az and dz,z = Packed_advice.upper n az ax in
      let d,side,word = if dx <= dz then dx,true,x else dz,false,z in
      if d < 7 || d > 18 then exit (print_report OutOfBudget);
      match packed_trial n ax az side word 2000000 with
      | Some answer -> exit (print_report answer)
      | None -> exit (print_report OutOfBudget)
    end;
    let x_side = match cmd with
      | "X" -> true | "Z" -> false | _ -> invalid_arg "invalid Pauli side" in
    let word = read_line () in
    if String.length word <> n then invalid_arg "wrong witness width";
    let ws = List.init n (fun i -> match word.[i] with
      | '1' -> true | '0' -> false | _ -> invalid_arg "nonbinary witness") in
    if not (replay_upper n ax az x_side ws) then exit (print_report OutOfBudget);
    let cap = replay_cap n ws in
    if budget = 100000000 && cap >= 6 && cap < 18 then
      (match packed_trial n ax az x_side ws 2000000 with
       | Some answer -> exit (print_report answer) | None -> ());
    let query a =
      fst (kernel_decide (n,a.model_m,a.model_l,a.model_k)
        (matrix_bytes a.model_h, matrix_bytes a.model_lg, matrix_bytes a.model_g)
        (budget,rules,cap))
    in
    let rx = query ax in
    if rx <> 0 then exit (print_report OutOfBudget);
    let _,mx,x = hx and _,mz,z = hz in
    let raw = {width=n;check_count=mz;same_count=mx;checks=z;same_bytes=x} in
    let rz = match Dual_advice.propose n hx hz with
      | Some (p,a,b) when raw_dual_check raw p a b -> rx
      | _ -> query az in
    match replay_report n ax az x_side ws rx rz with
    | Some answer -> exit (print_report answer)
    | None -> exit (print_report OutOfBudget)
  with Invalid_argument msg | Sys_error msg | Failure msg ->
    prerr_endline msg; exit 2
