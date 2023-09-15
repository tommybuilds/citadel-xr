open Babylon
open EntityManager
module Category : sig type t val define : string -> t end
module Entity :
sig
  val categorize :
    category:Category.t ->
      ('state -> Babylon.Vector3.t) ->
        ('msg, 'state) Entity.definition -> ('msg, 'state) Entity.definition
end
module World :
sig
  val getPosition : EntityId.t -> ReadOnlyWorld.t -> Vector3.t option
  val getNearestEntityOfCategory :
    position:Babylon.Vector3.t ->
      category:Category.t -> ReadOnlyWorld.t -> EntityId.t option
end