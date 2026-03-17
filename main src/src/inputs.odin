package main

import pd "playdate"


Input :: struct {
    sys:      ^pd.Api_System_Procs,
    current:  pd.Buttons,
    pushed:   pd.Buttons,
    released: pd.Buttons,
}
InputInit :: proc(sys: ^pd.Api_System_Procs) -> Input {
    return Input{sys = sys}
}

// Call once at the top of each frame to snapshot button state.
InputUpdate :: proc(i: ^Input) {
    i.sys.get_button_state(&i.current, &i.pushed, &i.released)
}
// Is the button held down this frame?
InputHeld :: proc(i: ^Input, button: pd.Button) -> bool {
    return button in i.current
}
// Was the button just pressed this frame?
InputJustPressed :: proc(i: ^Input, button: pd.Button) -> bool {
    return button in i.pushed
}
// Was the button just released this frame?
InputJustReleased :: proc(i: ^Input, button: pd.Button) -> bool {
    return button in i.released
}

HandleInputs :: proc (input: ^Input, translation, rotation: ^Vector3, scale: ^Vector3, renderMode: ^i8, renderModesCount: i8, deltaTime: f32) {
	step        : f32 = (0.25 if InputHeld(input, .A) else 1.0) * deltaTime
    angularStep : f32 = (12.0 if InputHeld(input, .A) else 48.0) * deltaTime

    // Translation - D-pad moves on X/Y
    if InputHeld(input, .Left)  { translation.x -= step }
    if InputHeld(input, .Right) { translation.x += step }
    if InputHeld(input, .Up)    { translation.y -= step }
    if InputHeld(input, .Down)  { translation.y += step }

    // Rotation - B + D-pad rotates X/Y
    if InputHeld(input, .B) {
        if InputHeld(input, .Left)  { rotation.y -= angularStep }
        if InputHeld(input, .Right) { rotation.y += angularStep }
        if InputHeld(input, .Up)    { rotation.x -= angularStep }
        if InputHeld(input, .Down)  { rotation.x += angularStep }
    }

    // Crank scales uniformly - ignored when docked
    if input.sys.is_crank_docked() == 0 {
        crankDelta := input.sys.get_crank_change()
        crankScale := crankDelta * (0.01 if InputHeld(input, .A) else 0.05)
        scale^ += Vector3{crankScale, crankScale, crankScale}
    }

    // Cycle render mode with just-pressed A+B together
    if InputJustPressed(input, .B) && InputHeld(input, .A) {
        renderMode^ = (renderMode^ + 1) % renderModesCount
    }
}
