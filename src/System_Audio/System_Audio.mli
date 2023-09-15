type context

val system : context EntityManager.System.definition

module Effect : sig
  val play : position:Babylon.Vector3.t -> string -> unit EntityManager.Effect.t
end