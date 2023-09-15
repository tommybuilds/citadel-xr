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

  val system : context EntityManager.System.definition

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

module Make (Config : sig
  type health
  type damage

  val applyDamage : health -> damage -> health
  val isAlive : health -> bool
end) =
struct
  type health = Config.health
  type damage = Config.damage

  module State = struct
    type t = { health : health }

    let create health = { health }
    let damage damage { health } = { health = Config.applyDamage health damage }
  end

  module Component = struct
    let health =
      (Component.readwrite ~name:"System_Damage.health" ()
        : (Component.readwrite, State.t) Component.t)
  end

  type context = unit

  module System = struct
    let tick ~deltaTime ~world context =
      let f prevWorld entityId (component : State.t) =
        let State.{ health } = component in
        if Config.isAlive health then prevWorld
        else World.destroy ~entity:entityId prevWorld
      in
      let world' = world |> World.fold ~f ~initial:world Component.health in
      (context, world')

    let system = System.define ~tick ()
  end

  let system = System.system

  type msg = damage EntityManager.Msg.t

  let msg = (Msg.define "damage" : Config.damage Msg.t)

  module Effects = struct
    let damage ~target ~damage system = Effect.send msg target damage
  end
end
