package main

import "core:fmt"
import "core:time"
import "core:math"
import "core:runtime"
import "core:math/linalg/glsl"

import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import stbi "vendor:stb/image"

import "camera"

GL_MAJOR_VERSION :: 3
GL_MINOR_VERSION :: 3

cam := camera.Camera{}
fill_polygon := true

resize_window :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	context = runtime.default_context()
	gl.Viewport(0, 0, width, height)
}

mouse_scroll :: proc "c"  (window: glfw.WindowHandle, x_offset, y_offset: f64){
	context = runtime.default_context()
	camera.handle_mouse_scroll(&cam, y_offset)
}

key_is_pressed := make(map[u32]bool)
process_input :: proc(window: glfw.WindowHandle, delta: f64){
	// Keyboard input
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}
	if(glfw.GetKey(window, glfw.KEY_I) == glfw.PRESS && !key_is_pressed[glfw.KEY_I]){
		key_is_pressed[glfw.KEY_I] = true

		fill_polygon = !fill_polygon
		if(fill_polygon){
			gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
		} else {
			gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
		}
	}
	if(glfw.GetKey(window, glfw.KEY_I) == glfw.RELEASE){
		key_is_pressed[glfw.KEY_I] = false
	}
	camera.handle_keyboard(&cam, window, delta)

	// Mouse Input
	camera.handle_mouse_movement(&cam, window)
}

vertices: [144]f32 = {
	// positions      // normals
  -0.5, -0.5, -0.5,  0.0, 0.0, -1.0,
   0.5, -0.5, -0.5,  0.0, 0.0, -1.0,
   0.5,  0.5, -0.5,  0.0, 0.0, -1.0,
  -0.5,  0.5, -0.5,  0.0, 0.0, -1.0,

  -0.5, -0.5,  0.5,  0.0, 0.0, 1.0,
   0.5, -0.5,  0.5,  0.0, 0.0, 1.0,
   0.5,  0.5,  0.5,  0.0, 0.0, 1.0,
	-0.5,  0.5,  0.5,  0.0, 0.0, 1.0,

  -0.5,  0.5,  0.5, -1.0, 0.0, 0.0,
  -0.5,  0.5, -0.5, -1.0, 0.0, 0.0,
  -0.5, -0.5, -0.5, -1.0, 0.0, 0.0,
  -0.5, -0.5,  0.5, -1.0, 0.0, 0.0,

   0.5,  0.5,  0.5,  1.0, 0.0, 0.0,
   0.5,  0.5, -0.5,  1.0, 0.0, 0.0,
   0.5, -0.5, -0.5,  1.0, 0.0, 0.0,
   0.5, -0.5,  0.5,  1.0, 0.0, 0.0,

  -0.5, -0.5, -0.5,  0.0, -1.0, 0.0,
   0.5, -0.5, -0.5,  0.0, -1.0, 0.0,
   0.5, -0.5,  0.5,  0.0, -1.0, 0.0,
  -0.5, -0.5,  0.5,  0.0, -1.0, 0.0,

  -0.5,  0.5, -0.5,  0.0, 1.0, 0.0,
   0.5,  0.5, -0.5,  0.0, 1.0, 0.0,
   0.5,  0.5,  0.5,  0.0, 1.0, 0.0,
  -0.5,  0.5,  0.5,  0.0, 1.0, 0.0,
};

indices : [36]u32 = {
	0,  1,  2,   2,  3,  0,
	4,  5,  6,   6,  7,  4,
	8,  9,  10,  10, 11, 8,
	12, 13, 14,  14, 15, 12,
	16, 17, 18,  18, 19, 16,
	20, 21, 22,  22, 23, 20,
}

cube_pos := glsl.vec3{0.0, 0.0, 0.0}
light_pos := glsl.vec3{1.2, 1.0, 2.0}

