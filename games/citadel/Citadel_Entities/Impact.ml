open Babylon
open React3d
open EntityManager

type model = {
  position : Vector3.t;
  rotation : Quaternion.t;
  particleLifeTime : float;
}

let render model =
  P.transform ~position:model.position
    [
      P.transform ~rotation:model.rotation
        [
          P.meshWithArgs
            (let open Mesh.ParticleSystem in
            { active = model.particleLifeTime > 0.0 })
            Mesh.particleSystem;
          P.plane ~width:0.1 ~height:0.1 [];
        ];
    ]

let think ~deltaTime model =
  ( { model with particleLifeTime = model.particleLifeTime -. deltaTime },
    Effect.none )

let entity position normal =
  let rotation = QuaternionEx.lookAt normal in
  let open Entity in
  define { position; rotation; particleLifeTime = 0.1 }
  |> withThink think
  |> withReadonlyComponent Components.render render
