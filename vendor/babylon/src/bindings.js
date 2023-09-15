// TODO:
// ' Requires: caml_js_to_array
// ' Requires: caml_js_to_string

// Provides: js_wrap_option
function js_wrap_option(maybeOption) {
    if (!maybeOption) {
        return null
    } else {
        return [0, maybeOption]
    }
}

// Provides: js_to_string
// Requires: caml_js_to_string
function js_to_string(obj) {
    return caml_js_to_string(obj.toString())
}

// Provides: js_equals
// Requires: caml_js_to_bool
function js_equals(a, b) {
    if (a.equalsWithEpsilon) {
        return caml_js_to_bool(a.equalsWithEpsilon(b, 0.00001))
    } else if (a.equals) {
        return caml_js_to_bool(a.equals(b))
    } else {
        return caml_js_to_bool(a == b)
    }
};

// AnimationGroup

// Provides: babylon_animationGroup_name
// Requires: caml_js_to_string
function babylon_animationGroup_name(animationGroup) {
    return caml_js_to_string(animationGroup.name)
}

// Provides: babylon_animationGroup_play
function babylon_animationGroup_play(animationGroup) {
    animationGroup.play()
}

// Provides: babylon_animationGroup_stop
function babylon_animationGroup_stop(animationGroup) {
    animationGroup.stop()
}

// Provides: babylon_animationGroup_goToFrame
function babylon_animationGroup_goToFrame(frame, animationGroup) {
    animationGroup.goToFrame(frame)
}

// AssetContainer

// Provides: babylon_assetContainer_entries_nodes
function babylon_assetContainer_entries_nodes(entries) {
    return entries.rootNodes
}

// Provides: babylon_assetContainer_instantiateModelsToScene
// Requires: caml_js_from_string
function babylon_assetContainer_instantiateModelsToScene(prefix, assetContainer) {
    return assetContainer.instantiateModelsToScene();
}

// Provides: babylon_engine_enterPointerLock
function babylon_engine_enterPointerLock(engine) {
    engine.enterPointerlock();
};

// Provides: babylon_engine_getDeltaTime
function babylon_engine_getDeltaTime(engine) {
    return engine.getDeltaTime();
};

// Provides: babylon_engine_isPointerLock
function babylon_engine_isPointerLock(engine) {
    return engine.isPointerLock;
}

// Provides: babylon_engine_null_ctor
function babylon_engine_null_ctor() {
    return new globalThis.BABYLON.NullEngine();
}

// Provides: babylon_debugLayer_isVisible
function babylon_debugLayer_isVisible(debugLayer) {
    return debugLayer.isVisible();
}

// Provides: babylon_debugLayer_hide
function babylon_debugLayer_hide(debugLayer) {
    debugLayer.hide();
}

// Provides: babylon_debugLayer_show
function babylon_debugLayer_show(debugLayer) {
    debugLayer.show();
}

// Provides: babylon_scene_debugLayer
function babylon_scene_debugLayer(scene) {
    return scene.debugLayer
}

// Provides: babylon_scene_dispose
function babylon_scene_dispose(scene) {
    scene.dispose();
}

// Provides: babylon_scene_ctor
function babylon_scene_ctor(engine) {
    var scene = new globalThis.BABYLON.Scene(engine);
    engine._lastCreatedScene = scene;
    return scene
};

// Provides: babylon_scene_registerBeforeRender
function babylon_scene_registerBeforeRender(f, scene) {
    scene.registerBeforeRender(f);

    return function () {
        scene.unregisterBeforeRender(f);
    };
}

// Provides: babylon_scene_setActiveCamera
function babylon_scene_setActiveCamera(camera, scene) {
    scene.activeCamera = camera;
}

// Provides: babylon_scene_setAmbientColor
function babylon_scene_setAmbientColor(color, scene) {
    scene.ambientColor = color;
}

// Provides: babylon_scene_setClearColor
function babylon_scene_setClearColor(color, scene) {
    scene.clearColor = color;
}

// CAMERA
// Provides: babylon_camera_free_ctor
// Requires: caml_js_from_string
function babylon_camera_free_ctor(name, position, scene) {
    var camera = new globalThis.BABYLON.FreeCamera(caml_js_from_string(name), position, scene);
    camera.speed = 0.05;
    camera.minZ = 0.1;
    // TODO: This is overly opinionated, but we don't use Babylon's movement input
    camera.inputs.removeByType("FreeCameraKeyboardMoveInput");
    return camera
}

// Provides: babylon_camera_arcRotate_ctor
// Requires: caml_js_from_string
function babylon_camera_arcRotate_ctor(name, target, scene) {
    var camera = new globalThis.BABYLON.ArcRotateCamera("test", 0.0, 0.0, 10.0,
        target,
        scene
    );
    camera.minZ = 0.1;
    camera.wheelPrecision = 50
    return camera
}

