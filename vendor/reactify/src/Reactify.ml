open Reactify_Types

module Make (ReconcilerImpl : Reconciler) = struct
  type renderedElement = RenderedPrimitive of ReconcilerImpl.node
  and elementWithChildren = element list
  and render = unit -> elementWithChildren

  and element =
    | Primitive of ReconcilerImpl.primitives * render
    | Empty of render

  and instance = {
    mutable element : element;
    children : element list;
    node : ReconcilerImpl.node option;
    rootNode : ReconcilerImpl.node;
    mutable childInstances : childInstances;
    container : t;
  }

  and container = {
    rootInstance : instance option ref;
    containerNode : ReconcilerImpl.node;
  }

  and t = container
  and childInstances = instance list

  type component = elementWithChildren
  type node = ReconcilerImpl.node
  type primitives = ReconcilerImpl.primitives

  let elementToHook x = x
  let elementFromHook x = x

  type reconcileNotification = node -> unit

  let createContainer (rootNode : ReconcilerImpl.node) =
    let ret =
      ({ containerNode = rootNode; rootInstance = ref None } : container)
    in
    ret

  let primitiveComponent ~children prim =
    elementToHook
      (Primitive (prim, fun () -> List.map elementFromHook children))

  let _getPreviousChildInstances (instance : instance option) =
    match instance with None -> [] | Some i -> i.childInstances

  let rec getFirstNode (node : instance) =
    match node.node with
    | Some n -> Some n
    | None -> (
        match node.childInstances with
        | [] -> None
        | [ c ] -> getFirstNode c
        | _ -> None)

  let rec instantiate rootNode (previousInstance : instance option)
      (element : element) (container : t) =
    let children =
      match element with Primitive (_, render) | Empty render -> render ()
    in
    let primitiveInstance =
      match element with
      | Primitive (p, _render) -> Some (ReconcilerImpl.createInstance p)
      | _ -> None
    in
    let nextRootPrimitiveInstance =
      match primitiveInstance with Some i -> i | None -> rootNode
    in
    let previousChildInstances = _getPreviousChildInstances previousInstance in
    let childInstances =
      reconcileChildren nextRootPrimitiveInstance previousChildInstances
        children container
    in
    let instance =
      ({
         element;
         node = primitiveInstance;
         rootNode = nextRootPrimitiveInstance;
         children;
         childInstances;
         container;
       }
        : instance)
    in
    instance

  and reconcile rootNode instance component container =
    let hadPrimitiveInstance =
      match component with Primitive (_p, _render) -> true | _ -> false
    in
    let r =
      match instance with
      | None ->
          let newInstance = instantiate rootNode instance component container in
          let newNode =
            match newInstance.node with
            | Some n -> Some (ReconcilerImpl.appendChild rootNode n)
            | None -> None
          in
          { newInstance with node = newNode }
      | Some i ->
          let ret =
            match (hadPrimitiveInstance, i.node) with
            | true, Some b -> (
                match (component, i.element) with
                | Primitive (newPrim, _), Primitive (oldPrim, _) ->
                    if oldPrim != newPrim then (
                      if ReconcilerImpl.canBeReused oldPrim newPrim then (
                        ReconcilerImpl.updateInstance b oldPrim newPrim;
                        i.element <- component;
                        let newChildren =
                          match component with
                          | Primitive (_, render) | Empty render -> render ()
                        in
                        i.childInstances <-
                          reconcileChildren b i.childInstances newChildren
                            container;
                        i)
                      else
                        let newInstance =
                          instantiate rootNode instance component container
                        in
                        ReconcilerImpl.replaceChild rootNode
                          (newInstance.node |> Option.get)
                          b;
                        newInstance)
                    else
                      let newChildren =
                        match component with
                        | Primitive (_, render) | Empty render -> render ()
                      in
                      i.childInstances <-
                        reconcileChildren b i.childInstances newChildren
                          container;
                      i
                | _ ->
                    print_endline
                      ("ERROR: Should only be nodes if there are primitives!"
                      [@reason.raw_literal
                        "ERROR: Should only be nodes if there are primitives!"]);
                    instantiate rootNode instance component container)
            | true, None ->
                let currentNode = getFirstNode i in
                (match currentNode with
                | Some c -> ReconcilerImpl.removeChild rootNode c
                | _ -> ());
                let newInstance =
                  instantiate rootNode instance component container
                in
                let node =
                  newInstance.node
                  |> Option.map (ReconcilerImpl.appendChild rootNode)
                in
                { newInstance with node }
            | false, Some b ->
                ReconcilerImpl.removeChild rootNode b;
                instantiate rootNode instance component container
            | false, None -> instantiate rootNode instance component container
          in
          ret
    in
    r

  and reconcileChildren (root : node) (currentChildInstances : childInstances)
      (newChildren : element list) (container : t) =
    let currentChildInstances =
      (Array.of_list currentChildInstances : instance array)
    in
    let newChildren = Array.of_list newChildren in
    let newChildInstances = (ref [] : childInstances ref) in
    for i = 0 to Array.length newChildren - 1 do
      let childInstance =
        match i >= Array.length currentChildInstances with
        | true -> None
        | false -> Some currentChildInstances.(i)
      in
      let childComponent = newChildren.(i) in
      let newChildInstance =
        reconcile root childInstance childComponent container
      in
      newChildInstances := List.append !newChildInstances [ newChildInstance ]
    done;
    for
      i = Array.length newChildren to Array.length currentChildInstances - 1
    do
      match currentChildInstances.(i).node with
      | Some n -> ReconcilerImpl.removeChild root n
      | _ -> ()
    done;
    !newChildInstances

  let updateContainer container element =
    let { containerNode; rootInstance } = container in
    let prevInstance = !rootInstance in
    let nextInstance = reconcile containerNode prevInstance element container in
    rootInstance := Some nextInstance
end

module Utility = Utility