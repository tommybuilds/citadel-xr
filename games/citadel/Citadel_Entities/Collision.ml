module Group =
  struct
    let world = Ammo.CollisionGroup.default
    let boundingBox = Ammo.CollisionGroup.create "boundingBox"
    let hitBox = Ammo.CollisionGroup.create "hitBox"
  end
module Mask =
  struct
    let empty = Ammo.CollisionMask.create []
    let worldAndHitBox =
      Ammo.CollisionMask.create [Group.hitBox; Group.world]
    let worldAndBoundingBox =
      Ammo.CollisionMask.create [Group.world; Group.boundingBox]
    let all = Ammo.CollisionMask.default
  end