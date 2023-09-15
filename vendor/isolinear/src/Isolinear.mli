type 'msg dispatcher = 'msg -> unit
type unsubscribe = unit -> unit

module Effect : sig
  type 'msg t

  val create : name:string -> (unit -> unit) -> 'a t
  val createWithDispatch : name:string -> ('msg dispatcher -> unit) -> 'msg t
  val none : _ t
  val batch : 'msg t list -> 'msg t
  val map : ('a -> 'b) -> 'a t -> 'b t
  val name : _ t -> string
  val run : 'msg t -> 'msg dispatcher -> unit
end

module Updater : sig
  type ('state, 'msg) t = 'state -> 'msg -> 'state * 'msg Effect.t

  val ofReducer : ('state -> 'msg -> 'state) -> ('state, 'msg) t
  val combine : ('state, 'msg) t list -> ('state, 'msg) t
end

module Sub : sig
  type 'msg t

  val none : 'msg t
  val batch : 'msg t list -> 'msg t
  val map : ('a -> 'b) -> 'a t -> 'b t

  module type S = sig
    type params
    type msg

    val create : params -> msg t
  end

  module type Provider = sig
    type params
    type msg
    type state

    val name : string
    val id : params -> string
    val init : params:params -> dispatch:(msg -> unit) -> state
    val update : params:params -> state:state -> dispatch:(msg -> unit) -> state
    val dispose : params:params -> state:state -> unit
  end

  module Make : functor (Provider : Provider) ->
    S with type msg = Provider.msg and type params = Provider.params
end

module Store : sig
  type ('msg, 'state) t

  val make : updater:('state, 'msg) Updater.t -> 'state -> ('msg, 'state) t
  val getState : ('msg, 'state) t -> 'state
  val dispatch : ('msg, 'state) t -> 'msg -> unit
  val hasPendingEffects : ('msg, 'state) t -> bool
  val runPendingEffects : ('msg, 'state) t -> unit
  val updateState : ('state -> 'state) -> ('msg, 'state) t -> unit
end

module Testing : sig
  module SubscriptionRunner : sig
    type 'msg t

    val empty : unit -> 'msg t
    val run : dispatch:('msg -> unit) -> sub:'msg Sub.t -> 'msg t -> 'msg t
  end
end