main :: proc() {
	// Initialize glfw
	glfw.Init()
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3);
  glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3);
  glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE);

	window := glfw.CreateWindow(800, 600, "Learning", nil, nil)
	if window == nil {
		fmt.printf("Failed to create window\n")
		return
	}
	defer glfw.DestroyWindow(window)

	glfw.MakeContextCurrent(window)
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

	gl.Viewport(0, 0, 800, 600)
	glfw.SetFramebufferSizeCallback(window, resize_window)
	glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)
	glfw.SetScrollCallback(window, mouse_scroll)

	gl.Enable(gl.STENCIL_TEST)

	// Register shaders
	vertex_code := string(#load("vertex.glsl"))
	fragment_code := string(#load("fragment.glsl"))
	shader_program, success := gl.load_shaders_source(vertex_code, fragment_code)
	if !success {
		log := make([^]u8, 512)
		gl.GetProgramInfoLog(shader_program, 512, nil, log)
		fmt.printf("Error linking shader program %s\n", log)
		return
	}
	defer gl.DeleteProgram(shader_program)
	gl.UseProgram(shader_program)

	single_fragment_code := string(#load("single_color.glsl"))
	outline_shader_program, _ := gl.load_shaders_source(vertex_code, single_fragment_code)
	defer gl.DeleteProgram(outline_shader_program)

	light_vertex_code := string(#load("light_vertex.glsl"))
	light_fragment_code := string(#load("light_fragment.glsl"))
	light_shader, _ := gl.load_shaders_source(light_vertex_code, light_fragment_code)
	defer gl.DeleteProgram(light_shader)

	// Create and register buffers
	vbo, vao, ebo: u32
	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)

	defer gl.DeleteVertexArrays(1, &vao)
	defer gl.DeleteBuffers(1, &vbo)
	defer gl.DeleteBuffers(1, &ebo)

	gl.BindVertexArray(vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)

	// Camera
	camera.init_module(window)
	cam.pos = glsl.vec3{0.0, 0.0, 3.0}
	cam.front = glsl.vec3{0.0, 0.0, -1.0}
	cam.up = glsl.vec3{0.0, 1.0, 0.0}
	cam.yaw = -90.0
	cam.pitch = 0
	cam.fov = 45

	currentTime := glfw.GetTime()

	location := gl.GetUniformLocation(shader_program, "objectColor")
	gl.Uniform3fv(location, 1, auto_cast &glsl.vec3{1.0, 0.5, 0.31})
	location = gl.GetUniformLocation(shader_program, "lightColor")
	gl.Uniform3fv(location, 1, auto_cast &glsl.vec3{1.0, 1.0, 1.0})

	for !glfw.WindowShouldClose(window) {
		newTime := glfw.GetTime()
		delta := newTime - currentTime
		currentTime = newTime

		glfw.PollEvents()

		// Input
		process_input(window, delta)

		// Rendering
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT | gl.STENCIL_BUFFER_BIT)

		gl.StencilOp(gl.KEEP, gl.KEEP, gl.REPLACE)
		gl.StencilFunc(gl.ALWAYS, 1, 0xFF)
		gl.StencilMask(0xFF)

		gl.UseProgram(shader_program)

		// Coordinate systems matrices
		light_pos.x = f32(math.cos(currentTime) * 1.2)
		light_pos.z = f32(math.sin(currentTime) * 2.0)
		location = gl.GetUniformLocation(shader_program, "lightPos")
		gl.Uniform3fv(location, 1, auto_cast &light_pos)

		direction: glsl.vec3
		direction.x = math.cos(math.to_radians(cam.yaw)) * math.cos(math.to_radians(cam.pitch))
		direction.y = math.sin(math.to_radians(cam.pitch))
		direction.z = math.sin(math.to_radians(cam.yaw)) * math.cos(math.to_radians(cam.pitch))
		cam.front = glsl.normalize(direction)

		view := glsl.mat4LookAt(cam.pos, cam.pos + cam.front, cam.up)
		projection := glsl.mat4Perspective(math.to_radians_f32(cam.fov), 800/600, 0.1, 1000)

		view_location := gl.GetUniformLocation(shader_program, "view")
		gl.UniformMatrix4fv(view_location, 1, gl.FALSE, auto_cast &view)
		projection_location := gl.GetUniformLocation(shader_program, "projection")
		gl.UniformMatrix4fv(projection_location, 1, gl.FALSE, auto_cast &projection)
		v_pos_location := gl.GetUniformLocation(shader_program, "viewPos")
		gl.Uniform3fv(v_pos_location, 1, auto_cast &cam.pos)

		gl.BindVertexArray(vao)
		defer gl.BindVertexArray(0)

		model := glsl.mat4Translate(cube_pos)
		model_location := gl.GetUniformLocation(shader_program, "model")
		gl.UniformMatrix4fv(model_location, 1, gl.FALSE, auto_cast &model)
		gl.DrawElements(gl.TRIANGLES, 36, gl.UNSIGNED_INT, nil)

		// Stencil for outline
		gl.StencilFunc(gl.NOTEQUAL, 1, 0xFF)
		gl.StencilMask(0x00)
		gl.Disable(gl.DEPTH_TEST)

		gl.UseProgram(outline_shader_program)

		outline_model := glsl.mat4Translate(cube_pos)
		outline_model = glsl.mat4Scale(glsl.vec3{1.02, 1.02, 1.02}) * outline_model

		outline_view_location := gl.GetUniformLocation(outline_shader_program, "view")
		gl.UniformMatrix4fv(outline_view_location, 1, gl.FALSE, auto_cast &view)
		outline_projection_location := gl.GetUniformLocation(outline_shader_program, "projection")
		gl.UniformMatrix4fv(outline_projection_location, 1, gl.FALSE, auto_cast &projection)
		outline_model_location := gl.GetUniformLocation(outline_shader_program, "model")
		gl.UniformMatrix4fv(outline_model_location, 1, gl.FALSE, auto_cast &outline_model)

		gl.DrawElements(gl.TRIANGLES, 36, gl.UNSIGNED_INT, nil)

		gl.StencilMask(0xFF)
		gl.StencilFunc(gl.ALWAYS, 1, 0xFF)
		gl.Enable(gl.DEPTH_TEST)

		gl.UseProgram(light_shader)

		view_location = gl.GetUniformLocation(light_shader, "view")
		gl.UniformMatrix4fv(view_location, 1, gl.FALSE, auto_cast &view)
		projection_location = gl.GetUniformLocation(light_shader, "projection")
		gl.UniformMatrix4fv(projection_location, 1, gl.FALSE, auto_cast &projection)

		model = glsl.mat4Scale(glsl.vec3{0.2, 0.2, 0.2})
		model = glsl.mat4Translate(light_pos) * model
		model_location = gl.GetUniformLocation(light_shader, "model")
		gl.UniformMatrix4fv(model_location, 1, gl.FALSE, auto_cast &model)
		gl.DrawElements(gl.TRIANGLES, 36, gl.UNSIGNED_INT, nil)

		// Swap
		glfw.SwapBuffers(window)

		free_all(context.temp_allocator)
	}

	free_all()
}
