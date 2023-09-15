open Util
module MeshBuilder = Babylon.MeshBuilder
module Node = Babylon.Node
module Quaternion = Babylon.Quaternion
module Vector3 = Babylon.Vector3
type ('args, 'node, 'state) t =
  | Instance:
  {
  isActive: bool ref ;
  isLoaded: bool ref ;
  rootNode: Babylon.transform Babylon.node ;
  childNode: 'node Babylon.node option ref ;
  definition: ('args, 'node, 'state) Definition.t ;
  meshState: 'state option ref ;
  latestMeshArgs: 'args option ref } -> ('args, 'node, 'state) t 
let make definition =
  let open Definition in
    let rootNode =
      Babylon.Node.createTransform ~name:"TODO: MeshInstanceName" in
    let isActive = ref true in
    let isLoaded = ref false in
    let childNode = ref None in
    let meshState = ref None in
    let latestMeshArgs = ref None in
    let _ =
      (definition.loader ()) |>
        (Promise.then_
           ~fulfilled:(fun (initialState, mesh) ->
                         if !isActive
                         then
                           (isLoaded := true;
                            (let clone = mesh in
                             childNode := (Some clone);
                             (let state =
                                match !latestMeshArgs with
                                | None -> initialState
                                | Some args ->
                                    Definition.apply args initialState
                                      definition clone in
                              meshState := (Some state);
                              Babylon.Node.setEnabled ~enabled:true clone;
                              Babylon.Node.setParent ~parent:rootNode clone)));
                         Promise.resolve ())) in
    Instance
      {
        rootNode;
        childNode;
        isActive;
        meshState;
        isLoaded;
        definition;
        latestMeshArgs
      }
let definition = function | Instance { definition;_} -> definition
let maybeChildNode = function | Instance { childNode;_} -> !childNode
let applyMeshArgs (args : 'meshArgs)
  (mesh : ('meshArgs, 'meshNode, 'meshState) Definition.t)
  (instance : ('args, 'node, 'state) t) =
  match instance with
  | ((Instance
      { definition; childNode; meshState; latestMeshArgs;_})[@explicit_arity
                                                              ])
      ->
      (match Pipe.send mesh.pipe definition.pipe args with
       | None -> ()
       | Some args ->
           (latestMeshArgs := (Some args);
            (match !childNode with
             | Some node ->
                 (match !meshState with
                  | None -> ()
                  | Some state ->
                      let newMeshState =
                        Definition.apply args state definition node in
                      (meshState := (Some newMeshState); ()))
             | None -> ())))
let rootNode instance =
  match instance with | Instance { rootNode;_} -> rootNode
let dispose instance =
  match instance with
  | Instance { isActive; rootNode;_} ->
      if !isActive then (isActive := false; Node.dispose rootNode)