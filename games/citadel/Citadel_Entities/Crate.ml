open Babylon
open React3d
module Physics = System_Physics

type model = { state : Physics.State.t; scale : float }

let crateMesh = Mesh.mesh (Mesh.Loader.fromFile "assets/crate2_out/crate2.gltf")

let render { state; scale } =
  let position = Physics.State.position state in
  let rotation = Physics.State.rotation state in
  let open React3d in
  P.transform ~position
    [
      P.transform ~rotation
        [
          P.transform ~scale:(Vector3.create1 scale)
            ~position:(Vector3.up (-0.4 *. scale))
            [ P.mesh crateMesh ];
        ];
    ]

open EntityManager.Entity

let entity ?(size = 0.4) position =
  let state =
    Physics.State.create ~mass:20. ~initialPosition:position
      ~initialRotation:(Quaternion.initial ())
      (Physics.Shape.box ~width:size ~height:size ~depth:size ())
  in
  let scale = size /. 0.4 in
  EntityManager.Entity.define { scale; state }
  |> EntityManager.Entity.withReadonlyComponent Components.render render
  |> System_Physics.Entity.dynamic
       ~read:(fun { state; _ } -> Some state)
       ~write:(fun state entity ->
         match state with None -> entity | Some state -> { entity with state })
