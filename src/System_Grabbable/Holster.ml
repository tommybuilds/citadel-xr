open Babylon
open EntityManager
module Type =
  struct
    let nextUniqueId = ref 0
    let none = 0
    type t = int
    let make () = incr nextUniqueId; !nextUniqueId
    let equals a b = a = b
  end
type t =
  {
  position: Vector3.t ;
  rotation: Quaternion.t ;
  size: float ;
  holsterType: Type.t }
let shape { position; size;_} = Shape.sphere ~radius:size position
let holsterType { holsterType;_} = holsterType
let make ?(size= 0.2)  ~position:(position : Vector3.t) 
  ~rotation:(rotation : Quaternion.t)  (holsterType : Type.t) =
  { size; position; rotation; holsterType }
let component =
  (EntityManager.Component.readonly ~name:"System_Grabbable.holster" () : 
  (Component.readonly, t) EntityManager.Component.t)