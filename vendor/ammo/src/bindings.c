#define STUB(name) \
  void name() { return; }

STUB(ammo_init);
STUB(ammo_step);

STUB(ammo_debugDrawer_create);
STUB(ammo_debugDrawer_draw);
STUB(ammo_debugDrawer_dispose);

STUB(ammo_transform_identity)
STUB(ammo_transform_origin)
STUB(ammo_transform_rotation)
STUB(ammo_transform_fromPositionRotation)

STUB(ammo_motionState_default)

STUB(ammo_rigidBody_create)
STUB(ammo_rigidBody_create_native)
STUB(ammo_rigidBody_position)
STUB(ammo_rigidBody_rotation)
STUB(ammo_rigidBody_applyImpulse)
STUB(ammo_rigidBody_applyForce)
STUB(ammo_rigidBody_applyCentralImpulse)
STUB(ammo_rigidBody_applyCentralForce)
STUB(ammo_rigidBody_setAngularFactor)
STUB(ammo_rigidBody_setLinearVelocity)
STUB(ammo_rigidBody_setPositionRotation)

STUB(ammo_addRigidBody);
STUB(ammo_removeRigidBody);

STUB(ammo_raycastResult_bodyId)
STUB(ammo_raycastResult_normal)
STUB(ammo_raycastResult_position)

STUB(ammo_raycast);
STUB(ammo_shapeCast);
STUB(ammo_shapeCast_native);

STUB(ammo_shape_box);
STUB(ammo_shape_capsule);
STUB(ammo_shape_sphere);
STUB(ammo_shape_triangleMesh);
