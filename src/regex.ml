open Regex_base

let rec repeat n l =
  if n = 0 then 
    []
  else 
    l @ repeat (n-1) l

let rec expr_repeat n e =
  if n = 0 then 
    Eps
  else 
    Concat(e, expr_repeat (n-1) e)

let rec is_empty e =
  match e with 
  | Eps -> true
  | Base x -> false
  | Joker -> false
  | Concat (g, d) -> is_empty g && is_empty d
  | Alt (g, d) -> is_empty g && is_empty d
  | Star x -> is_empty x  (* car Eps puissance n reste Eps *)
  
let rec null e =
  match e with 
  | Eps -> true
  | Base x -> false
  | Joker -> false
  | Concat (g, d) -> null g && null d
  | Alt (g, d) -> null g || null d
  | Star _ -> true

let rec is_finite e =
  match e with 
  | Eps -> true
  | Base x -> true
  | Joker -> true
  | Concat (g, d) -> is_finite g && is_finite d
  | Alt (g, d) -> is_finite g && is_finite d  
  | Star x -> is_empty x  (* car Eps puissance n reste Eps *)

  (* continue sur toplevel *)
let rec product l1 l2 =
  match l1 with 
  | [] -> []
  | x :: ll ->
      let rec aux list =
        match list with
        | [] -> product ll l2
        | y :: res -> [x @ y] @ aux res
      in aux l2 

let enumerate alphabet e =
  if not (is_finite e) then None
  else
    let rec eval exp =
      match exp with 
      | Eps -> [[]]
      | Base x -> [[x]]
      | Joker -> List.map (fun x -> [x]) alphabet
      | Concat (g, d) -> product (eval g) (eval d)
      | Alt (g, d) -> eval g @ eval d
      | Star x -> [] (* car le seul cas où Star apparait alors que is_finite e = true c lorsque x = Eps *)
    in Some (eval e)

let alphabet_expr e =
  match enumerate [] e with
  | None -> []
  | Some language ->
    let alpha = List.flatten language in
    List.sort_uniq compare alpha

type answer =
  Infinite | Accept | Reject

let accept_partial e w =
  let alphabet = alphabet_expr e in
  match (alphabet, enumerate alphabet e) with
  | (alpha, Some language_e) ->
    let resultat =
      if not (is_finite e) then Infinite
      else if List.for_all (fun c -> List.mem c alpha) w && List.mem w language_e then Accept
      else Reject
    in
    resultat
  | _ -> Infinite