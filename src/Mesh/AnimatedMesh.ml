open Util
module MeshBuilder = Babylon.MeshBuilder
module Node = Babylon.Node
module Quaternion = Babylon.Quaternion
module Vector3 = Babylon.Vector3
open Definition
type args = unit
type state = unit
let applyArgs _args _state _node = _state
let make ?friendlyId  (meshPath : string) =
  let loader () =
    (Loader.Cache.get ~forceReload:true ~rootUrl:meshPath "") |>
      (Promise.map
         (fun (mesh, animationGroups, _skeletons) ->
            Node.setEnabled ~enabled:true mesh;
            animationGroups |>
              (Array.iter
                 (fun ag ->
                    Babylon.AnimationGroup.goToFrame (Random.float 100.) ag;
                    Babylon.AnimationGroup.stop ag));
            ((), mesh))) in
  incr uniqueId;
  (let pipe = Pipe.create () in
   let statePipe = Pipe.create () in
   let friendlyId = friendlyId |> (Option.value ~default:meshPath) in
   let definition =
     {
       editor = Editor.empty;
       friendlyId;
       uniqueId = (!uniqueId);
       loader;
       statePipe;
       apply = applyArgs;
       pipe
     } in
   Registry.register definition (); definition)