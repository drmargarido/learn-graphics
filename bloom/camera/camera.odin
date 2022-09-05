package camera

import "core:math/linalg/glsl"
import glfw "vendor:glfw"

MOUSE_SENSITIVITY :: 0.1
KEYBOARD_SENSITIVITY :: 2.5

mouse_pos: glsl.vec2

Camera :: struct {
	pos: glsl.vec3,
	front: glsl.vec3,
	up: glsl.vec3,
	yaw: f32,
	pitch: f32,
	fov: f32,
}

init_module :: proc(window: glfw.WindowHandle){
	mx, my := glfw.GetCursorPos(window)
	mouse_pos.x = f32(mx)
	mouse_pos.y = f32(my)
}

handle_mouse_scroll :: proc(camera: ^Camera, y_offset: f64){
	camera.fov = glsl.clamp_f32(camera.fov - f32(y_offset), 1.0, 90.0)
}

handle_mouse_movement :: proc(camera: ^Camera, window: glfw.WindowHandle){
	new_x, new_y := glfw.GetCursorPos(window)
	offset_x := (f32(new_x) - mouse_pos.x) * MOUSE_SENSITIVITY
	offset_y := (mouse_pos.y - f32(new_y)) * MOUSE_SENSITIVITY // reversed since y coordinates are from bottom to top

	camera.yaw = camera.yaw + offset_x
	camera.pitch = glsl.clamp_f32(camera.pitch + offset_y, -89.0, 89.0)

	mouse_pos.x, mouse_pos.y = f32(new_x), f32(new_y)
}

handle_keyboard :: proc(camera: ^Camera, window: glfw.WindowHandle, delta: f64){
	speed : f32 = KEYBOARD_SENSITIVITY * f32(delta)

	if(glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS){
		camera.pos += speed * camera.front
	}
	if(glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS){
		camera.pos -= speed * camera.front
	}
	if(glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS){
		// cross between front and up to get the right vector
		camera.pos -= glsl.normalize(glsl.cross(camera.front, camera.up)) * speed
	}
	if(glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS){
		camera.pos += glsl.normalize(glsl.cross(camera.front, camera.up)) * speed
	}
}