// Provides: babylon_camera_realWorldHeight
function babylon_camera_realWorldHeight(camera) {
    return camera.realWorldHeight
}

// Provides: babylon_camera_set_target
function babylon_camera_set_target(target, camera) {
    camera.setTarget(target);
}

// Provides: babylon_camera_set_inertia
function babylon_camera_set_inertia(inertia, camera) {
    camera.inertia = inertia;
}

// Provides: babylon_camera_set_position
function babylon_camera_set_position(position, camera) {
    camera.position = position
}

// Provides: babylon_camera_rotate
function babylon_camera_rotate(x, y, camera) {
    camera.cameraRotation.x += x;
    camera.cameraRotation.y += y;
}

// Provides: babylon_camera_get_rotation
function babylon_camera_get_rotation(camera) {
    return camera.rotation;
}

// Provides: babylon_camera_attach_control
function babylon_camera_attach_control(canvas, attached, camera) {
    camera.attachControl(canvas, attached)
}

// Provides: babylon_camera_getAbsoluteRotation
function babylon_camera_getAbsoluteRotation(camera) {
    return camera.absoluteRotation;
}

// Provides: babylon_camera_setTransformationFromNonVRCamera
function babylon_camera_setTransformationFromNonVRCamera(reset, srcCamera, vrCamera) {
    vrCamera.setTransformationFromNonVRCamera(srcCamera, reset)
}

// GUI
// Provides: babylon_gui_holographicButton_create
// Requires: caml_js_from_string
function babylon_gui_holographicButton_create(text) {
    return new globalThis.BABYLON.GUI.HolographicButton(caml_js_from_string(text))
}

// Provides: babylon_gui_manager3d_create
function babylon_gui_manager3d_create(scene) {
    return new globalThis.BABYLON.GUI.GUI3DManager(scene)
}

// Provides: babylon_gui_manager3d_addControl
function babylon_gui_manager3d_addControl(control, manager) {
    manager.addControl(control)
}

// Provides: babylon_gui_manager3d_removeControl
function babylon_gui_manager3d_removeControl(control, manager) {
    manager.removeControl(control)
}

// Provides: babylon_gui_setText
// Requires: caml_js_from_string
function babylon_gui_setText(text, control) {
    control.text = caml_js_from_string(text);
}

// MESHBUILDER

// Provides: babylon_meshbuilder_box_create
// Requires: babylon_helper_getLastCreatedScene
function babylon_meshbuilder_box_create(opts) {
    var scene = babylon_helper_getLastCreatedScene()
    var size = opts[1]
    return globalThis.BABYLON.MeshBuilder.CreateBox("box", {
        size: size,
    }, scene)
}

// Provides: babylon_meshbuilder_cylinder_create
// Requires: babylon_helper_getLastCreatedScene
function babylon_meshbuilder_cylinder_create(opts) {
    var scene = babylon_helper_getLastCreatedScene()
    var height = opts[1]
    var diameter = opts[2]
    return globalThis.BABYLON.MeshBuilder.CreateCylinder("cylinder", {
        height: height,
        diameter: diameter,
    }, scene)
}

// Provides: babylon_meshbuilder_ground_create
// Requires: babylon_helper_getLastCreatedScene
function babylon_meshbuilder_ground_create(opts) {
    var scene = babylon_helper_getLastCreatedScene()
    var width = opts[1]
    var height = opts[2];
    return globalThis.BABYLON.MeshBuilder.CreateGround("ground", {
        width: width,
        height: height,
    }, scene)
}

// Provides: babylon_meshbuilder_sphere_create
// Requires: caml_js_from_string, babylon_helper_getLastCreatedScene
function babylon_meshbuilder_sphere_create(name, opts, scene) {
    if (!scene) {
        scene = babylon_helper_getLastCreatedScene()
    }
    var diameter = opts[1]
    return globalThis.BABYLON.MeshBuilder.CreateSphere(caml_js_from_string(name), { diameter: diameter }, scene);
}

// Provides: babylon_helper_getLastCreatedScene
function babylon_helper_getLastCreatedScene() {
    var lastCreatedScene = globalThis.BABYLON.Engine.LastCreatedScene;
    if (lastCreatedScene) {
        return
    }
    // Sometimes, with the null engine, the last created scene isn't stored...
    // so we also manually store it on the engine
    var lastCreatedEngine = globalThis.BABYLON.Engine.LastCreatedEngine;
    if (lastCreatedEngine && lastCreatedEngine._lastCreatedScene) {
        return lastCreatedEngine._lastCreatedScene
    }

    // We were unable to get an engine...
    console.warn("No scene available; this may cause issues.")
    return null
}

