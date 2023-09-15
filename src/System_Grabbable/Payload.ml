let nextId = ref 0
type 'a t = {
  uniqueId: int ;
  defaultValue: 'a ;
  msg: 'a EntityManager.Msg.t }
let withValue v payload = { payload with defaultValue = v }
module Abstract =
  struct
    type abstract =
      | Abstract: 'a t -> abstract 
    type t = abstract
    let make payload = Abstract payload
  end
let matches (nonAbstractPayload : 'a t) (abstractPayload : Abstract.t) =
  match abstractPayload with
  | Abstract { uniqueId;_} -> uniqueId = nonAbstractPayload.uniqueId
let define ~name  defaultValue =
  incr nextId;
  { uniqueId = (!nextId); defaultValue; msg = (EntityManager.Msg.define name)
  }
type 'msg handler =
  | Handler: {
  payload: 'a t ;
  mapper: 'a -> 'msg } -> 'msg handler 
let handler payload mapper = Handler { payload; mapper }
let component =
  (EntityManager.Component.readonly ~name:"System_Grabbable.payloads" () : 
  (EntityManager.Component.readonly, Abstract.t list)
    EntityManager.Component.t)