// TODO:
// ' Requires: caml_js_to_array
// ' Requires: caml_js_to_string

// Provides: ammo_allocate
function ammo_allocate(physics, object, args) {
    // TODO: Convert over remaining news
    var AmmoNamespace = physics.AmmoNamespace;
    var MemoryUsage = physics.memoryUsage;
    MemoryUsage.activeAllocations++;
    var fn = AmmoNamespace[object].bind.apply(AmmoNamespace[object], [null].concat(args));
    return new fn;
}

// Provides: ammo_destroy
function ammo_destroy(physics, object) {
    var AmmoNamespace = physics.AmmoNamespace;
    var MemoryUsage = physics.memoryUsage;
    MemoryUsage.activeAllocations--;
    AmmoNamespace.destroy(object);
}

// Provides: ammo_vec3_of_babylon
// Requires: ammo_allocate
function ammo_vec3_of_babylon(babylonVec3, physics) {
    var AmmoNamespace = physics.AmmoNamespace;
    var x = babylonVec3.x;
    var y = babylonVec3.y;
    var z = babylonVec3.z;

    return ammo_allocate(physics, "btVector3", [x, y, z]);
}

// Provides: ammo_quat_of_babylon
// Requires: ammo_allocate
function ammo_quat_of_babylon(babylonQuat, physics) {
    var AmmoNamespace = physics.AmmoNamespace;
    var x = babylonQuat.x;
    var y = babylonQuat.y;
    var z = babylonQuat.z;
    var w = babylonQuat.w;

    return ammo_allocate(physics, "btQuaternion", [x, y, z, w]);
}

// Provides: ammo_vec3_to_babylon
function ammo_vec3_to_babylon(v) {
    var x = v.x();
    var y = v.y();
    var z = v.z();

    return new globalThis.BABYLON.Vector3(x, y, z);
}

// Provides: ammo_quat_to_babylon
function ammo_quat_to_babylon(q) {
    var x = q.x();
    var y = q.y();
    var z = q.z();
    var w = q.w();

    return new globalThis.BABYLON.Quaternion(x, y, z, w);
}

// Provides: ammo_deref
function ammo_deref(ptr) {
    // TODO: This used to just be `ptr` - why did it change??
    return ptr.bB;
}

// Provides: ammo_init
function ammo_init(cb) {
    var Module = { TOTAL_MEMORY: 256 * 1024 * 1024 };

    var fn = typeof globalThis.AmmoFn !== "undefined" ? globalThis.AmmoFn : globalThis.Ammo;

    fn().then(function (AmmoNamespace) {
        var collisionConfiguration = new AmmoNamespace.btDefaultCollisionConfiguration();
        var dispatcher = new AmmoNamespace.btCollisionDispatcher(
            collisionConfiguration
        );
        var broadphase = new AmmoNamespace.btDbvtBroadphase();
        var solver = new AmmoNamespace.btSequentialImpulseConstraintSolver();

        var world = new AmmoNamespace.btDiscreteDynamicsWorld(
            dispatcher,
            broadphase,
            solver,
            collisionConfiguration
        );
        world.setGravity(new AmmoNamespace.btVector3(0, -6, 0));

        cb({ world: world, memoryUsage: { activeAllocations: 0 }, AmmoNamespace: AmmoNamespace })
    })
}