// Provides: babylon_meshbuilder_plane_create
// Requires: caml_js_from_string, babylon_helper_getLastCreatedScene
function babylon_meshbuilder_plane_create(name, opts) {
    var scene = babylon_helper_getLastCreatedScene()
    var width = opts[1];
    var height = opts[2];
    return globalThis.BABYLON.MeshBuilder.CreatePlane(caml_js_from_string(name), {
        width: width,
        height: height,
        sideOrientation: globalThis.BABYLON.Mesh.DOUBLESIDE,
    }, scene);
}

// LIGHTS

// Provides: babylon_light_hemispheric_ctor
// Requires: caml_js_from_string
function babylon_light_hemispheric_ctor(name, vector) {
    var light = new globalThis.BABYLON.HemisphericLight(caml_js_from_string(name), vector, null);

    return light;
}

// Provides: babylon_light_setSpecular
function babylon_light_setSpecular(color, light) {
    light.specular = color
}

// Provides: babylon_light_setIntensity
function babylon_light_setIntensity(intensity, light) {
    light.intensity = intensity
}

// Provides: babylon_light_setRange
function babylon_light_setRange(range, light) {
    light.range = range
}

// Provides: babylon_light_setDiffuse
function babylon_light_setDiffuse(color, light) {
    light.diffuse = color
}

// Provides: babylon_light_setGroundColor
function babylon_light_setGroundColor(color, light) {
    light.groundColor = color
}

// Provides: babylon_light_point_ctor
// Requires: caml_js_from_string
function babylon_light_point_ctor(name, vector) {
    var light = new globalThis.BABYLON.PointLight(caml_js_from_string(name), vector, null);
    return light;
}

// Provides: babylon_light_setDirection
function babylon_light_setDirection(direction, light) {
    light.direction = direction;
}

// Provides: babylon_light_spot_ctor
function babylon_light_spot_ctor(angle, exponent, position, direction) {
    var light = new globalThis.BABYLON.SpotLight("spotLight", position, direction, angle, exponent);
    return light;
}

// Provides: babylon_scene_render
function babylon_scene_render(scene) {
    scene.render()
}

// Provides: babylon_dispose
function babylon_dispose(obj) {
    obj.dispose();
}

// Provides: babylon_color3_ctor
function babylon_color3_ctor(red, green, blue) {
    return new globalThis.BABYLON.Color3(red, green, blue);
}

// Provides: babylon_color4_ctor
function babylon_color4_ctor(red, green, blue, alpha) {
    return new globalThis.BABYLON.Color4(red, green, blue, alpha);
}

// Provides: babylon_clone
function babylon_clone(obj) {
    var clone = obj.clone()
    return clone
}

// QUATERNION
// Provides: babylon_quat_ctor
function babylon_quat_ctor(x, y, z, w) {
    var quat = new globalThis.BABYLON.Quaternion(x, y, z, w)
    quat.normalize()
    return quat
}

// Provides: babylon_quat_invert
function babylon_quat_invert(quat) {
    return quat.invert();
}

// Provides: babylon_quat_lookAt
function babylon_quat_lookAt(forward, up) {
    return globalThis.BABYLON.Quaternion.FromLookDirectionLH(forward, up);
}

// Provides: babylon_quat_multiply
function babylon_quat_multiply(q1, q2) {
    return q1.multiply(q2);
}

// Provides: babylon_quat_toEulerAngles
function babylon_quat_toEulerAngles(quat) {
    return quat.toEulerAngles();
}

// Provides: babylon_quat_rotateAxis
function babylon_quat_rotateAxis(vector, angle) {
    return globalThis.BABYLON.Quaternion.RotationAxis(vector, angle)
}

// Provides: babylon_quat_rotateVector
function babylon_quat_rotateVector(vector, quat) {
    var out = new globalThis.BABYLON.Vector3();
    return vector.rotateByQuaternionToRef(quat, out);
}

// SOUND
// Provides: babylon_sound_ambient
// Requires: caml_js_from_string
function babylon_sound_ambient(name, path) {
    return new globalThis.BABYLON.Sound(
        caml_js_from_string(name), caml_js_from_string(path),
        globalThis.BABYLON.EngineStore.LastCreatedScene, null,
        { autoplay: true, loop: false })
}

// Provides: babylon_sound_spatial
// Requires: caml_js_from_string
function babylon_sound_spatial(name, position, path) {
    var sound = new globalThis.BABYLON.Sound(
        caml_js_from_string(name), caml_js_from_string(path),
        globalThis.BABYLON.EngineStore.LastCreatedScene,
        null,
        {
            spatialSound: true,
            autoplay: true,
            loop: false,
        })
    sound.setPosition(position)
    return sound
}

// Provides: babylon_sound_isPaused
function babylon_sound_isPaused(sound) {
    return sound.isPaused()
}

