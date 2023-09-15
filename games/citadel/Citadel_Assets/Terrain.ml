let material = Mesh.Material.standard ~diffuseTexture:"assets/ground.jpeg" ()

let makePrimitive () =
  let open Babylon in
  let width = 32 in
  let height = 32 in
  let size = 4.0 in
  let vertices = Array.make (width * height * 3) 0. in
  let uvs = Array.make (width * height * 2) 0. in
  let indices = Array.make (width * height * 6) 0 in
  for z = 0 to height - 1 do
    for x = 0 to width - 1 do
      let i = x + (z * height) in
      vertices.((i * 3) + 0) <- float x *. size;
      vertices.((i * 3) + 1) <- Float.sin (float (x + z) /. 10.) *. 5.;
      vertices.((i * 3) + 2) <- float z *. size;
      uvs.((i * 2) + 0) <- float x *. size;
      uvs.((i * 2) + 1) <- float z *. size
    done
  done;
  let triIndex = ref 0 in
  for z = 0 to height - 2 do
    for x = 0 to width - 2 do
      let tri = !triIndex in
      let v0 = x + (z * height) in
      let v1 = x + ((z + 1) * height) in
      let v2 = x + 1 + (z * height) in
      let v3 = x + 1 + ((z + 1) * height) in
      indices.(tri + 0) <- v0;
      indices.(tri + 1) <- v2;
      indices.(tri + 2) <- v1;
      indices.(tri + 3) <- v2;
      indices.(tri + 4) <- v3;
      indices.(tri + 5) <- v1;
      triIndex := !triIndex + 6
    done
  done;
  let mesh = Mesh.custom ~name:"test" in
  let vertexData = VertexData.create () in
  VertexData.setPositions ~positions:vertices vertexData;
  VertexData.setUVs ~uvs vertexData;
  VertexData.setIndices ~indices vertexData;
  VertexData.applyToMesh ~mesh vertexData;
  mesh

let mesh =
  Mesh.mesh ~friendlyId:"Terrain"
    ~postProcess:
      (Mesh.MeshProcessor.chain [ Mesh.MeshProcessor.remapMaterial material ])
    (Mesh.Loader.fromPrimitive makePrimitive)