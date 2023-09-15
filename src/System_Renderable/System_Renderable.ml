open EntityManager

module Components = struct
  let render =
    (Component.readonly ~name:"Internal.Render" ()
      : (EntityManager.Component.readonly, React3d.element) Component.t)
end

module Entity = struct
  let renderable render definition =
    definition
    |> EntityManager.Entity.withReadonlyComponent Components.render render
end
