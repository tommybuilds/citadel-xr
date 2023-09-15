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
     speed = 1.5;
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
    if lenSquared >= 1000. then EntityManager.Effect.destroySelf
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
  | RayCastResult (System_Physics.RayCastResult.Hit { entityId; position; _ })
    ->
      let applyForceEffect =
        System_Physics.Effects.applyForce ~position
          ~force:(Vector3.scale 10000. model.direction)
          ~entityId Systems.physics
      in
      let destroyEffect = Effect.destroySelf in
      let damageEffect =
        Damage.Effects.damage ~target:entityId ~damage:1000. Damage.system
      in
      (model, Effect.batch [ applyForceEffect; destroyEffect; damageEffect ])

let red = Babylon.Color.make ~r:1.0 ~g:0.0 ~b:0.0
let boltMaterial = React3d.Material.color ~emissive:red red

let render model =
  P.transform ~position:model.position
    [
      P.transform ~rotation:model.rotation
        [
          P.transform
            ~rotation:
              (Babylon.Quaternion.rotateAxis
                 ~axis:(Vector3.create ~x:1.0 ~y:0. ~z:0.)
                 (Float.pi /. 2.0))
            [ P.cylinder ~height:0.75 ~material:boltMaterial ~diameter:0.05 [] ];
        ];
    ]

let entity position rotation =
  let direction = Quaternion.rotateVector (Vector3.forward 1.0) rotation in
  let open Entity in
  define
    { position; initialPosition = position; direction; speed = 25.0; rotation }
  |> withThink tick |> withUpdate update
  |> withReadonlyComponent Components.render render
  |> withReadonlyComponent Components.bolt (fun { position; _ } -> position)