// Provides: babylon_sound_isPlaying
function babylon_sound_isPlaying(sound) {
    return sound.isPlaying
}

// Provides: babylon_sound_play
function babylon_sound_play(sound) {
    return sound.play()
}

// Provides: babylon_sound_setPosition
function babylon_sound_play(position, sound) {
    sound.setPosition(position)
}

// Provides: babylon_sound_isReady
function babylon_sound_isReady(sound) {
    return sound.isReady()
}

// Provides: babylon_sound_dispose
function babylon_sound_dispose(sound) {
    sound.dispose()
}

// VECTOR

// Provides: babylon_vec3_ctor
function babylon_vec3_ctor(x, y, z) {
    return new globalThis.BABYLON.Vector3(x, y, z);
}

// Provides: babylon_vec3_add
function babylon_vec3_add(v0, v1) {
    return v0.add(v1);
}

// Provides: babylon_vec3_cross
function babylon_vec3_cross(v0, v1) {
    return v0.cross(v1);
}

// Provides: babylon_vec3_dot
function babylon_vec3_dot(v0, v1) {
    return globalThis.BABYLON.Vector3.Dot(v0, v1);
}

// Provides: babylon_vec3_multiply
function babylon_vec3_multiply(v0, v1) {
    return v0.multiply(v1);
}

// Provides: babylon_vec3_normalize
function babylon_vec3_normalize(v) {
    return v.normalizeToNew()
}

// Provides: babylon_vec3_scale
function babylon_vec3_scale(m, v) {
    return v.scale(m);
}

// Provides: babylon_vec3_subtract
function babylon_vec3_subtract(v0, v1) {
    return v0.subtract(v1);
}

// Provides: babylon_vec3_length
function babylon_vec3_length(v0) {
    return v0.length()
}

// Provides: babylon_vec3_lengthSquared
function babylon_vec3_lengthSquared(v0) {
    return v0.lengthSquared()
}

// Provides: babylon_vec3_lerp
function babylon_vec3_lerp(start, stop, amt) {
    return globalThis.BABYLON.Vector3.Lerp(start, stop, amt)
}

// Provides: babylon_vec3_getX
function babylon_vec3_getX(vec) {
    return vec.x
}

// Provides: babylon_vec3_getY
function babylon_vec3_getY(vec) {
    return vec.y
}

// Provides: babylon_vec3_getZ
function babylon_vec3_getZ(vec) {
    return vec.z
}

// Provides: babylon_engine_ctor
function babylon_engine_ctor(canvas) {
    var engine = new globalThis.BABYLON.Engine(canvas, true, {
        preserveDrawingBuffer: true,
        stencil: true,
    });
    return engine;
}

// Provides: babylon_engine_runRenderLoop
function babylon_engine_runRenderLoop(f, engine) {
    engine.runRenderLoop(f);

    return function () {
        engine.stopRenderLoop(f);
    };
}

// Provides: babylon_vertexData_ctor 
function babylon_vertexData_ctor() {
    return new globalThis.BABYLON.VertexData();
}

// Provides: babylon_vertexData_setPositions
// Requires: caml_js_from_array
function babylon_vertexData_setPositions(positions, vertexData) {
    vertexData.positions = caml_js_from_array(positions);
}

// Provides: babylon_vertexData_setIndices
// Requires: caml_js_from_array
function babylon_vertexData_setIndices(indices, vertexData) {
    vertexData.indices = caml_js_from_array(indices);
}

// Provides: babylon_vertexData_setUVs
// Requires: caml_js_from_array
function babylon_vertexData_setUVs(uvs, vertexData) {
    vertexData.uvs = caml_js_from_array(uvs);
}

// Provides: babylon_vertexData_applyToMesh
function babylon_vertexData_applyToMesh(mesh, vertexData) {
    vertexData.applyToMesh(mesh)
}

// Provides: babylon_mesh_custom
// Requires: caml_js_from_string, babylon_helper_getLastCreatedScene
function babylon_mesh_custom(name) {
    var scene = babylon_helper_getLastCreatedScene()
    return new globalThis.BABYLON.Mesh(caml_js_from_string(name), scene);
}

// Provides: babylon_mesh_setMaterial
function babylon_mesh_setMaterial(material, mesh) {
    mesh.material = material;
}

// MATRIX

// Provides: babylon_matrix_compose
function babylon_matrix_compose(scale, rotation, translation) {
    return globalThis.BABYLON.Matrix.Compose(scale, rotation, translation);
}

// Provides: babylon_matrix_multiply
function babylon_matrix_multiply(m1, m2) {
    return m1.multiply(m2);
}

