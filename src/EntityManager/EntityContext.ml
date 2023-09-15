type t = { entityId : EntityId.t; world : ReadOnlyWorld.t }

let world { world; _ } = world
let id { entityId; _ } = entityId
