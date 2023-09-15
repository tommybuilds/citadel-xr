open EntityManager
type state =
  | Empty 
  | Hovered 
  | Full of {
  entityId: EntityId.t } 
type t = state
let state state = state
let initial = Empty
let full entityId = Full { entityId }
let component =
  (EntityManager.Component.readwrite ~name:"System_Grabbable.holsterState" () : 
  (Component.readwrite, t) EntityManager.Component.t)