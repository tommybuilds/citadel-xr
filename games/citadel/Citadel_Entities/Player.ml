open Babylon
open React3d
module AI = System_AI
module Physics = System_Physics

type model = { state : Physics.State.t }

let position { state; _ } = Physics.State.position state

let camera { state; _ } =
  let position = Physics.State.position state in
  System_Camera.free ~position ()

open EntityManager.Entity

let think ~deltaTime context model =
  let input = (Ambient.current ()).input in
  let entityId = context |> EntityManager.EntityContext.id in
  let eff =
    input |> Input.State.rightHand
    |> Option.map (fun rightHand ->
           let thumbstick = Input.HandController.thumbstick rightHand in
           let camera = Input.State.camera input in
           let cameraRot = Input.CameraController.rotation camera in
           let forward =
             Quaternion.rotateVector
               (Vector3.forward (-2. *. (thumbstick |> Input.Thumbstick.y)))
               cameraRot
           in
           let left =
             Quaternion.rotateVector
               (Vector3.left (-2. *. (thumbstick |> Input.Thumbstick.x)))
               cameraRot
           in
           let position = model.state |> System_Physics.State.position in
           let v = Vector3.add forward left in
           System_Physics.Effects.applyImpulse ~position ~impulse:v ~entityId
             Systems.physics)
    |> Option.value ~default:EntityManager.Effect.none
  in
  (model, eff)

let entity initialPosition =
  let state =
    Physics.State.create ~angularFactor:(Vector3.up 1.0) ~mass:20.
      ~initialPosition ~initialRotation:(Quaternion.initial ())
      (Physics.Shape.capsule ~radius:0.2 ~height:0.5 ())
  in
  let open EntityManager.Entity in
  define { state }
  |> AI.Entity.categorize ~category:Categories.player position
  |> withThinkEx think
  |> System_Physics.Entity.dynamic
       ~read:(fun { state; _ } -> Some state)
       ~write:(fun state model ->
         match state with None -> model | Some state -> { state })
  |> withReadonlyComponent System_Camera.camera camera
