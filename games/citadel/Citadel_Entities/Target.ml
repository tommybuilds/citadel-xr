module Quaternion = Babylon.Quaternion
module Vector3 = Babylon.Vector3
open EntityManager

type model = {
  position : Vector3.t;
  diameter : float;
  revive : float;
  isDead : bool;
  health : Damage.State.t;
  state : System_Physics.State.t list;
}

type msg = Damage of float

let think ~deltaTime model =
  if model.revive < 0. && model.isDead then
    ({ model with isDead = false }, Effect.none)
  else ({ model with revive = model.revive -. deltaTime }, Effect.none)

let update msg model =
  match msg with
  | Damage dmg ->
      ({ model with isDead = true; revive = 1.0 }, Effect.destroySelf)

let mesh = Citadel_Assets.Target.target
let innerPosition = Vector3.add (Vector3.forward 0.035) (Vector3.up (-0.85))

let innerRotation =
  Babylon.Quaternion.rotateAxis ~axis:(Vector3.up 1.0) (Float.pi /. -2.0)

let angle = -1.5
let height = 0.85

let render { diameter; state; isDead; _ } =
  let innerAngle =
    Babylon.Quaternion.rotateAxis ~axis:(Vector3.up 1.0)
      (match isDead with true -> Float.pi /. 2.0 | false -> 0.0)
  in
  let position = System_Physics.State.position (List.nth state 0) in
  let rotation = System_Physics.State.rotation (List.nth state 0) in
  let open React3d in
  P.transform ~position ~rotation
    [
      P.transform ~rotation:innerAngle
        [
          P.transform ~position:innerPosition ~rotation:innerRotation
            [ P.mesh mesh ];
        ];
    ]

let physicsShape1 =
  System_Physics.Shape.box ~width:0.25 ~height:0.55 ~depth:0.01 ()

let physicsShape2 =
  System_Physics.Shape.box ~width:0.15 ~height:0.15 ~depth:0.01 ()

let entity diameter position =
  let state1 =
    System_Physics.State.create ~mass:0.
      ~initialPosition:(Vector3.up (-0.4) |> Vector3.add position)
      ~initialRotation:(Quaternion.initial ()) physicsShape1
  in
  let state2 =
    System_Physics.State.create ~mass:0.
      ~initialPosition:(Vector3.up 0.35 |> Vector3.add position)
      ~initialRotation:(Quaternion.initial ()) physicsShape2
  in
  let state = [ state1; state2 ] in
  let health = Damage.State.create 100. in
  let open Entity in
  define { diameter; position; state; health; revive = 2.0; isDead = false }
  |> withThink think |> withUpdate update
  |> withReadonlyComponent Components.render render
  |> withReadonlyComponent Components.target (fun { position; diameter } ->
         let open Components in
         { position; radius = diameter /. -2. })
  |> System_Physics.Entity.multiple
       ~read:(fun { state; _ } -> state)
       ~write:(fun state model -> { model with state })
  |> withReadWriteComponent
       ~read:(fun { health; _ } -> health)
       ~write:(fun health model -> { model with health })
       Damage.Component.health
  |> withHandler Damage.msg (fun damage -> Damage damage)
