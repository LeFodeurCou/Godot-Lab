extends Orientable
class_name Wall

# Called when the node enters the scene tree for the first time.
static func create(id: String, size: Vector3, pos: Vector3) -> Wall:
	var wall = Wall.new()
	wall.name = id
	wall.position = pos
	var wallBody = StaticBody3D.new()
	wallBody.collision_layer = 2
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	wallBody.add_child(collision)
	
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	wallBody.add_child(mesh)
	
	wall.add_child(wallBody)
	return wall
