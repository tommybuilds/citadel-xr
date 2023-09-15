open EntityManager

module type D = sig
  type health
  type damage

  module State : sig
    type t

    val create : health -> t
    val damage : damage -> t -> t
  end

  module Component : sig
    val health : (Component.readwrite, State.t) Component.t
  end

  type context

  val system : context System.definition

  type msg = damage EntityManager.Msg.t

  val msg : msg

  module Effects : sig
    val damage :
      target:EntityId.t ->
      damage:damage ->
      context System.definition ->
      _ Effect.t
  end
end

module Make : functor
  (Config : sig
     type damage
     type health

     val applyDamage : health -> damage -> health
     val isAlive : health -> bool
   end)
  -> D with type damage = Config.damage and type health = Config.health
