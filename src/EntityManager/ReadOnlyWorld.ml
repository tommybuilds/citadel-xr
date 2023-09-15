type t = {
  read :
    'readability 'component.
    entityId:EntityId.t ->
    ('readability, 'component) Component.t ->
    'component option;
  valuesi :
    'readability 'component.
    ('readability, 'component) Component.t -> (EntityId.t * 'component) list;
}

let read :
      'readability 'component.
      t ->
      entityId:EntityId.t ->
      ('readability, 'component) Component.t ->
      'component option =
 fun { read; _ } ~entityId component -> read ~entityId component

let valuesi :
      'readability 'component.
      ('readability, 'component) Component.t ->
      t ->
      (EntityId.t * 'component) list =
 fun component { valuesi; _ } -> valuesi component

let has ~entityId component { read; _ } =
  read ~entityId component |> Option.is_some
