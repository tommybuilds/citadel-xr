open EntityManager
open Babylon
type mode =
  | Empty 
  | Squeezing 
  | Grabbing of
  {
  handleType: Grabbable.handleType ;
  holsterType: Holster.Type.t ;
  payloads: Payload.Abstract.t list ;
  entityId: EntityId.t } 
type t =
  {
  mode: mode ;
  position: Vector3.t ;
  rotation: Quaternion.t ;
  isTriggerPressed: bool ;
  isButton1Pressed: bool ;
  isButton2Pressed: bool ;
  getState: unit -> Input.HandController.t option }
let grab ~payloads  ~entityId  ~holsterType  ~handleType  handContext =
  {
    handContext with
    mode = (Grabbing { payloads; holsterType; entityId; handleType })
  }
let squeeze handContext = { handContext with mode = Squeezing }
let release handContext = { handContext with mode = Empty }
let initial =
  {
    mode = Empty;
    isButton1Pressed = false;
    isButton2Pressed = false;
    isTriggerPressed = false;
    position = (Vector3.zero ());
    rotation = (Quaternion.zero ());
    getState = (fun () -> None)
  }
let component =
  (EntityManager.Component.readonly
     ~name:"System_Grabbable.HandContext.component" () : (EntityManager.Component.readonly,
                                                           t list)
                                                           EntityManager.Component.t)