// Provides: ammo_debugDrawer_create
function ammo_debugDrawer_create(physics) {
    var console = globalThis.console;
    var BABYLON = globalThis.BABYLON;
    var AmmoNamespace = physics.AmmoNamespace;
    var world = physics.world;

    var debugDrawer = new AmmoNamespace.DebugDrawer()
    var pendingLines = [];
    debugDrawer.drawLine = function (from, to, color) {
        var heap = AmmoNamespace.HEAPF32;
        var r = heap[(color + 0) / 4];
        var g = heap[(color + 4) / 4];
        var b = heap[(color + 8) / 4];

        var fromX = heap[(from + 0) / 4];
        var fromY = heap[(from + 4) / 4];
        var fromZ = heap[(from + 8) / 4];

        var toX = heap[(to + 0) / 4];
        var toY = heap[(to + 4) / 4];
        var toZ = heap[(to + 8) / 4];

        var from = new BABYLON.Vector3(fromX, fromY, fromZ)
        var to = new BABYLON.Vector3(toX, toY, toZ)
        var color = new BABYLON.Color3(r, g, b)
        pendingLines.push([from, to, color])
    };
    debugDrawer.drawContactPoint = function (pointOnB, normalOnB, distance, lifeTime, color) {
        var heap = AmmoNamespace.HEAPF32;
        var r = heap[(color + 0) / 4];
        var g = heap[(color + 4) / 4];
        var b = heap[(color + 8) / 4];

        var x = heap[(pointOnB + 0) / 4];
        var y = heap[(pointOnB + 4) / 4];
        var z = heap[(pointOnB + 8) / 4];

        var dx = heap[(normalOnB + 0) / 4] * distance;
        var dy = heap[(normalOnB + 4) / 4] * distance;
        var dz = heap[(normalOnB + 8) / 4] * distance;

        var from = new BABYLON.Vector3(x, y, z)
        var to = new BABYLON.Vector3(x + dx, y + dy, z + dz)
        var color = new BABYLON.Color3(r, g, b)
        pendingLines.push([from, to, color])
    };
    debugDrawer.draw3dText = function () { console.log("draw 3d text") };
    // Constants here:
    // https://github.com/bulletphysics/bullet3/blob/5ae9a15ecac7bc7e71f1ec1b544a55135d7d7e32/src/LinearMath/btIDebugDraw.h#L52
    debugDrawer.getDebugMode = function () { return 13 + 64; }
    debugDrawer.setDebugMode = function () { console.log("set debug mode not implemented") };
    debugDrawer.reportErrorWarning = function (warningString) {
        if (AmmoNamespace.hasOwnProperty("UTF8ToString")) {
            console.warn(AmmoNamespace.UTF8ToString(warningString));
        } else if (!debugDrawer.warnedOnce) {
            debugDrawer.warnedOnce = true;
            console.warn("Cannot print warningString, please export UTF8ToString from Ammo.js in make.py");
        }
    };
    debugDrawer.world = world;
    debugDrawer.pendingLines = pendingLines

    world.setDebugDrawer(debugDrawer)
    return debugDrawer
}

// Provides: ammo_debugDrawer_draw
function ammo_debugDrawer_draw(drawer) {
    while (drawer.pendingLines.length > 0) {
        drawer.pendingLines.pop()
    }
    drawer.world.debugDrawWorld()

    var points = []
    var colors = []
    for (var i = 0; i < drawer.pendingLines.length; i++) {
        points.push([drawer.pendingLines[i][0], drawer.pendingLines[i][1]]);

        var color = drawer.pendingLines[0][2]
        colors.push([color, color]);
    }
    var options = {
        lines: points,
        colors: colors,
    };

    if (drawer.linesSceneObject != null) {
        drawer.linesSceneObject.dispose()
    }

    drawer.linesSceneObject = globalThis.BABYLON.MeshBuilder.CreateLineSystem("debug-lines", options)
    var lastCreatedScene = globalThis.BABYLON.Engine.LastCreatedScene;
    var parent = lastCreatedScene.getNodeByName("__debug__")
    drawer.linesSceneObject.parent = parent;
}

// Provides: ammo_debugDrawer_dispose
function ammo_debugDrawer_dispose(drawer) {
    globalThis.console.log("TODO: Dispose debugDrawer")
}

// Provides: ammo_step
function ammo_step(timeStep, maxSubSteps, physics) {
    var AmmoNamespace = physics.AmmoNamespace;
    var world = physics.world;

    world.stepSimulation(timeStep, maxSubSteps);
}

// Provides: ammo_shape_box
// Requires: ammo_vec3_of_babylon
function ammo_shape_box(vec, physics) {
    var dimensions = ammo_vec3_of_babylon(vec, physics)
    var shape = new physics.AmmoNamespace.btBoxShape(dimensions)
    shape.setMargin(0.1)
    return shape
}

