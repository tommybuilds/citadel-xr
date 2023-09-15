let glockMaterial =
  React3d.Material.standard ~uScale:1.0 ~vScale:1.0
    ~diffuseTexture:"assets/glock/diffuse.png"
    ~normalTexture:"assets/glock/normal.png"
    ~emissiveTexture:"assets/glock/emissive.png" ()

type args = { clipVisible : bool; slideAmount : float }

let initialArgs = { clipVisible = true; slideAmount = 0.0 }

type state = {
  clipNode : Babylon.mesh Babylon.node;
  slideNode : Babylon.mesh Babylon.node;
  originalSlidePosition : Babylon.Vector3.t;
  fullSlidePosition : Babylon.Vector3.t;
}

let initialState
    ({ rootNode = node; _ } : Babylon.transform Mesh.Loader.LoadResult.t) =
  let clipMeshes = Babylon.Node.getMeshesByName "WPN_Eder22_magazine" node in
  let clipNode = clipMeshes.(0) in
  let slideMeshes = Babylon.Node.getMeshesByName "WPN_Eder22_slide" node in
  let slideNode = slideMeshes.(0) in
  let originalSlidePosition = slideNode |> Babylon.Node.getPosition in
  let fullSlidePosition =
    originalSlidePosition
    |> Babylon.Vector3.add (Babylon.Vector3.forward (-0.02))
  in
  { clipNode; slideNode; originalSlidePosition; fullSlidePosition }

let apply (args : args) (state : state) node =
  Babylon.Node.setEnabled ~enabled:args.clipVisible state.clipNode;
  let slidePosition =
    Babylon.Vector3.lerp ~start:state.originalSlidePosition
      ~stop:state.fullSlidePosition args.slideAmount
  in
  Babylon.Node.setPosition ~position:slidePosition state.slideNode;
  state

let editor =
  Editor.widgets
    [
      Editor.Widget.checkbox ~label:"Clip Visible" (fun checked state ->
          { state with clipVisible = checked });
      Editor.Widget.slider ~label:"Slide Amount" ~min:0.0 ~max:1.0
        (fun amt state -> { state with slideAmount = amt });
    ]

let glock =
  Mesh.dynamic ~apply ~editor ~initialArgs ~initialState
    ~postProcess:(Mesh.MeshProcessor.remapMaterial glockMaterial)
    (Mesh.Loader.fromFile "assets/glock/glock.glb")

let glockClip =
  Mesh.dynamic ~apply ~editor ~friendlyId:"glock-clip" ~initialArgs
    ~initialState
    ~postProcess:
      (Mesh.MeshProcessor.chain
         [
           Mesh.MeshProcessor.remapMaterial glockMaterial;
           Mesh.MeshProcessor.extractMeshes
             [ "cal_40"; "cal_40.001"; "WPN_Eder22_magazine" ];
         ])
    (Mesh.Loader.fromFile "assets/glock/glock.glb")