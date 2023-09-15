open Babylon

type t = {
  collisionGroup : Ammo.CollisionGroup.t option;
  collisionMask : Ammo.CollisionMask.t option;
  mass : float;
  shape : Shape.t;
  position : Vector3.t;
  rotation : Quaternion.t;
  angularFactor : Vector3.t option;
  friction : float option;
  rollingFriction : float option;
}

let create ?angularFactor ?collisionGroup ?collisionMask ?friction
    ?rollingFriction ?(mass = 1.0) ~initialPosition
    ~(initialRotation : Quaternion.t) shape =
  {
    collisionGroup;
    collisionMask;
    angularFactor;
    rollingFriction;
    friction;
    mass;
    position = initialPosition;
    rotation = initialRotation;
    shape;
  }

let position { position; _ } = position
let rotation { rotation; _ } = rotation
