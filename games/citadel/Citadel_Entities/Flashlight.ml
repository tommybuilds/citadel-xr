let flashLightMesh = Citadel_Assets.Flashlight.target

type model = { isTriggerReleased : bool; isFlashlightOn : bool }

let size = 0.1
let shape = System_Physics.Shape.box ~width:size ~height:size ~depth:size ()

let render model =
  let open React3d in
  let light =
    if model.isFlashlightOn then P.transform [ P.pointLight []; P.spotLight [] ]
    else P.transform []
  in
  P.transform ~position:(Vector3.zero ()) [ P.mesh flashLightMesh; light ]

let think ~deltaTime ~grabState model =
  let isTriggerPressed =
    System_Grabbable.GrabState.isTriggerPressed grabState
  in
  let isFlashlightOn =
    if isTriggerPressed && model.isTriggerReleased then not model.isFlashlightOn
    else model.isFlashlightOn
  in
  { isTriggerReleased = not isTriggerPressed; isFlashlightOn }

let entity position =
  BaseGrabbable.entity ~think ~mass:100. ~position ~physicsShape:shape render
    { isTriggerReleased = true; isFlashlightOn = false }