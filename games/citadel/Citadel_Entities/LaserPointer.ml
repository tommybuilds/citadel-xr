open Babylon
open React3d
module Physics = System_Physics

type model = {
  lastPosition : Vector3.t;
  lastDirection : Vector3.t;
  lastHitResult : Physics.RayCastResult.t;
}

let initial =
  ({
     lastPosition = Vector3.zero ();
     lastDirection = Vector3.zero ();
     lastHitResult = Miss;
   }
    : model)

type msg = Raycast of Physics.RayCastResult.t

let think ~deltaTime model =
  let camera = (Ambient.current ()).input |> Input.State.camera in
  let position = camera |> Input.CameraController.position in
  let rotation = camera |> Input.CameraController.rotation in
  let forward = rotation |> Quaternion.rotateVector (Vector3.forward 25.0) in
  let endPosition = Vector3.add position forward in
  ( { model with lastDirection = forward; lastPosition = endPosition },
    Physics.Effects.rayCast ~position ~direction:forward Systems.physics
    |> EntityManager.Effect.map (fun result -> Raycast result) )

let update msg model =
  match msg with
  | Raycast result ->
      let eff =
        match result with
        | Miss -> EntityManager.Effect.none
        | Hit { position; entityId; _ } -> EntityManager.Effect.none
      in
      ({ model with lastHitResult = result }, eff)

let render { lastHitResult; lastPosition } =
  match lastHitResult with
  | Physics.RayCastResult.Miss ->
      let open React3d in
      P.transform ~position:lastPosition []
  | Physics.RayCastResult.Hit { position; _ } ->
      let open React3d in
      P.transform ~position [ P.sphere ~diameter:0.015 [] ]

let entity =
  let open EntityManager.Entity in
  define initial |> withThink think |> withUpdate update
  |> withReadonlyComponent Components.render render
