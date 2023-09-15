open Babylon
type kind =
  | Default 
  | Color of {
  diffuse: Color.t ;
  emissive: Color.t option } 
  | Standard of
  {
  uScale: float ;
  vScale: float ;
  invertY: bool ;
  hasAlpha: bool ;
  diffuseTexture: string option ;
  emissiveTexture: string option ;
  normalTexture: string option ;
  specularTexture: string option ;
  emissiveColor: Color.t option } 
  | Wireframe 
type cacheKey = int
let nextKey = ref 1
type t = {
  cacheKey: cacheKey option ;
  kind: kind }
let getKey () = incr nextKey; !nextKey
let default = { cacheKey = (Some (getKey ())); kind = Default }
let color ?emissive  diffuse =
  { cacheKey = (Some (getKey ())); kind = (Color { diffuse; emissive }) }
let standard ?uScale:((uScale : float)= 1.0)  ?vScale:((vScale : float)= 1.0)
   ?invertY:((invertY : bool)= false)  ?hasAlpha:((hasAlpha : bool)= false) 
  ?diffuseTexture:(diffuseTexture : string option) 
  ?emissiveTexture:(emissiveTexture : string option) 
  ?normalTexture:(normalTexture : string option) 
  ?specularTexture:(specularTexture : string option) 
  ?emissiveColor:(emissiveColor : Color.t option)  () =
  {
    cacheKey = (Some (getKey ()));
    kind =
      (Standard
         {
           uScale;
           vScale;
           invertY;
           diffuseTexture;
           normalTexture;
           emissiveColor;
           emissiveTexture;
           specularTexture;
           hasAlpha
         })
  }
let wireframe = { cacheKey = (Some (getKey ())); kind = Wireframe }
let createFactory =
  (fun primitive ->
     match primitive with
     | Default -> Babylon.Material.standard ~name:"Material"
     | Color { diffuse; emissive } ->
         let mat = Babylon.Material.standard ~name:"ColorMaterial" in
         (Babylon.Material.setDiffuseColor ~color:diffuse mat;
          emissive |>
            (Option.iter
               (fun color -> Babylon.Material.setEmissiveColor ~color mat));
          mat)
     | ((Standard
         { uScale; vScale; diffuseTexture; emissiveTexture; emissiveColor;
           normalTexture; specularTexture; hasAlpha; invertY })[@explicit_arity
                                                                 ])
         ->
         let mat = Babylon.Material.standard ~name:"Material" in
         let applyTexture f texFile =
           let texture = Texture.create ~invertY texFile in
           Babylon.Texture.setUScale ~scale:uScale texture;
           Babylon.Texture.setVScale ~scale:vScale texture;
           Babylon.Texture.setHasAlpha ~hasAlpha texture;
           f ~texture mat in
         (diffuseTexture |>
            (Option.iter (applyTexture Babylon.Material.setDiffuseTexture));
          emissiveTexture |>
            (Option.iter (applyTexture Babylon.Material.setEmissiveTexture));
          normalTexture |>
            (Option.iter (applyTexture Babylon.Material.setNormalTexture));
          specularTexture |>
            (Option.iter (applyTexture Babylon.Material.setSpecularTexture));
          emissiveColor |>
            (Option.iter
               (fun color -> Babylon.Material.setEmissiveColor ~color mat));
          mat)
     | Wireframe ->
         let mat = Babylon.Material.standard ~name:"Derp" in
         (Babylon.Material.setWireframe ~wireframe:true mat; mat) : kind ->
                                                                    Babylon.Material.t)
let cache = (Hashtbl.create 16 : (cacheKey, Babylon.Material.t) Hashtbl.t)
let createMaterial ({ cacheKey; kind } : t) =
  match cacheKey with
  | None -> createFactory kind
  | Some key ->
      (match Hashtbl.find_opt cache key with
       | None ->
           let mat = createFactory kind in (Hashtbl.add cache key mat; mat)
       | Some mat -> mat)
module Reconciler =
  struct
    type material = t
    type t = {
      lastMaterial: material option }
    let initial = { lastMaterial = None }
    let updateMaterialOnNode material node =
      let instance = createMaterial material in
      Babylon.Mesh.setMaterial ~material:instance node
    let reconcile (node : Babylon.mesh Babylon.node) (newMaterial : material)
      (reconciler : t) =
      let lastMaterial =
        match reconciler.lastMaterial with
        | None -> (updateMaterialOnNode newMaterial node; Some newMaterial)
        | Some mat when mat <> newMaterial ->
            (updateMaterialOnNode newMaterial node; Some newMaterial)
        | Some _ as previousMat -> previousMat in
      { lastMaterial }
  end