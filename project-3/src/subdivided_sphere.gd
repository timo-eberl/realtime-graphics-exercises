@tool
extends MeshInstance3D

@export_range(0,5) var subdivision_levels := 1:
	set(value):
		subdivision_levels = value
		redraw_sphere()

var st : SurfaceTool

func _ready():
	redraw_sphere()

func redraw_sphere():
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	tri (Vector3(  0.0,  1.0,  0.0),
		 Vector3(  0.0,  0.0, -1.0),
		 Vector3(  1.0,  0.0,  0.0))
	tri (Vector3(  1.0,  0.0,  0.0),
		 Vector3(  0.0,  0.0, -1.0),
		 Vector3(  0.0, -1.0,  0.0))
	# back left
	tri( Vector3(  0.0,  1.0,  0.0),
		 Vector3( -1.0,  0.0,  0.0),
		 Vector3(  0.0,  0.0, -1.0))
	tri( Vector3(  0.0,  0.0, -1.0),
		 Vector3( -1.0,  0.0,  0.0),
		 Vector3(  0.0, -1.0,  0.0))
	# front right
	tri( Vector3(  0.0,  1.0,  0.0),
		 Vector3(  1.0,  0.0,  0.0),
		 Vector3(  0.0,  0.0,  1.0))
	tri( Vector3(  0.0,  0.0,  1.0),
		 Vector3(  1.0,  0.0,  0.0),
		 Vector3(  0.0, -1.0,  0.0))
	# front left
	tri( Vector3(  0.0,  1.0,  0.0),
		 Vector3(  0.0,  0.0,  1.0),
		 Vector3( -1.0,  0.0,  0.0))
	tri( Vector3( -1.0,  0.0,  0.0),
		 Vector3(  0.0,  0.0,  1.0),
		 Vector3(  0.0, -1.0,  0.0))
	
	st.index()
	st.generate_normals()
	mesh = st.commit()

func tri(v1 : Vector3, v2 : Vector3, v3: Vector3, level := subdivision_levels) -> void:
	if level > 0: # subdivide further
		var v12 := mp(v1, v2)
		var v23 := mp(v2, v3)
		var v31 := mp(v3, v1)
		tri(v1 , v12, v31, level-1)
		tri(v12, v2 , v23, level-1)
		tri(v23, v3 , v31, level-1)
		tri(v12, v23, v31, level-1)
	else: # emit vertices for this triangle
		pn(v1)
		pn(v2)
		pn(v3)

func mp(v1 : Vector3, v2: Vector3) -> Vector3:
	return (v1+v2).normalized()

func pn(v: Vector3) -> void:
	#st.set_normal(v)
	st.add_vertex(v)
