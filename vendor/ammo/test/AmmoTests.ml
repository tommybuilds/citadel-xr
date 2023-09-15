open TestFramework[@@ocaml.doc " Simple test cases "]
open Babylon
open Ammo
let engine = Babylon.Engine.null ()
;;describe "Ammo"
    (fun { describe;_} ->
       let scene = Babylon.Scene.create engine in
       describe "transform"
         (fun { test;_} ->
            test "position is preserved"
              (fun { expect;_} ->
                 Ammo.init
                   (fun world ->
                      let pos = Vector3.create ~x:1.0 ~y:2.0 ~z:3.0 in
                      let transform =
                        Ammo.Transform.fromPositionRotation
                          ~rotation:(Quaternion.zero ()) ~position:pos world in
                      let position = transform |> Ammo.Transform.origin in
                      (expect.float (position |> Vector3.x)).toBeCloseTo 1.0;
                      (expect.float (position |> Vector3.y)).toBeCloseTo 2.0;
                      (expect.float (position |> Vector3.z)).toBeCloseTo 3.0)));
       describe "shapes"
         (fun { test;_} ->
            test "can create capsule shape"
              (fun { expect;_} ->
                 Ammo.init
                   (fun world ->
                      let plane = Babylon.MeshBuilder.Ground.create () in
                      let transform = Ammo.Transform.identity world in
                      let shape = Ammo.Shape.triangleMesh ~mesh:plane world in
                      let rigidBody =
                        Ammo.RigidBody.create ~id:42
                          ~mass:(Ammo.Mass.ofFloat 0.)
                          ~motionState:(Ammo.MotionState.default ~transform
                                          world) ~shape world in
                      let () = Ammo.addRigidBody ~body:rigidBody world in
                      let position = Babylon.Vector3.up 2. in
                      let rotation = Babylon.Quaternion.initial () in
                      let capsuleTransform =
                        Ammo.Transform.fromPositionRotation ~rotation
                          ~position world in
                      let capsuleShape =
                        Ammo.Shape.capsule ~radius:1.0 ~height:1.0 world in
                      let capsuleBody =
                        Ammo.RigidBody.create ~id:42
                          ~mass:(Ammo.Mass.ofFloat 1.)
                          ~motionState:(Ammo.MotionState.default
                                          ~transform:capsuleTransform world)
                          ~shape:capsuleShape world in
                      let () = Ammo.addRigidBody ~body:capsuleBody world in
                      let () = Ammo.step ~timeStep:10.0 ~maxSteps:1000 world in
                      let position = Ammo.RigidBody.position capsuleBody in
                      (expect.float (position |> Vector3.x)).toBeCloseTo 0.0;
                      (expect.float (position |> Vector3.y)).toBeCloseTo 1.5;
                      (expect.float (position |> Vector3.z)).toBeCloseTo 0.0)));
       describe "rigid body"
         (fun { test;_} ->
            test "rigid body falls with gravity"
              (fun { expect;_} ->
                 Ammo.init
                   (fun world ->
                      let plane = Babylon.MeshBuilder.Ground.create () in
                      let transform = Ammo.Transform.identity world in
                      let shape = Ammo.Shape.triangleMesh ~mesh:plane world in
                      let rigidBody =
                        Ammo.RigidBody.create ~id:42
                          ~mass:(Ammo.Mass.ofFloat 1.)
                          ~motionState:(Ammo.MotionState.default ~transform
                                          world) ~shape world in
                      let () = Ammo.addRigidBody ~body:rigidBody world in
                      let position = Ammo.RigidBody.position rigidBody in
                      (expect.float (position |> Vector3.x)).toBeCloseTo 0.0;
                      (expect.float (position |> Vector3.y)).toBeCloseTo 0.0;
                      (expect.float (position |> Vector3.z)).toBeCloseTo 0.0;
                      (let () = Ammo.step ~timeStep:10.0 ~maxSteps:1000 world in
                       let position = Ammo.RigidBody.position rigidBody in
                       (expect.float (position |> Vector3.x)).toBeCloseTo 0.0;
                       (expect.float (position |> Vector3.y)).toBeCloseTo
                         (-217.32);
                       (expect.float (position |> Vector3.z)).toBeCloseTo 0.0)));
            test "rigid body with no mass does not fall"
              (fun { expect;_} ->
                 Ammo.init
                   (fun world ->
                      let plane = Babylon.MeshBuilder.Ground.create () in
                      let transform = Ammo.Transform.identity world in
                      let shape = Ammo.Shape.triangleMesh ~mesh:plane world in
                      let rigidBody =
                        Ammo.RigidBody.create ~id:42
                          ~mass:(Ammo.Mass.ofFloat 0.)
                          ~motionState:(Ammo.MotionState.default ~transform
                                          world) ~shape world in
                      let () = Ammo.addRigidBody ~body:rigidBody world in
                      let () = Ammo.step ~timeStep:10.0 ~maxSteps:1000 world in
                      let position = Ammo.RigidBody.position rigidBody in
                      (expect.float (position |> Vector3.x)).toBeCloseTo 0.0;
                      (expect.float (position |> Vector3.y)).toBeCloseTo 0.0;
                      (expect.float (position |> Vector3.z)).toBeCloseTo 0.0)));
       describe "shape cast"
         (fun { test;_} ->
            test "shape cast miss returns none"
              (fun { expect;_} ->
                 Ammo.init
                   (fun world ->
                      let shape =
                        Ammo.Shape.box
                          ~dimensions:(Babylon.Vector3.create ~x:1.0 ~y:1.0
                                         ~z:1.0) world in
                      let maybeRayCastResult =
                        Ammo.shapeCast ~shape
                          ~start:(Babylon.Vector3.up 10.0)
                          ~stop:(Babylon.Vector3.up (-10.0)) world in
                      (expect.option maybeRayCastResult).toBeNone ()));
            test "shape cast hits a rigid body"
              (fun { expect;_} ->
                 Ammo.init
                   (fun world ->
                      let plane = Babylon.MeshBuilder.Ground.create () in
                      let transform = Ammo.Transform.identity world in
                      let shape = Ammo.Shape.triangleMesh ~mesh:plane world in
                      let rigidBody =
                        Ammo.RigidBody.create ~id:42
                          ~mass:(Ammo.Mass.ofFloat 0.)
                          ~motionState:(Ammo.MotionState.default ~transform
                                          world) ~shape world in
                      let () = Ammo.addRigidBody ~body:rigidBody world in
                      let () = Ammo.step ~timeStep:10.0 ~maxSteps:1000 world in
                      let shape =
                        Ammo.Shape.box
                          ~dimensions:(Babylon.Vector3.create ~x:1.0 ~y:1.0
                                         ~z:1.0) world in
                      let maybeShapeCastResult =
                        Ammo.shapeCast ~shape
                          ~start:(Babylon.Vector3.up 10.0)
                          ~stop:(Babylon.Vector3.up (-10.0)) world in
                      (expect.option maybeShapeCastResult).toBeSome ();
                      (let rayCastResult = Option.get maybeShapeCastResult in
                       let hitBodyId = rayCastResult |> RayCastResult.bodyId in
                       (expect.int hitBodyId).toBe 43))));
       describe "ray cast"
         (fun { test;_} ->
            test "ray cast miss returns none"
              (fun { expect;_} ->
                 Ammo.init
                   (fun world ->
                      let maybeRayCastResult =
                        Ammo.rayCast ~start:(Babylon.Vector3.up 10.0)
                          ~stop:(Babylon.Vector3.up (-10.0)) world in
                      (expect.option maybeRayCastResult).toBeNone ()));
            test "ray cast hits a rigid body"
              (fun { expect;_} ->
                 Ammo.init
                   (fun world ->
                      let plane = Babylon.MeshBuilder.Ground.create () in
                      let transform = Ammo.Transform.identity world in
                      let shape = Ammo.Shape.triangleMesh ~mesh:plane world in
                      let rigidBody =
                        Ammo.RigidBody.create ~id:42
                          ~mass:(Ammo.Mass.ofFloat 0.)
                          ~motionState:(Ammo.MotionState.default ~transform
                                          world) ~shape world in
                      let () = Ammo.addRigidBody ~body:rigidBody world in
                      let maybeRayCastResult =
                        Ammo.rayCast ~start:(Babylon.Vector3.up 10.0)
                          ~stop:(Babylon.Vector3.up (-10.0)) world in
                      (expect.option maybeRayCastResult).toBeSome ();
                      (let rayCastResult = Option.get maybeRayCastResult in
                       let hitPoint = rayCastResult |> RayCastResult.position in
                       let hitNormal = rayCastResult |> RayCastResult.normal in
                       let hitBodyId = rayCastResult |> RayCastResult.bodyId in
                       (expect.float (hitPoint |> Vector3.x)).toBeCloseTo 0.0;
                       (expect.float (hitPoint |> Vector3.y)).toBeCloseTo 0.0;
                       (expect.float (hitPoint |> Vector3.z)).toBeCloseTo 0.0;
                       (expect.float (hitNormal |> Vector3.x)).toBeCloseTo
                         0.0;
                       (expect.float (hitNormal |> Vector3.y)).toBeCloseTo
                         1.0;
                       (expect.float (hitNormal |> Vector3.z)).toBeCloseTo
                         0.0;
                       (expect.int hitBodyId).toBe 42)))))