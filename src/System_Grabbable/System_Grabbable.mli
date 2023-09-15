open Babylon
open EntityManager

type t

module Shape : sig
  type t

  val sphere : radius:float -> Vector3.t -> t
end

module Holster : sig
  module Type : sig
    type t

    val make : unit -> t
    val none : t
  end

  type t

  val make :
    ?size:float -> position:Vector3.t -> rotation:Quaternion.t -> Type.t -> t
end

module Payload : sig
  type 'a t

  val define : name:string -> 'a -> 'a t

  type 'msg handler

  val handler : 'payload t -> ('payload -> 'msg) -> 'msg handler
end

module Grabbable : sig
  type grabHandle

  val primary : Shape.t -> grabHandle
  val secondary : Shape.t -> grabHandle
  val dropTarget : Shape.t -> 'a Payload.t -> ('a -> 'msg) -> grabHandle

  type t

  val make :
    ?holsterType:Holster.Type.t ->
    position:Vector3.t ->
    rotation:Quaternion.t ->
    grabHandle list ->
    t
end

module GrabState : sig
  type t

  val initial : unit -> t

  type state =
    | Ungrabbed
    | Grabbed of {
        position : Vector3.t;
        rotation : Quaternion.t;
        isTriggerPressed : bool;
        isButton1Pressed : bool;
        isButton2Pressed : bool;
      }

  val isGrabbed : t -> bool
  val isTwoHandedGrabbed : t -> bool
  val isTriggerPressed : t -> bool
  val state : t -> state
end

module HolsterState : sig
  type t
  type state = Empty | Hovered | Full of { entityId : EntityId.t }

  val initial : t
  val full : EntityId.t -> t
  val state : t -> state
end

module Entity : sig
  val grabbable :
    ?payloads:'msg Payload.handler list ->
    readGrabState:('state -> GrabState.t) ->
    writeGrabState:(GrabState.t -> 'state -> 'state) ->
    grabHandles:('state -> Grabbable.t) ->
    ('msg, 'state) Entity.definition ->
    ('msg, 'state) Entity.definition

  val holster :
    readHolsterState:('state -> HolsterState.t) ->
    writeHolsterState:(HolsterState.t -> 'state -> 'state) ->
    holsters:('state -> Holster.t) ->
    ('msg, 'state) Entity.definition ->
    ('msg, 'state) Entity.definition

  val suppliesPayload :
    'a Payload.t ->
    ('state -> 'a) ->
    ('msg, 'state) Entity.definition ->
    ('msg, 'state) Entity.definition
end

module System : sig
  type context

  val system : context System.definition
end

module EntityFactory : sig
  module Hand : sig
    type model
    type msg
  end

  val hand :
    (unit -> Input.HandController.t option) ->
    System_Physics.System.context EntityManager.System.definition ->
    System.context EntityManager.System.definition ->
    (Hand.msg, Hand.model) EntityManager.Entity.definition
end

module Effects : sig
  val holster :
    entityToHolster:EntityId.t ->
    holster:EntityId.t ->
    System.context EntityManager.System.definition ->
    _ EntityManager.Effect.t
end