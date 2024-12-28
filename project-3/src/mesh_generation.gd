@tool
extends Node

## SUBDIVIDED SPHERE

func add_subdivided_sphere_to_mesh(mesh: ArrayMesh, subdivision_levels: int):
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	tri (Vector3(  0.0,  1.0,  0.0),
		 Vector3(  0.0,  0.0, -1.0),
		 Vector3(  1.0,  0.0,  0.0), subdivision_levels, st)
	tri (Vector3(  1.0,  0.0,  0.0),
		 Vector3(  0.0,  0.0, -1.0),
		 Vector3(  0.0, -1.0,  0.0), subdivision_levels, st)
	# back left
	tri( Vector3(  0.0,  1.0,  0.0),
		 Vector3( -1.0,  0.0,  0.0),
		 Vector3(  0.0,  0.0, -1.0), subdivision_levels, st)
	tri( Vector3(  0.0,  0.0, -1.0),
		 Vector3( -1.0,  0.0,  0.0),
		 Vector3(  0.0, -1.0,  0.0), subdivision_levels, st)
	# front right
	tri( Vector3(  0.0,  1.0,  0.0),
		 Vector3(  1.0,  0.0,  0.0),
		 Vector3(  0.0,  0.0,  1.0), subdivision_levels, st)
	tri( Vector3(  0.0,  0.0,  1.0),
		 Vector3(  1.0,  0.0,  0.0),
		 Vector3(  0.0, -1.0,  0.0), subdivision_levels, st)
	# front left
	tri( Vector3(  0.0,  1.0,  0.0),
		 Vector3(  0.0,  0.0,  1.0),
		 Vector3( -1.0,  0.0,  0.0), subdivision_levels, st)
	tri( Vector3( -1.0,  0.0,  0.0),
		 Vector3(  0.0,  0.0,  1.0),
		 Vector3(  0.0, -1.0,  0.0), subdivision_levels, st)
	
	st.index()
	st.generate_normals()
	st.commit(mesh)

func tri(v1 : Vector3, v2 : Vector3, v3: Vector3, level: int, st: SurfaceTool) -> void:
	if level > 0: # subdivide further
		var v12 := midpoint(v1, v2)
		var v23 := midpoint(v2, v3)
		var v31 := midpoint(v3, v1)
		tri(v1 , v12, v31, level-1, st)
		tri(v12, v2 , v23, level-1, st)
		tri(v23, v3 , v31, level-1, st)
		tri(v12, v23, v31, level-1, st)
	else: # emit vertices for this triangle
		st.add_vertex(v1)
		st.add_vertex(v2)
		st.add_vertex(v3)

func midpoint(v1 : Vector3, v2: Vector3) -> Vector3:
	return (v1+v2).normalized()

## TORUS

func add_torus_to_mesh(
	mesh: ArrayMesh,
	radius: float, tube_radius: float, radial_segments: int, tube_segments: int,
	height_offset: float
):
	# calculate vertices
	var vertices: Array[Vector3] = []
	for i in radial_segments:
		for j in tube_segments:
			var theta = (float(i) / radial_segments) * TAU # angle around the main circle
			var phi = (float(j) / tube_segments) * TAU # angle around the tube circle
			
			var v := Vector3( # position on segment
				tube_radius * cos(phi),
				tube_radius * sin(phi),
				0
			)
			
			var m := Transform3D.IDENTITY \
				.translated(Vector3(radius, 0, 0)) \
				.rotated(Vector3(0,1,0), theta) \
				.translated(Vector3(0,height_offset,0))
			vertices.append(m * v)
	
	# create triangles
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in radial_segments:
		for j in tube_segments:
			var next_i = (i + 1) % radial_segments
			var next_j = (j + 1) % tube_segments
			
			var idx_current = i * tube_segments + j
			var idx_current_next_i = next_i * tube_segments + j
			var idx_current_next_j = i * tube_segments + next_j
			var idx_current_next_i_j = next_i * tube_segments + next_j
			
			# first triangle
			st.add_vertex(vertices[idx_current])
			st.add_vertex(vertices[idx_current_next_i_j])
			st.add_vertex(vertices[idx_current_next_i])
			# second triangle
			st.add_vertex(vertices[idx_current])
			st.add_vertex(vertices[idx_current_next_j])
			st.add_vertex(vertices[idx_current_next_i_j])
	
	st.index()
	st.generate_normals()
	st.commit(mesh)

