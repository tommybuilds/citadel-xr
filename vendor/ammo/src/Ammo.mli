type world

val init : (world -> unit) -> unit
val step : timeStep:float -> maxSteps:int -> world -> unit

module CollisionGroup : sig
  type t

  val default : t
  val create : string -> t
end

module CollisionMask : sig
  type t

  val default : t
  val create : CollisionGroup.t list -> t
end

module DebugDrawer : sig
  type t

  val create : world -> t
  val draw : t -> unit
  val dispose : t -> unit
end

module Mass : sig
  type t

  val ofFloat : float -> t
end

module Shape : sig
  type t

  val box : dimensions:Babylon.Vector3.t -> world -> t
  val capsule : radius:float -> height:float -> world -> t
  val triangleMesh : mesh:Babylon.mesh Babylon.node -> world -> t
  val sphere : radius:float -> world -> t
end

module Transform : sig
  type t

  val origin : t -> Babylon.Vector3.t
  val rotation : t -> Babylon.Quaternion.t

  val fromPositionRotation :
    rotation:Babylon.Quaternion.t -> position:Babylon.Vector3.t -> world -> t

  val identity : world -> t
end

module MotionState : sig
  type t

  val default : transform:Transform.t -> world -> t
end

module RigidBody : sig
  type t

  val create :
    ?linearDamping:float ->
    ?angularDamping:float ->
    ?friction:float ->
    ?rollingFriction:float ->
    id:int ->
    mass:Mass.t ->
    motionState:MotionState.t ->
    shape:Shape.t ->
    world ->
    t

  val setPositionRotation :
    Babylon.Vector3.t -> Babylon.Quaternion.t -> t -> world -> unit

  val position : t -> Babylon.Vector3.t
  val rotation : t -> Babylon.Quaternion.t
  val setAngularFactor : Babylon.Vector3.t -> t -> unit

  val applyForce :
    force:Babylon.Vector3.t -> position:Babylon.Vector3.t -> world -> t -> unit

  val applyImpulse :
    impulse:Babylon.Vector3.t ->
    position:Babylon.Vector3.t ->
    world ->
    t ->
    unit

  val setLinearVelocity : velocity:Babylon.Vector3.t -> world -> t -> unit
end

module RayCastResult : sig
  type t

  val position : t -> Babylon.Vector3.t
  val normal : t -> Babylon.Vector3.t
  val bodyId : t -> int
end

val rayCast :
  ?collisionMask:CollisionMask.t ->
  start:Babylon.Vector3.t ->
  stop:Babylon.Vector3.t ->
  world ->
  RayCastResult.t option

val shapeCast :
  shape:Shape.t ->
  start:Babylon.Vector3.t ->
  ?startRotation:Babylon.Quaternion.t ->
  stop:Babylon.Vector3.t ->
  ?stopRotation:Babylon.Quaternion.t ->
  world ->
  RayCastResult.t option

val addRigidBody :
  ?collisionGroup:CollisionGroup.t ->
  ?collisionMask:CollisionMask.t ->
  body:RigidBody.t ->
  world ->
  unit

val removeRigidBody : body:RigidBody.t -> world -> unit