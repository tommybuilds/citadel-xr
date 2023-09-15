#define STUB(name) \
  void name() { return; }

// TODO: Will these wire up directly to BabylonNative?
// https://github.com/BabylonJS/BabylonNative
STUB(js_to_string)
STUB(js_equals)

STUB(babylon_dispose);
STUB(babylon_engine_ctor);
STUB(babylon_engine_enterPointerLock);
STUB(babylon_engine_getDeltaTime);
STUB(babylon_engine_isPointerLock);
STUB(babylon_engine_null_ctor);
STUB(babylon_engine_runRenderLoop);

STUB(babylon_vec3_ctor);
STUB(babylon_vec3_add);
STUB(babylon_vec3_cross);
STUB(babylon_vec3_dot);
STUB(babylon_vec3_multiply);
STUB(babylon_vec3_length);
STUB(babylon_vec3_lengthSquared);
STUB(babylon_vec3_lerp);
STUB(babylon_vec3_normalize);
STUB(babylon_vec3_scale);
STUB(babylon_vec3_subtract);
STUB(babylon_vec3_getX);
STUB(babylon_vec3_getY);
STUB(babylon_vec3_getZ);

// ANIMATION GROUP
STUB(babylon_animationGroup_name)
STUB(babylon_animationGroup_play)
STUB(babylon_animationGroup_stop)
STUB(babylon_animationGroup_goToFrame)

// SCENE

STUB(babylon_scene_ctor);
STUB(babylon_scene_dispose);
STUB(babylon_scene_render);
STUB(babylon_scene_debugLayer);
STUB(babylon_scene_registerBeforeRender);
STUB(babylon_scene_create_default_xr_experience_async);
STUB(babylon_scene_setActiveCamera);
STUB(babylon_scene_setAmbientColor);
STUB(babylon_scene_setClearColor);

STUB(babylon_debugLayer_isVisible);
STUB(babylon_debugLayer_hide);
STUB(babylon_debugLayer_show);
STUB(babylon_light_hemispheric_ctor);
STUB(babylon_light_point_ctor);
STUB(babylon_light_setDirection);
STUB(babylon_light_setIntensity);
STUB(babylon_light_setRange);
STUB(babylon_light_setSpecular);
STUB(babylon_light_setDiffuse);
STUB(babylon_light_setGroundColor);
STUB(babylon_light_spot_ctor);
STUB(babylon_color3_ctor);
STUB(babylon_color4_ctor);

// MESHBUILDER
STUB(babylon_meshbuilder_box_create);
STUB(babylon_meshbuilder_cylinder_create);
STUB(babylon_meshbuilder_ground_create);
STUB(babylon_meshbuilder_plane_create);
STUB(babylon_meshbuilder_sphere_create);

// ASSET CONTAINER
STUB(babylon_assetContainer_entries_nodes);
STUB(babylon_assetContainer_instantiateModelsToScene);

STUB(babylon_camera_arcRotate_ctor);
STUB(babylon_camera_free_ctor);
STUB(babylon_camera_attach_control);
STUB(babylon_camera_set_target);
STUB(babylon_camera_set_inertia);
STUB(babylon_camera_setTransformationFromNonVRCamera);
STUB(babylon_camera_set_position);
STUB(babylon_camera_realWorldHeight);
STUB(babylon_camera_rotate);
STUB(babylon_camera_getAbsoluteRotation);

// GUI
STUB(babylon_gui_holographicButton_create)
STUB(babylon_gui_manager3d_create)
STUB(babylon_gui_manager3d_removeControl)
STUB(babylon_gui_manager3d_addControl)
STUB(babylon_gui_setText)

// MESH
STUB(babylon_mesh_bakeTransformIntoVertices);
STUB(babylon_mesh_custom);
STUB(babylon_mesh_setMaterial);
STUB(babylon_mesh_getVisibility);
STUB(babylon_mesh_refreshBoundingInfo);
STUB(babylon_mesh_setVisibility);

// NODE
STUB(babylon_node_abstract);
STUB(babylon_node_clone);
STUB(babylon_node_dispose);
STUB(babylon_node_getChildren);
STUB(babylon_node_getChildMeshes);
STUB(babylon_node_getMeshesByName);
STUB(babylon_node_getName);
STUB(babylon_node_isMesh);
STUB(babylon_node_setName);
STUB(babylon_node_getPosition);
STUB(babylon_node_setEnabled);
STUB(babylon_node_setParent);
STUB(babylon_node_setPosition);
STUB(babylon_node_computeWorldMatrix);
STUB(babylon_node_createTransform);
STUB(babylon_node_getQuaternion);
STUB(babylon_node_setQuaternion);
STUB(babylon_node_getRotation);
STUB(babylon_node_setRotation)
STUB(babylon_node_getScaling)
STUB(babylon_node_setScaling)

// MATERIAL

