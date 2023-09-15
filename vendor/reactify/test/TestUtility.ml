open TestReconciler

type 'a tree = TreeNode of 'a * 'a tree list | TreeLeaf of 'a

exception ValidationFailure of string

let validateStructure (rootNode : node) (structure : primitives tree) =
  let rec f (inputNode : node) (st : primitives tree) level =
    match st with
    | TreeNode (p, c) ->
        if inputNode.nodeType <> p then
          raise (ValidationFailure "Nodetype was not as expected");
        if List.length !(inputNode.children) != List.length c then
          raise (ValidationFailure "Nodes not equal as expected");
        List.iter2 (fun a b -> f a b (level + 1)) !(inputNode.children) c
    | TreeLeaf p ->
        if inputNode.nodeType <> p then
          raise (ValidationFailure "Nodetype was not as expected")
  in
  f rootNode structure 0