module MeshBuilder = Babylon.MeshBuilder
module Node = Babylon.Node
module Quaternion = Babylon.Quaternion
module Vector3 = Babylon.Vector3
open Definition
type sphereArgs = {
  material: Material.t ;
  diameter: float }
type sphereState = {
  lastMaterial: Material.t option }
let applyArgs sphereArgs lastState node =
  let { diameter; material } = sphereArgs in
  let scale = Vector3.create ~x:diameter ~y:diameter ~z:diameter in
  let material' =
    match lastState.lastMaterial with
    | None ->
        let materialInstance = Material.createMaterial material in
        (Babylon.Mesh.setMaterial ~material:materialInstance node;
         Some material)
    | Some _ as mat -> mat in
  Node.setScaling ~scale node; { lastMaterial = material' }
let loader () =
  let state = { lastMaterial = None } in
  let sphere =
    MeshBuilder.Sphere.create ~name:"Sphere1"
      ~options:(let open MeshBuilder.Sphere in { diameter = 1.0 }) in
  Babylon.Node.setEnabled ~enabled:false sphere;
  Promise.resolve (state, sphere)
let sphere = simple applyArgs loader "sphere"