## MIRRORED CURVE RING

func add_mirrored_curve_ring_to_mesh(
	mesh: ArrayMesh, curve: Curve2D,
	radius: float, tube_radius: float, radial_segments: int, tube_segments: int,
	repetitions: int, ring_height: float, ring_bend_angle: float, height_offset: float
):
	#for i in 40:
		#print_curve_sample(curve, i / 40.0) # for debugging

	# calculate vertices
	var vertices: Array[Vector3] = []
	for i in radial_segments:
		for j in tube_segments:
			var phi = (float(j) / tube_segments) * TAU # angle around the tube circle
			
			# for some reason the mesh is fucked up if reprtitions is a multiple of 10
			# therefore we add a very small value, so its no longer a multiple of 10 :p
			var f : float = repetitions + 0.0001
			var t := float(i*f) / radial_segments # [0;f]
			var sample = sample_curve_mirrored(curve, t)
			var sp : Vector2 = sample["position"]
			var sr : float = sample["rotation"]
			
			var a = (float(i) / radial_segments) # [0;1]
			# for every repetition, remap to the x values defined by the curve
			a -= fmod(a, 1/f)
			a += sp.x / (2*f)
			var theta = a * TAU # angle around the main circle
			
			var half_ring_v := Vector3(radius,0,0).rotated( Vector3(0,1,0), 1/(2*f) * TAU )
			var half_ring_d := half_ring_v.distance_to(Vector3(radius,0,0))
			# rotates every segment so it aligns with the curves rotation
			# takes the non-uniform scaling of the curve into account
			var m1 := Transform3D.IDENTITY \
				.scaled(Vector3(1,   ring_height/half_ring_d, 1)) \
				.rotated(Vector3(1,0,0), sr) \
				.scaled(Vector3(1,   half_ring_d/ring_height, 1))
			
			# move and rotate the segments so they end up on the path defined by the curve
			var m2 := Transform3D.IDENTITY \
				.translated(Vector3(0, sp.y * ring_height, 0)) \
				.rotated(Vector3(0,0,-1), ring_bend_angle) \
				.translated(Vector3(radius, 0, 0)) \
				.rotated(Vector3(0,1,0), theta) \
				.translated(Vector3(0, height_offset, 0))
			
			var v := Vector3( tube_radius * cos(phi), tube_radius * sin(phi), 0 ) # pos on segment
			# apply m1, make sure distance to segment center is tube_radius, apply m2
			v = m2 * ((m1 * v).normalized() * Vector3(tube_radius,tube_radius,tube_radius))
			vertices.append(v)
	
	# create triangles
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in radial_segments:
		for j in tube_segments:
			var next_i = (i + 1) % radial_segments
			var next_j = (j + 1) % tube_segments
			
			var idx_current = i * tube_segments + j
			var idx_current_next_i = next_i * tube_segments + j
			var idx_current_next_j = i * tube_segments + next_j
			var idx_current_next_i_j = next_i * tube_segments + next_j
			
			# first triangle
			st.add_vertex(vertices[idx_current])
			st.add_vertex(vertices[idx_current_next_i_j])
			st.add_vertex(vertices[idx_current_next_i])
			# second triangle
			st.add_vertex(vertices[idx_current])
			st.add_vertex(vertices[idx_current_next_j])
			st.add_vertex(vertices[idx_current_next_i_j])
	
	st.index()
	st.generate_normals()
	st.commit(mesh)

# position range: [ (-1,0) ; (1,1) ]
# rotation range: [ -PI ; PI ]
func sample_curve_mirrored(curve: Curve2D, t: float) -> Dictionary:
	t = t - floor(t) # the same as fract(t)
	if t < 0.5:
		t = remap(t, 0, 0.5, 0, 1)
		var m := curve.sample_baked_with_rotation(t*curve.get_baked_length(), true)
		var p := m.get_origin() * Vector2(0.001, -0.001) + Vector2(0, 1)
		p.x = remap(p.x, 0, 1, -1, 0)
		return { "position": p, "rotation": -m.get_rotation() }
	else:
		t = remap(t, 0.5, 1, 1, 0)
		var m := curve.sample_baked_with_rotation(t*curve.get_baked_length(), true)
		var p := m.get_origin() * Vector2(0.001, -0.001) + Vector2(0, 1)
		p.x = remap(p.x, 0, 1, 1, 0)
		return { "position": p, "rotation": m.get_rotation() }

