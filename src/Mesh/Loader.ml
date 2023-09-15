open Babylon
type meshParams = {
  uniqueId: string ;
  rootUrl: string ;
  fileName: string }
module Cache =
  struct
    let cache = Hashtbl.create 16
    let get ?(forceReload= false)  ~rootUrl  fileName =
      let key = rootUrl ^ fileName in
      match Hashtbl.find_opt cache key with
      | Some ret when forceReload = false -> ret
      | _ ->
          let promise = SceneLoader.importMeshAsync ~rootUrl ~fileName None in
          let promise' =
            promise |>
              (Promise.then_
                 ~fulfilled:(fun loadResult ->
                               let transform = Node.createTransform ~name:key in
                               let meshes =
                                 SceneLoader.LoadResult.meshes loadResult in
                               let skeletons =
                                 SceneLoader.LoadResult.skeletons loadResult in
                               let animationGroups =
                                 SceneLoader.LoadResult.animationGroups
                                   loadResult in
                               meshes |>
                                 (Array.iter
                                    (fun mesh ->
                                       Node.setParent ~parent:transform mesh));
                               Node.setEnabled ~enabled:false transform;
                               Promise.resolve
                                 (transform, animationGroups, skeletons))
                 ~rejected:(fun err -> Promise.reject err)) in
          (Hashtbl.add cache key promise'; promise')
  end
module LoadResult =
  struct
    type 'a t =
      {
      rootNode: 'a Babylon.node ;
      animationGroups: Babylon.AnimationGroup.t array ;
      skeletons: Babylon.Skeleton.t array }
  end
type 'a t =
  {
  loadFunction: unit -> 'a LoadResult.t Promise.t ;
  friendlyName: string }
let load { loadFunction;_} = loadFunction ()
let friendlyName { friendlyName;_} = friendlyName
let fromFile (fileName : string) =
  let f () =
    (Cache.get ~forceReload:true ~rootUrl:fileName "") |>
      (Promise.map
         (fun (mesh, animationGroups, skeletons) ->
            let open LoadResult in
              { rootNode = mesh; animationGroups; skeletons })) in
  let friendlyName = fileName in { loadFunction = f; friendlyName }
let fromPrimitive ?friendlyName  (f : unit -> 'a Babylon.node) =
  let name =
    match friendlyName with | None -> "Unknown Primitive" | Some n -> n in
  let loadFunction () =
    let rootNode = f () in
    Node.setEnabled ~enabled:false rootNode;
    Promise.resolve
      (let open LoadResult in
         { rootNode; animationGroups = [||]; skeletons = [||] }) in
  { loadFunction; friendlyName = name }