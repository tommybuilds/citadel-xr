open TestFramework[@@ocaml.doc " Simple test cases "]
open Babylon
let engine = Babylon.Engine.null ()
;;describe "Matrix"
    (fun { describe;_} ->
       describe "compose / decompose"
         (fun { test;_} ->
            test "quaternion passes through"
              (fun { expect;_} ->
                 let quat = Quaternion.create ~x:1.0 ~y:2.0 ~z:3.0 ~w:4.0 in
                 let matrix =
                   Matrix.compose ~scale:Vector3.one ~rotation:quat
                     ~translation:(Vector3.zero ()) in
                 let Matrix.{ rotation;_}  = Matrix.decompose matrix in
                 (expect.bool (Quaternion.equals quat rotation)).toBeTrue ());
            test "scale passes through"
              (fun { expect;_} ->
                 let scaleIn = Vector3.create ~x:1.0 ~y:2.0 ~z:3.0 in
                 let matrix =
                   Matrix.compose ~scale:scaleIn
                     ~rotation:(Quaternion.zero ())
                     ~translation:(Vector3.zero ()) in
                 let Matrix.{ scale;_}  = Matrix.decompose matrix in
                 (expect.bool (Vector3.equals scaleIn scale)).toBeTrue ());
            test "translate passes through"
              (fun { expect;_} ->
                 let translateIn = Vector3.create ~x:1.0 ~y:2.0 ~z:3.0 in
                 let matrix =
                   Matrix.compose ~scale:Vector3.one
                     ~rotation:(Quaternion.zero ()) ~translation:translateIn in
                 let Matrix.{ translation;_}  = Matrix.decompose matrix in
                 (expect.bool (Vector3.equals translation translateIn)).toBeTrue
                   ());
            test "multiply smoke test: add transforms"
              (fun { expect;_} ->
                 let translateIn = Vector3.create ~x:1.0 ~y:2.0 ~z:3.0 in
                 let matrix =
                   Matrix.compose ~scale:Vector3.one
                     ~rotation:(Quaternion.zero ()) ~translation:translateIn in
                 let matrix2 =
                   Matrix.compose ~scale:Vector3.one
                     ~rotation:(Quaternion.zero ()) ~translation:translateIn in
                 let matrix3 = Matrix.multiply matrix matrix2 in
                 let expectedOutput = Vector3.create ~x:2.0 ~y:4.0 ~z:6.0 in
                 let Matrix.{ translation;_}  = Matrix.decompose matrix3 in
                 (expect.bool (Vector3.equals translation expectedOutput)).toBeTrue
                   ())))
;;describe "Quaternion"
    (fun { describe;_} ->
       describe "lookAt"
         (fun { test;_} ->
            test "basic case"
              (fun { expect;_} ->
                 let forward = Vector3.up 1.0 in
                 let up = Vector3.right 1.0 in
                 let quat = Quaternion.lookAt ~forward ~up in
                 let xVec =
                   Quaternion.rotateVector (Vector3.forward (-1.0)) quat in
                 let x = xVec |> Vector3.x in
                 let y = xVec |> Vector3.y in
                 let z = xVec |> Vector3.z in
                 (expect.float x).toBeCloseTo 0.0;
                 (expect.float y).toBeCloseTo 1.0;
                 (expect.float z).toBeCloseTo 0.0)))
;;describe "QuaternionEx"
    (fun { describe;_} ->
       describe "lookAt"
         (fun { test;_} ->
            test "base case - forward is forward"
              (fun { expect;_} ->
                 let forward = Vector3.forward 1.0 in
                 let quat = QuaternionEx.lookAt forward in
                 let xVec =
                   Quaternion.rotateVector (Vector3.forward (-1.0)) quat in
                 let x = xVec |> Vector3.x in
                 let y = xVec |> Vector3.y in
                 let z = xVec |> Vector3.z in
                 (expect.float x).toBeCloseTo 0.0;
                 (expect.float y).toBeCloseTo 0.0;
                 (expect.float z).toBeCloseTo 1.0);
            test "corner case - forward is up"
              (fun { expect;_} ->
                 let forward = Vector3.up 1.0 in
                 let quat = QuaternionEx.lookAt forward in
                 let xVec =
                   Quaternion.rotateVector (Vector3.forward (-1.0)) quat in
                 let x = xVec |> Vector3.x in
                 let y = xVec |> Vector3.y in
                 let z = xVec |> Vector3.z in
                 (expect.float x).toBeCloseTo 0.0;
                 (expect.float y).toBeCloseTo 1.0;
                 (expect.float z).toBeCloseTo 0.0)))
