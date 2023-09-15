open Babylon
open React3d
module Physics = System_Physics

type model = { size : float; state : Physics.State.t }

let holoMaterial =
  React3d.Material.standard ~uScale:1.0 ~vScale:1.0
    ~diffuseTexture:"assets/holo.png" ~emissiveTexture:"assets/holo.png" ()

let initial ~size position =
  {
    size;
    state =
      Physics.State.create ~mass:0. ~initialPosition:position
        ~initialRotation:(Quaternion.initial ())
        (Physics.Shape.box ~width:size ~height:(size *. 2.0) ~depth:size ());
  }

let render { state; size } =
  let position = Physics.State.position state in
  let rotation = Physics.State.rotation state in
  let open React3d in
  P.transform ~position
    [
      P.transform ~rotation
        [
          P.transform
            ~position:(Vector3.up (0.0 *. size))
            [
              P.box ~material:holoMaterial ~size:(size *. 2.0)
                ~scale:(Vector3.create ~x:1.0 ~y:2.0 ~z:1.)
                [];
            ];
        ];
    ]

open EntityManager.Entity

let entity position =
  EntityManager.Entity.define (initial 0.5 position)
  |> EntityManager.Entity.withReadonlyComponent Components.render render
  |> System_Physics.Entity.dynamic
       ~read:(fun { state; _ } -> Some state)
       ~write:(fun state model ->
         match state with None -> model | Some state -> { model with state })
