open Babylon

let run scene =
  let plane =
    MeshBuilder.Plane.create ~name:"Sphere test"
      ~options:
        (let open MeshBuilder.Plane in
        { width = 0.5; height = 0.5 })
      ()
  in
  Node.setPosition ~position:(Vector3.forward 10.0) plane;
  let texture =
    Babylon.Texture.dynamic ~name:"Test1" ~width:128 ~height:128 ()
  in
  let material = Babylon.Material.standard ~name:"Test" in
  Babylon.Material.setDiffuseTexture ~texture material;
  Babylon.Mesh.setMaterial ~material plane