// Provides: babylon_matrix_decompose
function babylon_matrix_decompose(m) {
    var scale = new globalThis.BABYLON.Vector3();
    var rotation = new globalThis.BABYLON.Quaternion();
    var translation = new globalThis.BABYLON.Vector3();

    m.decompose(scale, rotation, translation);
    return { scale: scale, rotation: rotation, translation: translation };
}

// Provides: babylon_matrix_transformCoordinates
function babylon_matrix_transformCoordinates(m, v) {
    return BABYLON.Vector3.TransformCoordinates(v, m);
}

// NODE

// Provides: babylon_node_abstract
function babylon_node_abstract(node) {
    return node;
}

// Provides: babylon_node_clone
// Requires: babylon_clone
function babylon_node_clone(node) {
    return babylon_clone(node)
}

// Provides: babylon_node_computeWorldMatrix
function babylon_node_computeWorldMatrix(node) {
    var matrix = node.computeWorldMatrix(true);
    console.log("MATRIX: " + JSON.stringify(matrix));
    return matrix;
}

// Provides: babylon_node_dispose
function babylon_node_dispose(node) {
    node.dispose()
}

// Provides: babylon_node_getChildMeshes
// Requires: caml_js_to_array
function babylon_node_getChildMeshes(node) {
    return caml_js_to_array(node.getChildMeshes(true, null))
}

// Provides: babylon_node_getChildren
// Requires: caml_js_to_array
function babylon_node_getChildren(node) {
    return caml_js_to_array(node.getChildren(null, true))
}

// Provides: babylon_node_getName
// Requires: caml_js_to_string
function babylon_node_getName(node) {
    return caml_js_to_string(node.name)
}

// Provides: babylon_node_isMesh
// Requires: caml_js_to_bool
function babylon_node_isMesh(node) {
    var className = node.getClassName()
    var isMesh = className.toLowerCase() === "mesh" && (node.isAnInstance || node.getTotalVertices() > 0);
    return caml_js_to_bool(isMesh);
}

// Provides: babylon_node_setName
// Requires: caml_js_from_string
function babylon_node_setName(name, node) {
    return node.name = caml_js_from_string(name)
}

// Provides: babylon_node_setEnabled
function babylon_node_setEnabled(enabled, node) {
    node.setEnabled(enabled)
}

// Provides: babylon_node_setParent
function babylon_node_setParent(parent, node) {
    node.parent = parent
}

// Provides: babylon_node_setPosition
function babylon_node_setPosition(position, node) {
    node.position = position
}

// Provides: babylon_node_getPosition
function babylon_node_getPosition(node) {
    return node.position;
}

// Provides: babylon_node_getMeshesByName
// Requires: caml_js_to_array, caml_js_from_string
function babylon_node_getMeshesByName(name, node) {
    var jsName = caml_js_from_string(name)
    var arr = node.getChildMeshes(false, function (n) {
        return n.name === jsName
    });
    return caml_js_to_array(arr)
}

// Provides: babylon_node_setRotation
function babylon_node_setRotation(rotation, node) {
    node.rotation = rotation
}

// Provides: babylon_node_getRotation
function babylon_node_getRotation(node) {
    return node.rotation;
}

// Provides: babylon_node_getScaling
function babylon_node_getScaling(node) {
    return node.scaling;
}

// Provides: babylon_node_setScaling
function babylon_node_setScaling(scaling, node) {
    node.scaling = scaling;
}

// Provides: babylon_node_createTransform
// Requires: caml_js_from_string
function babylon_node_createTransform(name) {
    return new globalThis.BABYLON.TransformNode(caml_js_from_string(name), null);
}

// Provides: babylon_node_setQuaternion
function babylon_node_setQuaternion(quaternion, node) {
    node.rotationQuaternion = quaternion
}

// Provides: babylon_node_getQuaternion
function babylon_node_getQuaternion(node) {
    if (!node.rotationQuaternion) {
        return globalThis.BABYLON.Quaternion.Identity()
    }
    return node.rotationQuaternion
}

// Provides: babylon_mesh_bakeTransformIntoVertices
function babylon_mesh_bakeTransformIntoVertices(matrix, mesh) {
    mesh.bakeTransformIntoVertices(matrix);
}

// Provides: babylon_mesh_refreshBoundingInfo
function babylon_mesh_refreshBoundingInfo(mesh) {
    mesh.refreshBoundingInfo(false /* applySkeleton */, false /* applyMorph */)
}

// Provides: babylon_mesh_setMaterial
function babylon_mesh_setMaterial(material, mesh) {
    mesh.material = material;
}

// Provides: babylon_mesh_setVisibility
function babylon_mesh_setVisibility(visibility, mesh) {
    mesh.visibility = visibility;
}

// Provides: babylon_mesh_getVisibility
function babylon_mesh_getVisibility(mesh) {
    return mesh.visibility;
}

// TEXTURE

