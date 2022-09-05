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

quad_vertices: [24]f32 = {
	// coords // tex
	-1,  1,   0, 1,
	-1, -1,   0, 0,
	 1, -1,   1, 0,
	-1,  1,   0, 1,
	 1, -1,   1, 0,
	 1,  1,   1, 1,
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

	gl.Enable(gl.DEPTH_TEST)

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
	defer gl.DeleteProgram(shader_program);
	gl.UseProgram(shader_program)

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

// Framebuffers
	fbo: u32
	gl.GenFramebuffers(1, &fbo)
	defer gl.DeleteFramebuffers(1, &fbo)
	gl.BindFramebuffer(gl.FRAMEBUFFER, fbo)

	fbo_texture: u32
	gl.GenTextures(1, &fbo_texture)
	gl.BindTexture(gl.TEXTURE_2D, fbo_texture)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, 800, 600, 0, gl.RGB, gl.UNSIGNED_BYTE, nil)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fbo_texture, 0)

	// attach depth and stencil buffers to framebuffer
	rbo: u32
	gl.GenRenderbuffers(1, &rbo)
	gl.BindRenderbuffer(gl.RENDERBUFFER, rbo)
	gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, 800, 600)
	gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
	gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, rbo)

	if(gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE){
		fmt.printf("Framebuffer is not complete\n")
	}

	quad_vbo, quad_vao: u32
	gl.GenVertexArrays(1, &quad_vao)
	gl.GenBuffers(1, &quad_vbo)

	defer gl.DeleteVertexArrays(1, &quad_vao)
	defer gl.DeleteBuffers(1, &quad_vbo)

	gl.BindVertexArray(quad_vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, quad_vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(quad_vertices), &quad_vertices, gl.STATIC_DRAW)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 2 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)

	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

	post_vertex_code := string(#load("postprocess_vertex.glsl"))
	post_fragment_code := string(#load("postprocess_fragment.glsl"))
	post_shader, _ := gl.load_shaders_source(post_vertex_code, post_fragment_code)
	defer gl.DeleteProgram(post_shader)

	for !glfw.WindowShouldClose(window) {
		newTime := glfw.GetTime()
		delta := newTime - currentTime
		currentTime = newTime

		glfw.PollEvents()

		// Input
		process_input(window, delta)

		// Rendering
		gl.Enable(gl.DEPTH_TEST)

		gl.BindFramebuffer(gl.FRAMEBUFFER, fbo)

		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

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

		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		gl.UseProgram(post_shader)
		gl.ClearColor(1.0, 1.0, 1.0, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.BindVertexArray(quad_vao)
		gl.Disable(gl.DEPTH_TEST)
		gl.BindTexture(gl.TEXTURE_2D, fbo_texture)
		gl.DrawArrays(gl.TRIANGLES, 0, 6)

		// Swap
		glfw.SwapBuffers(window)

		free_all(context.temp_allocator)
	}

	free_all()
}
