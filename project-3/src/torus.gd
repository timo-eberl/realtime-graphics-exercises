@tool
extends MeshInstance3D

@export var generate_button : bool:
	set(value):
		self.mesh = gen_mesh()
	get():
		return false

func _ready():
	self.mesh = gen_mesh()

func gen_mesh() -> Mesh:
	return create_torus(0.5, 0.25, 64, 32)

func create_torus(radius: float, tube_radius: float, radial_segments: int, tube_segments: int) -> ArrayMesh:
	# calculate vertices
	var vertices: Array[Vector3] = []
	for i in radial_segments:
		for j in tube_segments:
			var theta = (float(i) / radial_segments) * PI * 2  # angle around the main circle
			var phi = (float(j) / tube_segments) * PI * 2  # angle around the tube circle
			
			var v := Vector3( # position on segment
				tube_radius * cos(phi),
				tube_radius * sin(phi),
				0
			)
			
			var m := Transform3D.IDENTITY.translated(Vector3(radius, 0, 0)).rotated(Vector3(0,1,0), theta)
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
	return st.commit()
