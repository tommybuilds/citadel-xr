open Babylon
open EntityManager

module Shape : sig
  type t

  val box : ?width:float -> ?height:float -> ?depth:float -> unit -> t
  val capsule : ?radius:float -> ?height:float -> unit -> t
  val sphere : ?radius:float -> unit -> t
end

module State : sig
  type t

  val create :
    ?angularFactor:Vector3.t ->
    ?collisionGroup:Ammo.CollisionGroup.t ->
    ?collisionMask:Ammo.CollisionMask.t ->
    ?friction:float ->
    ?rollingFriction:float ->
    ?mass:float ->
    initialPosition:Vector3.t ->
    initialRotation:Quaternion.t ->
    Shape.t ->
    t

  val position : t -> Vector3.t
  val rotation : t -> Quaternion.t
end

module Component : sig
  val dynamic : (Component.readwrite, State.t list) Component.t
end

module System : sig
  type context

  val create : unit -> context EntityManager.System.definition
end

module RayCastResult : sig
  type t =
    | Hit of { position : Vector3.t; normal : Vector3.t; entityId : EntityId.t }
    | Miss
end

module Entity : sig
  val dynamic :
    read:('model -> State.t option) ->
    write:(State.t option -> 'model -> 'model) ->
    ('msg, 'model) EntityManager.Entity.definition ->
    ('msg, 'model) EntityManager.Entity.definition

  val multiple :
    read:('model -> State.t list) ->
    write:(State.t list -> 'model -> 'model) ->
    ('msg, 'model) EntityManager.Entity.definition ->
    ('msg, 'model) EntityManager.Entity.definition
end

module Effects : sig
  val attract :
    position:Vector3.t ->
    force:float ->
    entityId:EntityId.t ->
    System.context EntityManager.System.definition ->
    _ Effect.t

  val applyForce :
    ?position:Vector3.t ->
    force:Vector3.t ->
    entityId:EntityId.t ->
    System.context EntityManager.System.definition ->
    _ Effect.t

  val applyImpulse :
    ?position:Vector3.t ->
    impulse:Vector3.t ->
    entityId:EntityId.t ->
    System.context EntityManager.System.definition ->
    _ Effect.t

  val setLinearVelocity :
    velocity:Vector3.t ->
    entityId:EntityId.t ->
    System.context EntityManager.System.definition ->
    _ Effect.t

  val rayCast :
    ?collisionMask:Ammo.CollisionMask.t ->
    position:Vector3.t ->
    direction:Vector3.t ->
    System.context EntityManager.System.definition ->
    RayCastResult.t Effect.t
end