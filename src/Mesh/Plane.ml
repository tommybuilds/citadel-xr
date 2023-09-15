module MeshBuilder = Babylon.MeshBuilder
module Node = Babylon.Node
module Quaternion = Babylon.Quaternion
module Vector3 = Babylon.Vector3
open Definition
type args = {
  height: float ;
  width: float ;
  material: Material.t }
type state = Material.Reconciler.t
let applyArgs args lastState node =
  let { material; width; height } = args in
  let state' = Material.Reconciler.reconcile node material lastState in
  let scale = Vector3.create ~x:width ~y:height ~z:1.0 in
  Babylon.Node.setScaling ~scale node; state'
let loader =
  Loader.fromPrimitive ~friendlyName:"Plane"
    (fun () ->
       MeshBuilder.Plane.create
         ~options:(let open MeshBuilder.Plane in
                     { width = 1.0; height = 1.0 }) ~name:"Plane" ())
let plane =
  DynamicMesh.make
    ~initialArgs:{ width = 1.0; height = 1.0; material = Material.wireframe }
    ~initialState:(fun _ -> Material.Reconciler.initial) ~apply:applyArgs
    loader