;;describe "Vector3"
    (fun { test; describe;_} ->
       describe "cross"
         (fun { test;_} ->
            test "basic cross product"
              (fun { expect;_} ->
                 let forward = Vector3.forward (-1.0) in
                 let up = Vector3.up 1.0 in
                 let cross = Vector3.cross forward up in
                 let x = cross |> Vector3.x in
                 let y = cross |> Vector3.y in
                 let z = cross |> Vector3.z in
                 (expect.float x).toBeCloseTo 1.0;
                 (expect.float y).toBeCloseTo 0.0;
                 (expect.float z).toBeCloseTo 0.0));
       describe "dot"
         (fun { test;_} ->
            test "same vector"
              (fun { expect;_} ->
                 let up = Vector3.up 1.0 in
                 let dot = Vector3.dot up up in
                 (expect.float dot).toBeCloseTo 1.0);
            test "orthogonal vector"
              (fun { expect;_} ->
                 let up = Vector3.up 1.0 in
                 let forward = Vector3.forward 1.0 in
                 let dot = Vector3.dot forward up in
                 (expect.float dot).toBeCloseTo 0.0));
       describe "scale"
         (fun { test;_} ->
            test "simple case"
              (fun { expect;_} ->
                 let vec = Vector3.create ~x:1.0 ~y:2.0 ~z:3.0 in
                 let scaledVec = Vector3.scale 2.0 vec in
                 let x = scaledVec |> Vector3.x in
                 let y = scaledVec |> Vector3.y in
                 let z = scaledVec |> Vector3.z in
                 (expect.float x).toBeCloseTo 2.0;
                 (expect.float y).toBeCloseTo 4.0;
                 (expect.float z).toBeCloseTo 6.0));
       describe "equals"
         (fun { test;_} ->
            test "same instance - equals is true"
              (fun { expect;_} ->
                 let vec = Vector3.up 1.0 in
                 (expect.bool (Vector3.equals vec vec)).toBeTrue ());
            test "same instance - same value, still true"
              (fun { expect;_} ->
                 let vec = Vector3.up 1.0 in
                 let vec2 = Vector3.up 1.0 in
                 (expect.bool (Vector3.equals vec vec2)).toBeTrue ());
            test "same instance - different value, false"
              (fun { expect;_} ->
                 let vec = Vector3.up 1.0 in
                 let vec2 = Vector3.up 2.0 in
                 (expect.bool (Vector3.equals vec vec2)).toBeFalse ()));
       test "up sets y value"
         (fun { expect;_} ->
            let vec = Vector3.up 1.0 in
            let x = vec |> Vector3.x in
            let y = vec |> Vector3.y in
            let z = vec |> Vector3.z in
            (expect.float x).toBeCloseTo 0.0;
            (expect.float y).toBeCloseTo 1.0;
            (expect.float z).toBeCloseTo 0.0);
       describe "add"
         (fun { test;_} ->
            test "simple case"
              (fun { expect;_} ->
                 let vec1 = Vector3.create ~x:0.1 ~y:0.5 ~z:0.9 in
                 let vec2 = Vector3.create ~x:1.0 ~y:2.0 ~z:3.0 in
                 let vec = Vector3.add vec1 vec2 in
                 let x = vec |> Vector3.x in
                 let y = vec |> Vector3.y in
                 let z = vec |> Vector3.z in
                 (expect.float x).toBeCloseTo 1.1;
                 (expect.float y).toBeCloseTo 2.5;
                 (expect.float z).toBeCloseTo 3.9));
       describe "subtract"
         (fun { test;_} ->
            test "simple case"
              (fun { expect;_} ->
                 let vec1 = Vector3.create ~x:0.1 ~y:0.5 ~z:0.9 in
                 let vec2 = Vector3.create ~x:1.0 ~y:2.0 ~z:3.0 in
                 let vec = Vector3.subtract vec1 vec2 in
                 let x = vec |> Vector3.x in
                 let y = vec |> Vector3.y in
                 let z = vec |> Vector3.z in
                 (expect.float x).toBeCloseTo (-0.9);
                 (expect.float y).toBeCloseTo (-1.5);
                 (expect.float z).toBeCloseTo (-2.1)));
       describe "length"
         (fun { test;_} ->
            test "simple case"
              (fun { expect;_} ->
                 let vec1 = Vector3.create ~x:1. ~y:2. ~z:3. in
                 let len = Vector3.length vec1 in
                 (expect.float len).toBeCloseTo 3.741657));
       describe "lengthSquared"
         (fun { test;_} ->
            test "simple case"
              (fun { expect;_} ->
                 let vec1 = Vector3.create ~x:1. ~y:2. ~z:3. in
                 let len = Vector3.lengthSquared vec1 in
                 (expect.float len).toBeCloseTo 14.)))
