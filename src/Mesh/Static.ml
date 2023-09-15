open Definition
type t = {
  loader: unit -> Babylon.abstract Babylon.node Promise.t }
let static ?(position= Vector3.zero ())  ?(rotation= Quaternion.identity ()) 
  ?(scale= Vector3.one)  (mesh : ('args, 'node, 'state) Definition.t) =
  let loader () =
    let promise = mesh.loader () in
    (promise |> (Promise.map snd)) |>
      (Promise.map
         (fun node ->
            let node = Babylon.Node.abstract node in
            let () =
              node |>
                (MeshProcessor.chain
                   [MeshProcessor.translate position;
                   MeshProcessor.rotate rotation;
                   MeshProcessor.scale scale]) in
            let matrix = Babylon.Node.computeWorldMatrix node in
            let () =
              node |>
                (MeshProcessor.traverseMeshes
                   (fun m ->
                      m |> (Babylon.Mesh.bakeTransformIntoVertices matrix);
                      m |> Babylon.Mesh.refreshBoundingInfo)) in
            let () =
              node |>
                (MeshProcessor.traverseNodes
                   (fun node ->
                      Babylon.Node.setPosition
                        ~position:(Babylon.Vector3.zero ()) node;
                      Babylon.Node.setScaling ~scale:Babylon.Vector3.one node;
                      Babylon.Node.setRotationQuat
                        ~quaternion:(Babylon.Quaternion.identity ()) node)) in
            Node.setPosition ~position:(Vector3.zero ()) node;
            Node.setRotationQuat ~quaternion:(Quaternion.identity ()) node;
            Node.setScaling ~scale:Vector3.one node;
            node)) in
  { loader }
let load { loader } = loader ()