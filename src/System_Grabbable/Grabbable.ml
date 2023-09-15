open Babylon
open EntityManager
type handleType =
  | Primary 
  | Secondary 
  | DropTarget: 'msg Payload.t -> handleType 
type grabHandle = {
  shape: Shape.t ;
  handleType: handleType }
let primary shape = { handleType = Primary; shape }
let secondary shape = { handleType = Secondary; shape }
let handlesPayload payload { handleType;_} =
  match handleType with
  | Primary -> false
  | Secondary -> false
  | DropTarget targetPayload -> Payload.matches targetPayload payload
let dropTarget shape payload _mapper =
  { handleType = (DropTarget payload); shape }
let shape { shape;_} = shape
type t =
  {
  position: Vector3.t ;
  rotation: Quaternion.t ;
  holsterType: Holster.Type.t ;
  handles: grabHandle list }
let holsterType { holsterType;_} = holsterType
let handles { handles;_} = handles
let handleType { handleType;_} = handleType
let make ?(holsterType= Holster.Type.none)  ~position  ~rotation  handles =
  { holsterType; position; rotation; handles }
let onlyDropTargets payload ({ handles;_} as grabbable) =
  let handles' =
    handles |> (List.filter (fun handle -> handlesPayload payload handle)) in
  { grabbable with handles = handles' }
let expand { position; rotation; handles } =
  handles |>
    (List.map
       (fun grabHandle ->
          {
            grabHandle with
            shape = (Shape.transform ~position ~rotation grabHandle.shape)
          }))
let component =
  (EntityManager.Component.readonly ~name:"System_Grabbable.grabbable" () : 
  (Component.readonly, t) EntityManager.Component.t)