;;describe "Mesh"
    (fun { describe;_} ->
       describe "visibility"
         (fun { test;_} ->
            test "get / set"
              (fun { expect;_} ->
                 let scene = Babylon.Scene.create engine in
                 let node = Node.createTransform ~name:"test123" in
                 (expect.string (Node.name node)).toEqual "test123";
                 Node.setName "anotherName" node;
                 (expect.string (Node.name node)).toEqual "anotherName";
                 Scene.dispose scene)))
;;describe "MeshBuilder"
    (fun { test;_} ->
       test "CreatePlane"
         (fun _ ->
            let plane = Babylon.MeshBuilder.Plane.create () in
            Babylon.Node.dispose plane);
       test "CreateGround"
         (fun _ ->
            let ground = Babylon.MeshBuilder.Ground.create () in
            Babylon.Node.dispose ground);
       test "CreateSphere"
         (fun _ ->
            let sphere =
              Babylon.MeshBuilder.Sphere.create ~name:"test"
                ~options:(let open Babylon.MeshBuilder.Sphere in
                            { diameter = 1.0 }) in
            Babylon.Node.dispose sphere);
       test "CreateCylinder"
         (fun _ ->
            let cylinder = Babylon.MeshBuilder.Cylinder.create () in
            Babylon.Node.dispose cylinder);
       test "CreateBox"
         (fun _ ->
            let box = Babylon.MeshBuilder.Box.create () in
            Babylon.Node.dispose box))
;;describe "Node"
    (fun { test; describe;_} ->
       describe "isMesh"
         (fun { test;_} ->
            test "isMesh returns false for transform"
              (fun { expect;_} ->
                 let _ = Babylon.Scene.create engine in
                 let node = Babylon.Node.createTransform ~name:"test" in
                 (expect.bool (Babylon.Node.isMesh node)).toBeFalse ());
            test "isMesh returns true for mesh"
              (fun { expect;_} ->
                 let _ = Babylon.Scene.create engine in
                 let box = Babylon.MeshBuilder.Box.create () in
                 (expect.bool (Babylon.Node.isMesh box)).toBeTrue ()));
       describe "name"
         (fun { test;_} ->
            test "get / set"
              (fun { expect;_} ->
                 let scene = Babylon.Scene.create engine in
                 let mesh = Mesh.custom ~name:"mesh1" in
                 (expect.float (mesh |> Mesh.visibility)).toBeCloseTo 1.0;
                 Mesh.setVisibility 0.5 mesh;
                 (expect.float (mesh |> Mesh.visibility)).toBeCloseTo 0.5;
                 Scene.dispose scene));
       test "can create transform node"
         (fun { expect;_} ->
            let scene = Babylon.Scene.create engine in
            let _node = Node.createTransform ~name:"test" in
            Scene.dispose scene);
       test "can iterate children"
         (fun { expect;_} ->
            let scene = Babylon.Scene.create engine in
            let node = Node.createTransform ~name:"test" in
            let node1 = Node.createTransform ~name:"child1" in
            let node2 = Node.createTransform ~name:"child2" in
            let subNode3 = Node.createTransform ~name:"child3" in
            Node.setParent ~parent:node node1;
            Node.setParent ~parent:node node2;
            Node.setParent ~parent:node1 subNode3;
            (let children = Node.getChildren node in
             (expect.int (Array.length children)).toBe 2;
             (let children = Node.getChildren node1 in
              (expect.int (Array.length children)).toBe 1;
              (let children = Node.getChildren node2 in
               (expect.int (Array.length children)).toBe 0;
               Scene.dispose scene))));
       test "can iterate child meshes"
         (fun { expect;_} ->
            let scene = Babylon.Scene.create engine in
            let node = Node.createTransform ~name:"test" in
            let node1 = Node.createTransform ~name:"child1" in
            let mesh1 = Mesh.custom ~name:"mesh1" in
            let mesh2 = Mesh.custom ~name:"mesh2" in
            let mesh3 = Mesh.custom ~name:"mesh3" in
            Node.setParent ~parent:node node1;
            Node.setParent ~parent:node mesh1;
            Node.setParent ~parent:node mesh2;
            Node.setParent ~parent:mesh1 mesh3;
            (let children = Node.getChildMeshes node in
             (expect.int (Array.length children)).toBe 2;
             (expect.string (Node.name (children.(0)))).toEqual "mesh1";
             (expect.string (Node.name (children.(1)))).toEqual "mesh2";
             Scene.dispose scene)))