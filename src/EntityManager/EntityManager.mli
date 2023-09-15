module Component : sig
  type readonly
  type readwrite
  type ('writeaccess, 'component) t

  val readonly : ?name:string -> unit -> (readonly, 'component) t
  val readwrite : ?name:string -> unit -> (readwrite, 'component) t
end

module EntityId : sig
  type t

  val toInt : t -> int
  val unsafeFromInt : int -> t
end

type 'msg effect

module Msg : sig
  type 'payload t

  val define : string -> 'payload t
end

module ReadOnlyWorld : sig
  type t

  val read :
    t -> entityId:EntityId.t -> (_, 'component) Component.t -> 'component option

  val has : entityId:EntityId.t -> (_, _) Component.t -> t -> bool

  val valuesi :
    (_, 'component) Component.t -> t -> (EntityId.t * 'component) list
end

module EntityContext : sig
  type t

  val world : t -> ReadOnlyWorld.t
  val id : t -> EntityId.t
end

module Entity : sig
  type ('msg, 'state) definition

  val define : 'state -> ('msg, 'state) definition

  val withSub :
    ('state -> 'msg Isolinear.Sub.t) ->
    ('msg, 'state) definition ->
    ('msg, 'state) definition

  val withTick :
    (deltaTime:float -> 'state -> 'state * 'msg effect) ->
    ('msg, 'state) definition ->
    ('msg, 'state) definition

  val withThink :
    (deltaTime:float -> 'state -> 'state * 'msg effect) ->
    ('msg, 'state) definition ->
    ('msg, 'state) definition

  val withThinkW :
    (deltaTime:float -> ReadOnlyWorld.t -> 'state -> 'state * 'msg effect) ->
    ('msg, 'state) definition ->
    ('msg, 'state) definition

  val withThinkEx :
    (deltaTime:float -> EntityContext.t -> 'state -> 'state * 'msg effect) ->
    ('msg, 'state) definition ->
    ('msg, 'state) definition

  val withUpdate :
    ('msg -> 'state -> 'state * 'msg effect) ->
    ('msg, 'state) definition ->
    ('msg, 'state) definition

  val withUpdateW :
    (ReadOnlyWorld.t -> 'msg -> 'state -> 'state * 'msg effect) ->
    ('msg, 'state) definition ->
    ('msg, 'state) definition

  val withReadonlyComponent :
    (Component.readonly, 'component) Component.t ->
    ('state -> 'component) ->
    ('msg, 'state) definition ->
    ('msg, 'state) definition

  val withReadWriteComponent :
    read:('state -> 'component) ->
    write:('component -> 'state -> 'state) ->
    (Component.readwrite, 'component) Component.t ->
    ('msg, 'state) definition ->
    ('msg, 'state) definition

  val withHandler :
    'payload Msg.t ->
    ('payload -> 'msg) ->
    ('msg, 'state) definition ->
    ('msg, 'state) definition
end

module Effect : sig
  type 'msg t = 'msg effect

  val none : _ t
  val batch : 'a t list -> 'a t
  val createEntity : ('msg, 'state) Entity.definition -> _ t

  val createEntityI :
    (EntityId.t -> 'a) -> ('msg, 'state) Entity.definition -> 'a t

  val destroyEntity : EntityId.t -> _ t
  val destroySelf : _ t
  val send : 'payload Msg.t -> EntityId.t -> 'payload -> _ t
  val map : ('a -> 'b) -> 'a t -> 'b t
end

module World : sig
  type t

  val destroy : entity:EntityId.t -> t -> t
  val instantiate : entity:('msg, 'state) Entity.definition -> t -> t
  val entities : t -> EntityId.t list
  val values : (_, 'component) Component.t -> t -> 'component list

  val valuesi :
    (_, 'component) Component.t -> t -> (EntityId.t * 'component) list

  val has : entityId:EntityId.t -> (_, _) Component.t -> t -> bool

  val read :
    entity:EntityId.t -> (_, 'component) Component.t -> t -> 'component option

  val write :
    entity:EntityId.t ->
    value:'component ->
    (Component.readwrite, 'component) Component.t ->
    t ->
    t

  val map_entity :
    f:('component -> 'component) ->
    entityId:EntityId.t ->
    (Component.readwrite, 'component) Component.t ->
    t ->
    t

  val map_components :
    ('component -> 'component) ->
    (Component.readwrite, 'component) Component.t ->
    t ->
    t

  val map_componentsi :
    f:(EntityId.t -> 'component -> 'component) ->
    (Component.readwrite, 'component) Component.t ->
    t ->
    t

  val fold :
    f:('acc -> EntityId.t -> 'component -> 'acc) ->
    initial:'acc ->
    (_, 'component) Component.t ->
    t ->
    'acc

  val to_readonly : t -> ReadOnlyWorld.t
end

module System : sig
  type 'context definition

  val latestContext : 'context definition -> 'context

  val define :
    ?onAddStaticGeometry:(mesh:Babylon.mesh Babylon.node -> 'context -> unit) ->
    tick:(deltaTime:float -> world:World.t -> 'context -> 'context * World.t) ->
    'context ->
    'context definition

  module Effect : sig
    val sideEffect :
      ('args -> 'context -> unit) -> 'context definition -> 'args -> _ Effect.t

    val sideEffectWithDispatch :
      (dispatch:('msg -> unit) -> 'args -> 'context -> unit) ->
      'context definition ->
      'args ->
      'msg Effect.t
  end
end

type msg
type t

val instantiate : entity:('msg, 'state) Entity.definition -> t -> t

val instantiatei :
  entity:('msg, 'state) Entity.definition -> t -> EntityId.t * t

val destroy : entityId:EntityId.t -> t -> t
val entities : t -> EntityId.t list
val count : t -> int
val register : 'context System.definition -> t -> t
val initial : t

module SideEffects : sig
  type t

  val runSideEffects : (msg -> unit) -> t -> unit
end

val tick : deltaTime:float -> t -> t * SideEffects.t
val update : msg -> t -> t * SideEffects.t
val sub : t -> msg Isolinear.Sub.t
val world : t -> World.t
val addStaticGeometry : mesh:Babylon.mesh Babylon.node -> t -> unit
val context : 'context System.definition -> t -> 'context option
val values : (_, 'a) Component.t -> t -> 'a list
val valuesi : (_, 'a) Component.t -> t -> (EntityId.t * 'a) list
val exists : entity:EntityId.t -> t -> bool
val read : entity:EntityId.t -> (_, 'a) Component.t -> t -> 'a option

val write :
  entity:EntityId.t ->
  value:'a ->
  (Component.readwrite, 'a) Component.t ->
  t ->
  t
