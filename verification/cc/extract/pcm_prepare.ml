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

let prepare () =

    if Array.length Sys.argv <> 4 then invalid_arg "usage: pcm-prepare WIDTH OPPOSITE.txt SAME.txt";
    let n = int_of_string Sys.argv.(1) in
    if n <= 0 || n > 107374182 then invalid_arg "unsupported width";
    let wn, m, h = read_matrix Sys.argv.(2) in
    let wg, k, g = read_matrix Sys.argv.(3) in
    if (m <> 0 && wn <> n) || (k <> 0 && wg <> n) then invalid_arg "inconsistent widths";
    match fast_prepare_pcm_half {width=n;check_count=m;same_count=k;checks=h;same_bytes=g} with
    | None -> invalid_arg "invalid CSS matrices or C extents"
    | Some a ->
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

let finish () =
  let n = int_of_string Sys.argv.(2) in
  if n <= 0 || n > 107374182 then invalid_arg "unsupported width";
  let rx, ox = read_half_result n in
  let rz, oz = read_half_result n in
  match finish_pcm n rx ox rz oz with
  | OutOfBudget -> print_endline "{\"status\":\"UNKNOWN\"}"
  | NoLogical -> print_endline "{\"status\":\"EMPTY\"}"
  | Exact (d,x,z) ->
      Printf.printf "{\"status\":\"FOUND\",\"distance\":%d,\"x\":\"%s\",\"z\":\"%s\"}\n"
        d (bit_string x) (bit_string z)

let () =
  try
    if Sys.word_size <> 64 then invalid_arg "requires 64-bit OCaml";
    if Array.length Sys.argv = 3 && Sys.argv.(1) = "--finish" then finish ()
    else prepare ()
  with Invalid_argument msg | Failure msg | Sys_error msg ->
    prerr_endline msg; exit 2
  | End_of_file -> prerr_endline "short result stream"; exit 2
