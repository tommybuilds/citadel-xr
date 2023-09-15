open Babylon
open EntityManager
open Grabbable
type internalState =
  | IUngrabbed 
  | IHolstered of {
  position: Vector3.t ;
  rotation: Quaternion.t } 
  | IGrabbed of
  {
  position: Vector3.t ;
  rotation: Quaternion.t ;
  isTriggerPressed: bool ;
  isButton1Pressed: bool ;
  isButton2Pressed: bool } 
type state =
  | Ungrabbed 
  | Grabbed of
  {
  position: Vector3.t ;
  rotation: Quaternion.t ;
  isTriggerPressed: bool ;
  isButton1Pressed: bool ;
  isButton2Pressed: bool } 
type t = {
  state: internalState ;
  secondaryGrabPosition: Vector3.t option }
let internalToExternalState { state; secondaryGrabPosition } =
  match state with
  | IUngrabbed -> Ungrabbed
  | IGrabbed
      { position; rotation; isTriggerPressed; isButton1Pressed;
        isButton2Pressed }
      ->
      let rotation =
        match secondaryGrabPosition with
        | None -> rotation
        | Some pos ->
            let diff =
              (pos |> (Vector3.subtract position)) |> Vector3.normalize in
            let up =
              (Quaternion.rotateVector (Vector3.up 1.0) rotation) |>
                Vector3.normalize in
            let right = (Vector3.cross diff up) |> Vector3.normalize in
            let up = (Vector3.cross right diff) |> Vector3.normalize in
            let quat = Quaternion.lookAt ~forward:diff ~up in quat in
      Grabbed
        {
          position;
          rotation;
          isTriggerPressed;
          isButton2Pressed;
          isButton1Pressed
        }
  | IHolstered { position; rotation } ->
      Grabbed
        {
          position;
          rotation;
          isTriggerPressed = false;
          isButton1Pressed = false;
          isButton2Pressed = false
        }
let initial () = { state = IUngrabbed; secondaryGrabPosition = None }
let isGrabbed { state;_} = state <> IUngrabbed
let isTwoHandedGrabbed { state; secondaryGrabPosition } =
  (state <> IUngrabbed) && (secondaryGrabPosition <> None)
let isTriggerPressed { state;_} =
  match state with
  | IGrabbed { isTriggerPressed;_} -> isTriggerPressed
  | _ -> false
let state = internalToExternalState
let component =
  (EntityManager.Component.readwrite ~name:"System_Grabbable.grabState" () : 
  (Component.readwrite, t) EntityManager.Component.t)