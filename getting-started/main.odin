package main

import "core:fmt"
import "core:time"
import "core:math"
import "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import stbi "vendor:stb/image"

GL_MAJOR_VERSION :: 3
GL_MINOR_VERSION :: 3

MOUSE_SENSITIVITY :: 0.1

Texture :: struct {
	id: u32,
	data: [^]byte,
	width: i32,
	height: i32,
	nr_channels: i32,
}

Camera :: struct {
	pos: glsl.vec3,
	front: glsl.vec3,
	up: glsl.vec3,
	yaw: f32,
	pitch: f32,
	fov: f32,
}

cam := Camera{}
fill_polygon := true

resize_window :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

mouse_scroll :: proc "c"  (window: glfw.WindowHandle, x_offset, y_offset: f64){
	cam.fov = glsl.clamp_f32(cam.fov - f32(y_offset), 1.0, 90.0)
}

key_is_pressed := make(map[u32]bool)
mouse_pos: glsl.vec2
process_input :: proc(window: glfw.WindowHandle, delta: f64){
	camera_speed : f32 = 2.5 * f32(delta)

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
	if(glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS){
		cam.pos += camera_speed * cam.front
	}
	if(glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS){
		cam.pos -= camera_speed * cam.front
	}
	if(glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS){
		// cross between front and up to get the right vector
		cam.pos -= glsl.normalize(glsl.cross(cam.front, cam.up)) * camera_speed
	}
	if(glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS){
		cam.pos += glsl.normalize(glsl.cross(cam.front, cam.up)) * camera_speed
	}

	// Mouse Input
	new_x, new_y := glfw.GetCursorPos(window)
	offset_x := (f32(new_x) - mouse_pos.x) * MOUSE_SENSITIVITY
	offset_y := (mouse_pos.y - f32(new_y)) * MOUSE_SENSITIVITY // reversed since y coordinates are from bottom to top
	cam.yaw = cam.yaw + offset_x
	cam.pitch = glsl.clamp_f32(cam.pitch + offset_y, -89.0, 89.0)
	mouse_pos.x, mouse_pos.y = f32(new_x), f32(new_y)
}

vertices: [80]f32 = {
	// positions       // tex coords
  -0.5, -0.5, -0.5,  0.0, 0.0,
   0.5, -0.5, -0.5,  1.0, 0.0,
   0.5,  0.5, -0.5,  1.0, 1.0,
  -0.5,  0.5, -0.5,  0.0, 1.0,

  -0.5, -0.5,  0.5,  0.0, 0.0,
   0.5, -0.5,  0.5,  1.0, 0.0,
   0.5,  0.5,  0.5,  1.0, 1.0,
	-0.5,  0.5,  0.5,  0.0, 1.0,

  -0.5,  0.5,  0.5,  1.0, 0.0,
  -0.5,  0.5, -0.5,  1.0, 1.0,
  -0.5, -0.5, -0.5,  0.0, 1.0,

   0.5,  0.5,  0.5,  1.0, 0.0,
   0.5, -0.5, -0.5,  0.0, 1.0,
   0.5, -0.5,  0.5,  0.0, 0.0,

   0.5, -0.5, -0.5,  1.0, 1.0,

  -0.5,  0.5,  0.5,  0.0, 0.0,
};

indices : [36]u32 = {
	0,  1,  2,   2,  3,  0,
	4,  5,  6,   6,  7,  4,
	8,  9,  10,  10, 4,  8,
	11, 2,  12,  12, 13, 11,
	10, 14, 5,   5,  4,  10,
	3,  2,  11,  11, 15, 3,
}

cubes : [10]glsl.vec3 = {
	glsl.vec3{ 0.0,  0.0,  0.0},
  glsl.vec3{ 2.0,  5.0, -15.0},
  glsl.vec3{-1.5, -2.2, -2.5},
  glsl.vec3{-3.8, -2.0, -12.3},
  glsl.vec3{ 2.4, -0.4, -3.5},
  glsl.vec3{-1.7,  3.0, -7.5},
  glsl.vec3{ 1.3, -2.0, -2.5},
  glsl.vec3{ 1.5,  2.0, -2.5},
  glsl.vec3{ 1.5,  0.2, -1.5},
  glsl.vec3{-1.3,  1.0, -1.5}
}

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
	glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_HIDDEN)
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

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)

	// Load Textures
	stbi.set_flip_vertically_on_load(1)

	texture1, texture2: Texture
	// Texture1
	gl.GenTextures(1, &texture1.id)
	gl.BindTexture(gl.TEXTURE_2D, texture1.id)

	gl.GenTextures(1, &texture1.id)
	gl.BindTexture(gl.TEXTURE_2D, texture1.id)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST_MIPMAP_NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

	texture1.data = stbi.load("container.jpg", &texture1.width, &texture1.height, &texture1.nr_channels, 0)
	defer stbi.image_free(texture1.data)

	if texture1.data != nil {
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, texture1.width, texture1.height, 0, gl.RGB, gl.UNSIGNED_BYTE, texture1.data)
		gl.GenerateMipmap(gl.TEXTURE_2D)
	} else {
		fmt.printf("Failed to load the texture\n")
	}

	// Texture2
	gl.GenTextures(1, &texture2.id)
	gl.BindTexture(gl.TEXTURE_2D, texture2.id)

	gl.GenTextures(1, &texture2.id)
	gl.BindTexture(gl.TEXTURE_2D, texture2.id)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST_MIPMAP_NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

	texture2.data = stbi.load("awesomeface.png", &texture2.width, &texture2.height, &texture2.nr_channels, 0)
	defer stbi.image_free(texture2.data)

	if texture2.data != nil {
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, texture2.width, texture2.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, texture2.data)
		gl.GenerateMipmap(gl.TEXTURE_2D)
	} else {
		fmt.printf("Failed to load the texture\n")
	}

	gl.Uniform1i(gl.GetUniformLocation(shader_program, "texture1"), 0)
	gl.Uniform1i(gl.GetUniformLocation(shader_program, "texture2"), 1)

	// Camera
	cam.pos = glsl.vec3{0.0, 0.0, 3.0}
	cam.front = glsl.vec3{0.0, 0.0, -1.0}
	cam.up = glsl.vec3{0.0, 1.0, 0.0}
	cam.yaw = -90.0
	cam.pitch = 0
	cam.fov = 45

	currentTime := glfw.GetTime()
	mx, my := glfw.GetCursorPos(window)
	mouse_pos.x = f32(mx)
	mouse_pos.y = f32(my)

	for !glfw.WindowShouldClose(window) {
		newTime := glfw.GetTime()
		delta := newTime - currentTime
		currentTime = newTime

		glfw.PollEvents()

		// Input
		process_input(window, delta)

		// Rendering
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.UseProgram(shader_program)

		// Coordinate systems matrices
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

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, texture1.id)
		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, texture2.id)
		gl.BindVertexArray(vao)
		defer gl.BindVertexArray(0)

		for i := 0; i < 10; i += 1 {
			model := glsl.mat4Rotate(glsl.vec3{0.5, 1.0, 0.0}, f32(glfw.GetTime()) + math.to_radians_f32(20.0 * f32(i)))
			model = glsl.mat4Translate(cubes[i]) * model
			model_location := gl.GetUniformLocation(shader_program, "model")
			gl.UniformMatrix4fv(model_location, 1, gl.FALSE, auto_cast &model)
			gl.DrawElements(gl.TRIANGLES, 36, gl.UNSIGNED_INT, nil)
		}

		// Swap
		glfw.SwapBuffers(window)

		free_all(context.temp_allocator)
	}

	free_all()
}
