extends Orientable
class_name DoorWall

static func create(
	id: String, 
	size: Vector3,
	pos: Vector3,
	door: Door
) -> Node3D:
	var sideWidth = (size.x - door.width) / 2
	var topHeight = size.y - door.height
	
	var sideBlockSize = Vector3(sideWidth, size.y, size.z)
	var topBlockSize = Vector3(size.x, topHeight, size.z)
	
	var leftSideBlockPos = Vector3(-(door.width / 2 + sideWidth / 2), 0, 0)
	var rightSideBlockPos = Vector3(door.width / 2 + sideWidth / 2, 0, 0)
	var topSideBlockPos = Vector3(0, door.height / 2 + topHeight / 2, 0)
	
	var doorWall = DoorWall.new()
	doorWall.name = id
	doorWall.position = pos
	
	var wallBody = StaticBody3D.new()
	wallBody.collision_layer = 2
	
	doorWall.makeWallPart(wallBody, sideBlockSize, leftSideBlockPos)
	doorWall.makeWallPart(wallBody, sideBlockSize, rightSideBlockPos)
	doorWall.makeWallPart(wallBody, topBlockSize, topSideBlockPos)
	
	doorWall.add_child(wallBody)
	return doorWall
	
func makeWallPart(node, size, pos) -> void:
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = pos
	node.add_child(collision)
	
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	node.add_child(mesh)