// Provides: babylon_texture_ctor
// Requires: caml_js_from_string
function babylon_texture_ctor(invertY, name) {
    var path = caml_js_from_string(name);
    return new globalThis.BABYLON.Texture(path, null, null, invertY);
}

// Provides: babylon_texture_dynamic
// Requires: caml_js_from_string
function babylon_texture_dynamic(name, width, height) {
    var jsName = caml_js_from_string(name);
    var tex = new globalThis.BABYLON.DynamicTexture(jsName, { width: width, height: height })
    var font = "bold 24px monospace";
    tex.drawText("Grass2", 0, 15, font, "green", "white", true, true);
    return tex
}

// Provides: babylon_texture_setUScale
function babylon_texture_setUScale(scale, texture) {
    texture.uScale = scale;
}

// Provides: babylon_texture_setVScale
function babylon_texture_setVScale(scale, texture) {
    texture.vScale = scale;
}

// Provides: babylon_texture_setHasAlpha
function babylon_texture_setHasAlpha(hasAlpha, texture) {
    texture.hasAlpha = hasAlpha;
    //texture.useAlphaFromDiffuseTexture = hasAlpha;
}

// Provides: babylon_texture_setAlpha
function babylon_texture_setAlpha(alpha, texture) {
    texture.alpha = alpha;
}

// MATERIAL

// Provides: babylon_material_freeze
function babylon_material_freeze(mat) {
    return mat.freeze()
}

// Provides: babylon_material_unfreeze
function babylon_material_unfreeze(mat) {
    return mat.unfreeze()
}

// Provides: babylon_material_standard
// Requires: caml_js_from_string
function babylon_material_standard(name) {
    return new globalThis.BABYLON.StandardMaterial(caml_js_from_string(name));
}

// Provides: babylon_material_setDiffuseColor
function babylon_material_setDiffuseColor(color, material) {
    material.diffuseColor = color;
}

// Provides: babylon_material_setSpecularColor
function babylon_material_setSpecularColor(color, material) {
    material.specularColor = color;
}

// Provides: babylon_material_setEmissiveColor
function babylon_material_setEmissiveColor(color, material) {
    material.emissiveColor = color;
}

// Provides: babylon_material_setAmbientColor
function babylon_material_setAmbientColor(color, material) {
    material.ambientColor = color;
}

// Provides: babylon_material_setDiffuseTexture
function babylon_material_setDiffuseTexture(texture, material) {
    material.diffuseTexture = texture;
}

// Provides: babylon_material_setNormalTexture
function babylon_material_setNormalTexture(texture, material) {
    material.normalTexture = texture;
}

// Provides: babylon_material_setSpecularTexture
function babylon_material_setSpecularTexture(texture, material) {
    material.specularTexture = texture;
}

// Provides: babylon_material_setEmissiveTexture
function babylon_material_setEmissiveTexture(texture, material) {
    globalThis.BABYLON.StandardMaterial.EmissiveTextureEnabled = true;
    material.emissiveTexture = texture;
}

// Provides: babylon_material_setBumpTexture
function babylon_material_setBumpTexture(texture, material) {
    material.bumpTexture = texture;
}

// Provides: babylon_material_setWireframe
function babylon_material_setWireframe(wireframe, material) {
    material.wireframe = wireframe;
}

// Provides: babylon_glowLayer_ctor
function babylon_glowLayer_ctor(scene) {
    // TODO:
    var gl = new globalThis.BABYLON.GlowLayer("glow", scene);
    return gl;
}

// Provides: babylon_glowLayer_setIntensity
function babylon_glowLayer_setIntensity(intensity, layer) {
    layer.intensity = intensity;
}

// Provides: babylon_scene_create_default_xr_experience_async
function babylon_scene_create_default_xr_experience_async(scene) {
    var promise = scene.createDefaultXRExperienceAsync({
        optionalFeatures: true,
        useMultiview: true
    });
    // TODO: This is opinionated:
    // Disable the teleportation and pointer-selection since we implement our own solution
    promise.then(function (xrHelper) {
        xrHelper.teleportation.detach();
        xrHelper.pointerSelection.detach();
    })
    return promise
}

// WEBXR

// Provides: babylon_webxr_defaultExperience_baseExperience
function babylon_webxr_defaultExperience_baseExperience(defaultExperience) {
    return defaultExperience.baseExperience
}

// Provides: babylon_webxr_defaultExperience_input
function babylon_webxr_defaultExperience_input(exp) {
    return exp.input
}

// Provides: babylon_webxr_experienceHelper_camera
function babylon_webxr_experienceHelper_camera(exp) {
    return exp.camera
}

// Provides: babylon_webxr_experienceHelper_isInXR
function babylon_webxr_experienceHelper_isInXR(exp) {
    return exp.state != globalThis.BABYLON.WebXRState.NOT_IN_XR
}

