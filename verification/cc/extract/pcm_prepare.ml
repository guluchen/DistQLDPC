(* File/command-line adapter outside the Coq boundary. The extracted
   function performs binary-shape, commutation and C extent checks. *)
open Pcm_generated

let read_matrix path =
  let input = open_in path in
  let rec loop width count rev_bits =
    match input_line input with
    | line ->
        let data = List.hd (String.split_on_char '#' line) in
        let bits = ref [] in
        String.iter (function
          | '0' -> bits := 0 :: !bits
          | '1' -> bits := 1 :: !bits
          | ' ' | '\t' | '\r' -> ()
          | _ -> invalid_arg ("nonbinary character in " ^ path)) data;
        let n = List.length !bits in
        if n = 0 then loop width count rev_bits
        else begin
          if width <> 0 && n <> width then invalid_arg ("ragged rows in " ^ path);
          if n > 107374182 || count >= 2147483647 / n then invalid_arg "matrix exceeds C extent";
          loop n (count + 1) (List.rev_append (List.rev !bits) rev_bits)
        end
    | exception End_of_file -> width, count, List.rev rev_bits
  in Fun.protect ~finally:(fun () -> close_in input) (fun () -> loop 0 0 [])

let print_rows width xs =
  let rec loop col = function
    | [] -> ()
    | x :: more ->
        print_char (if x = 0 then '0' else '1');
        if col + 1 = width then (print_newline (); loop 0 more)
        else loop (col + 1) more
  in loop 0 xs

let checked_width text =
  let n = int_of_string text in
  if n <= 0 || n > 107374182 then invalid_arg "unsupported width";
  n

let prepare_half n (wn, m, h) (wg, k, g) =
  if (m <> 0 && wn <> n) || (k <> 0 && wg <> n) then invalid_arg "inconsistent widths";
  match bit_prepare {width=n;check_count=m;same_count=k;checks=h;same_bytes=g} with
  | None -> invalid_arg "invalid CSS matrices or C extents"
  | Some a -> a

let prepare () =
  if Array.length Sys.argv <> 4 then invalid_arg "usage: pcm-prepare WIDTH OPPOSITE.txt SAME.txt";
  let n = checked_width Sys.argv.(1) in
  let a = prepare_half n (read_matrix Sys.argv.(2)) (read_matrix Sys.argv.(3)) in
  Printf.printf "%d %d %d %d\n" a.model_n a.model_m a.model_l a.model_k;
  List.iter (print_rows n) [a.model_h;a.model_lg;a.model_g]

let read_half_result n =
  let status = int_of_string (read_line ()) in
  if not (List.mem status [-1; 0; 1]) then invalid_arg "bad kernel status";
  let bits = read_line () in
  if String.length bits <> n then invalid_arg "bad witness extent";
  status, List.init n (fun i ->
    match bits.[i] with '0' -> 0 | '1' -> 1 | _ -> invalid_arg "bad witness bit")

let bit_string bs =
  String.of_seq (Seq.map (fun b -> if b then '1' else '0') (List.to_seq bs))

let print_report = function
  | OutOfBudget -> print_endline "{\"status\":\"UNKNOWN\"}"; 3
  | NoLogical -> print_endline "{\"status\":\"EMPTY\"}"; 0
  | Exact (d,x,z) ->
      Printf.printf "{\"status\":\"FOUND\",\"distance\":%d,\"x\":\"%s\",\"z\":\"%s\"}\n"
        d (bit_string x) (bit_string z); 0

let finish () =
  let n = checked_width Sys.argv.(2) in
  let rx, ox = read_half_result n in
  let rz, oz = read_half_result n in
  ignore (print_report (finish_pcm n rx ox rz oz))

external kernel_distance :
  (int * int * int * int) -> (bytes * bytes * bytes) -> (int * int) -> int * bytes
  = "caml_ccv_distance"

let matrix_bytes xs =
  let data = Bytes.create (List.length xs) in
  List.iteri (fun j b -> Bytes.set data j (Char.chr b)) xs;
  data

let distance () =
  if Array.length Sys.argv <> 7 then invalid_arg "usage: pcm-prepare --distance WIDTH HX HZ BUDGET RULES";
  let n = checked_width Sys.argv.(2) in
  let budget = int_of_string Sys.argv.(5) and rules = int_of_string Sys.argv.(6) in
  if budget < 0 || budget > 4294967295 || rules < 0 || rules > 63 then invalid_arg "invalid search limits";
  let hx = read_matrix Sys.argv.(3) and hz = read_matrix Sys.argv.(4) in
  let solve a =
    let status, bits = kernel_distance (n,a.model_m,a.model_l,a.model_k)
      (matrix_bytes a.model_h, matrix_bytes a.model_lg, matrix_bytes a.model_g) (budget,rules) in
    status, List.init n (fun i -> Char.code (Bytes.get bits i))
  in
  let finish_pair (rx,ox) (rz,oz) = exit (print_report (finish_pcm n rx ox rz oz)) in
  let _,mx,_ = hx and _,mz,_ = hz in
  if n>=96 && n<=189 && mx<=189 && mz<=189 && budget=100000000 && rules=63 then begin
    let ax = prepare_half n hz hx and az = prepare_half n hx hz in
    match Packed_advice.certify n ax az with
    | Some answer -> exit (print_report answer)
    | None -> let x = solve ax in finish_pair x (solve az)
  end else begin
    let x = solve (prepare_half n hz hx) in
    finish_pair x (solve (prepare_half n hx hz))
  end

let () =
  try
    if Sys.word_size <> 64 then invalid_arg "requires 64-bit OCaml";
    if Array.length Sys.argv = 3 && Sys.argv.(1) = "--finish" then finish ()
    else if Array.length Sys.argv >= 2 && Sys.argv.(1) = "--distance" then distance ()
    else prepare ()
  with Invalid_argument msg | Failure msg | Sys_error msg ->
    prerr_endline msg; exit 2
  | End_of_file -> prerr_endline "short result stream"; exit 2