STUB(babylon_material_freeze);
STUB(babylon_material_unfreeze);
STUB(babylon_material_standard);
STUB(babylon_material_setDiffuseColor);
STUB(babylon_material_setSpecularColor);
STUB(babylon_material_setEmissiveColor);
STUB(babylon_material_setAmbientColor);
STUB(babylon_material_setDiffuseTexture);
STUB(babylon_material_setNormalTexture);
STUB(babylon_material_setSpecularTexture);
STUB(babylon_material_setEmissiveTexture);
STUB(babylon_material_setBumpTexture);
STUB(babylon_material_setWireframe);

// MATRIX
STUB(babylon_matrix_compose);
STUB(babylon_matrix_decompose);
STUB(babylon_matrix_multiply);
STUB(babylon_matrix_transformCoordinates);

// PARTICLE SYSTEM

STUB(babylon_particleSystem_addColorGradient);
STUB(babylon_particleSystem_addRampGradient);
STUB(babylon_particleSystem_addColorRemapGradient);
STUB(babylon_particleSystem_setUseRampGradients);
STUB(babylon_particleSystem_createDefault);
STUB(babylon_particleSystem_createHemisphericEmitter);
STUB(babylon_particleSystem_setEmitter);
STUB(babylon_particleSystem_setEmitRate);
STUB(babylon_particleSystem_setMinSize);
STUB(babylon_particleSystem_setMaxSize);
STUB(babylon_particleSystem_setMinLifeTime);
STUB(babylon_particleSystem_setMaxLifeTime);
STUB(babylon_particleSystem_setMinEmitPower);
STUB(babylon_particleSystem_setMaxEmitPower);
STUB(babylon_particleSystem_addLimitVelocityGradient);
STUB(babylon_particleSystem_setLimitVelocityDamping);
STUB(babylon_particleSystem_setMinInitialRotation);
STUB(babylon_particleSystem_setMaxInitialRotation);
STUB(babylon_particleSystem_setParticleTexture);
STUB(babylon_particleSystem_reset);
STUB(babylon_particleSystem_start);
STUB(babylon_particleSystem_stop);
STUB(babylon_particleSystem_setTargetStopDuration);

// SOUND
STUB(babylon_sound_ambient)
STUB(babylon_sound_spatial)
STUB(babylon_sound_isPaused)
STUB(babylon_sound_isPlaying)
STUB(babylon_sound_isReady)
STUB(babylon_sound_play)
STUB(babylon_sound_setPosition)
STUB(babylon_sound_dispose)

// TEXTURE

STUB(babylon_texture_ctor);
STUB(babylon_texture_dynamic);
STUB(babylon_texture_setUScale);
STUB(babylon_texture_setVScale);
STUB(babylon_texture_setHasAlpha);
STUB(babylon_texture_setAlpha);

STUB(babylon_glowLayer_ctor);
STUB(babylon_glowLayer_setIntensity);

// QUATERNION
STUB(babylon_clone)
STUB(babylon_quat_ctor)
STUB(babylon_quat_invert)
STUB(babylon_quat_lookAt)
STUB(babylon_quat_multiply)
STUB(babylon_quat_toEulerAngles)
STUB(babylon_quat_rotateAxis)
STUB(babylon_quat_rotateVector)

STUB(babylon_vertexData_ctor);
STUB(babylon_vertexData_applyToMesh);
STUB(babylon_vertexData_setPositions);
STUB(babylon_vertexData_setIndices);
STUB(babylon_vertexData_setUVs);

STUB(babylon_webxrexperiencehelper_create_async);
STUB(babylon_webxrexperiencehelper_isInXR);

// SCENELOADER

STUB(babylon_sceneLoader_loadResult_animationGroups)
STUB(babylon_sceneLoader_loadResult_meshes)
STUB(babylon_sceneLoader_loadResult_skeletons)
STUB(babylon_sceneLoader_importMeshAsync)
STUB(babylon_sceneLoader_loadAssetContainerAsync)

// BONE
STUB(babylon_bone_getLocalPosition)
STUB(babylon_bone_getLocalRotation)

// SKELETON
STUB(babylon_skeleton_boneCount)
STUB(babylon_skeleton_getBoneByIndex)

// WEBXR
STUB(babylon_controllerAxes_x)
STUB(babylon_controllerAxes_y)

STUB(babylon_controllerComponent_axes)
STUB(babylon_controllerComponent_id)
STUB(babylon_controllerComponent_pressed)

STUB(babylon_motionController_componentIds)
STUB(babylon_motionController_handedness)
STUB(babylon_motionController_component)
STUB(babylon_motionController_pulse)

STUB(babylon_webxr_controller_grip)
STUB(babylon_webxr_controller_motionController)
STUB(babylon_webxr_controller_pointer)
STUB(babylon_webxr_controller_uniqueId)

STUB(babylon_webxr_input_controllers)
STUB(babylon_webxr_experienceHelper_input)
STUB(babylon_webxr_experienceHelper_camera)
STUB(babylon_webxr_experienceHelper_isInXR)
STUB(babylon_webxr_defaultExperience_baseExperience)
STUB(babylon_webxr_defaultExperience_input)