// Provides: ammo_shape_capsule
function ammo_shape_capsule(radius, height, physics) {
    var shape = new physics.AmmoNamespace.btCapsuleShape(radius, height)
    shape.setMargin(0.1)
    return shape
}

// Provides: ammo_shape_sphere
function ammo_shape_sphere(radius, physics) {
    return new physics.AmmoNamespace.btSphereShape(radius)
}

// Provides: ammo_shape_triangleMesh
// Requires: ammo_vec3_of_babylon
function ammo_shape_triangleMesh(mesh, physics) {

    var AmmoNamespace = physics.AmmoNamespace;
    var physicsMesh = new physics.AmmoNamespace.btTriangleMesh();
    var vertices = mesh.getVerticesData(globalThis.BABYLON.VertexBuffer.PositionKind);
    var indices = mesh.getIndices();

    // TODO: Fix this up
    if (indices.length <= 0) {
        var shape = new physics.AmmoNamespace.btBoxShape(new Ammo.btVector3(0.01, 0.01, 0.01));
        return shape
    }

    for (var i = 0; i < indices.length; i += 3) {
        var i0 = indices[i];
        var i1 = indices[i + 1]
        var i2 = indices[i + 2]


        var v0X = vertices[i0 * 3];
        var v0Y = vertices[(i0 * 3) + 1];
        var v0Z = vertices[(i0 * 3) + 2];
        var v0 = new AmmoNamespace.btVector3(v0X, v0Y, v0Z);

        var v1X = vertices[i1 * 3];
        var v1Y = vertices[(i1 * 3) + 1];
        var v1Z = vertices[(i1 * 3) + 2];
        var v1 = new AmmoNamespace.btVector3(v1X, v1Y, v1Z);

        var v2X = vertices[i2 * 3];
        var v2Y = vertices[(i2 * 3) + 1];
        var v2Z = vertices[(i2 * 3) + 2];
        var v2 = new AmmoNamespace.btVector3(v2X, v2Y, v2Z);

        physicsMesh.addTriangle(v0, v2, v1, true);
        // AmmoNamespace.destroy(v0);
        // AmmoNamespace.destroy(v1);
        // AmmoNamespace.destroy(v2);
    }

    var shape = new physics.AmmoNamespace.btBvhTriangleMeshShape(
        physicsMesh,
        true,
        true
    );

    shape.setMargin(0.1);
    //shape.updateBound();

    //var shape = new physics.AmmoNamespace.btBoxShape(new Ammo.btVector3(1, 1, 1));

    return shape;
}

// Provides: ammo_transform_identity
// Requires: ammo_allocate
function ammo_transform_identity(physics) {
    var xform = ammo_allocate(physics, "btTransform", []);
    xform.setIdentity();
    return xform;
}

// Provides: ammo_transform_fromPositionRotation
// Requires: ammo_vec3_of_babylon
// Requires: ammo_quat_of_babylon
// Requires: ammo_allocate
function ammo_transform_fromPositionRotation(quat, pos, physics) {
    var q = ammo_quat_of_babylon(quat, physics);
    var v = ammo_vec3_of_babylon(pos, physics);
    var xform = ammo_allocate(physics, "btTransform", [q, v]);
    return xform;
}

// Provides: ammo_transform_origin
// Requires: ammo_vec3_to_babylon
function ammo_transform_origin(transform) {
    var origin = transform.getOrigin();
    return ammo_vec3_to_babylon(origin);
}

// Provides: ammo_transform_rotation
// Requires: ammo_quat_to_babylon
function ammo_transform_rotation(transform) {
    var rotation = transform.getRotation();
    return ammo_quat_to_babylon(rotation);
}

// Provides: ammo_motionState_default
function ammo_motionState_default(transform, physics) {
    return new physics.AmmoNamespace.btDefaultMotionState(transform);
}

// RIGIDBODY

