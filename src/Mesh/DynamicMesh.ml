open Util
module MeshBuilder = Babylon.MeshBuilder
module Node = Babylon.Node
module Quaternion = Babylon.Quaternion
module Vector3 = Babylon.Vector3
open Definition
let make ?friendlyId  ?(editor= Editor.empty) 
  ~initialArgs:(initialArgs : 'args) 
  ~initialState:(initialState : 'nodeType Loader.LoadResult.t -> 'state) 
  ?postProcess:((postProcess : MeshProcessor.t)= MeshProcessor.none) 
  ~apply:(apply : 'args -> 'state -> 'nodeType Babylon.node -> 'state) 
  (modelLoader : 'nodeType Loader.t) =
  let loader () =
    (Loader.load modelLoader) |>
      (Promise.map
         (fun (Loader.LoadResult.{ rootNode = mesh;_}  as loadResult) ->
            Node.setEnabled ~enabled:true mesh;
            (let () = postProcess (Node.abstract mesh) in
             let state = initialState loadResult in
             let state' = apply initialArgs state mesh in (state', mesh)))) in
  incr uniqueId;
  (let pipe = Pipe.create () in
   let statePipe = Pipe.create () in
   let friendlyId =
     match friendlyId with
     | None -> modelLoader |> Loader.friendlyName
     | Some f -> f in
   let definition =
     {
       editor;
       friendlyId;
       uniqueId = (!uniqueId);
       loader;
       statePipe;
       apply;
       pipe
     } in
   Registry.register definition initialArgs; definition)