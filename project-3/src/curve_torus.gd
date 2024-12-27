@tool
extends MeshInstance3D

@export var generate_button : bool:
	set(value):
		self.mesh = gen_mesh()
	get():
		return false
@export_range(0,50) var tip_count := 8
@export_range(0.0,2.0) var tip_height := 0.4
@export var path : Path2D

@export var radius: float = 0.5
@export var tube_radius: float = 0.02
@export var radial_segments: int = 1024
@export var tube_segments: int = 16

func _ready():
	self.mesh = gen_mesh()

# position range: [ (-1,0) ; (1,1) ]
# rotation range: [ -PI ; PI ]
func sample_curve(t) -> Dictionary:
	t = t - floor(t) # the same as fract(t)
	if t < 0.5:
		t = remap(t, 0, 0.5, 0, 1)
		var m := path.curve.sample_baked_with_rotation(t*path.curve.get_baked_length(), true)
		var p := m.get_origin() * Vector2(0.001, -0.001) + Vector2(0, 1)
		p.x = remap(p.x, 0, 1, -1, 0)
		return { "position": p, "rotation": -m.get_rotation() }
	else:
		t = remap(t, 0.5, 1, 1, 0)
		var m := path.curve.sample_baked_with_rotation(t*path.curve.get_baked_length(), true)
		var p := m.get_origin() * Vector2(0.001, -0.001) + Vector2(0, 1)
		p.x = remap(p.x, 0, 1, 1, 0)
		return { "position": p, "rotation": m.get_rotation() }

func print_sample(t):
	print("curve(",t,"): ", sample_curve(t)["position"], " rot: ", rad_to_deg(sample_curve(t)["rotation"]))

func gen_mesh() -> Mesh:
	#for i in 40:
		#print_sample(i / 40.0)
	return create_curve_torus()

func create_curve_torus() -> ArrayMesh:
	# calculate vertices
	var vertices: Array[Vector3] = []
	for i in radial_segments:
		for j in tube_segments:
			var phi = (float(j) / tube_segments) * TAU # angle around the tube circle
			
			var f : float = tip_count
			var t := float(i*f) / radial_segments # [0;f]
			var sample = sample_curve(t)
			var sp : Vector2 = sample["position"]
			var sr : float = sample["rotation"]
			
			var a = (float(i) / radial_segments) # [0;1]
			# for every tip, remap to the x values defined by the curve
			a -= fmod(a, 1/f)
			a += sp.x / (2*f)
			var theta = a * TAU # angle around the main circle
			
			var half_tip_v := Vector3(radius,0,0).rotated( Vector3(0,1,0), 1/(2*f) * TAU )
			var half_tip_d := half_tip_v.distance_to(Vector3(radius,0,0))
			# rotates every segment so it aligns with the curves rotation
			# takes the non-uniform scaling of the curve into account
			var m1 := Transform3D.IDENTITY \
				.scaled(Vector3(1,   tip_height/half_tip_d, 1)) \
				.rotated(Vector3(1,0,0), sr) \
				.scaled(Vector3(1,   half_tip_d/tip_height, 1))
			
			# move and rotate the segments so they end up on the path defined by the curve
			var m2 := Transform3D.IDENTITY \
				.translated(Vector3(radius, 0, 0)) \
				.translated(Vector3(0, sp.y * tip_height, 0)) \
				.rotated(Vector3(0,1,0), theta)
			
			# position on segment
			var v := Vector3( tube_radius * cos(phi), tube_radius * sin(phi), 0 )
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
	return st.commit()
