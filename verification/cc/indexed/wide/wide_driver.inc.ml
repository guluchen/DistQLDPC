let () =
  try
    if Array.length Sys.argv < 4 || Array.length Sys.argv > 6 then invalid_arg "usage: pcm-wide WIDTH HX HZ";
    let n=checked_width Sys.argv.(1) in
    if n > 378 then exit (print_report OutOfBudget);
    let hx=read_matrix Sys.argv.(2) and hz=read_matrix Sys.argv.(3) in
    let ax=prepare_half n hz hx and az=prepare_half n hx hz in
    if List.exists (fun a->a.model_m>378 || a.model_l>378) [ax;az] then exit(print_report OutOfBudget);
    let side=match read_line() with "X"->true |"Z"->false |_->invalid_arg "invalid side" in
    let bits=read_line() in if String.length bits<>n then invalid_arg "incorrect witness width";
    let w=List.init n(fun i->match bits.[i] with '0'->false|'1'->true|_->invalid_arg "nonbinary witness") in
    let p,inv=match Dual_advice.propose n hx hz with Some(v,_,_)->v,v |None->[],[] in
    let options=List.filteri (fun i _ -> i>=4) (Array.to_list Sys.argv) in
    if List.exists (fun opt -> opt<>"reverse-bfs" && opt<>"pair-pack") options then
      invalid_arg "optional settings: reverse-bfs, pair-pack";
    let bfs=List.mem "reverse-bfs" options and pairs=List.mem "pair-pack" options in
    let rx=Row_advice.order bfs n hz and rz=Row_advice.order bfs n hx in
    match packed_report n ax az side w (Wide_advice.make_advice 40000000 pairs) p inv rx rz with
    | Some ans->exit(print_report ans)|None->exit(print_report OutOfBudget)
  with Wide_advice.Exhausted->exit(print_report OutOfBudget)
     | Invalid_argument msg | Sys_error msg | Failure msg ->prerr_endline msg;exit 2
