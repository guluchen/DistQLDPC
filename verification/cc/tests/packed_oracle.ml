(* Directly exercise the checked front end, including deliberately bad advice.
   Small matrix distances in the oracle enumerate all physical supports. *)
open Pcm_generated

let require label value = if not value then failwith label
let bit mask i = mask land (1 lsl i) <> 0
let wt v =
  let rec loop x k = if x=0 then k else loop (x land (x-1)) (k+1) in loop v 0
let par mask word = wt (mask land word) mod 2 = 1
let good hs ls w = List.for_all (fun h->not (par h w)) hs && List.exists (fun l->par l w) ls
let bound n hs ls d = List.for_all (fun w->not (good hs ls w) || wt w>=d) (List.init (1 lsl n) Fun.id)
let test n h l d a = lower_test n (List.map bit h) (List.map bit l) d a
let adv=Packed_advice.advice

let () =
  let rng=Random.State.make [|93857|] in
  let checks=ref 0 in
  for n=1 to 7 do
    for _case=0 to 19 do
      let rows ()=List.init (Random.State.int rng 6) (fun _->Random.State.int rng (1 lsl n)) in
      let h=rows() and l=rows() in
      for d=1 to min (n+1) 5 do
        require "packed lower bound versus brute force" (test n h l d adv=bound n h l d);
        incr checks
      done
    done
  done;
  let h=[3;6] and l=[1] in
  let corrupted_index={adv with prepare_index=(fun _ _->bad_row,none)} in
  let bad_sums={adv with membership=(fun _ _ _->false)} in
  let invalid_orbit={adv with propose=(fun n _ -> List.init n (fun _->0),List.init n (fun _->0))} in
  let false_cut={adv with make_choice=(fun _ _ _ _->Pack_rows [0;0;0;0])} in
  let bad_split={adv with make_choice=(fun _ _ _ _->Split_row 99)} in
  List.iter (fun a->require "invalid advice licensed an unsound lower bound" (not(test 3 h l 4 a)))
    [adv;corrupted_index;bad_sums;invalid_orbit;false_cut;bad_split];
  require "incomplete short table must be rejected" (not(test 3 h l 3 bad_sums));
  require "corrupted rows must be rejected" (not(test 3 h l 3 corrupted_index));
  require "nonbijective orbit falls back to full roots" (test 3 h l 3 invalid_orbit);
  let n=7 and rows=[85;102;120] in
  let flat=List.concat_map (fun r->List.init n (fun i->if bit r i then 1 else 0)) rows in
  let raw={width=n;check_count=3;same_count=3;checks=flat;same_bytes=flat} in
  let a=Option.get (bit_prepare raw) in
  let id=List.init n Fun.id in
  let minimum=ref 0 in
  for w=0 to 127 do
    let valid=List.for_all (fun r->not(par r w)) rows && wt w=3 in
    List.iter (fun x_side ->
      let result=packed_report n a a x_side (List.init n (bit w)) adv id id in
      match result,valid with
      | Some(Exact(3,x,z)),true ->
         require "reported witness" ((if x_side then x else z)=List.init n (bit w));incr minimum
      | None,false -> ()
      | _ -> failwith "raw CSS weight or witness mismatch") [true;false]
  done;
  require "X/Z minimum witnesses" (!minimum=14);
  List.iter (fun i -> let cs=columns 189 [] [] in
    let c=List.nth cs i in
    require "packed column lane" (Packed_advice.mask c.mark=Packed_advice.unit i))
    [0;62;63;125;126;188];
  let hz=[bit 1] and lz=[bit 2] and hx=[bit 2] and lx=[bit 2] in
  require "incompatible half spaces" (not(dual_check 2 hx lx hz lz [0;1] [0;1]));
  Printf.printf "PASS %d finite lower-bound decisions, 256 raw reports, bad hints, dual rejection and lane boundaries\n" !checks