// Provides: ammo_rigidBody_create
function ammo_rigidBody_create(id, linearDamping, angularDamping, friction, rollingFriction, mass, motionState, shape, physics) {
    var inertia = null;

    if (mass > 0) {
        inertia = new physics.AmmoNamespace.btVector3(0, 0, 0);
        shape.calculateLocalInertia(mass, inertia)
    }

    var bci = new physics.AmmoNamespace.btRigidBodyConstructionInfo(
        mass,
        motionState,
        shape,
        inertia
    );

    var rigidBody = new physics.AmmoNamespace.btRigidBody(bci);

    rigidBody.setFriction(friction);
    rigidBody.setRollingFriction(rollingFriction);
    rigidBody.setDamping(linearDamping, angularDamping);

    rigidBody.setUserPointer(id);
    return rigidBody;
}

// Provides: ammo_rigidBody_position
// Requires: ammo_vec3_to_babylon
function ammo_rigidBody_position(rigidBody) {
    var origin = rigidBody.getWorldTransform().getOrigin()
    return ammo_vec3_to_babylon(origin)
}

// Provides: ammo_rigidBody_rotation
// Requires: ammo_quat_to_babylon
function ammo_rigidBody_rotation(rigidBody) {
    var rotation = rigidBody.getWorldTransform().getRotation()
    return ammo_quat_to_babylon(rotation)
}

// Provides: ammo_rigidBody_setPositionRotation
// Requires: ammo_vec3_of_babylon, ammo_quat_of_babylon, ammo_destroy
function ammo_rigidBody_setPositionRotation(position, rotation, body, physicsWorld) {
    var transform = body.getWorldTransform();
    var v = ammo_vec3_of_babylon(position, physicsWorld);
    var q = ammo_quat_of_babylon(rotation, physicsWorld)
    transform.setOrigin(v);
    transform.setRotation(q);
    ammo_destroy(physicsWorld, v);
    ammo_destroy(physicsWorld, q);
}

// Provides: ammo_rigidBody_applyForce
// Requires: ammo_vec3_of_babylon
function ammo_rigidBody_applyForce(force, globalPosition, physicsWorld, rigidBody) {
    var aPos = ammo_vec3_of_babylon(globalPosition, physicsWorld);
    var aForce = ammo_vec3_of_babylon(force, physicsWorld);
    var aLocalPos = rigidBody.getCenterOfMassTransform().getOrigin();
    var aRelPos = aPos.op_sub(aLocalPos);

    rigidBody.activate(true);
    rigidBody.applyForce(aForce, aRelPos);
}

// Provides: ammo_rigidBody_applyImpulse
// Requires: ammo_vec3_of_babylon
function ammo_rigidBody_applyImpulse(impulse, globalPosition, physicsWorld, rigidBody) {
    var aPos = ammo_vec3_of_babylon(globalPosition, physicsWorld);
    var aImpulse = ammo_vec3_of_babylon(impulse, physicsWorld);
    var aLocalPos = rigidBody.getCenterOfMassTransform().getOrigin();
    var aRelPos = aPos.op_sub(aLocalPos);

    rigidBody.activate(true);
    rigidBody.applyImpulse(aImpulse, aRelPos);
}

// Provides: ammo_rigidBody_setAngularFactor
function ammo_rigidBody_setAngularFactor(vec, rigidBody) {
    rigidBody.setAngularFactor(vec.x, vec.y, vec.z)
}

// Provides: ammo_rigidBody_setLinearVelocity
// Requires: ammo_vec3_of_babylon
function ammo_rigidBody_setLinearVelocity(vec, physicsWorld, rigidBody) {
    var velocity = ammo_vec3_of_babylon(vec, physicsWorld);
    rigidBody.activate(true);
    rigidBody.setLinearVelocity(velocity);
}

// Provides: ammo_addRigidBody
function ammo_addRigidBody(collisionGroup, collisionMask, body, physics) {
    physics.world.addRigidBody(body, collisionGroup, collisionMask);
}

// Provides: ammo_removeRigidBody
function ammo_removeRigidBody(body, physics) {
    physics.world.removeRigidBody(body);
}

// Provides: js_wrap_option
function js_wrap_option(maybeOption) {
    if (!maybeOption) {
        return 0
    } else {
        return [0, maybeOption]
    }
}

// Provides: ammo_raycastResult_position
function ammo_raycastResult_position(result) {
    return result.hitPoint;
}

