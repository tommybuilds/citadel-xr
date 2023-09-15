type 'state stateWithEntityManager = {
  entityManager : EntityManager.t;
  extraState : 'state;
}

type 'msg msgWithDefaults =
  | Tick of { deltaTime : float }
  | Entity of EntityManager.msg
  | ExtraMsg of 'msg

type t =
  | Scene : {
      subscriptionState :
        'msg msgWithDefaults Isolinear.Testing.SubscriptionRunner.t ref;
      uniqueId : string;
      render : 'state -> EntityManager.World.t -> React3d.element;
      staticGeometry : Mesh.Static.t list;
      store :
        ('msg msgWithDefaults, 'state stateWithEntityManager) Isolinear.Store.t;
    }
      -> t

type scene = t

let equals s1 s2 =
  match (s1, s2) with
  | Scene { uniqueId = id1; _ }, Scene { uniqueId = id2; _ } -> id1 = id2

module Internal = struct
  let scenes = (Hashtbl.create 8 : (string, t) Hashtbl.t)
  let getSceneById id = Hashtbl.find_opt scenes id
  let registerScene id scene = Hashtbl.add scenes id scene
end

let render = function
  | Scene { store; render } ->
      let { extraState; entityManager } = Isolinear.Store.getState store in
      render extraState (EntityManager.world entityManager)

let entityManager = function
  | Scene { store; _ } ->
      let { entityManager } = Isolinear.Store.getState store in
      entityManager

let eff pendingEffects =
  Isolinear.Effect.createWithDispatch ~name:"Run effects" (fun dispatch ->
      EntityManager.SideEffects.runSideEffects dispatch pendingEffects)
  |> Isolinear.Effect.map (fun msg -> Entity msg)

