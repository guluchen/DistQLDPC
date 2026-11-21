let () =
  try
    if Array.length Sys.argv < 4 || Array.length Sys.argv > 5 then invalid_arg "usage: pcm-large WIDTH HX HZ";
    let n=checked_width Sys.argv.(1) in
    if n > 756 then exit (print_report OutOfBudget);
    let hx=read_matrix Sys.argv.(2) and hz=read_matrix Sys.argv.(3) in
    let ax=prepare_half n hz hx and az=prepare_half n hx hz in
    if List.exists (fun a->a.model_m>756 || a.model_l>756) [ax;az] then exit(print_report OutOfBudget);
    let side=match read_line() with "X"->true |"Z"->false |_->invalid_arg "invalid side" in
    let bits=read_line() in if String.length bits<>n then invalid_arg "incorrect witness width";
    let w=List.init n(fun i->match bits.[i] with '0'->false|'1'->true|_->invalid_arg "nonbinary witness") in
    let p,inv=match Dual_advice.propose n hx hz with Some(v,_,_)->v,v |None->[],[] in
    let bfs=match Array.to_list Sys.argv with
      | [_;_;_;_] -> false | [_;_;_;_;"reverse-bfs"] -> true
      | _ -> invalid_arg "optional row order: reverse-bfs" in
    let rx=Row_advice.order bfs n hz and rz=Row_advice.order bfs n hx in
    match packed_report n ax az side w (Large_advice.make_advice 40000000) p inv rx rz with
    | Some ans->exit(print_report ans)|None->exit(print_report OutOfBudget)
  with Large_advice.Exhausted->exit(print_report OutOfBudget)
     | Invalid_argument msg | Sys_error msg | Failure msg ->prerr_endline msg;exit 2
