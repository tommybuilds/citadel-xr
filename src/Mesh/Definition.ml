open Util
module MeshBuilder = Babylon.MeshBuilder
module Node = Babylon.Node
module Quaternion = Babylon.Quaternion
module Vector3 = Babylon.Vector3
let uniqueId = ref 0
type ('args, 'node, 'state) t =
  {
  editor: 'args Editor.t ;
  friendlyId: string ;
  pipe: 'args Pipe.t ;
  statePipe: 'state Pipe.t ;
  uniqueId: int ;
  loader: unit -> ('state * 'node Babylon.node) Promise.t ;
  apply: 'args -> 'state -> 'node Babylon.node -> 'state }
let equals { uniqueId = a;_} { uniqueId = b;_} = a == b
let apply args state definition node = definition.apply args state node
let simple ?(postProcess= MeshProcessor.none)  f loader friendlyId =
  incr uniqueId;
  (let pipe = Pipe.create () in
   let statePipe = Pipe.create () in
   let loader' () =
     (loader ()) |>
       (Promise.then_
          ~fulfilled:(fun (state, mesh) ->
                        postProcess mesh; Promise.resolve (state, mesh))) in
   {
     editor = Editor.empty;
     friendlyId;
     uniqueId = (!uniqueId);
     loader = loader';
     statePipe;
     apply = f;
     pipe
   })