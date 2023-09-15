type 'msg dispatcher = 'msg -> unit
type 'msg effect = { getName : int -> string; f : 'msg dispatcher -> unit }
type 'msg t = 'msg effect option

module Internal = struct
  let indentName name level = String.make level ' ' ^ name
end

let create ~(name : string) (f : unit -> unit) =
  Some { getName = Internal.indentName name; f = (fun _ -> f ()) }

let createWithDispatch ~(name : string) (f : 'msg dispatcher -> unit) =
  Some { getName = Internal.indentName name; f }

let none = (None : 'msg t)

let run (effect : 'msg t) (dispatch : 'msg dispatcher) =
  Option.iter (fun eff -> eff.f dispatch) effect

let batch (effects : 'msg t list) =
  let effects = effects |> List.filter (fun eff -> eff <> None) in
  let execute dispatch = List.iter (fun e -> run e dispatch) effects in
  let getName indentLevel =
    let start = String.make indentLevel ' ' ^ "Batch" ^ ":" in
    start
    ^ List.fold_left
        (fun prev curr ->
          match curr with
          | None -> prev
          | Some curr ->
              let newName = curr.getName (indentLevel + 1) ^ "\n" in
              prev ^ newName)
        "\n" effects
  in
  match effects with [] -> None | _ -> Some { getName; f = execute }

let map f =
  Option.map (fun eff ->
      { eff with f = (fun dispatch -> eff.f (fun msg -> dispatch (f msg))) })

let name = function Some eff -> eff.getName 0 | None -> "(None)"