// Provides: ammo_raycastResult_normal
function ammo_raycastResult_normal(result) {
    return result.hitNormal;
}

// Provides: ammo_raycastResult_bodyId
function ammo_raycastResult_bodyId(result) {
    return result.bodyId;
}

// Provides: ammo_raycast
// Requires: ammo_vec3_of_babylon, ammo_vec3_to_babylon, js_wrap_option, ammo_deref, ammo_destroy
function ammo_raycast(mask, start, stop, physics) {
    var v0 = ammo_vec3_of_babylon(start, physics);
    var v1 = ammo_vec3_of_babylon(stop, physics);

    var callback = new physics.AmmoNamespace.ClosestRayResultCallback(v0, v1);
    callback.m_collisionFilterMask = mask;

    var result = physics.world.rayTest(v0, v1, callback);

    var hit = callback.hasHit();
    if (!hit) {
        ammo_destroy(physics, v0);
        ammo_destroy(physics, v1);
        ammo_destroy(physics, callback);
        return js_wrap_option(null)
    } else {
        ammo_destroy(physics, v0);
        ammo_destroy(physics, v1);
        var ap = callback.get_m_hitPointWorld();
        var an = callback.get_m_hitNormalWorld();
        var ac = callback.get_m_collisionObject();

        var bodyId = ammo_deref(ac.getUserPointer());
        var hitPoint = ammo_vec3_to_babylon(ap);
        var hitNormal = ammo_vec3_to_babylon(an);
        ammo_destroy(physics, callback);
        return js_wrap_option({ hitPoint: hitPoint, hitNormal: hitNormal, bodyId: bodyId });
    }
};

// Provides: ammo_shapeCast
// Requires: ammo_transform_fromPositionRotation
// Requires: ammo_vec3_of_babylon
// Requires: ammo_vec3_to_babylon
// Requires: ammo_quat_of_babylon
// Requires: js_wrap_option
// Requires: ammo_deref
function ammo_shapeCast(shape, startPosition, startRotation, endPosition, endRotation, physics) {
    var v0 = ammo_vec3_of_babylon(startPosition, physics);
    var v1 = ammo_vec3_of_babylon(endPosition, physics);
    var q0 = ammo_quat_of_babylon(startRotation, physics);
    var q1 = ammo_quat_of_babylon(endRotation, physics);
    var t0 = new physics.AmmoNamespace.btTransform(q0, v0);
    var t1 = new physics.AmmoNamespace.btTransform(q1, v1);

    var callback = new physics.AmmoNamespace.ClosestConvexResultCallback(v0, v1);

    physics.world.convexSweepTest(shape, t0, t1, callback);

    var hit = callback.hasHit();
    if (!hit) {
        physics.AmmoNamespace.destroy(v0)
        physics.AmmoNamespace.destroy(v1)
        physics.AmmoNamespace.destroy(q0)
        physics.AmmoNamespace.destroy(q1)
        physics.AmmoNamespace.destroy(t0)
        physics.AmmoNamespace.destroy(t1)
        physics.AmmoNamespace.destroy(callback)
        return js_wrap_option(null)
    } else {
        physics.AmmoNamespace.destroy(v0)
        physics.AmmoNamespace.destroy(v1)
        physics.AmmoNamespace.destroy(q0)
        physics.AmmoNamespace.destroy(q1)
        physics.AmmoNamespace.destroy(t0)
        physics.AmmoNamespace.destroy(t1)
        // physics.AmmoNamespace.destroy(startTransform)
        // physics.AmmoNamespace.destroy(endTransform)

        var ap = callback.get_m_hitPointWorld();
        var an = callback.get_m_hitNormalWorld();
        var ac = callback.get_m_hitCollisionObject();

        var bodyId = ammo_deref(ac.getUserPointer());
        var hitPoint = ammo_vec3_to_babylon(ap);
        var hitNormal = ammo_vec3_to_babylon(an);

        physics.AmmoNamespace.destroy(callback)
        return js_wrap_option({ hitPoint: hitPoint, hitNormal: hitNormal, bodyId: bodyId });
    }
}
