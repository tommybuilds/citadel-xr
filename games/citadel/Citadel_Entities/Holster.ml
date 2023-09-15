open Babylon
open React3d
type model =
  {
  position: Vector3.t ;
  rotation: Quaternion.t ;
  holsterOffset: Vector3.t ;
  holsterType: System_Grabbable.Holster.Type.t ;
  holsterState: System_Grabbable.HolsterState.t }
let defaultHolsterOffset = Vector3.add (Vector3.forward 1.0) (Vector3.up 0.2)
let tick ~deltaTime  model =
  let camera = (Ambient.current ()).input |> Input.State.camera in
  let cameraPosition = camera |> Input.CameraController.position in
  let rotation =
    (((camera |> Input.CameraController.rotation) |> Quaternion.toEulerAngles)
       |> Vector3.y)
      |> (Quaternion.rotateAxis ~axis:(Vector3.up 1.0)) in
  let position =
    (rotation |> (Quaternion.rotateVector model.holsterOffset)) |>
      (Vector3.add cameraPosition) in
  let extraRotation =
    Quaternion.rotateAxis ~axis:(Vector3.left 1.0)
      (((-1.0) *. Float.pi) /. 2.0) in
  let holsterRotation = Quaternion.multiply rotation extraRotation in
  ({ model with position; rotation = holsterRotation },
    EntityManager.Effect.none)
let rotation =
  Quaternion.rotateAxis ~axis:(Vector3.left 1.0) (Float.pi /. 2.0)
let material =
  React3d.Material.standard ~hasAlpha:true
    ~diffuseTexture:"assets/circle.png" ~emissiveTexture:"assets/circle.png"
    ()
let render { position; holsterState;_} =
  let size =
    match (System_Grabbable.HolsterState.state holsterState) ==
            System_Grabbable.HolsterState.Hovered
    with
    | true -> 0.5
    | false -> 0.1 in
  let open React3d in
    P.transform ~position
      [P.plane ~material ~rotation ~width:size ~height:size []]
let holsters { position; rotation; holsterType;_} =
  System_Grabbable.Holster.make ~position ~rotation holsterType
let entity (holsterOffset : Vector3.t)
  (holsterType : System_Grabbable.Holster.Type.t) =
  let open EntityManager.Entity in
    (((define
         {
           holsterOffset;
           holsterType;
           position = (Vector3.zero ());
           rotation = (Quaternion.identity ());
           holsterState = System_Grabbable.HolsterState.initial
         })
        |> (withThink tick))
       |> (withReadonlyComponent Components.render render))
      |>
      (System_Grabbable.Entity.holster
         ~readHolsterState:(fun { holsterState;_} -> holsterState)
         ~writeHolsterState:(fun holsterState ->
                               fun state -> { state with holsterState })
         ~holsters)