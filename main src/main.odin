package main

import "base:runtime"
import "core:log"
import pd "playdate"

global_ctx: runtime.Context
display: Display
input: Input


// translation : Vector3 = {0, 0, 0}
// rotation    : Vector3 = {0, 0, 0}
// scale       : Vector3 = {1, 1, 1}

mesh:             Mesh
camera:           Camera
zBuffer: 	      ^ZBuffer
projectionMatrix: Matrix4x4
translation:      Vector3
rotation:         Vector3
scale:            Vector3
renderMode:       i8
intensity:        f32
light:            Light
ambient:          f32

renderModesCount :: i8(4)

@(export)
eventHandler :: proc "c" (pd_api: ^pd.Api, event: pd.System_Event, arg: u32) -> i32 {
	#partial switch event {
	case .Init:
		global_ctx = pd.playdate_context_create(pd_api)
		context = global_ctx
		display = DisplayInit(pd_api.graphics)
		input   = InputInit(pd_api.system)

		mesh             = MakeMesh()
        camera           = MakeCamera({0.0, 0.0, -3.0}, {0.0, 0.0, -1.0})
        zBuffer          = new(ZBuffer)
        projectionMatrix = MakeProjectionMatrix(FOV, SCREEN_WIDTH, SCREEN_HEIGHT, NEAR_PLANE, FAR_PLANE)
        translation      = Vector3{0.0, 0.0, 0.0}
        rotation         = Vector3{0.0, 0.0, 0.0}
        scale            = Vector3{1.0, 1.0, 1.0}
        renderMode       = renderModesCount - 1
        light            = MakeLight({0.0, 1.0, 0.0}, 1.0)
        ambient          = 0.2
        intensity        = 1.0

		pd_api.system.set_update_callback(Update, nil)
	case .Terminate:
		pd.playdate_context_destroy(&global_ctx)
	}
	return 0
}

Update :: proc "c" (user_data: rawptr) -> pd.Update_Result {
	context = global_ctx

    deltaTime := input.sys.get_elapsed_time()
    input.sys.reset_elapsed_time()

    InputUpdate(&input)
    HandleInputs(&input, &translation, &rotation, &scale, &renderMode, renderModesCount, deltaTime)

	translationMatrix := MakeTranslationMatrix(translation.x, translation.y, translation.z)
    rotationMatrix    := MakeRotationMatrix(rotation.x, rotation.y, rotation.z)
    scaleMatrix       := MakeScaleMatrix(scale.x, scale.y, scale.z)
    modelMatrix       := Mat4Mul(translationMatrix, Mat4Mul(rotationMatrix, scaleMatrix))
    viewMatrix        := MakeViewMatrix(camera.position, camera.target)
    viewMatrix         = Mat4Mul(viewMatrix, modelMatrix)
    ApplyTransformations(&mesh.transformedVertices, mesh.vertices, viewMatrix)

	DisplayClear(&display)
	ClearZBuffer(zBuffer)

	switch renderMode {
        case 0: DrawWireFrame(&display, mesh.transformedVertices, mesh.triangles, projectionMatrix, intensity, false)
        case 1: DrawWireFrame(&display, mesh.transformedVertices, mesh.triangles, projectionMatrix, intensity, true)
        case 2: DrawUnlit(&display, mesh.transformedVertices, mesh.triangles, projectionMatrix, intensity, zBuffer)
        case 3: DrawFlatShaded(&display, mesh.transformedVertices, mesh.triangles,projectionMatrix, light, intensity, zBuffer, ambient)
    }

	DisplayPresent(&display)


	return .Update_Display
}

ApplyTransformations :: proc(transformed: ^[]Vector3, original: []Vector3, mat: Matrix4x4) {
    for i in 0..<len(original) {
        transformed[i] = Mat4MultVec3(mat, original[i])
    }
}
