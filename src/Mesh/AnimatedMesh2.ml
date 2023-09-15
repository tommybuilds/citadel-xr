type args =
  {
  animationFrame: float ;
  skeletonRef: Babylon.Skeleton.t option ref option }
type state =
  {
  animationGroups: Babylon.AnimationGroup.t array ;
  skeletons: Babylon.Skeleton.t array }
let initialState Loader.LoadResult.{ rootNode; animationGroups; skeletons;_} 
  = { animationGroups; skeletons }
let apply { animationFrame; skeletonRef }
  ({ animationGroups; skeletons } as state) _ =
  animationGroups |>
    (Array.iter
       (fun ag ->
          Babylon.AnimationGroup.play ag;
          Babylon.AnimationGroup.goToFrame animationFrame ag;
          Babylon.AnimationGroup.stop ag));
  skeletons |>
    (Array.iter
       (fun skeleton ->
          skeletonRef |> (Option.iter (fun ref -> ref := (Some skeleton)));
          ()));
  state
let mesh ?friendlyId  ?(postProcess= MeshProcessor.none)  loader =
  DynamicMesh.make ?friendlyId ~editor:Editor.empty
    ~initialArgs:{ animationFrame = 0.0; skeletonRef = None } ~initialState
    ~postProcess ~apply loader