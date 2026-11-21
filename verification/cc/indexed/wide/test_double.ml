(* Check the C hint, its extracted interpretation and a six-coordinate oracle
   together. Every assignment of syndrome, availability and budget is visited. *)
open Wide_generated

let rec popcount x =
  if x=0 then 0 else 1 + popcount (x land (x-1))

let pack positions mask =
  Array.fold_left (fun (index, result) q ->
    let used = mask land (1 lsl index) <> 0 in
    index+1, if used then join0 result (singleton0 q) else result
  ) (0,none0) positions |> snd

let rec permutations = function
  | [] -> [[]]
  | rows -> List.concat_map (fun row ->
      List.map (fun rest -> row::rest)
        (permutations (List.filter (fun other -> other<>row) rows))) rows

let checked = ref 0
let double_hints = ref 0
let known_cut = ref 0

let test positions patterns =
  let projected = Array.of_list patterns in
  let rows = Array.map (fun bits -> {support_mask=pack positions bits;neighbors=[]}) projected in
  let words = Array.map (fun row -> Wide_advice.words row.support_mask) rows in
  let incident = Array.init 378 (fun q ->
    List.filter (fun i -> Wide_advice.bit words.(i) q) [0;1;2;3] |> Array.of_list) in
  let oracle = Array.make_matrix 64 16 7 in
  for available=0 to 63 do
    for error=0 to 63 do
      if error land available=error then begin
        let syndrome = ref 0 in
        Array.iteri (fun i row ->
          if popcount (row land error) mod 2=1 then syndrome:= !syndrome lor (1 lsl i)) projected;
        oracle.(available).(!syndrome) <- min oracle.(available).(!syndrome) (popcount error)
      end
    done
  done;
  for available=0 to 63 do
    let free = pack positions available in
    for syndrome=0 to 15 do
      let sy = pack [|0;1;2;3|] syndrome in
      for budget=0 to 4 do
        incr checked;
        match Wide_advice.row_hint (words,incident,true,true) sy free budget with
        | Packed_double (ids,first,second) ->
          let cut = double_cut 4 (fun syn i -> i<4 && decode1 syn i)
              (Array.get rows) sy free budget ids in
          assert (cut first second);
          assert (oracle.(available).(syndrome)>budget);
          incr double_hints;
          if available=63 && patterns=[3;12;19;44] && syndrome=3 && budget=3 then begin
            assert (oracle.(available).(syndrome)=4);
            assert (not (cut first first));
            (* A weakened adviser returns to ordinary branching at this node. *)
            (match Wide_advice.row_hint (words,incident,true,false) sy free budget with
             | Split_row _ -> incr known_cut | _ -> assert false)
          end
        | _ -> ()
      done
    done
  done

let () =
  List.iter (fun positions ->
    List.iter (test positions) (permutations [3;12;19;44]))
    [[|0;1;2;3;4;5|]; [|0;63;126;189;252;315|]];
  assert (!known_cut=2 && !double_hints>2 && !checked=245760);
  Printf.printf "%d exhaustive C hint queries, %d double cuts, %d weakened-adviser controls passed\n"
    !checked !double_hints !known_cut
