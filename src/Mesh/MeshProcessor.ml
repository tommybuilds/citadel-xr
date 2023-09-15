module Node = Babylon.Node
type t = Babylon.abstract Babylon.node -> unit
let none _node = ()
let chain (processors : t list) (node : Babylon.abstract Babylon.node) =
  processors |> (List.iter (fun f -> f node))
let traverseMeshes f node =
  let rec traverse node =
    let meshChildren = Node.getChildMeshes node in
    Array.iter f meshChildren;
    (let allChildren = (Node.getChildren node) |> (Array.map Node.abstract) in
     Array.iter traverse allChildren) in
  traverse node;
  (match Node.toMesh node with | None -> () | Some mesh -> f mesh)
let rec traverseNodes f node =
  let allChildren = (Node.getChildren node) |> (Array.map Node.abstract) in
  Array.iter (traverseNodes f) allChildren; Array.iter f allChildren
let remapMaterial (material : Material.t)
  (node : Babylon.abstract Babylon.node) =
  let materialInstance = Material.createMaterial material in
  let f node = Babylon.Mesh.setMaterial ~material:materialInstance node in
  traverseMeshes f node;
  (match Babylon.Node.toMesh node with
   | None -> ()
   | Some mesh -> Babylon.Mesh.setMaterial ~material:materialInstance mesh)
let extractMeshes (meshNames : string list)
  (node : Babylon.abstract Babylon.node) =
  let shouldMeshBePreserved str =
    meshNames |> (List.exists (String.equal str)) in
  traverseMeshes
    (fun mesh ->
       let meshName = mesh |> Babylon.Node.name in
       if not (shouldMeshBePreserved meshName) then Babylon.Node.dispose mesh)
    node
let rotate rotation node =
  let originalRotation = Babylon.Node.rotationQuat node in
  let newRotation = Babylon.Quaternion.multiply rotation originalRotation in
  Babylon.Node.setRotationQuat ~quaternion:newRotation node
let translate translation node =
  let position = Babylon.Node.getPosition node in
  let newPosition = Babylon.Vector3.add position translation in
  Babylon.Node.setPosition ~position:newPosition node
let rotateAxis axis amount =
  let quat = Babylon.Quaternion.rotateAxis ~axis amount in rotate quat
let scale scaleVector node =
  let originalScale = Babylon.Node.scaling node in
  let newScaleVector = Babylon.Vector3.multiply scaleVector originalScale in
  Babylon.Node.setScaling ~scale:newScaleVector node
let scalef scaleFactor node =
  let originalScale = Babylon.Node.scaling node in
  let newScaleVector = Babylon.Vector3.scale scaleFactor originalScale in
  Babylon.Node.setScaling ~scale:newScaleVector node
let setVisibility (visibility : float) node =
  let f node = Babylon.Mesh.setVisibility visibility node in
  traverseMeshes f node