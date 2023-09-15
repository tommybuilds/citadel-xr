open Babylon
open React3d
open Mesh
module Physics = System_Physics

module AI = struct
  type behavior =
    | Wander of { nextDirectionChange : float }
    | RunTowards of { targetId : EntityManager.EntityId.t }
    | Attack of { targetId : EntityManager.EntityId.t }
    | Dead

  type state = {
    animationPlayer : unit AnimationPlayer.t;
    forward : Vector3.t;
    desiredForward : Vector3.t;
    behavior : behavior;
  }

  let forward { forward; _ } = forward

  let animationFrame { animationPlayer; _ } =
    AnimationPlayer.frame animationPlayer

  let initial =
    {
      animationPlayer =
        AnimationPlayer.create Citadel_Assets.Ghoul.Animations.run;
      desiredForward = Vector3.forward (-1.0);
      forward = Vector3.forward (-1.0);
      behavior = Wander { nextDirectionChange = 5.0 };
    }

  let randomDirection () =
    let rand () = Random.float 2.0 -. 1.0 in
    Vector3.create ~x:(rand ()) ~y:0. ~z:(rand ())

  let rotateTowards ~deltaTime currentForward desiredForward =
    let diff = Vector3.subtract desiredForward currentForward in
    let rotationSpeed = 5.0 in
    let deltaVector = Vector3.scale (rotationSpeed *. deltaTime) diff in
    Vector3.add currentForward deltaVector |> Vector3.normalize

  let kill ({ animationPlayer; behavior; _ } as currentState) =
    if behavior == Dead then currentState
    else
      let animationPlayer' =
        Mesh.AnimationPlayer.setAnimation Citadel_Assets.Ghoul.Animations.die
          animationPlayer
      in
      { currentState with behavior = Dead; animationPlayer = animationPlayer' }

  let think ~entityId ~currentPosition ~deltaTime ~world
      ({ forward; animationPlayer; behavior; desiredForward } as currentState :
        state) =
    let animationPlayer', _effects =
      AnimationPlayer.tick ~deltaTime animationPlayer
    in
    match behavior with
    | Attack { targetId } ->
        let eff =
          System_Physics.Effects.setLinearVelocity
            ~velocity:(Vector3.scale 0.0 forward)
            ~entityId Systems.physics
        in
        let maybePosition = System_AI.World.getPosition targetId world in
        let state' =
          match maybePosition with
          | None ->
              {
                currentState with
                animationPlayer =
                  AnimationPlayer.setAnimation
                    Citadel_Assets.Ghoul.Animations.idle animationPlayer';
                desiredForward = randomDirection ();
                behavior = Wander { nextDirectionChange = 5.0 };
              }
          | Some pos ->
              let delta = Vector3.subtract pos currentPosition in
              let distSquared = Vector3.lengthSquared delta in
              if distSquared > 5.0 then
                {
                  currentState with
                  animationPlayer =
                    AnimationPlayer.setAnimation
                      Citadel_Assets.Ghoul.Animations.run animationPlayer';
                  behavior = RunTowards { targetId };
                }
              else { currentState with animationPlayer = animationPlayer' }
        in
        (state', eff)
    | RunTowards { targetId } ->
        let eff =
          System_Physics.Effects.setLinearVelocity
            ~velocity:(Vector3.scale 3.0 forward)
            ~entityId Systems.physics
        in
        let maybePosition = System_AI.World.getPosition targetId world in
        let state' =
          match maybePosition with
          | Some pos ->
              let delta = Vector3.subtract pos currentPosition in
              let distSquared = Vector3.lengthSquared delta in
              let direction = Vector3.normalize delta in
              if distSquared < 2.0 then
                {
                  currentState with
                  animationPlayer =
                    AnimationPlayer.setAnimation
                      Citadel_Assets.Ghoul.Animations.attack2 animationPlayer';
                  behavior = Attack { targetId };
                }
              else
                {
                  currentState with
                  animationPlayer = animationPlayer';
                  desiredForward = direction;
                  forward = rotateTowards ~deltaTime forward desiredForward;
                }
          | None ->
              {
                currentState with
                animationPlayer = animationPlayer';
                desiredForward = randomDirection ();
                behavior = Wander { nextDirectionChange = 5.0 };
              }
        in
        (state', eff)
    | Wander { nextDirectionChange } ->
        let eff =
          System_Physics.Effects.setLinearVelocity
            ~velocity:(Vector3.scale 3.0 forward)
            ~entityId Systems.physics
        in
        let state' =
          if nextDirectionChange < 0. then
            let nearestPlayer =
              System_AI.World.getNearestEntityOfCategory
                ~position:currentPosition ~category:Categories.player world
            in
            (* match nearestPlayer with
               | Some targetId ->
                   {
                     currentState with
                     animationPlayer = animationPlayer';
                     behavior = (RunTowards { targetId })
                   }
               | None -> *)
            {
              currentState with
              animationPlayer = animationPlayer';
              desiredForward = randomDirection ();
              behavior = Wander { nextDirectionChange = 5.0 };
            }
          else
            {
              currentState with
              animationPlayer = animationPlayer';
              forward = rotateTowards ~deltaTime forward desiredForward;
              behavior =
                Wander
                  { nextDirectionChange = nextDirectionChange -. deltaTime };
            }
        in
        (state', eff)
    | Dead ->
        let eff =
          System_Physics.Effects.setLinearVelocity ~velocity:(Vector3.zero ())
            ~entityId Systems.physics
        in
        ({ currentState with animationPlayer = animationPlayer' }, eff)
end

type model = {
  health : Damage.State.t;
  state : Physics.State.t list;
  skeletonRef : Babylon.Skeleton.t option ref;
  aiState : AI.state;
}

type msg = Damage

let width = 0.5
let height = 0.9

let think ~deltaTime (context : EntityManager.EntityContext.t)
    ({ aiState; state; skeletonRef; _ } as model) =
  let position = Physics.State.position (List.nth state 0) in
  let entityId = EntityManager.EntityContext.id context in
  let world = EntityManager.EntityContext.world context in
  let aiState', eff =
    AI.think ~entityId ~currentPosition:position ~world ~deltaTime aiState
  in
  let forward = AI.forward aiState' in
  let initialState = List.nth state 0 in
  let hitbox skeleton =
    let rotation =
      Quaternion.rotateAxis (Babylon.Vector3.right 1.0) (Float.pi /. 2.0)
    in
    let scale = Vector3.create1 0.03 in
    let outerTransform =
      Matrix.compose ~scale ~rotation ~translation:(Vector3.zero ())
    in
    let lookAt = QuaternionEx.lookAt forward in
    let rotate180 = Quaternion.rotateAxis ~axis:(Vector3.up 1.0) Float.pi in
    let innerRotation = Quaternion.multiply lookAt rotate180 in
    let innerTransform =
      Matrix.compose ~scale:(Vector3.create1 1.0) ~rotation:innerRotation
        ~translation:(System_Physics.State.position initialState)
    in
    let bonesToGet =
      [ 0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; 65 ]
    in
    bonesToGet
    |> List.map (fun idx ->
           let bone =
             Babylon.Skeleton.getBoneByIndex idx skeleton |> Option.get
           in
           let position =
             bone |> Babylon.Bone.getLocalPosition
             |> Babylon.Matrix.transformCoordinates outerTransform
             |> Babylon.Matrix.transformCoordinates innerTransform
             |> Vector3.add (Vector3.up (-1.0 *. height))
           in
           let rotation =
             bone |> Babylon.Bone.getLocalRotation
             |> Babylon.Quaternion.multiply rotation
             |> Babylon.Quaternion.multiply innerRotation
           in
           Physics.State.create ~mass:0.0 ~collisionGroup:Collision.Group.hitBox
             ~collisionMask:Collision.Mask.all ~initialPosition:position
             ~initialRotation:rotation
             (Physics.Shape.box ~width:0.1 ~height:0.1 ~depth:0.1 ()))
  in
  let hitboxes =
    !skeletonRef |> Option.map hitbox |> Option.value ~default:[]
  in
  let state = initialState :: hitboxes in
  ({ model with aiState = aiState'; state }, eff)

let physics = object (this) end

let render { state; aiState; skeletonRef } =
  let position = Physics.State.position (List.nth state 0) in
  let rotation = Physics.State.rotation (List.nth state 0) in
  let legCube skeleton =
    let rotation =
      Quaternion.rotateAxis (Babylon.Vector3.right 1.0) (Float.pi /. 2.0)
    in
    let scale = Vector3.create1 0.03 in
    let bonesToGet = [ 0; 1; 2; 3; 4; 5; 6; 7; 8 ] in
    let xforms =
      bonesToGet
      |> List.map (fun idx ->
             let bone =
               Babylon.Skeleton.getBoneByIndex idx skeleton |> Option.get
             in
             let position = Babylon.Bone.getLocalPosition bone in
             P.transform [])
    in
    P.transform ~rotation ~scale xforms
  in
  let forward = AI.forward aiState in
  let lookAt = QuaternionEx.lookAt forward in
  let rotate180 = Quaternion.rotateAxis ~axis:(Vector3.up 1.0) Float.pi in
  let innerRotation = Quaternion.multiply lookAt rotate180 in
  let leg =
    !skeletonRef |> Option.map legCube |> Option.value ~default:(P.transform [])
  in
  let frame = AI.animationFrame aiState in
  let open React3d in
  P.transform
    [
      P.transform ~position
        [
          P.transform ~rotation
            [
              P.transform ~rotation:innerRotation
                [
                  P.transform
                    ~position:(Vector3.up (-1.0 *. height))
                    [
                      P.animatedMesh ~frame ~skeletonRef
                        Citadel_Assets.Ghoul.mesh;
                      leg;
                    ];
                ];
            ];
        ];
    ]

let update msg ({ aiState; _ } as model) =
  let aiState' = AI.kill aiState in
  ({ model with aiState = aiState' }, EntityManager.Effect.none)

open EntityManager.Entity

let entity position =
  let state =
    [
      Physics.State.create ~collisionGroup:Collision.Group.boundingBox
        ~collisionMask:Collision.Mask.worldAndBoundingBox
        ~angularFactor:(Vector3.up 1.0) ~mass:50. ~friction:0.
        ~rollingFriction:0. ~initialPosition:position
        ~initialRotation:(Quaternion.initial ())
        (Physics.Shape.box ~width ~height ~depth:width ());
    ]
  in
  let health = Damage.State.create 100. in
  EntityManager.Entity.define
    { state; health; skeletonRef = ref None; aiState = AI.initial }
  |> EntityManager.Entity.withThinkEx think
  |> EntityManager.Entity.withUpdate update
  |> EntityManager.Entity.withReadonlyComponent Components.render render
  |> withReadWriteComponent
       ~read:(fun { health; _ } -> health)
       ~write:(fun health model -> { model with health })
       Damage.Component.health
  |> withHandler Damage.msg (fun _damage -> Damage)
  |> System_Physics.Entity.multiple
       ~read:(fun { state } -> state)
       ~write:(fun state entity -> { entity with state })
