type args = { clipVisible : bool; selectorRotation : float }

type state = {
  clipNode : Babylon.mesh Babylon.node;
  selectorNode : Babylon.mesh Babylon.node;
}

let initialState
    ({ rootNode = node; _ } : Babylon.transform Mesh.Loader.LoadResult.t) =
  let clipMeshes = Babylon.Node.getMeshesByName "mg-ammo-clips" node in
  let clipMesh = clipMeshes.(0) in
  let selectorMeshes = Babylon.Node.getMeshesByName "mg-switch" node in
  let selectorNode = selectorMeshes.(0) in
  { clipNode = clipMesh; selectorNode }

let initialArgs = { clipVisible = false; selectorRotation = 0. }

let apply (args : args) (state : state) node =
  Babylon.Node.setEnabled ~enabled:args.clipVisible state.clipNode;
  Babylon.Node.setRotation
    ~rotation:(Babylon.Vector3.create ~x:args.selectorRotation ~y:0.0 ~z:0.0)
    state.selectorNode;
  state

let editor =
  Editor.widgets
    [
      Editor.Widget.checkbox ~label:"Clip Visible" (fun checked state ->
          { state with clipVisible = checked });
      Editor.Widget.slider ~min:0. ~max:4. ~label:"Selector Rotation"
        (fun amt state -> { state with selectorRotation = amt });
    ]

let mesh =
  Mesh.dynamic ~editor ~initialArgs ~initialState ~apply
    (Mesh.Loader.fromFile "assets/mg/machine-gun_mesh.gltf")