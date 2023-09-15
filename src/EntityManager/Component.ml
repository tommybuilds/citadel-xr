open Util

type readwrite = unit
type readonly = unit

type ('writeaccess, 'component) t = {
  name : string;
  uniqueId : int;
  pipe : 'component Pipe.t;
}

let nextUniqueId = ref 0

let readonly ?name () =
  let uniqueId = !nextUniqueId in
  incr nextUniqueId;
  let name' = name |> Option.value ~default:(string_of_int uniqueId) in
  { name = name'; uniqueId; pipe = Pipe.create () }

let readwrite = readonly