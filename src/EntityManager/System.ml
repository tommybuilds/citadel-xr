open Util

type 'context tickFunction =
  deltaTime:float -> world:World.t -> 'context -> 'context * World.t

type 'context addStaticMeshFunction =
  mesh:Babylon.mesh Babylon.node -> 'context -> unit

type 'context definition = {
  initialContext : 'context;
  latestContext : 'context ref;
  addStaticMeshFunction : 'context addStaticMeshFunction;
  tick : 'context tickFunction;
  pipe : 'context Pipe.t;
}

let defaultAddStaticMeshFn ~mesh _ = ()

let define ?(onAddStaticGeometry = defaultAddStaticMeshFn) ~tick initialContext
    =
  {
    pipe = Pipe.create ();
    addStaticMeshFunction = onAddStaticGeometry;
    initialContext;
    latestContext = ref initialContext;
    tick;
  }

let latestContext { latestContext; _ } = !latestContext

module Instance = struct
  type t =
    | Instance : {
        currentContext : 'context;
        definition : 'context definition;
        addStaticMeshFunction : 'context addStaticMeshFunction;
        tickFunction : 'context tickFunction;
      }
        -> t

  let tick ~deltaTime ~world = function
    | Instance
        { currentContext; definition; tickFunction; addStaticMeshFunction } ->
        let newContext, newWorld =
          tickFunction ~deltaTime ~world currentContext
        in
        definition.latestContext := newContext;
        ( Instance
            {
              currentContext = newContext;
              definition;
              tickFunction;
              addStaticMeshFunction;
            },
          newWorld )

  let addStaticGeometry ~mesh = function
    | Instance { currentContext; addStaticMeshFunction; _ } ->
        addStaticMeshFunction ~mesh currentContext

  let context (destDefinition : 'context definition) = function
    | Instance { currentContext; definition } ->
        Util.Pipe.send definition.pipe destDefinition.pipe currentContext
end

let instantiate (definition : 'context definition) =
  Instance.Instance
    {
      currentContext = definition.initialContext;
      definition;
      addStaticMeshFunction = definition.addStaticMeshFunction;
      tickFunction = definition.tick;
    }

module Effect = struct
  let sideEffect f definition args =
    Effect.sideEffect (fun () ->
        let context = !(definition.latestContext) in
        f args context)

  let sideEffectWithDispatch f definition args =
    Effect.sideEffectWithDispatch (fun dispatch ->
        let context = !(definition.latestContext) in
        f ~dispatch args context)
end
