module Js = Js_of_ocaml.Js
module Html = Js_of_ocaml.Dom_html
module S = Scene
open Babylon

let start initialScene =
  let doc = Html.window##.document in
  let body = doc##.body in
  let canvas = Html.createCanvas doc in
  canvas##.style##.width := Js.string "100%";
  canvas##.style##.height := Js.string "100%";
  canvas##.id := Js.string "render-canvas";
  Js_of_ocaml.Dom.appendChild body canvas;
  Input.initializeDomHandlers ();
  let engine = Engine.create canvas in
  let scene = Scene.create engine in
  S.Global.init ();
  let rootNode = Node.createTransform ~name:"React3d" in
  let debugNode = Node.createTransform ~name:"__debug__" in
  Node.setParent ~parent:rootNode debugNode;
  let staticGeometry = S.Global.switchScene initialScene in
  Babylon.Node.setParent ~parent:rootNode staticGeometry;
  Html.window##.onhashchange :=
    Html.handler (fun (evt : Html.hashChangeEvent Js.t) ->
        let oldURL = Js.to_string evt##.oldURL in
        let newURL = Js.to_string evt##.newURL in
        let hash = Js.to_string Html.window##.location##.hash in
        let hash = String.sub hash 1 (String.length hash - 1) in
        let rootNode = S.Global.switchSceneById hash in
        Babylon.Node.setParent ~parent:rootNode staticGeometry;
        Console.log ("old: " ^ oldURL);
        Console.log ("new: " ^ newURL);
        Console.log ("hash: " ^ hash);
        Js._true);
  let hash = Js.to_string Html.window##.location##.hash in
  (if String.length hash > 1 then
   let hash = String.sub hash 1 (String.length hash - 1) in
   let rootNode = S.Global.switchSceneById hash in
   Babylon.Node.setParent ~parent:rootNode staticGeometry);
  Scene.setAmbientColor ~color:(Color.make ~r:0.1 ~g:0.1 ~b:0.1) scene;
  Scene.setClearColor ~color:(Color.make ~r:0.0 ~g:0.0 ~b:0.0) scene;
  let _dispose =
    engine |> Engine.runRenderLoop (fun () -> Scene.render scene)
  in
  let arcCamera =
    Babylon.Camera.arcRotate ~name:"ArcRotate" ~target:(Vector3.zero ()) scene
  in
  let camera =
    Babylon.Camera.free ~name:"Camera"
      ~position:(Babylon.Vector3.create ~x:0. ~y:0. ~z:0.)
      scene
  in
  Camera.setTarget ~target:(Vector3.create ~x:0. ~y:0.0 ~z:(-1.0)) camera;
  Scene.setActiveCamera ~camera scene;
  Camera.attachControl ~canvas ~attached:false arcCamera;
  Camera.attachControl ~canvas ~attached:true camera;
  Experiments.run scene;
  let glowLayer = GlowLayer.create scene in
  GlowLayer.setIntensity ~intensity:0.0 glowLayer;
  let container = React3d.createContainer (Node rootNode) in
  let promise = WebXR.createDefaultXRExperienceAsync scene in
  let previousUseArcCamera = ref false in
  let defaultCamera =
    System_Camera.free
      ~position:(Babylon.Vector3.create ~x:0. ~y:1. ~z:(-3.))
      ~rotation:(Babylon.Quaternion.initial ())
      ()
  in
  let getCamera =
    (fun scene ->
       let cameras =
         scene |> S.entityManager |> EntityManager.values System_Camera.camera
       in
       List.nth_opt cameras 0 |> Option.value ~default:defaultCamera
      : S.t -> System_Camera.camera)
  in
  let lastCamera = ref defaultCamera in
  let _ =
    Promise.then_
      ~fulfilled:(fun (defaultExperience : WebXR.DefaultExperience.t) ->
        let isInXR =
          defaultExperience |> WebXR.DefaultExperience.baseExperience
          |> WebXR.ExperienceHelper.isInXR
        in
        let () =
          if isInXR then
            defaultExperience |> WebXR.DefaultExperience.baseExperience
            |> WebXR.ExperienceHelper.camera
            |> Camera.setTransformationFromNonVRCamera
                 ~resetToBaseReferenceSpace:false ~sourceCamera:camera
        in
        let (_ : unit -> unit) =
          Scene.registerBeforeRender
            (fun () ->
              let isInXR =
                defaultExperience |> WebXR.DefaultExperience.baseExperience
                |> WebXR.ExperienceHelper.isInXR
              in
              let currentCamera = getCamera !S.Global.activeScene in
              if not (System_Camera.equals currentCamera !lastCamera) then (
                lastCamera := currentCamera;
                let useArcCamera =
                  match currentCamera.cameraType with
                  | System_Camera.Arc -> true
                  | System_Camera.Free -> false
                in
                ();
                if useArcCamera <> !previousUseArcCamera then (
                  print_endline
                    ("Changing camera type"
                    [@reason.raw_literal "Changing camera type"]);
                  if useArcCamera then (
                    let origPosition = Node.getPosition camera in
                    Node.setPosition ~position:origPosition arcCamera;
                    Scene.setActiveCamera ~camera:arcCamera scene;
                    Camera.attachControl ~canvas ~attached:false camera;
                    Camera.attachControl ~canvas ~attached:true arcCamera)
                  else (
                    Node.setPosition ~position:(Vector3.zero ()) camera;
                    Scene.setActiveCamera ~camera scene;
                    Camera.attachControl ~canvas ~attached:false arcCamera;
                    Camera.attachControl ~canvas ~attached:true camera);
                  previousUseArcCamera := useArcCamera));
              System_Camera.persist currentCamera;
              let cameraRotation =
                currentCamera.rotation
                |> Option.value ~default:(Quaternion.identity ())
              in
              let cameraPosition =
                match isInXR with
                | true -> currentCamera.position
                | false -> Vector3.add currentCamera.position (Vector3.up 1.6)
              in
              let cameraTransform =
                Matrix.compose ~scale:Vector3.one ~rotation:cameraRotation
                  ~translation:cameraPosition
              in
              let inverseCameraRotation = cameraRotation |> Quaternion.invert in
              let input =
                if isInXR then
                  Input.fromXR ~transform:cameraTransform defaultExperience
                else Input.fromMock ~transform:cameraTransform camera
              in
              Citadel_Entities.Ambient.update { input };
              let deltaTime = Babylon.Engine.getDeltaTime engine /. 1000. in
              let () = S.tick ~deltaTime !S.Global.activeScene in
              let () = S.runSubscriptions !S.Global.activeScene in
              let () = S.runPendingEffects !S.Global.activeScene in
              let currentCamera = getCamera !S.Global.activeScene in
              Node.setRotationQuat ~quaternion:inverseCameraRotation rootNode;
              Node.setPosition
                ~position:(Vector3.scale (-1.0) cameraPosition)
                rootNode;
              let rendered = S.render !S.Global.activeScene in
              let () = React3d.updateContainer container rendered in
              GlowLayer.setIntensity ~intensity:1.5 glowLayer)
            scene
        in
        Promise.resolve ())
      ~rejected:(fun _err ->
        Console.log "ERROR2";
        Promise.resolve ())
      promise
  in
  ()

module Scene = Scene