let update ({ entityManager; _ } as model) msg =
  match msg with
  | Tick { deltaTime } ->
      let entityManager', effects =
        EntityManager.tick ~deltaTime entityManager
      in
      ({ model with entityManager = entityManager' }, eff effects)
  | Entity entityMsg ->
      let entityManager', effects =
        EntityManager.update entityMsg entityManager
      in
      ({ model with entityManager = entityManager' }, eff effects)
  | ExtraMsg _ -> (model, Isolinear.Effect.none)

let make ~(uniqueId : string) ~update:_ ~render ~subscriptions state =
  let state = { entityManager = EntityManager.initial; extraState = state } in
  let outerRender state _world = render state in
  let store = Isolinear.Store.make update state in
  let subscriptionState = ref (Isolinear.Testing.SubscriptionRunner.empty ()) in
  let scene =
    Scene
      {
        uniqueId;
        store;
        staticGeometry = [];
        render = outerRender;
        subscriptionState;
      }
  in
  Internal.registerScene uniqueId scene;
  scene

module SceneBuilder = struct
  type t = {
    entityManager : EntityManager.t;
    staticGeometry : Mesh.Static.t list;
    renderFn : React3d.element -> React3d.element;
  }

  let initial =
    {
      entityManager = EntityManager.initial;
      staticGeometry = [];
      renderFn = (fun elem -> elem);
    }

  let system system ({ entityManager; _ } as sceneBuilder) =
    {
      sceneBuilder with
      entityManager = EntityManager.register system entityManager;
    }

  let static staticMesh ({ staticGeometry; _ } as sceneBuilder) =
    print_endline "adding static mesh?";
    { sceneBuilder with staticGeometry = staticMesh :: staticGeometry }

  let entityi entity ({ entityManager; _ } as sceneBuilder) =
    let id, entityManager' = EntityManager.instantiatei entity entityManager in
    (id, { sceneBuilder with entityManager = entityManager' })

  let entity entity sceneBuilder = sceneBuilder |> entityi entity |> snd

  let wrapRender (render : React3d.element -> React3d.element) sceneBuilder =
    {
      sceneBuilder with
      renderFn = (fun element -> element |> sceneBuilder.renderFn |> render);
    }

  let make =
    (fun uniqueId sceneBuilder ->
       let render () (world : EntityManager.World.t) =
         let element =
           React3d.Primitives.transform
             (EntityManager.World.values System_Renderable.Components.render
                world)
         in
         sceneBuilder.renderFn element
       in
       let state =
         { entityManager = sceneBuilder.entityManager; extraState = () }
       in
       let store = Isolinear.Store.make update state in
       let subscriptionState =
         ref (Isolinear.Testing.SubscriptionRunner.empty ())
       in
       let scene =
         Scene
           {
             uniqueId;
             store;
             staticGeometry = sceneBuilder.staticGeometry;
             render;
             subscriptionState;
           }
       in
       Internal.registerScene uniqueId scene;
       scene
      : string -> t -> scene)
end

let subscriptions = function
  | Scene { store } ->
      store |> Isolinear.Store.getState
      |> (fun model -> model.entityManager |> EntityManager.sub)
      |> Isolinear.Sub.map (fun msg -> Entity msg)

let runSubscriptions = function
  | Scene { store; subscriptionState; _ } as scene ->
      let subs = !subscriptionState in
      subscriptionState :=
        Isolinear.Testing.SubscriptionRunner.run
          ~dispatch:(Isolinear.Store.dispatch store)
          ~sub:(subscriptions scene) subs

let initscene = function
  | Scene { store; staticGeometry; uniqueId; _ } ->
      let staticGeometryNode =
        Babylon.Node.createTransform ~name:"static-geometry"
      in
      let _ =
        staticGeometry
        |> List.iter (fun static ->
               print_endline "Iterating a static geometry";
               let promise = Mesh.Static.load static in
               let _ =
                 promise
                 |> Promise.then_ ~fulfilled:(fun mesh ->
                        Babylon.Node.setParent ~parent:staticGeometryNode mesh;
                        let state = Isolinear.Store.getState store in
                        mesh
                        |> Mesh.MeshProcessor.traverseMeshes (fun m ->
                               EntityManager.addStaticGeometry ~mesh:m
                                 state.entityManager);
                        Promise.resolve ())
               in
               ())
      in
      staticGeometryNode

let dispose = function
  | Scene { store; subscriptionState; _ } ->
      let subs = !subscriptionState in
      subscriptionState :=
        Isolinear.Testing.SubscriptionRunner.run
          ~dispatch:(Isolinear.Store.dispatch store)
          ~sub:Isolinear.Sub.none subs

let runPendingEffects = function
  | Scene { store; _ } -> Isolinear.Store.runPendingEffects store

let tick ~(deltaTime : float) = function
  | Scene { store } -> Isolinear.Store.dispatch store (Tick { deltaTime })

module BasicBox = struct
  let render () =
    React3d.Primitives.transform
      [
        React3d.Primitives.hemisphericLight ();
        React3d.Primitives.box ~material:React3d.Material.wireframe [];
      ]

  let scene =
    make ~uniqueId:"internal/basic/box" ~render
      ~subscriptions:(fun () -> Isolinear.Sub.none)
      ~update:(fun () -> ())
      ()
end

module BasicSphere = struct
  let render () =
    React3d.Primitives.transform
      [
        React3d.Primitives.hemisphericLight ();
        React3d.Primitives.sphere ~material:React3d.Material.wireframe [];
      ]

  let scene =
    make ~uniqueId:"internal/basic/sphere" ~render
      ~subscriptions:(fun () -> Isolinear.Sub.none)
      ~update:(fun () -> ())
      ()
end

module Global = struct
  let activeScene = ref BasicBox.scene

  let init () =
    let models = Mesh.Registry.all () in
    let () =
      models
      |> List.iter (function Mesh.Registry.Specimen { definition; args } ->
             let editorSystem = Editor.System.make args definition.editor in
             let position = Babylon.Vector3.create ~x:0. ~y:1. ~z:(-3.) in
             let render () =
               let context = EntityManager.System.latestContext editorSystem in
               React3d.Primitives.transform
                 [
                   React3d.Primitives.hemisphericLight ();
                   React3d.Primitives.meshWithArgs ~args:context definition;
                 ]
             in
             let persistenceKey =
               System_Camera.key ("__camera__" ^ definition.friendlyId)
             in
             let camera = System_Camera.arc ~persistenceKey ~position () in
             let scene =
               SceneBuilder.initial
               |> SceneBuilder.system editorSystem
               |> SceneBuilder.entity (System_Camera.Entity.camera camera)
               |> SceneBuilder.wrapRender (fun _ -> render ())
               |> SceneBuilder.make definition.friendlyId
             in
             let baseUrl =
               Js_of_ocaml.Dom_html.window##.location##.href
               |> Js_of_ocaml.Js.to_string
             in
             Console.log
               ("Registered scene: " ^ baseUrl ^ "#" ^ definition.friendlyId);
             Internal.registerScene definition.friendlyId scene)
    in
    ()

  let switchScene newScene =
    let currentScene = !activeScene in
    if not (equals currentScene newScene) then (
      dispose currentScene;
      activeScene := newScene);
    initscene newScene

  let switchSceneById sceneId =
    Console.log ("Trying to switch scene: " ^ sceneId);
    let maybeScene = sceneId |> Internal.getSceneById in
    match maybeScene with
    | None -> failwith ("Unable to find scene: " ^ sceneId)
    | Some scene -> switchScene scene
end
