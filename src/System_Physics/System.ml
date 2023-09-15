module C = Component
open Babylon
open Ammo
open EntityManager

type t

type context = {
  extraTime : float;
  physicsWorld : Ammo.world option ref;
  debugDrawer : Ammo.DebugDrawer.t option ref;
  entityToRigidBody : (EntityId.t, (int, Ammo.RigidBody.t) Hashtbl.t) Hashtbl.t;
  pendingStaticMeshes : Babylon.mesh Babylon.node list ref;
}

let reconcile (physicsWorld : Ammo.world)
    (physicsEntities :
      (EntityId.t, (int, Ammo.RigidBody.t) Hashtbl.t) Hashtbl.t)
    (worldEntities : (EntityId.t, (int, State.t) Hashtbl.t) Hashtbl.t) =
  let entityMerge entityId (subId : int) view =
    match view with
    | `Left physicsEntity ->
        Ammo.removeRigidBody ~body:physicsEntity physicsWorld;
        None
    | `Right worldEntity ->
        let state = (worldEntity : State.t) in
        let transform =
          Ammo.Transform.fromPositionRotation ~rotation:state.rotation
            ~position:state.position physicsWorld
        in
        let shape =
          match state.shape with
          | Box { dimensions } -> Ammo.Shape.box ~dimensions physicsWorld
          | Capsule { radius; height } ->
              Ammo.Shape.capsule ~radius ~height physicsWorld
          | Sphere { radius } -> Ammo.Shape.sphere radius physicsWorld
        in
        let body =
          Ammo.RigidBody.create ~id:(EntityId.toInt entityId)
            ?friction:state.friction ?rollingFriction:state.rollingFriction
            ~mass:(Ammo.Mass.ofFloat state.mass)
            ~motionState:(Ammo.MotionState.default ~transform physicsWorld)
            ~shape physicsWorld
        in
        (match state.angularFactor with
        | None -> ()
        | Some af -> Ammo.RigidBody.setAngularFactor af body);
        Ammo.addRigidBody ?collisionGroup:state.collisionGroup
          ?collisionMask:state.collisionMask ~body physicsWorld;
        Some body
    | `Both (physicsEntity, worldEntity) -> Some physicsEntity
  in
  let merge entityId view =
    match view with
    | `Left physicsEntityMap ->
        physicsEntityMap |> Hashtbl.to_seq_values
        |> Seq.iter (fun body -> Ammo.removeRigidBody ~body physicsWorld);
        None
    | `Right worldEntity -> Some (Hashtbl.create 16)
    | `Both (physicsEntityMap, worldEntityMap) ->
        Some
          (Util.HashtblEx.merge ~f:(entityMerge entityId) physicsEntityMap
             worldEntityMap)
  in
  Util.HashtblEx.merge ~f:merge physicsEntities worldEntities

let tick ~(deltaTime : float) ~(world : World.t) context =
  let entityIdToState =
    world
    |> World.fold
         ~f:(fun acc entityId state ->
           let stateHash = Hashtbl.create 16 in
           state |> List.iteri (fun idx item -> Hashtbl.add stateHash idx item);
           Hashtbl.add acc entityId stateHash;
           acc)
         ~initial:(Hashtbl.create 16) C.dynamic
  in
  let entityToRigidBody' =
    !(context.physicsWorld)
    |> Option.map (fun physicsWorld ->
           reconcile physicsWorld context.entityToRigidBody entityIdToState)
    |> Option.value ~default:context.entityToRigidBody
  in
  !(context.physicsWorld)
  |> Option.iter (fun physicsWorld ->
         let () = Ammo.step ~timeStep:deltaTime ~maxSteps:1 physicsWorld in
         ());
  !(context.debugDrawer) |> Option.iter Ammo.DebugDrawer.draw;
  let world' =
    !(context.physicsWorld)
    |> Option.map (fun physicsWorld ->
           let f (entityId : EntityId.t) (physicsItems : State.t list) =
             let maybeEntityTable =
               Hashtbl.find_opt entityToRigidBody' entityId
             in
             match maybeEntityTable with
             | None -> physicsItems
             | Some entityTable ->
                 physicsItems
                 |> List.mapi (fun idx item ->
                        match Hashtbl.find_opt entityTable idx with
                        | Some rigidBody ->
                            let open State in
                            if item.mass = 0.0 then (
                              Ammo.RigidBody.setPositionRotation item.position
                                item.rotation rigidBody physicsWorld;
                              item)
                            else
                              let position' =
                                rigidBody |> Ammo.RigidBody.position
                              in
                              let rotation' =
                                rigidBody |> Ammo.RigidBody.rotation
                              in
                              let open State in
                              {
                                item with
                                position = position';
                                rotation = rotation';
                              }
                        | None -> item)
           in
           World.map_componentsi ~f C.dynamic world)
    |> Option.value ~default:world
  in
  ({ context with entityToRigidBody = entityToRigidBody' }, world')

let onAddStaticGeometryReal mesh world =
  let rotation = Quaternion.identity () in
  let position = Vector3.zero () in
  let transform =
    Ammo.Transform.fromPositionRotation ~position ~rotation world
  in
  let shape = Ammo.Shape.triangleMesh ~mesh world in
  let body =
    Ammo.RigidBody.create ~id:(-1) ~mass:(Ammo.Mass.ofFloat 0.)
      ~motionState:(Ammo.MotionState.default ~transform world)
      ~shape world
  in
  let () = Ammo.addRigidBody ~body world in
  ()

let onQueueStaticGeometry mesh context =
  context.pendingStaticMeshes := mesh :: !(context.pendingStaticMeshes)

let onAddStaticGeometry ~mesh context =
  match !(context.physicsWorld) with
  | None -> onQueueStaticGeometry mesh context
  | Some world -> onAddStaticGeometryReal mesh world

let create () =
  let physicsWorld = ref None in
  let debugDrawer = ref None in
  let pendingStaticMeshes = ref [] in
  Ammo.init (fun world ->
      physicsWorld := Some world;
      let rotation = Quaternion.rotateAxis ~axis:(Vector3.up 1.0) 0. in
      let position = Vector3.up (-1.0) in
      let transform =
        Ammo.Transform.fromPositionRotation ~position ~rotation world
      in
      let floor =
        Ammo.Shape.box
          ~dimensions:(Vector3.create ~x:100. ~y:1.25 ~z:100.)
          world
      in
      let body =
        Ammo.RigidBody.create ~id:(-1) ~mass:(Ammo.Mass.ofFloat 0.)
          ~motionState:(Ammo.MotionState.default ~transform world)
          ~shape:floor world
      in
      let () = Ammo.addRigidBody ~body world in
      !pendingStaticMeshes
      |> List.iter (fun m -> onAddStaticGeometryReal m world);
      ());
  System.define ~onAddStaticGeometry ~tick
    {
      debugDrawer;
      extraTime = 0.0;
      physicsWorld;
      entityToRigidBody = Hashtbl.create 16;
      pendingStaticMeshes;
    }