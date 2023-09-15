module Color = Babylon.Color
module Light = Babylon.Light
module MeshBuilder = Babylon.MeshBuilder
module Quaternion = Babylon.Quaternion
module Vector3 = Babylon.Vector3
module Material = Mesh.Material

type meshFactory = unit -> Babylon.mesh Babylon.node

type kind =
  | Transform
  | Mesh : {
      args : 'args;
      mesh : ('args, 'node, 'state) Mesh.Definition.t;
    }
      -> kind
  | PointLight of { range : float; diffuse : Color.t; specular : Color.t }
  | SpotLight of { direction : Vector3.t }
  | HemisphericLight of {
      direction : Vector3.t;
      diffuse : Color.t;
      specular : Color.t;
      ground : Color.t;
      intensity : float;
    }
  | Ground of { material : Material.t }
  | Plane of { width : float; height : float; material : Material.t }
  | Box of { size : float; material : Material.t }
  | Cylinder of { diameter : float; height : float; material : Material.t }

type primitives = {
  position : Vector3.t;
  rotation : Quaternion.t;
  scale : Vector3.t;
  kind : kind;
}

type node =
  | Node : 'a Babylon.node -> node
  | MeshInstance : ('args, 'node, 'state) Mesh.Instance.t -> node

let extractRootNode (node : node) =
  match node with
  | Node node -> node |> Babylon.Node.abstract
  | MeshInstance instance ->
      instance |> Mesh.Instance.rootNode |> Babylon.Node.abstract

let canBeReused prim1 prim2 =
  match (prim1, prim2) with
  | { kind = oldKind; _ }, { kind = newKind; _ } -> (
      match (oldKind, newKind) with
      | Mesh { mesh = meshA; _ }, Mesh { mesh = meshB; _ } ->
          Mesh.Definition.equals meshA meshB
      | _ -> Reactify.Utility.areConstructorsEqual oldKind newKind)

let createInstance { position; rotation; scale; kind } =
  let node =
    match kind with
    | Transform -> Node (Babylon.Node.createTransform ~name:"transform")
    | Mesh { args; mesh } ->
        let instance = mesh |> Mesh.Instance.make in
        let () = instance |> Mesh.Instance.applyMeshArgs args mesh in
        MeshInstance instance
    | SpotLight _ ->
        let transformNode =
          Babylon.Node.createTransform ~name:"light-transform"
        in
        let light =
          Light.spot ~exponent:2. ~position:(Vector3.zero ())
            ~direction:(Vector3.forward 1.0) ()
        in
        Babylon.Node.setParent ~parent:transformNode light;
        Node transformNode
    | PointLight { diffuse; range; specular } ->
        let light =
          Light.point ~name:"point-light" ~position:(Vector3.zero ())
        in
        Light.setRange ~range light;
        Light.setDiffuse ~color:diffuse light;
        Light.setSpecular ~color:specular light;
        Node light
    | ((HemisphericLight { direction; diffuse; specular; ground; intensity })
    [@explicit_arity]) ->
        let node = Light.hemispheric ~name:"Hemispheric" ~direction in
        Light.setDiffuse ~color:diffuse node;
        Light.setSpecular ~color:specular node;
        Light.setGroundColor ~color:ground node;
        Light.setIntensity ~intensity node;
        Node node
    | Plane { material; width; height } ->
        let node = Babylon.Node.createTransform ~name:"test" in
        Node node
    | Ground { material } ->
        let ground =
          MeshBuilder.Ground.create
            ~options:
              (let open MeshBuilder.Ground in
              { width = 10.0; height = 10.0 })
            ()
        in
        let materialInstance = Material.createMaterial material in
        Babylon.Mesh.setMaterial ~material:materialInstance ground;
        Node ground
    | Cylinder { material; diameter; height } ->
        let mesh =
          MeshBuilder.Cylinder.create
            ~options:
              (let open MeshBuilder.Cylinder in
              { diameter; height })
            ()
        in
        let materialInstance = Material.createMaterial material in
        Babylon.Mesh.setMaterial ~material:materialInstance mesh;
        Node mesh
    | Box { material; size } ->
        let mesh =
          MeshBuilder.Box.create
            ~options:
              (let open MeshBuilder.Box in
              { size })
            ()
        in
        let materialInstance = Material.createMaterial material in
        Babylon.Mesh.setMaterial ~material:materialInstance mesh;
        Node mesh
  in
  (match node with
  | Node n ->
      Babylon.Node.setPosition ~position n;
      Babylon.Node.setScaling ~scale n;
      Babylon.Node.setRotationQuat ~quaternion:rotation n
  | MeshInstance instance ->
      let n = Mesh.Instance.rootNode instance in
      Babylon.Node.setPosition ~position n;
      Babylon.Node.setScaling ~scale n;
      Babylon.Node.setRotationQuat ~quaternion:rotation n);
  node

let appendChild parent child =
  let parentNode = extractRootNode parent in
  let childNode = extractRootNode child in
  Babylon.Node.setParent ~parent:parentNode childNode;
  child

let removeChild _parent (child : node) =
  match child with
  | Node child -> Babylon.Node.dispose child
  | MeshInstance instance -> Mesh.Instance.dispose instance

let updateInstance node _oldPrim newPrim =
  let { kind = newKind; position; rotation; scale; _ } = newPrim in
  match node with
  | Node node ->
      Babylon.Node.setPosition ~position node;
      Babylon.Node.setRotationQuat ~quaternion:rotation node;
      Babylon.Node.setScaling ~scale node
  | MeshInstance instance -> (
      let node = Mesh.Instance.rootNode instance in
      Babylon.Node.setPosition ~position node;
      Babylon.Node.setRotationQuat ~quaternion:rotation node;
      Babylon.Node.setScaling ~scale node;
      let definition = instance |> Mesh.Instance.definition in
      match newKind with
      | Mesh { mesh; args } ->
          if Mesh.Definition.equals definition mesh then
            Mesh.Instance.applyMeshArgs args mesh instance
      | _ -> ())

let replaceChild parent newChild oldChild =
  let parentNode = extractRootNode parent in
  let newChildNode = extractRootNode newChild in
  let oldChildNode = extractRootNode oldChild in
  Babylon.Node.dispose oldChildNode;
  Babylon.Node.setParent ~parent:parentNode newChildNode