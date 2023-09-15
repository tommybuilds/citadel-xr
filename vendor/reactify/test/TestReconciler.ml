type primitives = Root | A of int | B | C
[@@ocaml.doc
  "\n\
  \ * Implementation of a very simple reconciler,\n\
  \ * useful for testing the basic functionality\n"]

type updateType = Append | Create | Remove | Update | Replace

let canBeReused = Reactify.Utility.areConstructorsEqual
let updates = (ref [] : updateType list ref)
let printUpdate _u = ()
let _currentId = ref 1

type node = {
  children : node list ref;
  mutable nodeType : primitives;
  nodeId : int;
}

let getUpdates () = !updates
let makePadding (amt : int) = String.make (amt * 2) ' '

let rec showHelper (level : int) (node : node) =
  let s =
    match node.nodeType with
    | A i -> "- A(" ^ string_of_int i ^ ")"
    | B -> "- B"
    | C -> "- C"
    | Root -> "Root"
  in
  print_endline (makePadding level ^ s);
  List.iter (showHelper (level + 1)) !(node.children)

let show (node : node) = showHelper 0 node

let pushUpdate u =
  updates := List.append (getUpdates ()) [ u ];
  printUpdate u

let createInstance prim =
  _currentId := !_currentId + 1;
  let ret =
    ({ children = ref []; nodeType = prim; nodeId = !_currentId } : node)
  in
  pushUpdate Create;
  ret

let appendChild parent child =
  parent.children := !(parent.children) @ [ child ];
  pushUpdate Append;
  child

let removeChild parent child =
  parent.children := List.filter (fun c -> c <> child) !(parent.children);
  pushUpdate Remove

let updateInstance node oldPrim newPrim =
  (match (oldPrim, newPrim) with
  | A _o, A n -> node.nodeType <- A n
  | _ -> print_endline "Unhandled primitive in updateInstance");
  ()

let clearUpdates () = updates := []
let printUpdates () = List.iter printUpdate (getUpdates ())

let replaceChild parent newChild oldChild =
  removeChild parent oldChild;
  let _node = appendChild parent newChild in
  pushUpdate Replace
