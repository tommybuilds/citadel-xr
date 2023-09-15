open Babylon

module CameraController = struct
  type t = {
    position : Vector3.t;
    rotation : Quaternion.t;
    realWorldHeight : float;
  }

  let position { position; _ } = position
  let rotation { rotation; _ } = rotation
  let realWorldHeight { realWorldHeight; _ } = realWorldHeight

  let ofCamera ~isInXR ~(transform : Matrix.t) (camera : camera node) =
    let position = Babylon.Node.getPosition camera in
    let position' = Matrix.transformCoordinates transform position in
    let rotation =
      camera |> Babylon.Camera.absoluteRotation |> Quaternion.clone
    in
    let realWorldHeight =
      match isInXR with
      | true -> camera |> Babylon.Camera.realWorldHeight
      | false -> 1.6
    in
    { position = position'; rotation; realWorldHeight }
end

module Button = struct
  type t = { isPressed : bool }

  let ofBool isPressed = { isPressed }

  let fromXR (id : string) (controller : WebXR.Controller.t) =
    controller |> WebXR.Controller.motionController
    |> (fun c -> Option.bind c (WebXR.MotionController.getComponent id))
    |> Option.map (fun (component : WebXR.ControllerComponent.t) ->
           ofBool (WebXR.ControllerComponent.pressed component))
    |> Option.value ~default:(ofBool false)

  let isPressed { isPressed } = isPressed
end

module Thumbstick = struct
  type t = { x : float; y : float }

  let x { x; _ } = x
  let y { y; _ } = y

  let fromXR (id : string) (controller : WebXR.Controller.t) =
    controller |> WebXR.Controller.motionController
    |> (fun c -> Option.bind c (WebXR.MotionController.getComponent id))
    |> Option.map (fun (component : WebXR.ControllerComponent.t) ->
           let axes = WebXR.ControllerComponent.axes component in
           { x = WebXR.ControllerAxes.x axes; y = WebXR.ControllerAxes.y axes })
    |> Option.value ~default:{ x = 0.; y = 0. }
end

module HandController = struct
  type t = {
    position : Vector3.t;
    rotation : Quaternion.t;
    trigger : Button.t;
    squeeze : Button.t;
    button1 : Button.t;
    button2 : Button.t;
    thumbstick : Thumbstick.t;
  }

  let fromXR ~transform (button1Name : string) (button2Name : string)
      (controller : WebXR.Controller.t) =
    let pointer = WebXR.Controller.pointer controller in
    let position =
      pointer |> Node.getPosition |> Vector3.clone
      |> Matrix.transformCoordinates transform
    in
    let rotation = pointer |> Node.rotationQuat |> Quaternion.clone in
    let trigger = Button.fromXR "xr-standard-trigger" controller in
    let squeeze = Button.fromXR "xr-standard-squeeze" controller in
    let button1 = Button.fromXR button1Name controller in
    let button2 = Button.fromXR button2Name controller in
    let thumbstick = Thumbstick.fromXR "xr-standard-thumbstick" controller in
    { position; rotation; trigger; squeeze; thumbstick; button1; button2 }

  let position { position; _ } = position
  let rotation { rotation; _ } = rotation
  let trigger { trigger; _ } = trigger
  let squeeze { squeeze; _ } = squeeze
  let button1 { button1; _ } = button1
  let button2 { button2; _ } = button2
  let thumbstick { thumbstick; _ } = thumbstick
end

module State = struct
  type t = {
    camera : CameraController.t;
    leftHand : HandController.t option;
    rightHand : HandController.t option;
  }

  let default =
    {
      camera =
        (let open CameraController in
        {
          position = Vector3.zero ();
          rotation = Quaternion.zero ();
          realWorldHeight = 1.6;
        });
      leftHand = None;
      rightHand = None;
    }

  let camera { camera; _ } = camera
  let leftHand { leftHand; _ } = leftHand
  let rightHand { rightHand; _ } = rightHand
end

let handedness (controller : WebXR.Controller.t) =
  controller |> WebXR.Controller.motionController
  |> Option.map WebXR.MotionController.handedness
  |> Option.value ~default:WebXR.Handedness.None

let fromXR ~transform experience =
  let open State in
  let controllers =
    experience |> WebXR.DefaultExperience.input |> WebXR.Input.controllers
  in
  let leftHandControllers =
    controllers |> Array.to_list
    |> List.filter (fun c -> handedness c = WebXR.Handedness.Left)
  in
  let rightHandControllers =
    controllers |> Array.to_list
    |> List.filter (fun c -> handedness c = WebXR.Handedness.Right)
  in
  let leftHand =
    leftHandControllers |> fun l ->
    List.nth_opt l 0
    |> Option.map (HandController.fromXR ~transform "x-button" "y-button")
  in
  let rightHand =
    rightHandControllers |> fun l ->
    List.nth_opt l 0
    |> Option.map (HandController.fromXR ~transform "a-button" "b-button")
  in
  let camera =
    experience |> WebXR.DefaultExperience.baseExperience
    |> WebXR.ExperienceHelper.camera
    |> CameraController.ofCamera ~isInXR:true ~transform
  in
  { camera; leftHand; rightHand }

type keyboardInputState = {
  isForwardPressed : bool;
  isBackwardPressed : bool;
  isLeftArrowPressed : bool;
  isRightArrowPressed : bool;
  isLeftBracketPressed : bool;
  isRightBracketPressed : bool;
  isSpacePressed : bool;
  isXPressed : bool;
  isZPressed : bool;
}

let globalKeyboardState =
  ref
    {
      isForwardPressed = false;
      isBackwardPressed = false;
      isLeftArrowPressed = false;
      isRightArrowPressed = false;
      isLeftBracketPressed = false;
      isRightBracketPressed = false;
      isXPressed = false;
      isZPressed = false;
      isSpacePressed = false;
    }

let initializeDomHandlers () =
  let open Js_of_ocaml in
  let module Html = Js_of_ocaml.Dom_html in
  let doc = Html.window##.document in
  let body = doc##.body in
  let _ =
    Html.addEventListener body Html.Event.mousedown
      (Html.handler (fun e ->
           Js.Optdef.iter e##.which (fun which ->
               Firebug.console##log "mouse down hit";
               match which with
               | Html.Left_button -> Firebug.console##log "left pressed"
               | Html.Right_button -> Firebug.console##log "right pressed"
               | _ ->
                   Firebug.console##log
                     ("Some other mouse button pressed"
                     [@reason.raw_literal "Some other mouse button pressed"]));
           Js._true))
      (Js.bool false)
  in
  body##.onkeydown :=
    Html.handler (fun e ->
        let _ =
          match e##.keyCode with
          | 32 ->
              globalKeyboardState :=
                { !globalKeyboardState with isSpacePressed = true }
          | 37 ->
              globalKeyboardState :=
                { !globalKeyboardState with isLeftArrowPressed = true }
          | 38 ->
              globalKeyboardState :=
                { !globalKeyboardState with isForwardPressed = true }
          | 39 ->
              globalKeyboardState :=
                { !globalKeyboardState with isRightArrowPressed = true }
          | 40 ->
              globalKeyboardState :=
                { !globalKeyboardState with isBackwardPressed = true }
          | 88 ->
              globalKeyboardState :=
                { !globalKeyboardState with isXPressed = true }
          | 90 ->
              globalKeyboardState :=
                { !globalKeyboardState with isZPressed = true }
          | 219 ->
              globalKeyboardState :=
                { !globalKeyboardState with isLeftBracketPressed = true }
          | 221 ->
              globalKeyboardState :=
                { !globalKeyboardState with isRightBracketPressed = true }
          | _ ->
              Firebug.console##log
                ("Some other key pressed: " ^ string_of_int e##.keyCode)
        in
        Js._true);
  body##.onkeyup :=
    Html.handler (fun e ->
        let _ =
          match e##.keyCode with
          | 32 ->
              globalKeyboardState :=
                { !globalKeyboardState with isSpacePressed = false }
          | 38 ->
              globalKeyboardState :=
                { !globalKeyboardState with isForwardPressed = false }
          | 37 ->
              globalKeyboardState :=
                { !globalKeyboardState with isLeftArrowPressed = false }
          | 39 ->
              globalKeyboardState :=
                { !globalKeyboardState with isRightArrowPressed = false }
          | 40 ->
              globalKeyboardState :=
                { !globalKeyboardState with isBackwardPressed = false }
          | 88 ->
              globalKeyboardState :=
                { !globalKeyboardState with isXPressed = false }
          | 90 ->
              globalKeyboardState :=
                { !globalKeyboardState with isZPressed = false }
          | 219 ->
              globalKeyboardState :=
                { !globalKeyboardState with isLeftBracketPressed = false }
          | 221 ->
              globalKeyboardState :=
                { !globalKeyboardState with isRightBracketPressed = false }
          | _ -> Firebug.console##log "Some other key pressed"
        in
        Js._true)

let fromMock ~transform cam =
  let camera = CameraController.ofCamera ~isInXR:false ~transform cam in
  let lHandOffset = Vector3.create ~x:(-0.3) ~y:(-0.25) ~z:0.5 in
  let rHandOffset = Vector3.create ~x:0.3 ~y:(-0.25) ~z:0.5 in
  let justYRot =
    camera.rotation |> Quaternion.toEulerAngles |> Vector3.y
    |> Quaternion.rotateAxis ~axis:(Vector3.up 1.0)
  in
  let rHandPosition =
    justYRot
    |> Quaternion.rotateVector rHandOffset
    |> Vector3.add camera.position
  in
  let lHandPosition =
    justYRot
    |> Quaternion.rotateVector lHandOffset
    |> Vector3.add camera.position
  in
  let keyState = !globalKeyboardState in
  let thumbstickY =
    (match keyState.isForwardPressed with true -> -1.0 | false -> 0.0)
    +. match keyState.isBackwardPressed with true -> 1.0 | false -> 0.0
  in
  let thumbstickX =
    (match keyState.isLeftArrowPressed with true -> -1.0 | false -> 0.0)
    +. match keyState.isRightArrowPressed with true -> 1.0 | false -> 0.0
  in
  let rHand =
    let open HandController in
    {
      position = rHandPosition;
      rotation = camera.rotation;
      button1 = Button.ofBool !globalKeyboardState.isLeftBracketPressed;
      button2 = Button.ofBool !globalKeyboardState.isRightBracketPressed;
      trigger = Button.ofBool !globalKeyboardState.isSpacePressed;
      squeeze = Button.ofBool !globalKeyboardState.isXPressed;
      thumbstick =
        (let open Thumbstick in
        { x = thumbstickX; y = thumbstickY });
    }
  in
  let lHand =
    let open HandController in
    {
      position = lHandPosition;
      rotation = camera.rotation;
      button1 = Button.ofBool !globalKeyboardState.isLeftBracketPressed;
      button2 = Button.ofBool !globalKeyboardState.isRightBracketPressed;
      trigger = Button.ofBool !globalKeyboardState.isSpacePressed;
      squeeze = Button.ofBool !globalKeyboardState.isZPressed;
      thumbstick =
        (let open Thumbstick in
        { x = 0.; y = 0. });
    }  in
  let open State in
  {
    camera = CameraController.ofCamera ~isInXR:false ~transform cam;
    leftHand = Some lHand;
    rightHand = Some rHand;
  }
