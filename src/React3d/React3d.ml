module R = Reactify.Make (Reconciler)
include R
module Material = Mesh.Material
module Mesh = Mesh
module AnimatedMesh2 = Mesh.AnimatedMesh2
module Quaternion = Babylon.Quaternion
module Vector3 = Babylon.Vector3

module Primitives = struct
  open Reconciler

  let sphere ?(diameter = 1.0) ?(material = Material.default)
      ?(position = Babylon.Vector3.zero ())
      ?(rotation = Babylon.Quaternion.zero ()) ?(scale = Babylon.Vector3.one)
      children =
    R.primitiveComponent ~children
      {
        position;
        rotation;
        scale;
        kind =
          Mesh
            {
              args =
                (let open Mesh.Sphere in
                { material; diameter });
              mesh = Mesh.sphere;
            };
      }

  let cylinder ?(diameter = 1.0) ?(height = 2.0) ?(material = Material.default)
      ?(position = Babylon.Vector3.zero ())
      ?(rotation = Babylon.Quaternion.zero ()) ?(scale = Babylon.Vector3.one)
      children =
    R.primitiveComponent ~children
      {
        position;
        rotation;
        scale;
        kind = Cylinder { diameter; height; material };
      }

  let box ?(size = 1.0) ?(material = Material.default)
      ?(position = Babylon.Vector3.zero ())
      ?(rotation = Babylon.Quaternion.zero ()) ?(scale = Babylon.Vector3.one)
      children =
    R.primitiveComponent ~children
      { position; rotation; scale; kind = Box { size; material } }

  let transform ?(position = Vector3.zero ()) ?(rotation = Quaternion.zero ())
      ?(scale = Babylon.Vector3.one) children =
    R.primitiveComponent ~children
      { position; rotation; scale; kind = Transform }

  let ground ?(material = Material.default)
      ?(position = Babylon.Vector3.zero ())
      ?(rotation = Babylon.Quaternion.zero ()) ?(scale = Babylon.Vector3.one)
      children =
    R.primitiveComponent ~children
      { position; rotation; scale; kind = Ground { material } }

  let plane ?(material = Material.default) ?(position = Babylon.Vector3.zero ())
      ?(rotation = Babylon.Quaternion.zero ()) ?(scale = Babylon.Vector3.one)
      ?(width = 1.0) ?(height = 1.0) children =
    R.primitiveComponent ~children
      {
        position;
        rotation;
        scale;
        kind =
          Mesh
            {
              args =
                (let open Mesh.Plane in
                { material; width; height });
              mesh = Mesh.plane;
            };
      }

  let spotLight ?(position = Babylon.Vector3.zero ())
      ?(rotation = Babylon.Quaternion.zero ())
      ?(direction = Babylon.Vector3.forward 1.0) ?(scale = Babylon.Vector3.one)
      children =
    R.primitiveComponent ~children
      { position; rotation; scale; kind = SpotLight { direction } }

  let pointLight ?(range = 10.0) ?(position = Babylon.Vector3.zero ())
      ?(rotation = Babylon.Quaternion.zero ()) ?(scale = Babylon.Vector3.one)
      ?(diffuse = Babylon.Color.white) ?(specular = Babylon.Color.white)
      children =
    R.primitiveComponent ~children
      {
        position;
        rotation;
        scale;
        kind = PointLight { range; diffuse; specular };
      }

  let hemisphericLight ?(position = Babylon.Vector3.zero ())
      ?(rotation = Babylon.Quaternion.zero ()) ?(scale = Babylon.Vector3.one)
      ?(direction = Babylon.Vector3.up 1.0) ?(diffuse = Babylon.Color.white)
      ?(specular = Babylon.Color.white) ?(ground = Babylon.Color.black)
      ?(intensity = 1.0) () =
    R.primitiveComponent ~children:[]
      {
        position;
        rotation;
        scale;
        kind =
          HemisphericLight { direction; diffuse; specular; ground; intensity };
      }

  let mesh ?(position = Babylon.Vector3.zero ())
      ?(rotation = Babylon.Quaternion.zero ()) ?(scale = Babylon.Vector3.one)
      mesh =
    R.primitiveComponent ~children:[]
      { position; rotation; scale; kind = Mesh { args = (); mesh } }

  let animatedMesh ?skeletonRef ?(position = Babylon.Vector3.zero ())
      ?(rotation = Babylon.Quaternion.zero ()) ?(scale = Babylon.Vector3.one)
      ?(frame = 0.0) mesh =
    R.primitiveComponent ~children:[]
      {
        position;
        rotation;
        scale;
        kind =
          Mesh
            {
              args =
                (let open AnimatedMesh2 in
                { animationFrame = frame; skeletonRef });
              mesh;
            };
      }

  let meshWithArgs ?(position = Babylon.Vector3.zero ())
      ?(rotation = Babylon.Quaternion.zero ()) ?(scale = Babylon.Vector3.one)
      ~args mesh =
    R.primitiveComponent ~children:[]
      { position; rotation; scale; kind = Mesh { args; mesh } }
end

module P = Primitives