// Provides: babylon_webxr_input_controllers
// Requires: caml_js_to_array
function babylon_webxr_input_controllers(exp) {
    return caml_js_to_array(exp.controllers)
}

// Provides: babylon_webxr_controller_uniqueId
// Requires: caml_js_to_string
function babylon_webxr_controller_uniqueId(controller) {
    return caml_js_to_string(controller.uniqueId)
}

// Provides: babylon_motionController_handedness
function babylon_motionController_handedness(controllerComponent) {
    var handedness = controllerComponent.handedness;
    if (handedness == "left") {
        return 1
    } else if (handedness == "right") {
        return 2
    } else {
        return 0
    }
}

// Provides: babylon_controllerAxes_x
function babylon_controllerAxes_x(axes) {
    return axes.x
}

// Provides: babylon_controllerAxes_y
function babylon_controllerAxes_y(axes) {
    return axes.y
}

// Provides: babylon_controllerComponent_axes
function babylon_controllerComponent_axes(controllerComponent) {
    return controllerComponent.axes
}

// Provides: babylon_controllerComponent_id
// Requires: caml_js_to_string
function babylon_controllerComponent_id(controllerComponent) {
    return caml_js_to_string(controllerComponent.id)
}

// Provides: babylon_controllerComponent_pressed
function babylon_controllerComponent_pressed(controllerComponent) {
    return controllerComponent.pressed
}

// Provides: babylon_webxr_controller_grip
function babylon_webxr_controller_grip(controller) {
    return controller.grip
}

// Provides: babylon_motionController_componentIds
// Requires: caml_js_to_string
// Requires: caml_js_to_array
function babylon_motionController_componentIds(controller) {
    var ids = controller.getComponentIds();
    var newMap = ids.map(function (id) {
        return caml_js_to_string(id)
    });
    return caml_js_to_array(newMap)
}

// Provides: babylon_motionController_pulse
function babylon_motionController_pulse(value, duration, motionController) {
    motionController.pulse(value, duration)
}

// Provides: babylon_motionController_component
// Requires: js_wrap_option
function babylon_motionController_component(id, controller) {
    return js_wrap_option(controller.getComponent(id));
}

// Provides: babylon_webxr_controller_motionController
// Requires: js_wrap_option
function babylon_webxr_controller_motionController(controller) {
    return js_wrap_option(controller.motionController)
}

// Provides: babylon_webxr_controller_pointer
function babylon_webxr_controller_pointer(controller) {
    return controller.pointer
}

// SceneLoader

// Provides: babylon_sceneLoader_loadAssetContainerAsync
// Requires: caml_js_from_string
function babylon_sceneLoader_loadAssetContainerAsync(rootUrl, fileName) {
    return globalThis.BABYLON.SceneLoader.LoadAssetContainerAsync(
        caml_js_from_string(rootUrl),
        caml_js_from_string(fileName)
    );
}

// Provides: babylon_sceneLoader_loadResult_meshes
// Requires: caml_js_to_array
function babylon_sceneLoader_loadResult_meshes(loadResult) {
    return caml_js_to_array(loadResult.meshes)
}

// Provides: babylon_sceneLoader_loadResult_skeletons
// Requires: caml_js_to_array
function babylon_sceneLoader_loadResult_skeletons(loadResult) {
    return caml_js_to_array(loadResult.skeletons)
}

// Provides: babylon_sceneLoader_loadResult_animationGroups
// Requires: caml_js_to_array
function babylon_sceneLoader_loadResult_animationGroups(loadResult) {
    return caml_js_to_array(loadResult.animationGroups)
}

// Bone
// Provides: babylon_bone_getLocalPosition
function babylon_bone_getLocalPosition(bone) {
    return bone.getPosition(1);
}

// Provides: babylon_bone_getLocalRotation
function babylon_bone_getLocalRotation(bone) {
    return bone.getRotationQuaternion(1);
}

// Skeleton
// Provides: babylon_skeleton_boneCount
function babylon_skeleton_boneCount(skeleton) {
    return skeleton.bones.length;
}

// Provides: babylon_skeleton_getBoneByIndex
// Requires: js_wrap_option
function babylon_skeleton_getBoneByIndex(idx, skeleton) {
    var len = skeleton.bones.length;
    if (idx < 0 || idx >= len) {
        return js_wrap_option(null)
    } else {
        return js_wrap_option(skeleton.bones[idx])
    }
}

// Provides: js_unwrap_option
function js_unwrap_option(option) {
    if (option.length == 1) {
        return null
    } else {
        return option[1]
    }
}