func print_curve_sample(curve: Curve2D, t: float):
	var s = sample_curve_mirrored(curve,t)
	print("curve(",t,"): ", s["position"], " rot: ", rad_to_deg(s["rotation"]))

func add_flat_ring_to_mesh(
	mesh: ArrayMesh,
	radius: float, radial_segments: int, height: float, inside: bool, height_offset: float
):
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in radial_segments:
		var first := Vector3(radius, 0, 0)
		var current := first.rotated(Vector3.UP, (float( i ) / radial_segments) * TAU)
		var next    := first.rotated(Vector3.UP, (float(i+1) / radial_segments) * TAU)
		
		var c  := current + Vector3(0,height_offset,0)
		var n  := next    + Vector3(0,height_offset,0)
		var ct := current + Vector3(0,height_offset + height,0)
		var nt := next    + Vector3(0,height_offset + height,0)
		
		st.add_vertex(c)
		if inside:
			st.add_vertex(n)
			st.add_vertex(nt)
		else:
			st.add_vertex(nt)
			st.add_vertex(n)
		
		st.add_vertex(c)
		if inside:
			st.add_vertex(nt)
			st.add_vertex(ct)
		else:
			st.add_vertex(ct)
			st.add_vertex(nt)
	
	st.index()
	st.generate_normals()
	st.commit(mesh)

func add_curve_limited_flat_ring_to_mesh(
	mesh: ArrayMesh, curve: Curve,
	radius: float, radial_segments: int, inside: bool,
	repetitions: int, height_offset: float
):
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in radial_segments:
		var first := Vector3(radius, 0, 0)
		var current := first.rotated(Vector3.UP, (float( i ) / radial_segments) * TAU)
		var next    := first.rotated(Vector3.UP, (float(i+1) / radial_segments) * TAU)
		var current_height := curve.sample( fmod(float( ( i ) * repetitions ) / radial_segments, 1.0) )
		var next_height    := curve.sample( fmod(float( (i+1) * repetitions ) / radial_segments, 1.0) )
		
		var c  := current + Vector3(0,height_offset,0)
		var n  := next    + Vector3(0,height_offset,0)
		var ct := current + Vector3(0,height_offset + current_height,0)
		var nt := next    + Vector3(0,height_offset + next_height,0)
		
		st.add_vertex(c)
		if inside:
			st.add_vertex(n)
			st.add_vertex(nt)
		else:
			st.add_vertex(nt)
			st.add_vertex(n)
		
		st.add_vertex(c)
		if inside:
			st.add_vertex(nt)
			st.add_vertex(ct)
		else:
			st.add_vertex(ct)
			st.add_vertex(nt)
	
	st.index()
	st.generate_normals()
	st.commit(mesh)

func add_gem_to_mesh(mesh: ArrayMesh, segments: int, radius: float):
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in segments:
		var phi_curr = (float(i-0.5) / segments) * TAU # angle around the "circle"
		var phi_next = (float(i+0.5) / segments) * TAU # angle around the "circle"
		
		var vc := Vector3(radius * cos(phi_curr), radius * sin(phi_curr), 0)
		var vn := Vector3(radius * cos(phi_next), radius * sin(phi_next), 0)
		
		# front
		st.set_smooth_group(-1) # flat shading
		st.add_vertex(Vector3(0,0,radius))
		st.set_smooth_group(-1)
		st.add_vertex(vn)
		st.set_smooth_group(-1)
		st.add_vertex(vc)
		
		# back
		st.set_smooth_group(-1)
		st.add_vertex(Vector3(0,0,-radius))
		st.set_smooth_group(-1)
		st.add_vertex(vc)
		st.set_smooth_group(-1)
		st.add_vertex(vn)
	
	st.index()
	st.generate_normals()
	st.commit(mesh)
