open Babylon
open React3d
open EntityManager

type model = {
  initialPosition : Vector3.t;
  position : Vector3.t;
  direction : Vector3.t;
  rotation : Quaternion.t;
  speed : float;
}

let initial =
  ({
     position = Vector3.zero ();
     initialPosition = Vector3.zero ();
     direction = Vector3.forward 1.0;
     rotation = Quaternion.zero ();
     speed = 370.;
   }
    : model)

let update msg model = (model, EntityManager.Effect.none)

type msg = RayCastResult of System_Physics.RayCastResult.t

let tick ~deltaTime ({ initialPosition; position; direction; speed } as entity)
    =
  let x = Vector3.x position +. (Vector3.x direction *. deltaTime *. speed) in
  let y = Vector3.y position +. (Vector3.y direction *. deltaTime *. speed) in
  let z = Vector3.z position +. (Vector3.z direction *. deltaTime *. speed) in
  let position' = Vector3.create ~x ~y ~z in
  let lenSquared =
    Vector3.lengthSquared (Vector3.subtract initialPosition position')
  in
  let effect =
    if lenSquared >= 1000000. then EntityManager.Effect.destroySelf
    else
      System_Physics.Effects.rayCast
        ~collisionMask:Collision.Mask.worldAndHitBox ~position
        ~direction:(Vector3.subtract position' position)
        Systems.physics
      |> Effect.map (fun rayCastResult -> RayCastResult rayCastResult)
  in
  ({ entity with position = position' }, effect)

let update msg model =
  match msg with
  | RayCastResult System_Physics.RayCastResult.Miss -> (model, Effect.none)
  | RayCastResult
      (System_Physics.RayCastResult.Hit { entityId; position; normal }) ->
      let applyForceEffect =
        System_Physics.Effects.applyForce ~position
          ~force:(Vector3.scale 10000. model.direction)
          ~entityId Systems.physics
      in
      let nNormal = Vector3.normalize normal in
      let createImpact =
        Effect.createEntity
          (Impact.entity
             (Vector3.add position (Vector3.scale 0.01 nNormal))
             nNormal)
      in
      let destroyEffect = Effect.destroySelf in
      let damageEffect =
        Damage.Effects.damage ~target:entityId ~damage:1000. Damage.system
      in
      (model, Effect.batch [ destroyEffect; damageEffect; createImpact ])

let entity position rotation =
  let direction =
    Quaternion.rotateVector (Vector3.forward 1.0) rotation |> Vector3.normalize
  in
  let open Entity in
  define
    { initial with position; initialPosition = position; direction; rotation }
  |> withThink tick |> withUpdate update
  |> withReadonlyComponent Components.bolt (fun { position; _ } -> position)
