type world

external init : (world -> unit) -> unit = "ammo_init"
external step : timeStep:float -> maxSteps:int -> world -> unit = "ammo_step"

module CollisionGroup = struct
  type t = { id : int; name : string }

  let uniqueId = ref 1
  let default = { id = 1; name = "default" }

  let nextId () =
    incr uniqueId;
    !uniqueId

  let create name = { name; id = Int.shift_left 1 (nextId () - 1) }
  let toInt { id; _ } = id
end

module CollisionMask = struct
  type t = int

  let default =
    List.init 32 (fun i -> Int.shift_left 1 i)
    |> List.fold_left (fun acc cur -> Int.logor acc cur) 0

  let create groups =
    groups
    |> List.map (fun ({ id; _ } : CollisionGroup.t) -> id)
    |> List.fold_left (fun acc cur -> Int.logor acc cur) 0
end

module DebugDrawer = struct
  type t

  external create : world -> t = "ammo_debugDrawer_create"
  external draw : t -> unit = "ammo_debugDrawer_draw"
  external dispose : t -> unit = "ammo_debugDrawer_dispose"
end

module Mass = struct
  type t = float

  let ofFloat = Fun.id
end

module Shape = struct
  type t

  external box : dimensions:Babylon.Vector3.t -> world -> t = "ammo_shape_box"

  external capsule : radius:float -> height:float -> world -> t
    = "ammo_shape_capsule"

  external triangleMesh : mesh:Babylon.mesh Babylon.node -> world -> t
    = "ammo_shape_triangleMesh"

  external sphere : radius:float -> world -> t = "ammo_shape_sphere"
end

module Transform = struct
  type t

  external origin : t -> Babylon.Vector3.t = "ammo_transform_origin"
  external rotation : t -> Babylon.Quaternion.t = "ammo_transform_rotation"

  external fromPositionRotation :
    rotation:Babylon.Quaternion.t -> position:Babylon.Vector3.t -> world -> t
    = "ammo_transform_fromPositionRotation"

  external identity : world -> t = "ammo_transform_identity"
end

module MotionState = struct
  type t

  external default : transform:Transform.t -> world -> t
    = "ammo_motionState_default"
end

module RigidBody = struct
  type t

  external _create :
    id:int ->
    linearDamping:float ->
    angularDamping:float ->
    friction:float ->
    rollingFriction:float ->
    mass:Mass.t ->
    motionState:MotionState.t ->
    shape:Shape.t ->
    world ->
    t = "ammo_rigidBody_create" "ammo_rigidBody_create_native"

  let create ?(linearDamping = 0.1) ?(angularDamping = 0.1) ?(friction = 0.5)
      ?(rollingFriction = 0.5) ~id ~mass ~motionState ~shape world =
    _create ~linearDamping ~angularDamping ~friction ~rollingFriction ~id ~mass
      ~motionState ~shape world

  external position : t -> Babylon.Vector3.t = "ammo_rigidBody_position"
  external rotation : t -> Babylon.Quaternion.t = "ammo_rigidBody_rotation"

  external setAngularFactor : Babylon.Vector3.t -> t -> unit
    = "ammo_rigidBody_setAngularFactor"

  external setPositionRotation :
    Babylon.Vector3.t -> Babylon.Quaternion.t -> t -> world -> unit
    = "ammo_rigidBody_setPositionRotation"

  external applyForce :
    force:Babylon.Vector3.t -> position:Babylon.Vector3.t -> world -> t -> unit
    = "ammo_rigidBody_applyForce"

  external applyImpulse :
    impulse:Babylon.Vector3.t ->
    position:Babylon.Vector3.t ->
    world ->
    t ->
    unit = "ammo_rigidBody_applyImpulse"

  external setLinearVelocity : velocity:Babylon.Vector3.t -> world -> t -> unit
    = "ammo_rigidBody_setLinearVelocity"
end

module RayCastResult = struct
  type t

  external position : t -> Babylon.Vector3.t = "ammo_raycastResult_position"
  external normal : t -> Babylon.Vector3.t = "ammo_raycastResult_normal"
  external bodyId : t -> int = "ammo_raycastResult_bodyId"
end

external _rayCast :
  collisionMask:int ->
  start:Babylon.Vector3.t ->
  stop:Babylon.Vector3.t ->
  world ->
  RayCastResult.t option = "ammo_raycast"

let rayCast ?collisionMask ~start ~stop world =
  let collisionMask =
    match collisionMask with None -> CollisionMask.default | Some v -> v
  in
  _rayCast ~collisionMask ~start ~stop world

external _shapeCast :
  shape:Shape.t ->
  start:Babylon.Vector3.t ->
  startRotation:Babylon.Quaternion.t ->
  stop:Babylon.Vector3.t ->
  stopRotation:Babylon.Quaternion.t ->
  world ->
  RayCastResult.t option = "ammo_shapeCast" "ammo_shapeCast_native"

let defaultRotation = Babylon.Quaternion.identity ()

let shapeCast ~shape ~start ?(startRotation = defaultRotation) ~stop
    ?(stopRotation = defaultRotation) world =
  _shapeCast ~shape ~start ~startRotation ~stop ~stopRotation world

external _addRigidBody :
  collisionGroup:int -> collisionMask:int -> body:RigidBody.t -> world -> unit
  = "ammo_addRigidBody"

let addRigidBody ?collisionGroup ?collisionMask ~body world =
  let collisionGroup =
    (match collisionGroup with None -> CollisionGroup.default | Some v -> v)
    |> CollisionGroup.toInt
  in
  let collisionMask =
    match collisionMask with None -> CollisionMask.default | Some v -> v
  in
  _addRigidBody ~collisionGroup ~collisionMask ~body world

external removeRigidBody : body:RigidBody.t -> world -> unit
  = "ammo_removeRigidBody"