// Provides: babylon_sceneLoader_importMeshAsync
// Requires: caml_js_from_string, js_unwrap_option
function babylon_sceneLoader_importMeshAsync(rootUrl, fileName, maybeScene) {
    globalThis.BABYLON.OBJFileLoader.OPTIMIZE_WITH_UV = true;
    var promise = globalThis.BABYLON.SceneLoader.ImportMeshAsync(
        // mesh filter "",
        "",
        caml_js_from_string(rootUrl),
        caml_js_from_string(fileName),
        js_unwrap_option(maybeScene));
    return promise;
}

// Particle System

// Provides: babylon_particleSystem_addColorGradient
function babylon_particleSystem_addColorGradient(color, gradient, system) {
    system.addColorGradient(gradient, color)
}

// Provides: babylon_particleSystem_setEmitter
function babylon_particleSystem_setEmitter(emitter, system) {
    system.emitter = emitter;
    system.isLocal = true;
    system.minEmitBox = new globalThis.BABYLON.Vector3(0, 0, 0); // Starting all from
    system.maxEmitBox = new globalThis.BABYLON.Vector3(0, 0, 0); // To...
}

// Provides: babylon_particleSystem_addRampGradient
function babylon_particleSystem_addRampGradient(color, gradient, system) {
    system.addRampGradient(gradient, color)
}

// Provides: babylon_particleSystem_setUseRampGradients
function babylon_particleSystem_setUseRampGradients(use, system) {
    system.useRampGradients = use
}

// Provides: babylon_particleSystem_addColorRemapGradient
function babylon_particleSystem_addColorRemapGradient(min, max, gradient, system) {
    system.addColorRemapGradient(gradient, min, max)
}

// Provides: babylon_particleSystem_createDefault
function babylon_particleSystem_createDefault(count) {
    return new globalThis.BABYLON.ParticleSystem("particles", count);
}

// Provides: babylon_particleSystem_createHemisphericEmitter
function babylon_particleSystem_createHemisphericEmitter(radius, radiusRange, system) {
    return system.createHemisphericEmitter(radius, radiusRange)
}

// Provides: babylon_particleSystem_setEmitRate
function babylon_particleSystem_setEmitRate(emitRate, system) {
    system.emitRate = emitRate
}

// Provides: babylon_particleSystem_setMinSize
function babylon_particleSystem_setMinSize(minSize, system) {
    system.minSize = minSize
}

// Provides: babylon_particleSystem_setMaxSize
function babylon_particleSystem_setMaxSize(maxSize, system) {
    system.maxSize = maxSize
}

// Provides: babylon_particleSystem_setMinLifeTime
function babylon_particleSystem_setMinLifeTime(minLifeTime, system) {
    system.minLifeTime = minLifeTime
}

// Provides: babylon_particleSystem_setMaxLifeTime
function babylon_particleSystem_setMaxLifeTime(maxLifeTime, system) {
    system.maxLifeTime = maxLifeTime
}

// Provides: babylon_particleSystem_setMinEmitPower
function babylon_particleSystem_setMinEmitPower(minEmitPower, system) {
    system.minEmitPower = minEmitPower;
}

// Provides: babylon_particleSystem_setMaxEmitPower
function babylon_particleSystem_setMaxEmitPower(maxEmitPower, system) {
    system.maxEmitPower = maxEmitPower;
}

// Provides: babylon_particleSystem_addLimitVelocityGradient
function babylon_particleSystem_addLimitVelocityGradient(factor, gradient, system) {
    system.addLimitVelocityGradient(gradient, factor)
}

// Provides: babylon_particleSystem_setLimitVelocityDamping
function babylon_particleSystem_setLimitVelocityDamping(damping, system) {
    system.limitVelocityDamping = damping
}

// Provides: babylon_particleSystem_setMinInitialRotation
function babylon_particleSystem_setMinInitialRotation(rotation, system) {
    system.minInitialRotation = rotation;
}

// Provides: babylon_particleSystem_setMaxInitialRotation
function babylon_particleSystem_setMaxInitialRotation(rotation, system) {
    system.maxInitialRotation = rotation;
}

// Provides: babylon_particleSystem_setParticleTexture
function babylon_particleSystem_setParticleTexture(texture, system) {
    system.particleTexture = texture;
    // TODO: Factor to separate function
    system.blendMode = globalThis.BABYLON.ParticleSystem.BLENDMODE_MULTIPLYADD;
}

// Provides: babylon_particleSystem_reset
function babylon_particleSystem_reset(system) {
    system.reset();
}

// Provides: babylon_particleSystem_start
function babylon_particleSystem_start(delay, system) {
    system.start(delay)
}

// Provides: babylon_particleSystem_stop
function babylon_particleSystem_stop(system) {
    system.stop();
}

// Provides: babylon_particleSystem_setTargetStopDuration
function babylon_particleSystem_setTargetStopDuration(duration, system) {
    system.targetStopDuration = duration;
}
