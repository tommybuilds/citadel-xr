open Babylon
open React3d
open EntityManager

type model = {
  position : Vector3.t;
  velocity : Vector3.t;
  acceleration : Vector3.t;
  rotation : Quaternion.t;
  timeRemaining : float;
}

let initial =
  ({
     position = Vector3.zero ();
     velocity = Vector3.forward 1.0;
     acceleration = Vector3.up (-10.0);
     rotation = Quaternion.identity ();
     timeRemaining = 2.0;
   }
    : model)

type msg = RayCastResult of System_Physics.RayCastResult.t | Noop

let tick ~deltaTime
    ({ position; velocity; acceleration; timeRemaining } as entity) =
  let x = Vector3.x position +. (Vector3.x velocity *. deltaTime) in
  let y = Vector3.y position +. (Vector3.y velocity *. deltaTime) in
  let z = Vector3.z position +. (Vector3.z velocity *. deltaTime) in
  let position' = Vector3.create ~x ~y ~z in
  let velocity' = Vector3.add velocity (Vector3.scale deltaTime acceleration) in
  let timeRemaining' = timeRemaining -. deltaTime in
  let eff =
    if timeRemaining' < 0.0 then Effect.destroySelf
    else
      let direction = Vector3.subtract position' position in
      System_Physics.Effects.rayCast
        ~position:(Vector3.add position direction)
        ~direction:(Vector3.scale 2.0 direction)
        Systems.physics
      |> Effect.map (fun rayCastResult -> RayCastResult rayCastResult)
  in
  ( {
      entity with
      position = position';
      timeRemaining = timeRemaining';
      velocity = velocity';
    },
    eff )

let update msg model =
  match msg with
  | RayCastResult System_Physics.RayCastResult.Miss -> (model, Effect.none)
  | RayCastResult
      (System_Physics.RayCastResult.Hit { entityId; position; normal; _ }) ->
      let velocity = Vector3.scale (-0.3) model.velocity in
      ( {
          model with
          position = Vector3.add position (Vector3.scale 0.1 velocity);
          velocity;
        },
        System_Audio.Effect.play ~position:model.position
          "assets/sfx/Shell_Short_01_SFX.wav"
        |> Effect.map (fun () -> Noop) )
  | Noop -> failwith "never happens"

let render model =
  P.transform ~position:model.position ~rotation:model.rotation
    [ P.mesh Citadel_Assets.ShellCase.asset ]

let entity ~position ~velocity ~rotation =
  let open Entity in
  define
    {
      position;
      velocity;
      acceleration = Vector3.up (-10.0);
      rotation;
      timeRemaining = 2.0;
    }
  |> withThink tick |> withUpdate update
  |> withReadonlyComponent Components.render render
