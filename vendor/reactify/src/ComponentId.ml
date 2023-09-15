type t = { id : int; friendlyName : string }
type scope = { mutable lastId : int }

let createScope () =
  let ret = ({ lastId = 0 } : scope) in
  ret

let newId ?(friendlyName : string option) (scope : scope) =
  let id = scope.lastId + 1 in
  scope.lastId <- id;
  let friendlyName =
    match friendlyName with
    | Some x -> x
    | None -> "component" ^ string_of_int id
  in
  let ret = ({ id; friendlyName } : t) in
  ret
